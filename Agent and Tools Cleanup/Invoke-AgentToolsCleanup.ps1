<#
.SYNOPSIS
    Disables stale agent identities and blueprint principals, and blocks unused agents and tools,
    from the CSVs that Get-AgentToolsReport.ps1 writes. Nothing is deleted.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest, beta endpoint). Acts only on rows whose
    recommendation is Disable (identities, blueprints) or Block (agents and tools). Edit the CSVs first
    and change any row you want to keep to Keep.

    Choose what to change with the switches. With no switch, nothing changes.
      -DisableAgentIdentities  PATCH accountEnabled=false on each agent identity.
      -DisableBlueprints       PATCH accountEnabled=false on each blueprint principal. This stops
                               every agent identity under that blueprint from getting tokens.
      -BlockPackages           POST .../packages/{id}/block for agents and tools in the Agent 365 catalog.

    Every change is saved to cleanup-undo-<time>.json in the report folder. Run again with
    -Restore -UndoFile <file> to re-enable and unblock exactly those objects.

    Why disable instead of delete: a disabled identity keeps its permissions, owners and
    sponsors, so you can turn it back on if someone shouts. Deleting a blueprint deletes every
    child agent identity with it (cascade), and the 30-day soft-delete window is the only way
    back. Let the Entra Agent ID inactivity policy handle deletion (see README).

    Roles and permissions:
      - Agent identities: AgentIdentity.EnableDisable.All, Agent ID Administrator role (or owner).
      - Blueprints: AgentIdentityBlueprintPrincipal.EnableDisable.All, Agent ID Administrator.
      - Agents: CopilotPackages.ReadWrite.All, AI Administrator, Agent 365 license.

.EXAMPLE
    .\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261030-2100 -DisableAgentIdentities -BlockPackages -WhatIf
    .\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261030-2100 -DisableAgentIdentities -BlockPackages
    .\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261030-2100 -Restore -UndoFile .\AgentToolsReport-20261030-2100\cleanup-undo-20261030-2115.json
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$ReportFolder,
    [switch]$DisableAgentIdentities,
    [switch]$DisableBlueprints,
    [switch]$BlockPackages,
    [switch]$Restore,
    [string]$UndoFile,
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

