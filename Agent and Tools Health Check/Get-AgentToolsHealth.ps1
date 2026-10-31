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

    Scores: every item starts at 100 (High -25, Medium -10, Low -3). Each area's score is the
    average of its items. Green 80+, Amber 50-79, Red under 50.

    Output (in -OutputFolder): Findings.csv, Scorecard.csv, Packages.csv and Report.html.
    Packages.csv is the file you attach in Copilot Cowork: the Enterprise MCP server can't read
    the Agent 365 catalog, so Cowork reads agents and tools from this file and reads everything
    else live. Use -PackagesOnly to write just Packages.csv.
    The files name agents, groups and sponsors. Keep them private and out of source control.

    Permissions (delegated): CopilotPackages.Read.All (Agent 365 license, AI Administrator),
    Application.Read.All, AgentIdentityBlueprint.Read.All, AuditLog.Read.All (sign-ins),
    User.Read.All, Group.Read.All, Policy.Read.All (Conditional Access).

.EXAMPLE
    .\Get-AgentToolsHealth.ps1
    .\Get-AgentToolsHealth.ps1 -StaleDays 60
    .\Get-AgentToolsHealth.ps1 -PackagesOnly
    .\Get-AgentToolsHealth.ps1 -SkipPackages
#>
[CmdletBinding()]
param(
    [int]$StaleDays          = 90,
    [int]$SecretWarningDays  = 30,
    [int]$PendingRequestDays = 14,
    [switch]$PackagesOnly,
    [switch]$SkipPackages,
    [string]$OutputFolder = ".\AgentToolsHealth-$(Get-Date -Format yyyyMMdd-HHmm)",

    # Words that make a name unclear. Matched at the start of a word, so "demo" also catches "demoe".
    [string]$UnclearNamePattern = '\b(test\w*|demo\w*|temp\b|tmp\b|copy\b|draft\b|sample\w*|poc\b|sandbox\w*|untitled\b|dummy\b|delete ?me\b|do not use\b)|^(new|my) (agent|plugin|skill|bot)\b|\b(agent|plugin|skill|bot) ?\d+$|\(\d+\)$',

    # Microsoft Graph application permissions treated as High risk for an agent. Other *.ReadWrite.All are Medium.
    [string]$HighPrivilegePattern = '^(Directory|RoleManagement|Application|AppRoleAssignment|Policy|User|Group|GroupMember|Domain|Organization)\.ReadWrite|^(Mail\.Send|Mail\.ReadWrite|Sites\.FullControl\.All|Files\.ReadWrite\.All|Sites\.ReadWrite\.All|Directory\.AccessAsUser\.All|full_access_as_app)$'
)

#Requires -Modules Microsoft.Graph.Authentication

$scopes = @(
    if (-not $SkipPackages) { "CopilotPackages.Read.All" }
    if (-not $PackagesOnly) { "Application.Read.All", "AgentIdentityBlueprint.Read.All", "AuditLog.Read.All", "User.Read.All", "Group.Read.All", "Policy.Read.All" }
    if ($PackagesOnly)      { "Group.Read.All" }
)
Connect-MgGraph -NoWelcome -Scopes $scopes

$graph  = "https://graph.microsoft.com/beta"   # beta everywhere; it usually has more
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
        @{ n = "Fix";      e = { $Fix } }
}

# Category for the report's filters, from the check text.
function Get-Category([string]$Check) {
    switch -Regex ($Check) {
        'Conditional Access|high-risk'                     { "Security"; break }
        'sponsor|owner'                                    { "Ownership"; break }
        'permission|secret|credential|agent user'          { "Permissions"; break }
        "^Group '|Available|Installed|Assigned"           { "Access"; break }
        'name|description'                                 { "Naming"; break }
        default                                            { "Usage" }
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
            type, publisher, shortDescription, isBlocked, availableTo, deployedTo, requestStatus, requestType,
            @{ n = "groupIds";         e = { @($allowed | Where-Object resourceType -eq "group" | ForEach-Object resourceId | Sort-Object -Unique) -join ";" } },
            @{ n = "groups";           e = { @($allowed | Where-Object resourceType -eq "group" | ForEach-Object resourceId | Sort-Object -Unique | ForEach-Object { (Get-Group $_).displayName }) -join "; " } },
            @{ n = "directUsers";      e = { @($allowed | Where-Object resourceType -eq "user" | ForEach-Object resourceId | Sort-Object -Unique).Count } },
            @{ n = "lastModifiedDateTime"; e = { ConvertTo-Utc $_.lastModifiedDateTime } },
            @{ n = "lastUsedDateTime"; e = { ConvertTo-Utc $_.lastUsedDateTime } },
            @{ n = "activeUsers30d";   e = { $_.activeUsers } },
            @{ n = "sessions30d";      e = { $_.totalSessions } }
    }
}

