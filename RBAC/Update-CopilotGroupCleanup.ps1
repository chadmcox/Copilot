<#
.SYNOPSIS
    One-off cleanup of the "Copilot*" groups in the tenant (inventory taken 2026-10-16):
      1. Deletes the three groups the design no longer uses.
      2. Sets descriptions on groups created by hand with no description, and refreshes
         the descriptions that are now out of date.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest). Needs Group.ReadWrite.All.
    Supports -WhatIf. Deletions also prompt for confirmation unless you pass -Confirm:$false.

    Safety on delete:
      - Members and owners of each group are exported to CSV before it is deleted.
      - A group that still has members is skipped unless you use -DeleteEvenIfMembers.
      - Before running, remove each group from any setting that still points at it
        (Cowork plugin "Installed for", spending policies, Copilot settings). Deleting a
        group a setting still uses can leave that setting scoped to nothing.

.EXAMPLE
    .\Update-CopilotGroupCleanup.ps1 -WhatIf
    .\Update-CopilotGroupCleanup.ps1
    .\Update-CopilotGroupCleanup.ps1 -DeleteEvenIfMembers
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$DeleteEvenIfMembers,
    [string]$ExportFolder = ".\CopilotGroupCleanup-$(Get-Date -Format yyyyMMdd-HHmm)"
)

#Requires -Modules Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome
$graph = "https://graph.microsoft.com/v1.0"

# ---------------------------------------------------------------------------
# 1. Groups to delete (replaced in the current design)
# ---------------------------------------------------------------------------
$toDelete = [ordered]@{
    "Copilot + Cowork Access"       = "Cowork access now comes only from the Cowork spend groups."
    "Copilot + Code Access"         = "Code access will come from the Code spend groups, like Cowork."
    "Copilot Preview Models Access" = "Replaced by Copilot Independent Processor Models Access."
}

# ---------------------------------------------------------------------------
# 2. Descriptions to set (missing or outdated)
# ---------------------------------------------------------------------------
$descriptions = [ordered]@{
    # Created by hand with no description
    "Copilot + Cowork Spend Unlimited Temp"      = "Scope of the Cowork - Temporary Unlimited spending policy. Granted for 30 days by the Temporary Unlimited access package; only Spend Limit members can request it."
    "Copilot Teams Phone Agent Accounts"         = "Teams Phone Agent resource accounts only (no people). Scope of the Teams Phone Agent spending policy. Not managed by access packages."
    "Copilot Work IQ API Access"                 = "Scope of the Work IQ API spending policy: users of custom agents and apps that call the Work IQ API."
    "Copilot SharePoint OneDrive Advanced Access" = "Scope of the spending policy selecting Advanced work in SharePoint and Advanced work in OneDrive."
    "Copilot Managed Runtime Access"             = "Scope of the Copilot Managed Runtime spending policy: people who run apps built in Cowork, Copilot Studio or the CLI. No Copilot license needed."

    # Outdated descriptions
    "Copilot + Autopilot Access"                 = "Microsoft Autopilot (formerly Scout, Frontier). Pair with Copilot Frontier Access; scope of the Autopilot spending policy once Microsoft publishes it (MC1479277)."
    "Copilot Frontier Access"                    = "Target of Copilot > Settings > Copilot Frontier. Required for Opal, Code, Autopilot, SpaceXAI subprocessor models and Cowork app building. Keep flat (direct members)."
    "Copilot + Cowork Browser Access"            = "Scope for Copilot > Settings > Cowork settings > Allow browser access, and the Intune Edge policy CopilotCoworkToolActionsEnabled (Edge 152+)."
    "Copilot Advanced Package Upload Access"     = "Scope for Copilot > Settings > Advanced package uploads (agents/plugins with actions or MCP servers). Set before Oct 25, 2026 (MC1472007)."
    "Copilot + Code Spend Limit"                 = "On hold: scope of the Code - Limited spending policy once Code appears in the wizard. Mutually exclusive with Code Spend Unlimited."
    "Copilot + Code Spend Unlimited"             = "On hold: scope of the Code - Unlimited spending policy once Code appears in the wizard. Mutually exclusive with Code Spend Limit."
    "Copilot + Code Secure Execution Exemption"  = "On hold: Copilot Code policy exemption group (local projects run outside the protected environment). Keep small."
    "Copilot Access"                             = "Baseline Microsoft Copilot license (group-based licensing). Keep the Microsoft Copilot with Graph-grounded chat service plan on."
    "Copilot Cost Reader"                        = "Read-only Copilot consumption reporting. Assign AI Reader, or retire and use Copilot AI Reader."
    "Copilot Plugin Approvers"                   = "Notification/ticket queue for org-wide agent and plugin publish requests. No Entra role or approver setting exists."
}

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
# Deletes
# ---------------------------------------------------------------------------
foreach ($name in $toDelete.Keys) {
    $found = Get-GroupByName $name
    if ($found.Count -eq 0) { $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Not found" }; continue }
    if ($found.Count -gt 1) { $results += [pscustomobject]@{ Group = $name; Action = "Delete"; Result = "Skipped: $($found.Count) groups share this name" }; continue }
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
    if ($WhatIfPreference) {
        $results += [pscustomobject]@{ Group = $name; Action = "Describe"; Result = "WhatIf" }
        continue
    }
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
# Report groups the design expects that aren't in the tenant yet
# ---------------------------------------------------------------------------
$expectedMissing = @(
    "Copilot SpaceXAI Models Access", "Copilot Independent Processor Models Access",
    "Copilot App Builder Access", "Copilot Agent ID Developers", "Copilot Platform Admin"
)
foreach ($name in $expectedMissing) {
    if ((Get-GroupByName $name).Count -eq 0) {
        $results += [pscustomobject]@{ Group = $name; Action = "Check"; Result = "Missing: run New-CopilotGroups.ps1 (or New-CopilotAdminPim.ps1 for Platform Admin)" }
    }
}

$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotGroupCleanup-Results-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
