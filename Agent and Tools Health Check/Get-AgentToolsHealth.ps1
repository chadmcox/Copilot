<#
.SYNOPSIS
    Read-only health check for Copilot agents and tools (plugins, skills, MCP servers), Entra agent
    identities, agent identity blueprints and the tenant settings around them. Proof of concept.

.DESCRIPTION
    Uses only Connect-MgGraph and Invoke-MgGraphRequest (module Microsoft.Graph.Authentication),
    on the Graph beta endpoint. Changes nothing.

    It checks (rules in Cowork/plugin/skills/agent-tools-health/references/rules.md):
      - Agents and tools: available to or installed for everyone, assigned to people instead of
        groups, groups with fewer than two owners or no description, unclear names, missing
        descriptions, old pending requests, no use in -StaleDays.
      - Agent identities: no sponsor, sponsor or owner disabled or gone, high-privilege
        permissions, single sponsor, unclear names, stale or never signed in, agent user accounts.
      - Blueprints: All allowed inheritable permissions, no sponsor or owner, client secrets,
        expiring secrets, unclear names, no description, nothing active under them.
      - Tenant: Conditional Access for agent identities and for risky agents.
      - Discovered agents (Microsoft Defender, KQL through Graph advanced hunting): agents in
        Defender's AgentsInfo inventory that aren't in the Agent 365 registry, cloud agents with no
        Entra agent identity, MCP servers reached without TLS or on a host outside this script's list
        of Microsoft domains, and local AI agents found on devices. Without the Agent 365 catalog, AgentsInfo becomes the agent list
        (availability, owner and name checks). Agent 365 activity in CloudAppEvents (last 30 days)
        counts as use in the stale checks.
      - Agents without Agent ID: older Copilot Studio agents that run as classic
        service principals (tags AgentCreatedBy:CopilotStudio, AgenticApp, AIAgentBuilder,
        AgenticInstance, power-virtual-agents-*), not as Entra agent identities.

    Scores: every item starts at 100 (High -25, Medium -10, Low -3). Each area's score is the
    average of its items. Green 80+, Amber 50-79, Red under 50.

    Output (in -OutputFolder): Findings.csv, Scorecard.csv, Packages.csv, DefenderAgents.csv and
    Report.html. Packages.csv and DefenderAgents.csv are the files you attach in Copilot Cowork:
    the Enterprise MCP server can't read the Agent 365 catalog or run Defender hunting queries,
    so Cowork reads them from these files and reads everything else live. Use -PackagesOnly to
    write just those two files.
    The files name agents, groups and sponsors. Keep them private and out of source control.

    Permissions (delegated): CopilotPackages.Read.All (Agent 365 license, AI Administrator),
    Application.Read.All, AgentIdentityBlueprint.Read.All, AuditLog.Read.All (sign-ins),
    User.Read.All, Group.Read.All, Policy.Read.All (Conditional Access), ThreatHunting.Read.All
    (Defender advanced hunting; Security Reader role). Use -SkipDefender without Defender.

.EXAMPLE
    .\Get-AgentToolsHealth.ps1
    .\Get-AgentToolsHealth.ps1 -StaleDays 60
    .\Get-AgentToolsHealth.ps1 -PackagesOnly
    .\Get-AgentToolsHealth.ps1 -SkipPackages -SkipDefender
