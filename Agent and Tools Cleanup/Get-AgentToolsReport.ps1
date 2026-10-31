<#
.SYNOPSIS
    Finds Copilot agents and tools (plugins, skills, MCP servers) nobody uses, stale Entra agent
    identities and stale agent identity blueprints. Read-only: it changes nothing.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest, beta endpoint). Writes these CSV files:

      Packages.csv         Everything in the Agent 365 catalog (copilot/admin/catalog/packages):
                           agents, tools (plugins with skills, MCP servers or connectors) and
                           other apps, with the last time each one was used.
      AgentIdentities.csv  Entra agent identities with their last sign-in.
      Blueprints.csv       Agent identity blueprints with child counts and last sign-in.
      AuditUsage.csv       Only with -AuditDays: agents and plugins seen in Copilot audit records.

    Every row has a status and a recommendation (Keep, Disable, Block, Review,
    AlreadyDisabled, AlreadyBlocked). Invoke-AgentToolsCleanup.ps1 acts only on rows marked
    Disable or Block, so review the CSVs and change any row to Keep before you run it.

    Where "last used" comes from:
      - Packages: the package detail call (GET /copilot/admin/catalog/packages/{id}) returns
        lastUsedDateTime, activeUsers and totalSessions (last 30 days). The script also uses the
        sign-in of the package's agent identity, the admin center Agent usage export
        (-AgentUsageCsv), Agent 365 activity in Microsoft Defender (CloudAppEvents, last 30 days,
        through Graph advanced hunting) and, with -AuditDays, Copilot audit records. It keeps the
        newest date.
      - Agent identities and blueprints: the Entra service principal sign-in activity report
        (reports/servicePrincipalSignInActivities, preview), plus Agent 365 activity in Defender
        matched on the agent's appId (equal to the object ID for Agent ID agents). In testing, some
        Copilot Studio agent identities had no recorded sign-in of their own, so the Defender
        activity matters.

    Not covered: standalone MCP servers and standalone skills that aren't inside a package.
    Check those in the Microsoft 365 admin center under Agents > Tools > Registry.

    Requirements:
      - Microsoft.Graph.Authentication module.
      - Packages: Microsoft Agent 365 license (or Microsoft 365 E7) and the AI Administrator or
        Global Administrator role. Use -SkipPackages if you don't have it.
      - Sign-in activity: AuditLog.Read.All and a Reports Reader or Security Reader role.
      - -AuditDays: AuditLogsQuery.Read.All and a Purview role that can search the audit log.
      - Defender activity: ThreatHunting.Read.All and the Security Reader role. Use -SkipDefender
        without Defender. Only agents that send Agent 365 observability data show activity.

.PARAMETER Days
    An object with no use in this many days is stale. Default 90.

.PARAMETER AgentUsageCsv
    Path to the Agent usage report exported from the Microsoft 365 admin center.

.PARAMETER AuditDays
    Also search this many days of Copilot audit records (CopilotInteraction) for agent and plugin
    use. 0 (default) skips it. Audit searches run in the background in Purview and can take
    several minutes. Up to 180 days with Audit (Standard).

.PARAMETER SkipPackages
    Skip the Agent 365 catalog (for tenants without the Agent 365 license).

.PARAMETER OutFolder
    Folder for the CSV files. Keep it out of source control.

.EXAMPLE
    .\Get-AgentToolsReport.ps1
    .\Get-AgentToolsReport.ps1 -Days 60 -AuditDays 90
    .\Get-AgentToolsReport.ps1 -AgentUsageCsv .\AgentUsage.csv
    .\Get-AgentToolsReport.ps1 -SkipPackages -SkipDefender
#>
[CmdletBinding()]
param(
    [int]$Days = 90,
    [string]$AgentUsageCsv,
    [ValidateRange(0, 180)][int]$AuditDays = 0,
    [switch]$SkipPackages,
    [switch]$SkipDefender,
    [string]$OutFolder = ".\AgentToolsReport-$(Get-Date -Format yyyyMMdd-HHmm)"
)

#Requires -Modules Microsoft.Graph.Authentication

$ErrorActionPreference = "Stop"
$graph  = "https://graph.microsoft.com/beta"
$now    = (Get-Date).ToUniversalTime()
$cutoff = $now.AddDays(-$Days)

