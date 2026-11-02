<#PSScriptInfo
.VERSION 2026.11
.GUID f97c2926-657c-4239-a9b0-b3901348c3a3
.AUTHOR Chad Cox
    https://blogs.technet.microsoft.com/chadcox/
    https://github.com/chadmcox
.COMPANYNAME
.COPYRIGHT This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys` fees, that arise or result
from the use or distribution of the Sample Code..
.description
Brings the descriptions of Copilot groups already in the tenant up to the Nov 2, 2026 version of the Copilot Group Assignment Guide.
url: Manage Microsoft Copilot settings in the M365 admin center - https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-page
#>

<#
.SYNOPSIS
    Dated one-off: updates the descriptions of five Copilot groups for the Nov 2, 2026 guide.
    Renames nothing and deletes nothing. Lists any of these groups that aren't in the tenant yet.

.DESCRIPTION
    Graph only (Invoke-MgGraphRequest). Needs Group.ReadWrite.All.
    Least-privileged role: Groups Administrator. The role-assignable Copilot Compliance Admin
    group also needs Privileged Role Administrator, or that one update fails and is reported.
    Run it after Update-CopilotGroups-20261026.ps1, because that script sets older text.

    What changed this week:
      - Frontier now also gives previews in Teams, new Outlook, OneDrive and SharePoint (MC1529472).
      - SpaceXAI has two separate settings. The subprocessor setting covers Word, Excel and
        PowerPoint. The independent processor setting covers Cowork and Copilot Studio.
      - Teams MeetingAI and TranscriptionWithMeetingAI replace the Copilot meeting policy (MC1532253).
      - DSPM for AI classic retires in March 2027 (MC1481315).

.EXAMPLE
    .\Update-CopilotGroups-20261102.ps1 -WhatIf
    .\Update-CopilotGroups-20261102.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

$descriptions = [ordered]@{
    "Copilot Frontier Access"                     = "Target of Copilot > Settings > Copilot Frontier. Gives public previews in Copilot, Teams, new Outlook, OneDrive and SharePoint (MC1529472). Required for Opal, Code, Autopilot, SpaceXAI models and Cowork app building. Keep flat (direct members)."
    "Copilot SpaceXAI Models Access"              = "AI providers operating as Microsoft subprocessors > SpaceXAI (Frontier only): Grok models in Word, Excel, PowerPoint and, with usage-based billing, Chat. Cowork and Copilot Studio use the independent processor setting instead."
    "Copilot Independent Processor Models Access" = "AI providers operating as independent processors, every provider (e.g. Mistral AI, Anthropic Models with Data Retention, and SpaceXAI for Cowork and Copilot Studio). Data leaves Microsoft terms - legal approval required. Global Admin configures."
    "Copilot Teams Policy Exceptions"             = "Users assigned a non-default Teams meeting/calling AI policy. MeetingAI and TranscriptionWithMeetingAI replace the Copilot policy from mid-November 2026 (MC1532253)."
    "Copilot Compliance Admin"                    = "Purview DLP, audit, eDiscovery, DSPM."
}

function Connect-Cloud {
    # Which Microsoft cloud to sign in to. GCC uses Global, GCC High is USGov, DoD is USGovDoD.
    if (-not $Environment) {
        Get-MgEnvironment | Where-Object Name -in "Global", "USGov", "USGovDoD" | Select-Object Name, GraphEndpoint | Out-Host
        $choice = Read-Host "Type the cloud to connect to (Global, USGov or USGovDoD). Press Enter for Global"
        $Environment = if ($choice -in "Global", "USGov", "USGovDoD") { $choice } else { "Global" }
    }
    Connect-MgGraph -Environment $Environment -Scopes "Group.ReadWrite.All" -NoWelcome | Out-Null
    (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint
}

function Get-CopilotGroup {
    param([Parameter(ValueFromPipeline = $true)][string]$Name)
    process {
        $esc = $Name.Replace("'", "''")
        $filter = [uri]::EscapeDataString("displayName eq '$esc'")
        $uri = "$graph/groups?`$filter=$filter&`$select=id,displayName,description"
        # displayName isn't unique, so follow @odata.nextLink like every other collection.
        $found = do {
            $page = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
            $page.value
            $uri = $page.'@odata.nextLink'
        } while ($uri)
        $Name | Select-Object @{ n = "Name"; e = { $Name } }, @{ n = "Found"; e = { @($found | Where-Object { $_ }) } }
    }
}

function Update-CopilotGroupDescription {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)]$Item)
    process {
        $new = $descriptions[$Item.Name]
        $result = if ($Item.Found.Count -eq 0) { "Not in tenant yet. New-CopilotGroups.ps1 creates it" }
        elseif ($Item.Found.Count -gt 1) { "Skipped: duplicate name" }
        elseif ($Item.Found[0].description -eq $new) { "Already current" }
        elseif ($PSCmdlet.ShouldProcess($Item.Name, "Update description")) {
            try {
                Invoke-MgGraphRequest -Method PATCH -Uri "$graph/groups/$($Item.Found[0].id)" `
                    -Body (@{ description = $new } | ConvertTo-Json) -ContentType "application/json" | Out-Null
                "Updated"
            }
            catch { "Failed: $($_.Exception.Message)" }
        }
        else { "WhatIf" }
        $Item | Select-Object Name, @{ n = "Result"; e = { $result } }
    }
}

$graph = "$(Connect-Cloud)/beta"
@($descriptions.Keys) | Get-CopilotGroup | Update-CopilotGroupDescription | Format-Table -AutoSize