#>
[CmdletBinding()]
param(
    [int]$StaleDays          = 90,
    [int]$SecretWarningDays  = 30,
    [int]$PendingRequestDays = 14,
    [switch]$PackagesOnly,
    [switch]$SkipPackages,
    [switch]$SkipDefender,
    [string]$OutputFolder = ".\AgentToolsHealth-$(Get-Date -Format yyyyMMdd-HHmm)",

    # Words that make a name unclear. Matched at the start of a word, so "demo" also catches "demoe".
    [string]$UnclearNamePattern = '\b(test\w*|demo\w*|temp\b|tmp\b|copy\b|draft\b|sample\w*|poc\b|sandbox\w*|untitled\b|dummy\b|delete ?me\b|do not use\b)|^(new|my) (agent|plugin|skill|bot)\b|\b(agent|plugin|skill|bot) ?\d+$|\(\d+\)$',

    # Microsoft Graph application permissions treated as High risk for an agent. Other *.ReadWrite.All are Medium.
    [string]$HighPrivilegePattern = '^(Directory|RoleManagement|Application|AppRoleAssignment|Policy|User|Group|GroupMember|Domain|Organization)\.ReadWrite|^(Mail\.Send|Mail\.ReadWrite|Sites\.FullControl\.All|Files\.ReadWrite\.All|Sites\.ReadWrite\.All|Directory\.AccessAsUser\.All|full_access_as_app)$',
    [ValidateSet("Global", "USGov", "USGovDoD", "China")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

$scopes = @(
    if (-not $SkipPackages) { "CopilotPackages.Read.All" }
    if (-not $PackagesOnly) { "Application.Read.All", "AgentIdentity.Read.All", "AgentIdentityBlueprint.Read.All", "AgentIdentityBlueprintPrincipal.Read.All", "AuditLog.Read.All", "User.Read.All", "Group.Read.All", "Policy.Read.All" }
    if ($PackagesOnly)      { "Group.Read.All" }
    if (-not $SkipDefender) { "ThreatHunting.Read.All" }
)
# Which Microsoft cloud to sign in to. GCC uses Global, GCC High is USGov, DoD is USGovDoD.
# Not every Copilot or agent API exists in every national cloud; check Microsoft's docs for yours.
if (-not $Environment) {
    Get-MgEnvironment | Select-Object Name, GraphEndpoint | Out-Host
    $choice = Read-Host "Type the cloud to connect to (Global, USGov, USGovDoD or China). Press Enter for Global"
    $Environment = if ($choice -in "Global", "USGov", "USGovDoD", "China") { $choice } else { "Global" }
}
$graphEndpoint = (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint

Connect-MgGraph -Environment $Environment -NoWelcome -Scopes $scopes

$graph  = "$graphEndpoint/beta"   # beta everywhere; it usually has more
$now    = (Get-Date).ToUniversalTime()
$cutoff = $now.AddDays(-$StaleDays)
$userCache  = @{}
$groupCache = @{}

# ---------------------------------------------------------------------------
# Graph helpers
# ---------------------------------------------------------------------------

# GET every page of a collection and send each item down the pipeline.
function Get-GraphAll([string]$Uri) {
    while ($Uri) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        $page.value
        $Uri = $page.'@odata.nextLink'
    }
}

# GET one object or collection. Returns $null when it fails (for example, a deleted user).
function Get-GraphOptional([string]$Uri) {
    try { Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject }
    catch { $null }
}

function Get-GraphAllOptional([string]$Uri) {
    try { @(Get-GraphAll $Uri) }
    catch { Write-Warning "Couldn't read $Uri. $($_.Exception.Message)" }
}

function ConvertTo-Utc($Value) { if ($Value) { ([datetime]$Value).ToUniversalTime() } }

# A user, cached. $null when the user is gone.
function Get-User([string]$Id) {
    if (-not $userCache.ContainsKey($Id)) { $userCache[$Id] = Get-GraphOptional "$graph/users/$($Id)?`$select=id,displayName,userPrincipalName,accountEnabled" }
    $userCache[$Id]
}

# A group with its owner count, cached. $null when the group is gone.
function Get-Group([string]$Id) {
    if (-not $groupCache.ContainsKey($Id)) {
        $g = Get-GraphOptional "$graph/groups/$($Id)?`$select=id,displayName,description"
        $groupCache[$Id] = if ($g) {
            $g | Select-Object id, displayName, description,
                @{ n = "ownerCount"; e = { @(Get-GraphAllOptional "$graph/groups/$Id/owners?`$select=id").Count } }
        }
    }
    $groupCache[$Id]
}

# ---------------------------------------------------------------------------
# Findings and scores
# ---------------------------------------------------------------------------

# Area: Agents, Tools, Agent identities, Blueprints or Tenant. Item: the object the finding is about.
function New-Finding([string]$Area, [string]$Item, [string]$Severity, [string]$Check, [string]$Fix) {
    $Item | Select-Object @{ n = "Area"; e = { $Area } },
        @{ n = "Item";     e = { $_ } },
        @{ n = "Category"; e = { Get-Category $Check } },
        @{ n = "Severity"; e = { $Severity } },
        @{ n = "Check";    e = { $Check } },
        @{ n = "Fix";      e = { $Fix } },
        @{ n = "Reference"; e = { Get-Reference $Check } }
}

# Category for the report's filters, from the check text.
function Get-Category([string]$Check) {
    switch -Regex ($Check) {
        'Conditional Access|high-risk'                     { "Security"; break }
        'sponsor|owner'                                    { "Ownership"; break }
        'Agent ID|classic service principal'               { "Identity"; break }
        'Defender|registry|Local AI agent'                 { "Inventory"; break }
        'MCP server'                                       { "Tools"; break }
        'permission|secret|credential|agent user'          { "Permissions"; break }
        "^Group '|Available|Installed|Assigned"           { "Access"; break }
        'name|description'                                 { "Naming"; break }
        default                                            { "Usage" }
    }
}

# CIS Controls v8.1 safeguards and CISA "Careful Adoption of Agentic AI Services" risk categories
# behind each check. See Cowork/plugin/skills/agent-tools-health/references/guidance.md.
function Get-Reference([string]$Check) {
    switch -Regex ($Check) {
        'not in the Agent 365 registry|Not in the registry'      { "CIS 1.1, 2.1, 2.3 | CISA: accountability"; break }
        'Local AI agent'                                         { "CIS 2.1, 2.3, 2.5 | CISA: design and configuration"; break }
        'MCP server without TLS'                                 { "CIS 3.10 | CISA: design and configuration"; break }
        'external MCP server'                                    { "CIS 2.5, 15.1 | CISA: design and configuration"; break }
        '\(Agent ID\)|not an Agent ID'                        { "CIS 5.5, 5.6 | CISA: design and configuration, accountability"; break }
        'No sponsor|no longer exists|is disabled|One sponsor|No owner|no owner' { "CIS 5.1, 5.5 | CISA: accountability"; break }
        "^Group '.*owner"                                        { "CIS 5.1, 6.1 | CISA: accountability"; break }
        'High-privilege|Tenant-wide write'                       { "CIS 3.3, 5.4 | CISA: privilege"; break }
        'Inheritable permissions'                                { "CIS 3.3, 6.8 | CISA: privilege, structural"; break }
        'client secret|credential'                               { "CIS 4.1 | CISA: design and configuration"; break }
        'agent user account'                                     { "CIS 5.5 | CISA: privilege"; break }
        'high-risk agents'                                       { "CIS 6.7 | CISA: behavioral"; break }
        'Conditional Access'                                     { "CIS 4.1, 6.7 | CISA: design and configuration"; break }
        'Available to all|Installed for the entire|directly, not through a group|available to all users|no longer exists' { "CIS 6.1, 6.8 | CISA: privilege"; break }
        "^Group '"                                               { "CIS 6.1 | CISA: accountability"; break }
        'Unclear name|description'                               { "CIS 2.1, 5.5 | CISA: accountability"; break }
        'Not used|No sign-in|No active agents'                   { "CIS 5.3, 6.2 | CISA: accountability"; break }
        'pending'                                                { "CIS 6.1"; break }
        default                                                  { "" }
    }
}

function Test-UnclearName([string]$Name) { -not $Name -or $Name.Trim().Length -lt 4 -or $Name -match $UnclearNamePattern }
function Test-PoorDescription([string]$Text, [string]$Name) { -not $Text -or $Text.Trim().Length -lt 20 -or $Text.Trim() -eq $Name.Trim() }

# Score each area: the average of its items' scores. Items with no findings score 100.
function Get-AreaScore {
    param([Parameter(ValueFromPipeline)]$Area, $Findings)
    begin { $weights = @{ High = 25; Medium = 10; Low = 3; Info = 0 } }
    process {
        $areaFindings = @($Findings | Where-Object Area -eq $Area.Name)
        $byItem = $areaFindings | Group-Object Item -AsHashTable -AsString
        if (-not $byItem) { $byItem = @{} }
        $itemScores = @($Area.Items | ForEach-Object { [math]::Max(0, 100 - (@($byItem["$_"]) | Where-Object { $_ } | ForEach-Object { $weights[$_.Severity] } | Measure-Object -Sum).Sum) })
        $Area | Select-Object @{ n = "Area"; e = { $_.Name } },
            @{ n = "Score";  e = { if ($itemScores) { [int][math]::Round(($itemScores | Measure-Object -Average).Average) } else { 100 } } },
            @{ n = "Items";  e = { $itemScores.Count } },
            @{ n = "High";   e = { @($areaFindings | Where-Object Severity -eq "High").Count } },
            @{ n = "Medium"; e = { @($areaFindings | Where-Object Severity -eq "Medium").Count } },
            @{ n = "Low";    e = { @($areaFindings | Where-Object Severity -eq "Low").Count } },
            @{ n = "Info";   e = { @($areaFindings | Where-Object Severity -eq "Info").Count } } |
        Select-Object Area, Score, @{ n = "Rating"; e = { if ($_.Score -ge 80) { "Green" } elseif ($_.Score -ge 50) { "Amber" } else { "Red" } } }, Items, High, Medium, Low, Info
    }
}

# ---------------------------------------------------------------------------
# Agents and tools (Agent 365 catalog)
# ---------------------------------------------------------------------------

function Get-PackageKind($ElementTypes) {
    $types = @($ElementTypes) -join " "
    if ($types -match 'declarativeAgent|customEngine|bot')     { "Agent" }
    elseif ($types -match 'skill|connector|mcp|plugin|action') { "Tool" }
    else                                                       { "App" }
}

# One row per package, with the detail call's usage and access fields. This is Packages.csv.
function Get-PackageRow {
    process {
        $p = $_
        $d = Get-GraphOptional "$graph/copilot/admin/catalog/packages/$([uri]::EscapeDataString($p.id))"
        if (-not $d) { Write-Warning "Couldn't read details for '$($p.displayName)'."; $d = $p }
        $allowed = @($d.allowedUsersAndGroups) + @($d.acquireUsersAndGroups) | Where-Object { $_ }
        $d | Select-Object id, displayName,
            @{ n = "kind";             e = { Get-PackageKind $_.elementTypes } },
            @{ n = "elementTypes";     e = { @($_.elementTypes) -join ";" } },
            type, publisher, shortDescription, appId, manifestId, assetId, agentIdentityId, isBlocked, availableTo, deployedTo, requestStatus, requestType,
            @{ n = "groupIds";         e = { @($allowed | Where-Object resourceType -eq "group" | ForEach-Object resourceId | Sort-Object -Unique) -join ";" } },
            @{ n = "groups";           e = { @($allowed | Where-Object resourceType -eq "group" | ForEach-Object resourceId | Sort-Object -Unique | ForEach-Object { (Get-Group $_).displayName }) -join "; " } },
            @{ n = "directUsers";      e = { @($allowed | Where-Object resourceType -eq "user" | ForEach-Object resourceId | Sort-Object -Unique).Count } },
            @{ n = "lastModifiedDateTime"; e = { ConvertTo-Utc $_.lastModifiedDateTime } },
            @{ n = "lastUsedDateTime"; e = { ConvertTo-Utc $_.lastUsedDateTime } },
            @{ n = "activeUsers30d";   e = { $_.activeUsers } },
            @{ n = "sessions30d";      e = { $_.totalSessions } }
    }
}

function Test-Package($P, $ActivityByKey) {
    if ($P.kind -eq "App") { return }   # Office add-ins and other apps aren't in scope
    $area = if ($P.kind -eq "Agent") { "Agents" } else { "Tools" }
    $name = $P.displayName
    $custom = $P.type -ne "microsoft"

    if ($custom -and $P.availableTo -match "^all$|ForAll$") { New-Finding $area $name "High" "Available to all users" "Make it available to specific groups" }
    if ($custom -and $P.deployedTo -match "^all$|ForAll$") { New-Finding $area $name "High" "Installed for the entire organization" "Install it for a group, or let people install it themselves" }
    if ($P.directUsers -gt 0) { New-Finding $area $name "Medium" "Assigned to $($P.directUsers) $(if ($P.directUsers -eq 1) { 'person' } else { 'people' }) directly, not through a group" "Assign it to a group instead" }
    @($P.groupIds -split ";") | Where-Object { $_ } | ForEach-Object {
        $g = Get-Group $_
        if (-not $g) { New-Finding $area $name "Medium" "Assigned to a group that no longer exists" "Assign it to the right group" }
        elseif ($g.ownerCount -lt 2) { New-Finding $area $name "Medium" "Group '$($g.displayName)' has $($g.ownerCount) owner(s)" "Add owners so there are at least two" }
        elseif (-not $g.description) { New-Finding $area $name "Low" "Group '$($g.displayName)' has no description" "Describe the group and name the agent or tool it's for" }
    }
    if ($custom -and $P.kind -eq "Agent" -and $P.elementTypes -match 'customEngine|bot' -and -not $P.agentIdentityId) {
        New-Finding $area $name "Low" "No Entra agent identity (Agent ID)" "If it's a custom agent you own, move it to Agent ID so it gets a sponsor, Conditional Access and lifecycle controls"
    }
    if ($custom -and (Test-UnclearName $name)) { New-Finding $area $name "Medium" "Unclear name" "Rename it so people can tell what it does and who owns it" }
    if ($custom -and (Test-PoorDescription $P.shortDescription $name)) { New-Finding $area $name "Medium" "Missing or too-short description" "Describe what it does, for whom, and what data it uses" }
    if ($P.requestStatus -eq "pending" -and $P.lastModifiedDateTime -and $P.lastModifiedDateTime -lt $now.AddDays(-$PendingRequestDays)) {
        New-Finding $area $name "Low" "Request ($($P.requestType)) pending for more than $PendingRequestDays days" "Approve or reject it"
    }
    $defenderLast = @($P.id, $P.appId, $P.manifestId, $P.assetId, $P.agentIdentityId) | Where-Object { $_ -and $ActivityByKey["$_"] } | ForEach-Object { $ActivityByKey["$_"] } | Sort-Object -Descending | Select-Object -First 1
    $lastUsed = @($P.lastUsedDateTime, $defenderLast) | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
    if ($custom -and -not $P.isBlocked -and -not ($P.activeUsers30d -gt 0) -and (-not $lastUsed -or $lastUsed -lt $cutoff) -and $P.lastModifiedDateTime -lt $cutoff) {
        New-Finding $area $name "Medium" "Not used in $StaleDays days" "Block it, or run Agent and Tools Cleanup"
    }
}

# ---------------------------------------------------------------------------
# Agent identities and blueprints
# ---------------------------------------------------------------------------

# Microsoft Graph app role ID -> permission name, to read appRoleAssignments.
function Get-GraphRoleNames {
    $index = @{}
    $sp = Get-GraphOptional "$graph/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?`$select=id,appRoles"
    $sp.appRoles | Where-Object id | ForEach-Object { $index[$_.id] = $_.value }
    $index["__id"] = $sp.id
    $index
}

# Permission names an agent (identity or blueprint principal) holds on Microsoft Graph.
function Get-GraphPermission([string]$ServicePrincipalId, $RoleNames) {
    @(Get-GraphAllOptional "$graph/servicePrincipals/$ServicePrincipalId/appRoleAssignments?`$select=appRoleId,resourceId") |
        Where-Object { $_.resourceId -eq $RoleNames["__id"] } | ForEach-Object { $RoleNames[$_.appRoleId] }
    @(Get-GraphAllOptional "$graph/oauth2PermissionGrants?`$filter=$([uri]::EscapeDataString("clientId eq '$ServicePrincipalId'"))") |
        Where-Object { $_.resourceId -eq $RoleNames["__id"] } | ForEach-Object { $_.scope -split " " } | Where-Object { $_ }
}

function Test-Permission([string]$Area, [string]$Name, [string[]]$Permissions) {
    $high = @($Permissions | Where-Object { $_ -match $HighPrivilegePattern } | Sort-Object -Unique)
    $broad = @($Permissions | Where-Object { $_ -notmatch $HighPrivilegePattern -and $_ -match '\.ReadWrite\.All$' } | Sort-Object -Unique)
    if ($high) { New-Finding $Area $Name "High" "High-privilege Graph permissions: $($high -join ', ')" "Replace them with narrower permissions (least privilege), or remove them" }
    if ($broad) { New-Finding $Area $Name "Medium" "Tenant-wide write permissions: $($broad -join ', ')" "Check each one is needed; prefer Selected or narrower scopes" }
}

function Test-People([string]$Area, [string]$Name, $Sponsors, $Owners) {
    $sponsorIds = @($Sponsors | ForEach-Object id)
    $ownerIds   = @($Owners | ForEach-Object id)
    if (-not $sponsorIds) { New-Finding $Area $Name "High" "No sponsor" "Add a sponsor: the person accountable for what it does" }
    @($sponsorIds + $ownerIds | Sort-Object -Unique) | Where-Object { $_ } | ForEach-Object {
        $u = Get-User $_
        if (-not $u) { New-Finding $Area $Name "High" "A sponsor or owner no longer exists" "Replace them with an active person" }
        elseif (-not $u.accountEnabled) { New-Finding $Area $Name "High" "Sponsor or owner $($u.displayName) is disabled" "Replace them with an active person" }
    }
    if ($sponsorIds.Count -eq 1 -and -not $ownerIds) { New-Finding $Area $Name "Medium" "One sponsor and no owner" "Add an owner (technical admin) or a second sponsor" }
}

function Test-Identity($I, $SignIns, $RoleNames) {
    $name = $I.displayName
    $last = ConvertTo-Utc $SignIns[$I.appId]
    $created = ConvertTo-Utc $I.createdDateTime
    Test-People "Agent identities" $name $I.sponsors @(Get-GraphAllOptional "$graph/servicePrincipals/$($I.id)/owners?`$select=id")
    Test-Permission "Agent identities" $name @(Get-GraphPermission $I.id $RoleNames)
    if (Test-UnclearName ($name -replace '\s*\(Microsoft Copilot Studio\)$', '')) { New-Finding "Agent identities" $name "Medium" "Unclear name" "Rename the agent so people can tell what it does and who owns it" }
    if ($I.accountEnabled -and $last -and $last -lt $cutoff) { New-Finding "Agent identities" $name "Medium" "No sign-in for $StaleDays days" "Ask the sponsor if it's still needed, or run Agent and Tools Cleanup" }
    if ($I.accountEnabled -and -not $last -and $created -lt $cutoff) { New-Finding "Agent identities" $name "Low" "No sign-in recorded, created more than $StaleDays days ago" "Ask the sponsor if it's still needed" }
}

function Test-Blueprint($B, $Principal, $Children, $SignIns, $RoleNames) {
    $name = $B.displayName
    Test-People "Blueprints" $name $B.sponsors @(Get-GraphAllOptional "$graph/applications/$($B.id)/owners?`$select=id")
    @(Get-GraphAllOptional "$graph/applications/$($B.id)/microsoft.graph.agentIdentityBlueprint/inheritablePermissions") |
        Where-Object { $_.inheritableScopes.kind -eq "allAllowed" -or $_.inheritableRoles.kind -eq "allAllowed" } | ForEach-Object {
            $resource = if ($_.resourceAppId -eq "00000003-0000-0000-c000-000000000000") { "Microsoft Graph" } else { $_.resourceAppId }
            New-Finding "Blueprints" $name "High" "Inheritable permissions set to All allowed for $resource" "List only the scopes its agents need (enumerated scopes)"
        }
    if ($Principal) { Test-Permission "Blueprints" $name @(Get-GraphPermission $Principal.id $RoleNames) }
    if ($B.passwordCredentials) { New-Finding "Blueprints" $name "Medium" "Uses a client secret" "Use a certificate or a federated credential (managed identity) instead" }
    @($B.passwordCredentials) + @($B.keyCredentials) | Where-Object { $_ -and $_.endDateTime } | ForEach-Object {
        $end = ConvertTo-Utc $_.endDateTime
        if ($end -lt $now) { New-Finding "Blueprints" $name "Medium" "A credential expired on $($end.ToString('yyyy-MM-dd'))" "Remove it" }
        elseif ($end -lt $now.AddDays($SecretWarningDays)) { New-Finding "Blueprints" $name "Medium" "A credential expires on $($end.ToString('yyyy-MM-dd'))" "Roll it before then" }
    }
    if (Test-UnclearName $name) { New-Finding "Blueprints" $name "Medium" "Unclear name" "Rename it so people can tell which agents it's for" }
    if (Test-PoorDescription $B.description $name) { New-Finding "Blueprints" $name "Medium" "Missing or too-short description" "Describe its purpose, scope and owning team" }
    $active = @($Children | Where-Object { $_.accountEnabled -and (($l = ConvertTo-Utc $SignIns[$_.appId]) -and $l -ge $cutoff -or (ConvertTo-Utc $_.createdDateTime) -ge $cutoff) })
    $lastBp = ConvertTo-Utc $SignIns[$B.appId]
    if (-not $active -and (-not $lastBp -or $lastBp -lt $cutoff) -and (ConvertTo-Utc $B.createdDateTime) -lt $cutoff) {
        New-Finding "Blueprints" $name "Low" "No active agents and no sign-in for $StaleDays days" "Check it's still needed, or run Agent and Tools Cleanup"
    }
}

# ---------------------------------------------------------------------------
# Tenant settings
# ---------------------------------------------------------------------------

function Test-Tenant {
    $policies = @(Get-GraphAllOptional "$graph/identity/conditionalAccess/policies?`$select=displayName,state,conditions,grantControls")
    $agentPolicies = @($policies | Where-Object { $_.conditions.clientApplications.includeAgentIdServicePrincipals -or $_.conditions.clientApplications.agentIdServicePrincipalFilter -or $_.conditions.agents -or $_.conditions.agentIdRiskLevels })
    if (-not $agentPolicies) { New-Finding "Tenant" "Conditional Access" "High" "No Conditional Access policy targets agent identities" "Create agent policies (start in report-only): block high-risk agents, and limit what non-production agents reach" }
    elseif (-not ($agentPolicies | Where-Object state -eq "enabled")) { New-Finding "Tenant" "Conditional Access" "Medium" "Agent Conditional Access policies are report-only or off" "Review the report-only results, then turn them on" }
    if (-not ($agentPolicies | Where-Object { $_.state -eq "enabled" -and "$($_.conditions.agentIdRiskLevels)" -match "high" -and $_.grantControls.builtInControls -contains "block" })) {
        New-Finding "Tenant" "Conditional Access" "Medium" "No enabled policy blocks high-risk agents" "Add a policy that blocks agent identities at high risk"
    }
}

# ---------------------------------------------------------------------------
# Discovered agents (Microsoft Defender AgentsInfo)
# ---------------------------------------------------------------------------

# Latest record of every agent Defender knows about. One row per agent. This is DefenderAgents.csv.
function Get-DefenderAgent {
    $kql = @'
AgentsInfo
| summarize arg_max(Timestamp, *) by AgentId
| where LifecycleStatus != "Deleted"
| extend AgentName = iff(isempty(AgentName), tostring(column_ifexists("Name", "")), AgentName)
| project AgentId, AgentName, Platform, SourceAgentId, EntraAgentId, EntraBlueprintId, Availability,
    PublishedStatus, LifecycleStatus, CreatedDateTime, LastUpdatedDateTime, OwnerCount = array_length(Owners),
    McpServerUrls = strcat_array(extract_all(@'(https?://[^\s"\],}]+)', tostring(McpServers)), ";"),
    SkillCount = array_length(Skills), ToolCount = array_length(DeclaredTools)
'@
    $activity = Get-DefenderActivity
    Invoke-HuntingQuery $kql | ForEach-Object {
        # CloudAppEvents names agents by their Entra appId. For Agent ID agents that equals EntraAgentId.
        $hit = @($_.EntraAgentId, $_.SourceAgentId, $_.AgentId) | Where-Object { $_ -and $activity["$_"] } | ForEach-Object { $activity["$_"] } | Select-Object -First 1
        $_ | Select-Object AgentId, AgentName, Platform, SourceAgentId, EntraAgentId, EntraBlueprintId, Availability,
            PublishedStatus, LifecycleStatus, CreatedDateTime, LastUpdatedDateTime, OwnerCount, McpServerUrls, SkillCount, ToolCount,
            @{ n = "LastActivity";   e = { $hit.LastActivity } },
            @{ n = "Invocations30d"; e = { $hit.Invocations } },
            @{ n = "ToolCalls30d";   e = { $hit.ToolCalls } }
    }
}

# Runs a KQL query through Graph advanced hunting and returns the rows.
function Invoke-HuntingQuery([string]$Kql) {
    $body = @{ Query = $Kql; Timespan = "P30D" } | ConvertTo-Json
    (Invoke-MgGraphRequest -Method POST -Uri "$graph/security/runHuntingQuery" -Body $body -ContentType "application/json" -OutputType PSObject).results
}

# Agent 365 activity (CloudAppEvents) for the last 30 days, keyed by the agent's Entra appId. Only agents
# that send Agent 365 observability data appear, so a missing agent isn't proof that it's unused.
# Per Microsoft's attribute reference, on InvokeAgent records AgentId is the *calling* agent (all zeros
# when a person invokes it) and TargetAgentId is the invoked agent; on tool calls AgentId is the agent.
function Get-DefenderActivity {
    $kql = @'
CloudAppEvents
| where ActionType in ("InvokeAgent", "ExecuteToolByMCPServer", "ExecuteToolByGateway", "ExecuteToolBySDK")
| extend Raw = parse_json(tostring(RawEventData))
| extend AgentAppId = iff(ActionType == "InvokeAgent", tostring(Raw.TargetAgentId), tostring(Raw.AgentId))
| where isnotempty(AgentAppId) and AgentAppId != "00000000-0000-0000-0000-000000000000"
| summarize LastActivity = max(Timestamp), Invocations = countif(ActionType == "InvokeAgent"), ToolCalls = countif(ActionType startswith "ExecuteTool") by AgentAppId
'@
    $index = @{}
    try { Invoke-HuntingQuery $kql | ForEach-Object { $index[$_.AgentAppId] = $_ } }
    catch { Write-Warning "Couldn't read agent activity from CloudAppEvents. $($_.Exception.Message)" }
    $index
}

# Defender's last activity for each registry key (package id, app ID, agent identity...), for usage checks.
function Get-ActivityByKey($Agents) {
    $index = @{}
    $Agents | Where-Object LastActivity | ForEach-Object {
        $a = $_
        @($a.AgentId, $a.SourceAgentId, $a.EntraAgentId) | Where-Object { $_ } | ForEach-Object { $index["$_"] = ConvertTo-Utc $a.LastActivity }
    }
    $index
}

# This script's own list of Microsoft domains (not a Microsoft-published list). A host outside it is
# flagged Low as an external MCP server to check against your approved tools list.
$microsoftHosts = '\.(microsoft|cloud\.microsoft|office|office365|sharepoint|azure|azure-api|windows|dynamics|powerplatform|powerapps|azurewebsites|svc\.cloud\.microsoft)\.(com|net|microsoft)$|\.cloud\.microsoft$'

function Test-AgentTools([string]$Area, [string]$Name, [string]$Urls) {
    @($Urls -split ";") | Where-Object { $_ } | Sort-Object -Unique | ForEach-Object {
        $uri = $_ -as [uri]
        if ($_ -like "http://*") { New-Finding $Area $Name "High" "Connects to an MCP server without TLS: $_" "Use HTTPS only, or remove the server" }
        elseif ($uri -and $uri.Host -notmatch $microsoftHosts) { New-Finding $Area $Name "Low" "Connects to an external MCP server: $($uri.Host)" "Check it's on your approved tools list (Agents > Tools), and who runs it" }
    }
}

# Every ID a registry package can be known by, so Defender's agents can be matched to it.
function Get-RegistryKey($Packages) {
    $keys = @{}
    $Packages | ForEach-Object { @($_.id, $_.appId, $_.manifestId, $_.assetId, $_.agentIdentityId) } | Where-Object { $_ } | ForEach-Object { $keys["$_"] = $true }
    $keys
}

function Test-DefenderAgent($Agents, $RegistryKeys, [bool]$HaveRegistry) {
    $cloud = @($Agents | Where-Object { $_.Platform -ne "LocalAgents" -and $_.LifecycleStatus -ne "Uninstalled" })
    $cloud | ForEach-Object {
        $name = if ($_.AgentName) { "$($_.AgentName) ($($_.Platform))" } else { "$($_.AgentId) ($($_.Platform))" }
        $inRegistry = [bool](@($_.AgentId, $_.SourceAgentId, $_.EntraAgentId) | Where-Object { $_ -and $RegistryKeys["$_"] })
        if ($HaveRegistry -and -not $inRegistry) {
            New-Finding "Discovered agents" $name "Medium" "Found by Defender, but not in the Agent 365 registry" "Add it to the registry (registry sync) with an owner, or remove it"
            if ("$($_.Availability)" -match "all") { New-Finding "Discovered agents" $name "High" "Not in the registry, and available to all users" "Limit it to a group, then register it" }
            if (-not ($_.OwnerCount -gt 0)) { New-Finding "Discovered agents" $name "Medium" "Not in the registry, and no owner" "Find who built it and make them the owner, or remove it" }
        }
        if (-not $HaveRegistry) {
            # No Agent 365 catalog: use Defender's inventory as the agent list.
            if ("$($_.Availability)" -match "all") { New-Finding "Discovered agents" $name "High" "Available to all users" "Make it available to specific groups" }
            if (-not ($_.OwnerCount -gt 0)) { New-Finding "Discovered agents" $name "Medium" "No owner" "Find who built it and make them the owner, or remove it" }
            if (Test-UnclearName $_.AgentName) { New-Finding "Discovered agents" $name "Medium" "Unclear name" "Rename it so people can tell what it does and who owns it" }
        }
        if (-not $_.EntraAgentId) { New-Finding "Discovered agents" $name "Medium" "No Entra agent identity (Agent ID)" "Find who owns it and whether its platform supports Agent ID; an agent identity adds a sponsor, Conditional Access and lifecycle controls" }
        Test-AgentTools "Discovered agents" $name $_.McpServerUrls
    }
    # Local AI agents (coding assistants and the like) seen on devices: one finding per agent name.
    # Each AgentsInfo row for a local agent is one installation (one agent, device and account).
    $Agents | Where-Object { $_.Platform -eq "LocalAgents" -and $_.LifecycleStatus -ne "Uninstalled" } | Group-Object AgentName | ForEach-Object {
        New-Finding "Discovered agents" "$($_.Name) (local)" "Low" "Local AI agent found in $($_.Count) installation$(if ($_.Count -ne 1) { 's' }) on devices" "Check it's an approved tool; govern it with Defender for Endpoint and Intune"
    }
}

# ---------------------------------------------------------------------------
# Agents without Agent ID (classic service principals)
# ---------------------------------------------------------------------------

function Get-ClassicAgent($AgentObjectIds) {
    $select = "`$select=id,appId,displayName,accountEnabled,tags,createdDateTime"
    $byId = @{}
    @(
        "tags/any(t:t eq 'AgentCreatedBy:CopilotStudio')"
        "tags/any(t:t eq 'AgenticApp')"
        "tags/any(t:t eq 'AIAgentBuilder')"
        "tags/any(t:t eq 'AgenticInstance')"
        "tags/any(t:startswith(t,'power-virtual-agents-'))"
    ) | ForEach-Object { Get-GraphAllOptional "$graph/servicePrincipals?`$filter=$([uri]::EscapeDataString($_))&$select" } |
        Where-Object { $_ -and -not $AgentObjectIds[$_.id] -and "$($_.'@odata.type')" -notmatch 'agentIdentity' } |
        ForEach-Object { $byId[$_.id] = $_ }
    $byId.Values
}

function Test-ClassicAgent($S, $SignIns) {
    $name = $S.displayName
    $last = ConvertTo-Utc $SignIns[$S.appId]
    $made = if ($S.tags -contains "AgentCreatedBy:CopilotStudio" -or ($S.tags -match '^power-virtual-agents-')) { "Copilot Studio" } else { "an older platform" }
    New-Finding "Agents without Agent ID" $name "Medium" "Agent from $made runs as a classic service principal, not an Agent ID" "There's no in-place migration. Unused: retire it. Lightly used: recreate it with Agent ID, then retire this one. Busy production agent: Microsoft says wait for an automated migration path"
    if (-not @(Get-GraphAllOptional "$graph/servicePrincipals/$($S.id)/owners?`$select=id").Count) { New-Finding "Agents without Agent ID" $name "Medium" "No owner" "Find who built it and make them the owner" }
    if ($S.accountEnabled -and (-not $last -or $last -lt $cutoff) -and (ConvertTo-Utc $S.createdDateTime) -lt $cutoff) {
        New-Finding "Agents without Agent ID" $name "Low" "No sign-in for $StaleDays days" "Check with the owner, then retire it instead of recreating it"
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$packages = @()
if (-not $SkipPackages) {
    Write-Host "Reading the Agent 365 catalog (one detail call per package)..."
    try { $packages = @(Get-GraphAll "$graph/copilot/admin/catalog/packages" | Get-PackageRow) }
    catch { Write-Warning "Couldn't read the Agent 365 catalog. It needs an Agent 365 license and the AI Administrator role. Run with -SkipPackages to skip it. $($_.Exception.Message)" }
    $packages | Export-Csv (Join-Path $OutputFolder "Packages.csv") -NoTypeInformation -Encoding UTF8
}
$defenderAgents = @()
$haveDefender = $false
if (-not $SkipDefender) {
    Write-Host "Reading Microsoft Defender's agent inventory (AgentsInfo)..."
    try {
        $defenderAgents = @(Get-DefenderAgent)
        $haveDefender = $true
        $defenderAgents | Export-Csv (Join-Path $OutputFolder "DefenderAgents.csv") -NoTypeInformation -Encoding UTF8
    }
    catch { Write-Warning "Couldn't run the Defender hunting query. It needs ThreatHunting.Read.All and the Security Reader role. Run with -SkipDefender to skip it. $($_.Exception.Message)" }
}
if ($PackagesOnly) {
    Write-Host "Saved Packages.csv and DefenderAgents.csv to $OutputFolder. Attach them in Copilot Cowork with the prompt in the Cowork folder of this repo."
    return
}

Write-Host "Reading agent identities, blueprints and sign-in activity..."
$signIns = @{}
Get-GraphAllOptional "$graph/reports/servicePrincipalSignInActivities" | Where-Object appId | ForEach-Object { $signIns[$_.appId] = $_.lastSignInActivity.lastSignInDateTime }
$roleNames  = Get-GraphRoleNames
$identities = @(Get-GraphAllOptional "$graph/servicePrincipals/microsoft.graph.agentIdentity?`$select=id,appId,displayName,accountEnabled,agentIdentityBlueprintId,createdDateTime&`$expand=sponsors(`$select=id)")
$blueprints = @(Get-GraphAllOptional "$graph/applications/microsoft.graph.agentIdentityBlueprint?`$select=id,appId,displayName,description,createdDateTime,passwordCredentials,keyCredentials&`$expand=sponsors(`$select=id)")
$principals = @{}
Get-GraphAllOptional "$graph/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal?`$select=id,appId,displayName" | ForEach-Object { $principals[$_.appId] = $_ }
$agentUsers = @(Get-GraphAllOptional "$graph/users/microsoft.graph.agentUser?`$select=id,displayName,identityParentId")
$agentObjectIds = @{}
@($identities.id) + @($principals.Values | ForEach-Object id) | Where-Object { $_ } | ForEach-Object { $agentObjectIds[$_] = $true }
Write-Host "Looking for agents without Agent ID..."
$classicAgents = @(Get-ClassicAgent $agentObjectIds)
$children = $identities | Where-Object agentIdentityBlueprintId | Group-Object agentIdentityBlueprintId -AsHashTable -AsString
if (-not $children) { $children = @{} }

$findings = @(
    $activityByKey = Get-ActivityByKey $defenderAgents
    $packages | ForEach-Object { Test-Package $_ $activityByKey }
    $identities | ForEach-Object { Write-Host "  $($_.displayName)"; Test-Identity $_ $signIns $roleNames }
    $agentUsers | ForEach-Object {
        $parent = $identities | Where-Object id -eq $_.identityParentId | Select-Object -First 1
        New-Finding "Agent identities" $(if ($parent) { $parent.displayName } else { $_.displayName }) "Low" "Has an agent user account ($($_.displayName))" "Keep it only if the agent needs a mailbox or Teams presence"
    }
    # Blueprints registered in this tenant only; Microsoft's and other publishers' blueprints are theirs to fix.
    $blueprints | ForEach-Object { Test-Blueprint $_ $principals[$_.appId] @($children[$_.appId]) $signIns $roleNames }
    Test-Tenant
    if ($haveDefender) { Test-DefenderAgent $defenderAgents (Get-RegistryKey $packages) ([bool]$packages) }
    $classicAgents | ForEach-Object { Test-ClassicAgent $_ $signIns }
)

# Well-governed funnel for agent identities.
$identityFindings = $findings | Where-Object Area -eq "Agent identities" | Group-Object Item -AsHashTable -AsString
if (-not $identityFindings) { $identityFindings = @{} }
function Measure-Identity([scriptblock]$Filter) { @($identities | Where-Object $Filter).Count }
$noIssue = { param($Name, $Pattern) -not (@($identityFindings[$Name]) | Where-Object { $_ -and $_.Check -match $Pattern }) }
$step1 = { & $noIssue $_.displayName 'No sponsor|no longer exists|is disabled' }
$step2 = { (& $step1) -and (& $noIssue $_.displayName 'Unclear name') }
$step3 = { (& $step2) -and (& $noIssue $_.displayName 'High-privilege') }
$step4 = { (& $step3) -and (& $noIssue $_.displayName 'No sign-in') }
function New-FunnelStep([string]$Label, [int]$Count, [string]$Note) {
    $Label | Select-Object @{ n = "label"; e = { $Label } }, @{ n = "count"; e = { $Count } }, @{ n = "note"; e = { $Note } }
}
$funnel = @(
    New-FunnelStep "Agent identities" $identities.Count "Every agent identity in Entra"
    New-FunnelStep "With an active sponsor" (Measure-Identity $step1) "A sponsor, and every sponsor and owner is an active account"
    New-FunnelStep "With a clear name" (Measure-Identity $step2) "No test, demo, copy, draft or similar"
    New-FunnelStep "Least privilege" (Measure-Identity $step3) "No high-privilege Microsoft Graph permissions"
    New-FunnelStep "In use" (Measure-Identity $step4) "Signed in within $StaleDays days"
)
$governedPercent = if ($identities.Count) { [int][math]::Round(100 * (Measure-Identity $step4) / $identities.Count) } else { 0 }

$areas = @(
    "Agents"           | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @($packages | Where-Object kind -eq "Agent" | ForEach-Object displayName) } }
    "Tools"            | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @($packages | Where-Object kind -eq "Tool" | ForEach-Object displayName) } }
    "Agent identities" | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @($identities | ForEach-Object displayName) } }
    "Blueprints"       | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @($blueprints | ForEach-Object displayName) } }
    "Tenant"           | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @("Conditional Access") } }
    if ($haveDefender) {
        "Discovered agents" | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @(
            $defenderAgents | Where-Object { $_.Platform -ne "LocalAgents" -and $_.LifecycleStatus -ne "Uninstalled" } | ForEach-Object { if ($_.AgentName) { "$($_.AgentName) ($($_.Platform))" } else { "$($_.AgentId) ($($_.Platform))" } }
            $defenderAgents | Where-Object Platform -eq "LocalAgents" | ForEach-Object AgentName | Sort-Object -Unique | ForEach-Object { "$_ (local)" }) } }
    }
    "Agents without Agent ID" | Select-Object @{ n = "Name"; e = { $_ } }, @{ n = "Items"; e = { @($classicAgents | ForEach-Object displayName) } }
)
$scorecard = @($areas | Get-AreaScore -Findings $findings | Sort-Object Score)

