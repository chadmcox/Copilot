<#
.SYNOPSIS
    Dated one-off: brings the "Copilot*" groups already in the tenant up to the Oct 26, 2026
    version of the Copilot Group Assignment Guide.
      1. Renames groups whose names changed in this version (none this week - the table is empty).
      2. Refreshes descriptions that are now wrong (setting renames, Copilot Code, SpaceXAI).
      3. Deletes groups the design no longer uses (none this week - Update-CopilotGroupCleanup.ps1
         still owns the three retired groups from the first version).
      4. Reports groups the design expects that are not in the tenant yet.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest). Needs Group.ReadWrite.All.
    Supports -WhatIf. Deletions also prompt for confirmation unless you pass -Confirm:$false.

    What changed this week (see the guide for the detail):
      - Browser use setting renamed to "Browser use in Microsoft Copilot" (MC1515930).
      - Copilot Code is rolling out to Frontier and is now a usage-based service (MC1519871),
        so the Code groups are no longer "on hold" and the Code exemption group has a real
        setting: the Policy exemption group in Copilot Code secure local execution.
      - Spending policies now need a per-user limit of at least 2,000 credits a month.
      - New admin group: Copilot Agent Registry Admin (Entra role Agent Registry Administrator).
      - Policy names in the guide dropped their dash, because the new Graph cost management
        API only accepts letters, digits and spaces in a policy name.

    Safety on delete:
      - Members and owners of each group are exported to CSV before it is deleted.
      - A group that still has members is skipped unless you use -DeleteEvenIfMembers.
      - Before running, remove each group from any setting that still points at it.

.EXAMPLE
    .\Update-CopilotGroups-20261026.ps1 -WhatIf
    .\Update-CopilotGroups-20261026.ps1
    .\Update-CopilotGroups-20261026.ps1 -DeleteEvenIfMembers
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$DeleteEvenIfMembers,
    [string]$ExportFolder = ".\CopilotGroups-20261026-$(Get-Date -Format yyyyMMdd-HHmm)"
)

#Requires -Modules Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome
$graph = "https://graph.microsoft.com/v1.0"

# ---------------------------------------------------------------------------
# 1. Renames (OldName = NewName). Empty this week.
# ---------------------------------------------------------------------------
$renames = [ordered]@{ }