$scopes = @(
    "Application.Read.All"
    "AgentIdentity.Read.All"
    "AgentIdentityBlueprint.Read.All"
    "AgentIdentityBlueprintPrincipal.Read.All"
    "AuditLog.Read.All"
    if (-not $SkipPackages) { "CopilotPackages.Read.All" }
    if ($AuditDays)         { "AuditLogsQuery.Read.All" }
    if (-not $SkipDefender) { "ThreatHunting.Read.All" }
)
Connect-MgGraph -Scopes $scopes -NoWelcome

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Get-GraphCollection {
    param([Parameter(ValueFromPipeline)][string]$Uri)
    process {
        $next = $Uri
        while ($next) {
            try   { $page = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject }
            catch { throw "Graph call failed: $next`n$($_.Exception.Message)" }
            $page.value
            $next = $page.'@odata.nextLink'
        }
    }
}

function ConvertTo-Utc($value) {
    if ($value) { ([datetime]$value).ToUniversalTime() }
}

function Get-DaysSince($date) {
    if ($date) { [int]($now - $date).TotalDays }
}

function Get-UsageStatus($lastUsed, $created) {
    if ($lastUsed -and $lastUsed -ge $cutoff)  { "Active" }
    elseif ($lastUsed)                         { "Stale" }
    elseif ($created -and $created -ge $cutoff) { "New" }
    else                                       { "NoActivity" }
}

function Get-RelatedCount($id, $type, $relation) {
    try   { @("$graph/servicePrincipals/$id/$type/$($relation)?`$select=id" | Get-GraphCollection).Count }
    catch { Write-Warning "Couldn't read $relation for $id. $($_.Exception.Message)" }
}

# appId -> last sign-in (any flow, as client or resource)
function Get-SignInIndex {
    $index = @{}
    try {
        "$graph/reports/servicePrincipalSignInActivities" | Get-GraphCollection |
            Where-Object { $_.appId } |
            ForEach-Object { $index[$_.appId] = ConvertTo-Utc $_.lastSignInActivity.lastSignInDateTime }
    }
    catch {
        Write-Warning "Service principal sign-in activity isn't available (needs AuditLog.Read.All and a reports role). Identities and blueprints will be marked Review, not Disable. $($_.Exception.Message)"
    }
    $index
}

# Agent 365 activity in Microsoft Defender (CloudAppEvents), last 30 days. KQL through Graph advanced
# hunting. CloudAppEvents names agents by their Entra appId: on InvokeAgent records the invoked agent is
# TargetAgentId (AgentId is the calling agent, all zeros when a person invokes it); on tool calls it's
# AgentId. Keyed by that appId, plus the Defender and source agent IDs joined from AgentsInfo.
function Get-DefenderActivity {
    $index = @{}
    if ($SkipDefender) { return $index }
    $kql = @'
CloudAppEvents
| where ActionType in ("InvokeAgent", "ExecuteToolByMCPServer", "ExecuteToolByGateway", "ExecuteToolBySDK")
| extend Raw = parse_json(tostring(RawEventData))
| extend AgentAppId = iff(ActionType == "InvokeAgent", tostring(Raw.TargetAgentId), tostring(Raw.AgentId))
| where isnotempty(AgentAppId) and AgentAppId != "00000000-0000-0000-0000-000000000000"
| summarize LastActivity = max(Timestamp) by AgentAppId
| join kind=leftouter (AgentsInfo | summarize arg_max(Timestamp, AgentId, SourceAgentId) by EntraAgentId | extend EntraAgentId = tostring(EntraAgentId)) on $left.AgentAppId == $right.EntraAgentId
| project AgentAppId, AgentId, SourceAgentId, LastActivity
'@
    try {
        $body = @{ Query = $kql; Timespan = "P30D" } | ConvertTo-Json
        (Invoke-MgGraphRequest -Method POST -Uri "$graph/security/runHuntingQuery" -Body $body -ContentType "application/json" -OutputType PSObject).results | ForEach-Object {
            $last = ConvertTo-Utc $_.LastActivity
            @($_.AgentAppId, $_.AgentId, $_.SourceAgentId) | Where-Object { $_ } | ForEach-Object { if (-not $index["$_"] -or $last -gt $index["$_"]) { $index["$_"] = $last } }
        }
        Write-Host "Defender activity: $($index.Count) agent IDs with Agent 365 activity in the last 30 days."
    }
    catch { Write-Warning "Couldn't read agent activity from Defender (needs ThreatHunting.Read.All and Security Reader). Run with -SkipDefender to skip it. $($_.Exception.Message)" }
    $index
}