$findings | Sort-Object @{ e = { @("High", "Medium", "Low", "Info").IndexOf($_.Severity) } }, Area, Item |
    Export-Csv (Join-Path $OutputFolder "Findings.csv") -NoTypeInformation -Encoding UTF8
$scorecard | Export-Csv (Join-Path $OutputFolder "Scorecard.csv") -NoTypeInformation -Encoding UTF8

# The same check in Copilot Cowork, so people can rerun it and follow up without PowerShell.
$coworkPrompt = @"
Run the agent and tools health check. Count anything unused for $StaleDays days as stale.

Use the attached Packages.csv for agents and tools, and the attached DefenderAgents.csv for agents Microsoft Defender found. Use the Microsoft MCP Server for Enterprise to read: service principals tagged as agents that aren't agent identities (agents without Agent ID); every agent identity with its sponsors, owners, Microsoft Graph permissions and last sign-in; every agent identity blueprint with its sponsors, owners, inheritable permissions, credentials and description; agent user accounts; the groups listed in Packages.csv (owners and description); and the Conditional Access policies.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the agent-tools-health rules and give me:
1. A scorecard: one row per area (Agents, Tools, Agent identities, Blueprints, Tenant, Discovered agents, Agents without Agent ID) with a score out of 100 and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the item, what's wrong and the fix.
3. The top 3 fixes to do first.
4. The well-governed funnel for agent identities: with an active sponsor, a clear name, least privilege, in use.
5. The Microsoft Graph calls you ran.
6. The HTML report from the skill's report template, named Agent and Tools Health.html.
"@