# ---------------------------------------------------------------------------
# 2. Descriptions to refresh for this version
# ---------------------------------------------------------------------------
$descriptions = [ordered]@{
    "Copilot + Cowork Browser Access"            = "Copilot > Settings > Browser use in Microsoft Copilot > Allow local browser use (renamed from Cowork settings, MC1515930). Also the Intune Edge policy CopilotCoworkToolActionsEnabled (Edge 152+)."
    "Copilot + Cowork Spend Limit"               = "Scope of the Cowork Limited spending policy. Per-user limit on (minimum 2,000 credits/month). Mutually exclusive with Unlimited."
    "Copilot + Cowork Spend Unlimited"           = "Scope of the Cowork Unlimited spending policy. No per-user limit. Mutually exclusive with Limit."
    "Copilot + Cowork Spend Unlimited Temp"      = "Scope of the Cowork Temporary Unlimited spending policy. Granted for 30 days by the Temporary Unlimited access package; only Spend Limit members can request it. Only one policy applies to a person at a time, and spending already used still counts."
    "Copilot + Code Spend Limit"                 = "Scope of the Code Limited spending policy. Per-user limit on (minimum 2,000 credits/month). Mutually exclusive with Unlimited."
    "Copilot + Code Spend Unlimited"             = "Scope of the Code Unlimited spending policy. No per-user limit. Mutually exclusive with Limit."
    "Copilot + Code Secure Execution Exemption"  = "Policy exemption group for Copilot Code secure local execution - runs local projects outside the protected environment. Keep small."
    "Copilot + Code Access"                      = "RETIRED by the current design: Code access comes from the Code spend groups. Delete with Update-CopilotGroupCleanup.ps1."
    "Copilot + Cowork Access"                    = "RETIRED by the current design: Cowork access comes from the Cowork spend groups. Delete with Update-CopilotGroupCleanup.ps1."
    "Copilot Preview Models Access"              = "RETIRED by the current design: use Copilot Independent Processor Models Access. Delete with Update-CopilotGroupCleanup.ps1."
    "Copilot SpaceXAI Models Access"             = "SpaceXAI models (Frontier only). On Oct 23, 2026 SpaceXAI appeared under AI providers operating as independent processors, not subprocessors - use the page where you see it."
    "Copilot Independent Processor Models Access" = "AI providers operating as independent processors, every provider except SpaceXAI (e.g. Mistral AI, Anthropic Models with Data Retention). Data leaves Microsoft terms - legal approval required."
    "Copilot Anthropic Models Access"            = "AI providers operating as Microsoft subprocessors > Anthropic. Required for Word/Excel/PowerPoint Agents."
    "Copilot OpenAI Models Access"               = "AI providers operating as Microsoft subprocessors > OpenAI (if restricting)."
    "Copilot + Autopilot Access"                 = "Microsoft Autopilot (formerly Scout, Frontier). Pair with Copilot Frontier Access; scope of the Autopilot spending policy once Microsoft publishes it (MC1479277)."
    "Copilot Frontier Access"                    = "Target of Copilot > Settings > Copilot Frontier. Required for Opal, Code, Autopilot, SpaceXAI models and Cowork app building. Keep flat (direct members)."
    "Copilot Advanced Package Upload Access"     = "Scope for Copilot > Settings > Advanced package uploads (agents/plugins with actions or MCP servers). The Oct 25, 2026 date has passed - set this now (MC1472007)."
    "Copilot Agent Sharing Access"               = "Who can share Agent Builder agents org-wide (Agents > Settings > Sharing)."
    "Copilot Pilot Ring"                         = "Early-validation users; scope of the Copilot New Services Pilot spending policy (auto-applies new credit-billed services, e.g. Copilot Code)."
    "Copilot Managed Runtime Access"             = "Scope of the Managed Runtime spending policy: people who run apps built in Cowork, Copilot Studio or the CLI. No Copilot license needed."
    "Copilot Work IQ API Access"                 = "Scope of the Work IQ API spending policy: users of custom agents and apps that call the Work IQ API. Admin controls for Business Applications in Work IQ reach preview by Nov 17, 2026 (MC1518036)."
    "Copilot SharePoint OneDrive Advanced Access" = "Scope of the SharePoint OneDrive Advanced Work spending policy (Advanced work in SharePoint and OneDrive)."
    "Copilot Teams Phone Agent Accounts"         = "Teams Phone Agent resource accounts only (no people). Scope of the Teams Phone Agent spending policy. One group and one policy per budget (MC1482800). Not managed by access packages."
    "Copilot Access"                             = "Baseline Microsoft Copilot license (group-based licensing). Keep the Microsoft Copilot with Graph-grounded chat service plan on."
    "Copilot Agent ID Developers"                = "Can create agent blueprints after 'Users can register agent identity blueprints' is set to No (MC1506733)."
    "Copilot Cloud Policy Exceptions"            = "Users with non-default Cloud Policy (web search, Pages/Notebooks, code previews, and the Clipchamp AI video policy from late Nov 2026, MC1518034)."
    "Copilot Cost Reader"                        = "Read-only Copilot consumption reporting. Assign AI Reader, or retire and use Copilot AI Reader."
    "Copilot Plugin Approvers"                   = "Notification/ticket queue for org-wide agent and plugin publish requests. No Entra role or approver setting exists."
}

# ---------------------------------------------------------------------------
# 3. Groups to delete in this version. Empty this week.
# ---------------------------------------------------------------------------
$toDelete = [ordered]@{ }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Get-GroupByName([string]$name) {
    $esc = $name.Replace("'", "''")
    $uri = "$graph/groups?`$filter=$([uri]::EscapeDataString("displayName eq '$esc'"))&`$select=id,displayName,description"
    @((Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject).value)
}

function Get-AllPages([string]$uri) {
    $items = @()
    while ($uri) {
        $page  = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
        $items += $page.value
        $uri   = $page.'@odata.nextLink'
    }
    $items
}

$results = @()