# Agent ID / App ID / External app ID -> last activity date, from the admin center export
function Get-UsageIndex($path) {
    $index = @{}
    if ($path) {
        Import-Csv -Path $path | ForEach-Object {
            $date = ConvertTo-Utc ($_.PSObject.Properties | Where-Object Name -match '^Last activity' | Select-Object -First 1).Value
            $_.PSObject.Properties | Where-Object { $_.Name -match '^(Agent ID|App ID|External app ID)$' -and $_.Value } | ForEach-Object {
                if ($date -and (-not $index[$_.Value] -or $date -gt $index[$_.Value])) { $index[$_.Value] = $date }
            }
        }
        Write-Host "Agent usage report: $($index.Count) agent IDs with activity."
    }
    $index
}

# ---------------------------------------------------------------------------
# Agent identities
# ---------------------------------------------------------------------------
function Get-IdentityRecommendation {
    param([Parameter(ValueFromPipeline)]$Identity)
    process {
        $Identity | Select-Object *, @{ n = "recommendation"; e = {
            if (-not $_.accountEnabled)                 { "AlreadyDisabled" }
            elseif ($_.status -in "Active", "New")      { "Keep" }
            elseif ($_.status -eq "NoActivity")         { "Review" }   # some agents run without a recorded identity sign-in
            elseif (-not $script:haveSignInData)        { "Review" }
            else                                        { "Disable" }
        } }
    }
}

function Get-AgentIdentityReport($signIns, $blueprintPrincipals) {
    "$graph/servicePrincipals/microsoft.graph.agentIdentity?`$select=id,appId,displayName,accountEnabled,agentIdentityBlueprintId,createdByAppId,createdDateTime" |
        Get-GraphCollection |
        Select-Object id, displayName, appId, accountEnabled, agentIdentityBlueprintId, createdByAppId,
            @{ n = "createdDateTime";    e = { ConvertTo-Utc $_.createdDateTime } },
            @{ n = "lastSignInDateTime"; e = { if ($_.appId) { $signIns[$_.appId] } } },
            @{ n = "defenderLastActivity"; e = { $script:defenderActivity[$_.id] } } |
        Select-Object *, @{ n = "lastUsedDateTime"; e = { @($_.lastSignInDateTime, $_.defenderLastActivity) | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1 } } |
        Select-Object *,
            @{ n = "daysSinceUsed";     e = { Get-DaysSince $_.lastUsedDateTime } },
            @{ n = "status";            e = { Get-UsageStatus $_.lastUsedDateTime $_.createdDateTime } },
            @{ n = "blueprintInTenant"; e = { [bool]($_.agentIdentityBlueprintId -and $blueprintPrincipals[$_.agentIdentityBlueprintId]) } } |
        Select-Object *,
            @{ n = "sponsorCount"; e = { if ($_.status -in "Stale", "NoActivity") { Get-RelatedCount $_.id "microsoft.graph.agentIdentity" "sponsors" } } },
            @{ n = "ownerCount";   e = { if ($_.status -in "Stale", "NoActivity") { Get-RelatedCount $_.id "microsoft.graph.agentIdentity" "owners" } } } |
        Get-IdentityRecommendation
}