function Get-ReportTemplate {
    $local = Join-Path $PSScriptRoot "Cowork/plugin/skills/agent-tools-health/assets/report-template.html"
    if (Test-Path $local) { return Get-Content $local -Raw }
    try { (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chadmcox/Copilot/main/Agent%20and%20Tools%20Health%20Check/Cowork/plugin/skills/agent-tools-health/assets/report-template.html" -UseBasicParsing).Content }
    catch { Write-Warning "Couldn't get the report template, so Report.html is skipped. The CSV files are still saved." }
}

function New-HtmlReport([string]$Template, [string]$Path) {
    $data = [ordered]@{
        title        = "Agent and Tools Health"
        generated    = Get-Date -Format "yyyy-MM-dd HH:mm"
        source       = "PowerShell: Get-AgentToolsHealth.ps1"
        subjectLabel = "Area"
        areaLabel    = "Category"
        sample       = $false
        funnelTitle  = "Well-governed agent identities: $governedPercent%"
        funnel       = $funnel
        scorecard    = @($scorecard | Select-Object @{ n = "name"; e = { $_.Area } },
                          @{ n = "score"; e = { $_.Score } }, @{ n = "rating"; e = { $_.Rating } },
                          @{ n = "high"; e = { $_.High } }, @{ n = "medium"; e = { $_.Medium } },
                          @{ n = "low"; e = { $_.Low } }, @{ n = "info"; e = { $_.Info } },
                          @{ n = "detail"; e = { "$($_.Items) item$(if ($_.Items -ne 1) { 's' }) checked" } })
        findings     = @($findings | Select-Object @{ n = "subject"; e = { $_.Area } },
                          @{ n = "area"; e = { $_.Category } }, @{ n = "severity"; e = { $_.Severity } },
                          @{ n = "target"; e = { $_.Item } }, @{ n = "check"; e = { $_.Check } },
                          @{ n = "fix"; e = { if ($_.Reference) { "$($_.Fix) [$($_.Reference)]" } else { $_.Fix } } })
        fixFirst     = @($findings | Where-Object Severity -in "High", "Medium" | Group-Object Fix |
                          Sort-Object @{ e = { @("High", "Medium").IndexOf($_.Group[0].Severity) } }, @{ e = { $_.Count }; Descending = $true } |
                          Select-Object -First 3 | ForEach-Object { "$($_.Name): $($_.Count) $(if ($_.Count -eq 1) { 'item' } else { 'items' }) ($(($_.Group | ForEach-Object Item | Select-Object -Unique -First 3) -join ', ')$(if ($_.Count -gt 3) { ', …' }))." })
        manualChecks = @(
                          "Entra > Entra ID > Users > User settings: Users can register agent identity blueprints (docs: Users can create agent blueprints) is No."
                          "Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID (Preview): the default inactivity policy is on."
                          "Microsoft 365 admin center > Agents > Settings > Agent and plugin access: Allow agents and plugins built by external publishers is off, or reviewed."
                          "Microsoft 365 admin center > Agents > Settings > Sharing: Specific users, not All users (applies to Agent Builder agents only)."
                          "Agents > Tools > Registry: standalone MCP servers and skills (no API) have clear names, owners and group-scoped availability."
                          "Sponsors attested each agent in the last 12 months (access review or attestation).")
        graphCalls   = @(
                          "GET /beta/copilot/admin/catalog/packages (+ /{id} for each)"
                          "GET /beta/servicePrincipals/microsoft.graph.agentIdentity?`$expand=sponsors (+ owners, appRoleAssignments)"
                          "GET /beta/oauth2PermissionGrants?`$filter=clientId eq '{id}'"
                          "GET /beta/applications/microsoft.graph.agentIdentityBlueprint?`$expand=sponsors (+ owners, inheritablePermissions)"
                          "GET /beta/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal"
                          "GET /beta/users/microsoft.graph.agentUser"
                          "GET /beta/reports/servicePrincipalSignInActivities"
                          "GET /beta/groups/{id} (+ owners), GET /beta/users/{id}"
                          "GET /beta/identity/conditionalAccess/policies"
                          "GET /beta/servicePrincipals?`$filter=tags/any(t:t eq 'AgentCreatedBy:CopilotStudio') (and AgenticApp, AIAgentBuilder, AgenticInstance, power-virtual-agents-*)"
                          "POST /beta/security/runHuntingQuery: AgentsInfo | summarize arg_max(Timestamp, *) by AgentId (MCP servers, skills, tools)"
                          "POST /beta/security/runHuntingQuery: CloudAppEvents | where ActionType in (InvokeAgent, ExecuteTool...) | summarize max(Timestamp) by agent appId (TargetAgentId or AgentId)")
        notes        = @(
                          "References in brackets: this repo's mapping of each check to CIS Controls v8.1 safeguards (AI Agent and MCP Companion Guides, April 2026) and to the CISA risk categories in 'Careful Adoption of Agentic AI Services' (CISA, NSA and partners, 2026). The mapping is a judgment, not published by CIS or CISA. CIS 5.3 says to disable dormant accounts after 45 days; run with -StaleDays 45 to match it."
                          "Scores: each item starts at 100 (High -25, Medium -10, Low -3); an area's score is the average of its items."
                          "Microsoft-published agents and tools, and blueprints from other publishers, aren't checked for names or descriptions."
                          if ($SkipPackages -or -not $packages) { "Agents and tools weren't checked: the Agent 365 catalog wasn't read." }
                          if (-not $haveDefender) { "Discovered agents weren't checked: the Defender hunting query didn't run (needs ThreatHunting.Read.All and Security Reader)." }
                          if ($haveDefender -and -not $packages) { "The Agent 365 registry wasn't read, so Defender's AgentsInfo inventory was used as the agent list." }
                          if (-not $signIns.Count) { "Sign-in activity wasn't available, so stale checks on identities and blueprints are incomplete." })
        prompt       = $coworkPrompt
    }
    $json = ($data | ConvertTo-Json -Depth 6).Replace("</", "<\/")
    $html = [regex]::Replace($Template, '(?s)(<script id="report-data" type="application/json">).*?(</script>)', { param($m) $m.Groups[1].Value + "`n" + $json + "`n" + $m.Groups[2].Value })
    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
}

$template = Get-ReportTemplate
if ($template) { New-HtmlReport $template (Join-Path ((Resolve-Path $OutputFolder).Path) "Report.html") }

$scorecard | Format-Table -AutoSize
Write-Host "$governedPercent% of agent identities are well governed."
Write-Host "Saved Findings.csv, Scorecard.csv, Packages.csv, DefenderAgents.csv and Report.html to $OutputFolder. Keep these files private."