function Test-Package($P) {
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
    if ($custom -and (Test-UnclearName $name)) { New-Finding $area $name "Medium" "Unclear name" "Rename it so people can tell what it does and who owns it" }
    if ($custom -and (Test-PoorDescription $P.shortDescription $name)) { New-Finding $area $name "Medium" "Missing or too-short description" "Describe what it does, for whom, and what data it uses" }
    if ($P.requestStatus -eq "pending" -and $P.lastModifiedDateTime -and $P.lastModifiedDateTime -lt $now.AddDays(-$PendingRequestDays)) {
        New-Finding $area $name "Low" "Request ($($P.requestType)) pending for more than $PendingRequestDays days" "Approve or reject it"
    }
    if ($custom -and -not $P.isBlocked -and -not ($P.activeUsers30d -gt 0) -and (-not $P.lastUsedDateTime -or $P.lastUsedDateTime -lt $cutoff) -and $P.lastModifiedDateTime -lt $cutoff) {
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
    $sp.appRoles | ForEach-Object { $index[$_.id] = $_.value }
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
if ($PackagesOnly) {
    Write-Host "Saved Packages.csv to $OutputFolder. Attach it in Copilot Cowork with the prompt in the Cowork folder of this repo."
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
$children = $identities | Where-Object agentIdentityBlueprintId | Group-Object agentIdentityBlueprintId -AsHashTable -AsString
if (-not $children) { $children = @{} }

$findings = @(
    $packages | ForEach-Object { Test-Package $_ }
    $identities | ForEach-Object { Write-Host "  $($_.displayName)"; Test-Identity $_ $signIns $roleNames }
    $agentUsers | ForEach-Object {
        $parent = $identities | Where-Object id -eq $_.identityParentId | Select-Object -First 1
        New-Finding "Agent identities" $(if ($parent) { $parent.displayName } else { $_.displayName }) "Low" "Has an agent user account ($($_.displayName))" "Keep it only if the agent needs a mailbox or Teams presence"
    }
    # Blueprints registered in this tenant only; Microsoft's and other publishers' blueprints are theirs to fix.
    $blueprints | ForEach-Object { Test-Blueprint $_ $principals[$_.appId] @($children[$_.appId]) $signIns $roleNames }
    Test-Tenant
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
)
$scorecard = @($areas | Get-AreaScore -Findings $findings | Sort-Object Score)

$findings | Sort-Object @{ e = { @("High", "Medium", "Low", "Info").IndexOf($_.Severity) } }, Area, Item |
    Export-Csv (Join-Path $OutputFolder "Findings.csv") -NoTypeInformation -Encoding UTF8
$scorecard | Export-Csv (Join-Path $OutputFolder "Scorecard.csv") -NoTypeInformation -Encoding UTF8

# The same check in Copilot Cowork, so people can rerun it and follow up without PowerShell.
$coworkPrompt = @"
Run the agent and tools health check. Count anything unused for $StaleDays days as stale.

Use the attached Packages.csv for agents and tools. Use the Microsoft MCP Server for Enterprise to read: every agent identity with its sponsors, owners, Microsoft Graph permissions and last sign-in; every agent identity blueprint with its sponsors, owners, inheritable permissions, credentials and description; agent user accounts; the groups listed in Packages.csv (owners and description); and the Conditional Access policies.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the agent-tools-health rules and give me:
1. A scorecard: one row per area (Agents, Tools, Agent identities, Blueprints, Tenant) with a score out of 100 and Green 80+, Amber 50-79, Red under 50.
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
                          @{ n = "target"; e = { $_.Item } }, @{ n = "check"; e = { $_.Check } }, @{ n = "fix"; e = { $_.Fix } })
        fixFirst     = @($findings | Where-Object Severity -in "High", "Medium" | Group-Object Fix |
                          Sort-Object @{ e = { @("High", "Medium").IndexOf($_.Group[0].Severity) } }, @{ e = { $_.Count }; Descending = $true } |
                          Select-Object -First 3 | ForEach-Object { "$($_.Name): $($_.Count) $(if ($_.Count -eq 1) { 'item' } else { 'items' }) ($(($_.Group | ForEach-Object Item | Select-Object -Unique -First 3) -join ', ')$(if ($_.Count -gt 3) { ', …' }))." })
        manualChecks = @(
                          "Entra > Entra ID > Users > User settings: Users can register agent identity blueprints is No."
                          "Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID: the default inactivity policy is on."
                          "Microsoft 365 admin center > Agents > Settings > Agent and plugin access: external publishers are off, or reviewed."
                          "Microsoft 365 admin center > Agents > Settings > Sharing: limited to a group."
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
                          "GET /beta/identity/conditionalAccess/policies")
        notes        = @(
                          "Scores: each item starts at 100 (High -25, Medium -10, Low -3); an area's score is the average of its items."
                          "Microsoft-published agents and tools, and blueprints from other publishers, aren't checked for names or descriptions."
                          if ($SkipPackages -or -not $packages) { "Agents and tools weren't checked: the Agent 365 catalog wasn't read." }
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
Write-Host "Saved Findings.csv, Scorecard.csv, Packages.csv and Report.html to $OutputFolder. Keep these files private."