# Which Microsoft cloud to sign in to. GCC uses Global, GCC High is USGov, DoD is USGovDoD.
# Not every Copilot or agent API exists in every national cloud; check Microsoft's docs for yours.
if (-not $Environment) {
    Get-MgEnvironment | Where-Object Name -in "Global", "USGov", "USGovDoD" | Select-Object Name, GraphEndpoint | Out-Host
    $choice = Read-Host "Type the cloud to connect to (Global, USGov or USGovDoD). Press Enter for Global"
    $Environment = if ($choice -in "Global", "USGov", "USGovDoD") { $choice } else { "Global" }
}
$graphEndpoint = (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint

$graph = "$graphEndpoint/beta"

# ---------------------------------------------------------------------------
# What to change
# ---------------------------------------------------------------------------
function Get-CleanupItems {
    $identities = Join-Path $ReportFolder "AgentIdentities.csv"
    $blueprints = Join-Path $ReportFolder "Blueprints.csv"
    $packages   = Join-Path $ReportFolder "Packages.csv"

    if ($DisableAgentIdentities -and (Test-Path $identities)) {
        Import-Csv $identities | Where-Object recommendation -eq "Disable" |
            Select-Object @{ n = "kind"; e = { "agentIdentity" } }, id, displayName
    }
    if ($DisableBlueprints -and (Test-Path $blueprints)) {
        Import-Csv $blueprints | Where-Object { $_.recommendation -eq "Disable" -and $_.principalId } |
            Select-Object @{ n = "kind"; e = { "blueprintPrincipal" } }, @{ n = "id"; e = { $_.principalId } }, displayName
    }
    if ($BlockPackages -and (Test-Path $packages)) {
        Import-Csv $packages | Where-Object recommendation -eq "Block" |
            Select-Object @{ n = "kind"; e = { "package" } }, id, displayName
    }
}

function Get-Scopes($items) {
    $items | Select-Object -ExpandProperty kind -Unique | ForEach-Object {
        switch ($_) {
            "agentIdentity"      { "AgentIdentity.EnableDisable.All" }
            "blueprintPrincipal" { "AgentIdentityBlueprintPrincipal.EnableDisable.All" }
            "package"            { "CopilotPackages.ReadWrite.All" }
        }
    }
}

# ---------------------------------------------------------------------------
# Make (or undo) one change. Outputs the item when the change succeeded.
# ---------------------------------------------------------------------------
function Invoke-AgentChange {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(ValueFromPipeline)]$Item,
        [switch]$Undo
    )
    process {
        $enable = [bool]$Undo
        $body   = @{ accountEnabled = $enable } | ConvertTo-Json
        switch ($Item.kind) {
            "agentIdentity"      { $method = "PATCH"; $uri = "$graph/servicePrincipals/$($Item.id)/microsoft.graph.agentIdentity" }
            "blueprintPrincipal" { $method = "PATCH"; $uri = "$graph/servicePrincipals/$($Item.id)/microsoft.graph.agentIdentityBlueprintPrincipal" }
            "package"            { $method = "POST";  $uri = "$graph/copilot/admin/catalog/packages/$($Item.id)/$(if ($Undo) { 'unblock' } else { 'block' })"; $body = $null }
        }
        $action = if ($Item.kind -eq "package") { if ($Undo) { "Unblock package" } else { "Block package" } }
                  else { if ($Undo) { "Enable" } else { "Disable" } }

        if ($PSCmdlet.ShouldProcess("$($Item.kind) '$($Item.displayName)' ($($Item.id))", $action)) {
            try {
                if ($body) { Invoke-MgGraphRequest -Method $method -Uri $uri -Body $body -ContentType "application/json" | Out-Null }
                else       { Invoke-MgGraphRequest -Method $method -Uri $uri | Out-Null }
                $Item | Select-Object kind, id, displayName, @{ n = "changedDateTime"; e = { (Get-Date).ToUniversalTime().ToString("o") } }
            }
            catch { Write-Warning "$action failed for $($Item.kind) '$($Item.displayName)' ($($Item.id)): $($_.Exception.Message)" }
        }
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
if ($Restore) {
    if (-not $UndoFile -or -not (Test-Path $UndoFile)) { throw "Use -UndoFile with a cleanup-undo-*.json file from an earlier run." }
    $items = Get-Content -Path $UndoFile -Raw | ConvertFrom-Json
    $items = @($items | ForEach-Object { $_ })
    Connect-MgGraph -Environment $Environment -Scopes @(Get-Scopes $items) -NoWelcome
    $restored = @($items | Invoke-AgentChange -Undo)
    Write-Host "Restored $($restored.Count) of $($items.Count) objects."
    return
}

$items = @(Get-CleanupItems)
if (-not $items) {
    Write-Host "Nothing to change. Pick -DisableAgentIdentities, -DisableBlueprints or -BlockPackages, and check the CSVs have Disable or Block rows."
    return
}

$items | Group-Object kind | Select-Object @{ n = "Change"; e = { $_.Name } }, Count | Format-Table -AutoSize
Connect-MgGraph -Environment $Environment -Scopes @(Get-Scopes $items) -NoWelcome

$changed = @($items | Invoke-AgentChange)

if ($changed) {
    $path = Join-Path $ReportFolder "cleanup-undo-$(Get-Date -Format yyyyMMdd-HHmm).json"
    $json = ConvertTo-Json -InputObject $changed -Depth 3
    [System.IO.File]::WriteAllText((Join-Path (Resolve-Path $ReportFolder).Path (Split-Path $path -Leaf)), $json, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Changed $($changed.Count) of $($items.Count) objects. Undo file: $path"
}
