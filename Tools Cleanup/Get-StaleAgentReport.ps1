<#
.SYNOPSIS
    Finds Copilot agents nobody uses, stale Entra agent identities and stale agent identity
    blueprints. Read-only: it changes nothing.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest, beta endpoint). Writes three CSV files:

      AgentPackages.csv    Agents in the Agent 365 registry (copilot/admin/catalog/packages)
                           with the last time each one was used.
      AgentIdentities.csv  Entra agent identities with their last sign-in.
      Blueprints.csv       Agent identity blueprints with child counts and last sign-in.

    Every row has a status and a recommendation (Keep, Disable, Block, Review,
    AlreadyDisabled, AlreadyBlocked). Invoke-StaleAgentCleanup.ps1 acts only on rows marked
    Disable or Block, so review the CSVs and change any row to Keep before you run it.

    Where "last used" comes from:
      - Agent identities and blueprints: the Entra service principal sign-in activity report
        (reports/servicePrincipalSignInActivities, preview). Needs AuditLog.Read.All and a
        Reports Reader, Security Reader or Security Administrator role.
      - Agents (packages): there is no Graph API for per-agent usage yet. The script uses
          1. the sign-in of the agent identity the package points to (agentIdentityId), and
          2. the Agent usage report you export from the Microsoft 365 admin center
             (Reports > Usage > Microsoft Copilot > Agents > Export), passed with -AgentUsageCsv.
        The admin center report covers the last 7 or 30 days only. An agent that isn't in the
        export wasn't used in that period; it may have been used before it.

    Requirements:
      - Microsoft.Graph.Authentication module.
      - Agent registry (packages) API: Microsoft Agent 365 license (or Microsoft 365 E7) and the
        AI Administrator or Global Administrator role. Use -SkipPackages if you don't have it.
      - Agent identities and blueprints: Agent ID Administrator, or a reader role that can read
        applications and service principals.

.PARAMETER Days
    An object with no use in this many days is stale. Default 90.

.PARAMETER AgentUsageCsv
    Path to the Agent usage report exported from the Microsoft 365 admin center.

.PARAMETER SkipPackages
    Skip the Agent 365 registry (for tenants without the Agent 365 license).

.PARAMETER OutFolder
    Folder for the CSV files. Keep it out of source control.

.EXAMPLE
    .\Get-StaleAgentReport.ps1
    .\Get-StaleAgentReport.ps1 -Days 60 -AgentUsageCsv .\AgentUsage.csv
    .\Get-StaleAgentReport.ps1 -SkipPackages
#>
[CmdletBinding()]
param(
    [int]$Days = 90,
    [string]$AgentUsageCsv,
    [switch]$SkipPackages,
    [string]$OutFolder = ".\StaleAgentReport-$(Get-Date -Format yyyyMMdd-HHmm)"
)

#Requires -Modules Microsoft.Graph.Authentication

$ErrorActionPreference = "Stop"
$graph  = "https://graph.microsoft.com/beta"
$now    = (Get-Date).ToUniversalTime()
$cutoff = $now.AddDays(-$Days)

$scopes = @(
    "Application.Read.All"
    "AgentIdentityBlueprint.Read.All"
    "AuditLog.Read.All"
    if (-not $SkipPackages) { "CopilotPackages.Read.All" }
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
            @{ n = "lastSignInDateTime"; e = { if ($_.appId) { $signIns[$_.appId] } } } |
        Select-Object *,
            @{ n = "daysSinceSignIn";   e = { Get-DaysSince $_.lastSignInDateTime } },
            @{ n = "status";            e = { Get-UsageStatus $_.lastSignInDateTime $_.createdDateTime } },
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
# Agents in the Agent 365 registry
# ---------------------------------------------------------------------------
function Get-PackageReport($identityIndex, $usage) {
    $filter = [uri]::EscapeDataString("supportedHosts/any(h:h eq 'Copilot')")
    "$graph/copilot/admin/catalog/packages?`$filter=$filter" | Get-GraphCollection |
        Select-Object id, displayName, type, publisher, platform, isBlocked, availableTo, deployedTo, appId, manifestId, agentIdentityId,
            @{ n = "lastModifiedDateTime"; e = { ConvertTo-Utc $_.lastModifiedDateTime } },
            @{ n = "reportLastActivity";   e = { $p = $_; @($p.id, $p.manifestId, $p.appId) | Where-Object { $_ -and $usage[$_] } | ForEach-Object { $usage[$_] } | Sort-Object -Descending | Select-Object -First 1 } },
            @{ n = "identityLastSignIn";   e = { if ($_.agentIdentityId) { $identityIndex[$_.agentIdentityId] } } } |
        Select-Object *, @{ n = "lastUsedDateTime"; e = { @($_.reportLastActivity, $_.identityLastSignIn) | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1 } } |
        Select-Object *,
            @{ n = "daysSinceUsed"; e = { Get-DaysSince $_.lastUsedDateTime } },
            @{ n = "status"; e = {
                if (-not $usage.Count -and -not $_.agentIdentityId) { "NoUsageData" }
                else { Get-UsageStatus $_.lastUsedDateTime $_.lastModifiedDateTime }
            } } |
        Select-Object *, @{ n = "recommendation"; e = {
            if ($_.isBlocked)                      { "AlreadyBlocked" }
            elseif ($_.type -eq "microsoft")       { "Keep" }
            elseif ($_.status -in "Active", "New") { "Keep" }
            elseif ($_.status -eq "NoUsageData")   { "Review" }
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

$packages = @()
if (-not $SkipPackages) {
    Write-Host "Reading agents from the Agent 365 registry..."
    $identityIndex = @{}
    $identities | ForEach-Object { $identityIndex[$_.id] = $_.lastSignInDateTime }
    try {
        $packages = @(Get-PackageReport $identityIndex (Get-UsageIndex $AgentUsageCsv))
        $packages | Export-Csv -Path (Join-Path $OutFolder "AgentPackages.csv") -NoTypeInformation -Encoding UTF8
    }
    catch {
        Write-Warning "Couldn't read the agent registry. It needs an Agent 365 license and the AI Administrator role. Run with -SkipPackages to skip it. $($_.Exception.Message)"
    }
}

# Summary
@(
    $packages   | Select-Object @{ n = "Object"; e = { "Agent" } },          recommendation
    $identities | Select-Object @{ n = "Object"; e = { "Agent identity" } }, recommendation
    $blueprints | Select-Object @{ n = "Object"; e = { "Blueprint" } },      recommendation
) | Group-Object Object, recommendation | Select-Object @{ n = "Object / recommendation"; e = { $_.Name } }, Count | Format-Table -AutoSize

Write-Host "Reports saved to $((Resolve-Path $OutFolder).Path). Review them, then run Invoke-StaleAgentCleanup.ps1 -ReportFolder <folder> -WhatIf."