# ---------------------------------------------------------------------------
# Renames
# ---------------------------------------------------------------------------
foreach ($oldName in $renames.Keys) {
    $newName = $renames[$oldName]
    $found = Get-GroupByName $oldName
    if ($found.Count -eq 0) { $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "Not found" }; continue }
    if ($found.Count -gt 1) { $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "Skipped: duplicate name" }; continue }
    if ((Get-GroupByName $newName).Count -gt 0) {
        $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "Skipped: '$newName' already exists" }
        continue
    }
    if ($WhatIfPreference) { $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "WhatIf -> $newName" }; continue }
    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "$graph/groups/$($found[0].id)" `
            -Body (@{ displayName = $newName } | ConvertTo-Json) -ContentType "application/json" | Out-Null
        $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "Renamed to '$newName'" }
    }
    catch {
        $results += [pscustomobject]@{ Group = $oldName; Action = "Rename"; Result = "Failed: $($_.Exception.Message)" }
    }
}

# ---------------------------------------------------------------------------
# Deletes
# ---------------------------------------------------------------------------
foreach ($name in $toDelete.Keys) {
    $found = Get-GroupByName $name
    if ($found.Count -eq 0) { $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Not found" }; continue }
    if ($found.Count -gt 1) { $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Skipped: duplicate name" }; continue }
    $g = $found[0]

    $members = Get-AllPages "$graph/groups/$($g.id)/members?`$select=id,displayName,userPrincipalName"
    $owners  = Get-AllPages "$graph/groups/$($g.id)/owners?`$select=id,displayName,userPrincipalName"

    if ($members.Count -gt 0 -and -not $DeleteEvenIfMembers) {
        $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Skipped: $($members.Count) members (use -DeleteEvenIfMembers)" }
        continue
    }

    if ($PSCmdlet.ShouldProcess("$name ($($g.id)) - $($toDelete[$name])", "DELETE group")) {
        if (-not (Test-Path $ExportFolder)) { New-Item -ItemType Directory -Path $ExportFolder | Out-Null }
        $safe = ($name -replace '[^A-Za-z0-9]', '')
        $export = @($members | ForEach-Object { [pscustomobject]@{ Role = "Member"; Id = $_.id; DisplayName = $_.displayName; UPN = $_.userPrincipalName } }) +
                  @($owners  | ForEach-Object { [pscustomobject]@{ Role = "Owner";  Id = $_.id; DisplayName = $_.displayName; UPN = $_.userPrincipalName } })
        $export | Export-Csv -Path (Join-Path $ExportFolder "$safe-$($g.id).csv") -NoTypeInformation

        try {
            Invoke-MgGraphRequest -Method DELETE -Uri "$graph/groups/$($g.id)" | Out-Null
            $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Deleted ($($members.Count) members, $($owners.Count) owners exported)" }
        }
        catch {
            $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Failed: $($_.Exception.Message)" }
        }
    }
    else {
        $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "WhatIf ($($members.Count) members)" }
    }
}

# ---------------------------------------------------------------------------
# Description updates
# ---------------------------------------------------------------------------
foreach ($name in $descriptions.Keys) {
    $new = $descriptions[$name]
    $found = Get-GroupByName $name
    if ($found.Count -eq 0) { $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "Not found" }; continue }
    if ($found.Count -gt 1) { $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "Skipped: duplicate name" }; continue }
    $g = $found[0]

    if ($g.description -eq $new) { $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "Already current" }; continue }

    # Description updates are low-risk, so they honor -WhatIf but don't prompt like the deletes.
    if ($WhatIfPreference) { $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "WhatIf" }; continue }
    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "$graph/groups/$($g.id)" `
            -Body (@{ description = $new } | ConvertTo-Json) -ContentType "application/json" | Out-Null
        $was = if ([string]::IsNullOrEmpty($g.description)) { "was empty" } else { "replaced old text" }
        $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "Updated ($was)" }
    }
    catch {
        $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "Failed: $($_.Exception.Message)" }
    }
}

# ---------------------------------------------------------------------------
# Groups the design expects that aren't in the tenant yet
# ---------------------------------------------------------------------------
$expectedMissing = @(
    "Copilot SpaceXAI Models Access", "Copilot Independent Processor Models Access",
    "Copilot App Builder Access", "Copilot Agent ID Developers",
    "Copilot Agent Registry Admin", "Copilot Platform Admin"
)
foreach ($name in $expectedMissing) {
    if ((Get-GroupByName $name).Count -eq 0) {
        $results += [pscustomobject]@{ Group = $name; Action = "Check"; Result = "Missing: run New-CopilotGroups.ps1 (or New-CopilotAdminPim.ps1 for Platform Admin)" }
    }
}

$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotGroups-20261026-Results-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