# ---------------------------------------------------------------------------
# Blueprints (principal = the blueprint's presence in this tenant)
# ---------------------------------------------------------------------------
function Get-BlueprintReport($blueprintPrincipals, $blueprintApps, $identities, $signIns) {
    $children = @{}
    $identities | Where-Object agentIdentityBlueprintId | Group-Object agentIdentityBlueprintId | ForEach-Object { $children[$_.Name] = $_.Group }

    # Blueprints used in this tenant (home-tenant or from another publisher)
    $blueprintPrincipals.Values |
        Select-Object @{ n = "principalId"; e = { $_.id } }, appId, displayName, accountEnabled,
            @{ n = "registeredInTenant";  e = { [bool]$blueprintApps[$_.appId] } },
            @{ n = "childCount";          e = { @($children[$_.appId]).Where({ $_ }).Count } },
            @{ n = "activeChildCount";    e = { @($children[$_.appId]).Where({ $_ -and $_.accountEnabled -and $_.status -in "Active", "New" }).Count } },
            @{ n = "lastSignInDateTime";  e = { $signIns[$_.appId] } },
            @{ n = "createdDateTime";     e = { ConvertTo-Utc $blueprintApps[$_.appId].createdDateTime } } |
        Select-Object *,
            @{ n = "daysSinceSignIn"; e = { Get-DaysSince $_.lastSignInDateTime } },
            @{ n = "status";          e = { Get-UsageStatus $_.lastSignInDateTime $_.createdDateTime } } |
        Select-Object *, @{ n = "recommendation"; e = {
            if (-not $_.accountEnabled)                                   { "AlreadyDisabled" }
            elseif ($_.activeChildCount -gt 0 -or $_.status -in "Active", "New") { "Keep" }
            elseif (-not $_.registeredInTenant)                           { "Review" }   # Microsoft or ISV blueprint: disabling it breaks every agent built on it
            elseif ($_.status -eq "NoActivity" -or -not $script:haveSignInData) { "Review" }
            else                                                          { "Disable" }
        } }

    # Blueprints registered here that were never added to this tenant as a principal.
    # They may still be used in other tenants (multitenant), so only flag them for review.
    $blueprintApps.Values | Where-Object { -not $blueprintPrincipals[$_.appId] } |
        Select-Object @{ n = "principalId"; e = { $null } }, appId, displayName,
            @{ n = "accountEnabled";     e = { $null } },
            @{ n = "registeredInTenant"; e = { $true } },
            @{ n = "childCount";         e = { 0 } },
            @{ n = "activeChildCount";   e = { 0 } },
            @{ n = "lastSignInDateTime"; e = { $null } },
            @{ n = "createdDateTime";    e = { ConvertTo-Utc $_.createdDateTime } },
            @{ n = "daysSinceSignIn";    e = { $null } },
            @{ n = "status";             e = { "NoPrincipal" } },
            @{ n = "recommendation";     e = { "Review" } }
}

# ---------------------------------------------------------------------------
# Copilot audit records: which agents and plugins people actually used
# ---------------------------------------------------------------------------
function Wait-AuditQuery {
    param([Parameter(ValueFromPipeline)]$Query)
    process {
        $deadline = (Get-Date).AddMinutes(30)
        $status = $Query.status
        while ($status -notin "succeeded", "failed", "cancelled") {
            if ((Get-Date) -gt $deadline) { throw "The audit search $($Query.id) didn't finish in 30 minutes. Run the report again later." }
            Start-Sleep -Seconds 30
            $status = (Invoke-MgGraphRequest -Method GET -Uri "$graph/security/auditLog/queries/$($Query.id)" -OutputType PSObject).status
            Write-Host "  Audit search: $status"
        }
        if ($status -ne "succeeded") { throw "The audit search $($Query.id) ended as $status." }
        $Query.id
    }
}

# Key (plugin ID or name, agent ID, the GUID at the end of an agent ID, agent name) -> last use and count.
# Output is one row per key; no user names are kept.
function Get-AuditUsage {
    $body = @{
        displayName         = "Agent and tools cleanup $(Get-Date -Format yyyy-MM-dd)"
        filterStartDateTime = $now.AddDays(-$AuditDays).ToString("o")
        filterEndDateTime   = $now.ToString("o")
        operationFilters    = @("CopilotInteraction")
    } | ConvertTo-Json
    Write-Host "Starting a Purview audit search for $AuditDays days of Copilot interactions (this can take several minutes)..."
    $queryId = Invoke-MgGraphRequest -Method POST -Uri "$graph/security/auditLog/queries" -Body $body -ContentType "application/json" -OutputType PSObject | Wait-AuditQuery

    "$graph/security/auditLog/queries/$queryId/records" | Get-GraphCollection | ForEach-Object {
        $created = ConvertTo-Utc $_.createdDateTime
        $event = $_.auditData.CopilotEventData
        @(
            $event.AISystemPlugin | Where-Object { $_ } | ForEach-Object { $_.Id; $_.Name } | Select-Object @{ n = "kind"; e = { "Plugin" } }, @{ n = "key"; e = { $_ } }
            @($_.auditData.AgentId; $event.AgentId; $_.auditData.AgentName; $event.AgentName) | Where-Object { $_ } | ForEach-Object { $_; ($_ -split '\.')[-1] } |
                Select-Object @{ n = "kind"; e = { "Agent" } }, @{ n = "key"; e = { $_ } }
        ) | Where-Object { $_.key -and $_.key -ne "BuiltIn" } | Select-Object kind, key, @{ n = "used"; e = { $created } }
    } |
        Group-Object kind, key |
        Select-Object @{ n = "kind"; e = { $_.Group[0].kind } }, @{ n = "key"; e = { $_.Group[0].key } },
            @{ n = "lastUsedDateTime"; e = { $_.Group.used | Sort-Object -Descending | Select-Object -First 1 } },
            @{ n = "interactions";     e = { $_.Count } }
}

# ---------------------------------------------------------------------------
# Agents and tools in the Agent 365 catalog
# ---------------------------------------------------------------------------
function Get-PackageKind($elementTypes) {
    $types = @($elementTypes) -join " "
    if ($types -match 'declarativeAgent|customEngine|bot')        { "Agent" }
    elseif ($types -match 'skill|connector|mcp|plugin|action')    { "Tool" }
    else                                                          { "App" }
}

# Adds the usage fields that only the detail call returns
function Add-PackageDetail {
    param([Parameter(ValueFromPipeline)]$Package)
    process {
        try   { $detail = Invoke-MgGraphRequest -Method GET -Uri "$graph/copilot/admin/catalog/packages/$([uri]::EscapeDataString($Package.id))" -OutputType PSObject }
        catch { Write-Warning "Couldn't read details for package '$($Package.displayName)'. $($_.Exception.Message)"; $detail = $null }
        $Package | Select-Object *,
            @{ n = "detailLastUsed"; e = { ConvertTo-Utc $detail.lastUsedDateTime } },
            @{ n = "activeUsers30d"; e = { $detail.activeUsers } },
            @{ n = "sessions30d";    e = { $detail.totalSessions } }
    }
}

function Get-PackageReport($identityIndex, $usage, $audit) {
    "$graph/copilot/admin/catalog/packages" | Get-GraphCollection | Add-PackageDetail |
        Select-Object id, displayName,
            @{ n = "kind";         e = { Get-PackageKind $_.elementTypes } },
            @{ n = "elementTypes"; e = { @($_.elementTypes) -join ";" } },
            type, publisher, platform, isBlocked, availableTo, deployedTo, appId, manifestId, agentIdentityId,
            @{ n = "lastModifiedDateTime"; e = { ConvertTo-Utc $_.lastModifiedDateTime } },
            detailLastUsed, activeUsers30d, sessions30d,
            @{ n = "reportLastActivity"; e = { $p = $_; @($p.id, $p.manifestId, $p.appId) | Where-Object { $_ -and $usage[$_] } | ForEach-Object { $usage[$_] } | Sort-Object -Descending | Select-Object -First 1 } },
            @{ n = "auditLastUsed";      e = { $p = $_; @($p.id, $p.manifestId, $p.appId, $p.displayName) | Where-Object { $_ -and $audit[$_] } | ForEach-Object { $audit[$_] } | Sort-Object -Descending | Select-Object -First 1 } },
            @{ n = "identityLastSignIn"; e = { if ($_.agentIdentityId) { $identityIndex[$_.agentIdentityId] } } },
            @{ n = "defenderLastActivity"; e = { $p = $_; @($p.id, $p.appId, $p.manifestId, $p.agentIdentityId) | Where-Object { $_ -and $script:defenderActivity["$_"] } | ForEach-Object { $script:defenderActivity["$_"] } | Sort-Object -Descending | Select-Object -First 1 } } |
        Select-Object *, @{ n = "lastUsedDateTime"; e = {
            @($_.detailLastUsed, $_.reportLastActivity, $_.auditLastUsed, $_.identityLastSignIn, $_.defenderLastActivity) | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        } } |
        Select-Object *,
            @{ n = "daysSinceUsed"; e = { Get-DaysSince $_.lastUsedDateTime } },
            @{ n = "status"; e = {
                if ($_.activeUsers30d -gt 0) { "Active" }
                else { Get-UsageStatus $_.lastUsedDateTime $_.lastModifiedDateTime }
            } } |
        Select-Object *, @{ n = "recommendation"; e = {
            if ($_.isBlocked)                      { "AlreadyBlocked" }
            elseif ($_.type -eq "microsoft")       { "Keep" }
            elseif ($_.status -in "Active", "New") { "Keep" }
            elseif ($_.kind -eq "App")             { "Review" }   # Office add-ins, tabs and other apps: not in scope for automatic blocking
            else                                   { "Block" }
        } }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Path $OutFolder -Force | Out-Null

Write-Host "Reading service principal sign-in activity..."
$signIns = Get-SignInIndex
$script:haveSignInData = $signIns.Count -gt 0

Write-Host "Reading Agent 365 activity from Microsoft Defender..."
$script:defenderActivity = Get-DefenderActivity

Write-Host "Reading agent identity blueprints..."
$blueprintApps = @{}
"$graph/applications/microsoft.graph.agentIdentityBlueprint?`$select=id,appId,displayName,createdDateTime" | Get-GraphCollection | ForEach-Object { $blueprintApps[$_.appId] = $_ }
$blueprintPrincipals = @{}
"$graph/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal?`$select=id,appId,displayName,accountEnabled" | Get-GraphCollection | ForEach-Object { $blueprintPrincipals[$_.appId] = $_ }

Write-Host "Reading agent identities..."
$identities = @(Get-AgentIdentityReport $signIns $blueprintPrincipals)
$identities | Export-Csv -Path (Join-Path $OutFolder "AgentIdentities.csv") -NoTypeInformation -Encoding UTF8

$blueprints = @(Get-BlueprintReport $blueprintPrincipals $blueprintApps $identities $signIns)
$blueprints | Export-Csv -Path (Join-Path $OutFolder "Blueprints.csv") -NoTypeInformation -Encoding UTF8

$audit = @{}
if ($AuditDays) {
    try {
        $auditRows = @(Get-AuditUsage)
        $auditRows | Export-Csv -Path (Join-Path $OutFolder "AuditUsage.csv") -NoTypeInformation -Encoding UTF8
        $auditRows | ForEach-Object { if (-not $audit[$_.key] -or $_.lastUsedDateTime -gt $audit[$_.key]) { $audit[$_.key] = $_.lastUsedDateTime } }
        Write-Host "Audit records: $($auditRows.Count) agents and plugins with activity."
    }
    catch {
        Write-Warning "The audit search didn't work. It needs AuditLogsQuery.Read.All and a Purview audit role. The report carries on without it. $($_.Exception.Message)"
    }
}

$packages = @()
if (-not $SkipPackages) {
    Write-Host "Reading agents and tools from the Agent 365 catalog (one detail call per package)..."
    $identityIndex = @{}
    $identities | ForEach-Object { $identityIndex[$_.id] = $_.lastUsedDateTime }
    try {
        $packages = @(Get-PackageReport $identityIndex (Get-UsageIndex $AgentUsageCsv) $audit)
        $packages | Export-Csv -Path (Join-Path $OutFolder "Packages.csv") -NoTypeInformation -Encoding UTF8
    }
    catch {
        Write-Warning "Couldn't read the Agent 365 catalog. It needs an Agent 365 license and the AI Administrator role. Run with -SkipPackages to skip it. $($_.Exception.Message)"
    }
}

# Summary
@(
    $packages   | Select-Object @{ n = "Object"; e = { $_.kind } },            recommendation
    $identities | Select-Object @{ n = "Object"; e = { "Agent identity" } }, recommendation
    $blueprints | Select-Object @{ n = "Object"; e = { "Blueprint" } },      recommendation
) | Group-Object Object, recommendation | Select-Object @{ n = "Object / recommendation"; e = { $_.Name } }, Count | Format-Table -AutoSize

Write-Host "Reports saved to $((Resolve-Path $OutFolder).Path). Review them, then run Invoke-AgentToolsCleanup.ps1 -ReportFolder <folder> -WhatIf."
