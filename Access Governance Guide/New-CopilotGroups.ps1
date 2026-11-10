<#PSScriptInfo
.VERSION 2026.11
.GUID c3e624bd-42dd-423f-b57b-86d80ed63d11
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
Checks every Copilot group in the tenant against this design and creates or fixes what is missing or out of date.
url: Manage Microsoft Copilot settings in the M365 admin center - https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-page
#>

<#
.SYNOPSIS
    The one script for the Copilot groups. Run it any time: it checks each group in the
    table below and creates or fixes it. Graph only (Invoke-MgGraphRequest).

.DESCRIPTION
    For every group in $groups:
      - Missing: creates it (admin groups as role-assignable; that can only be set at creation).
      - Missing, but found under one of its OldNames: renames it.
      - Description differs from the table: updates it.
      - Admin group that isn't role-assignable: warns (it has to be recreated by hand).
      - Two groups with the same name: skips it and says so.

    For every group in $retiredGroups:
      - Reports it if it's still in the tenant.
      - With -RemoveRetiredGroups: exports its members and owners to CSV, then deletes it.
        Groups that still have members are skipped unless you add -DeleteEvenIfMembers.
        Deletes ask for confirmation unless you pass -Confirm:$false.

    HOW TO CHANGE THE DESIGN
      - New group: add a line to $groups.
      - New description: change Desc. The next run updates the tenant.
      - Renamed group: change Name and put the old name in OldNames.
      - Retired group: move it from $groups to $retiredGroups with the reason.
    Roles and PIM settings for the admin groups live in New-CopilotAdminPim.ps1.
    Access packages live in New-CopilotAccessPackages.ps1.

    Least-privileged role: Privileged Role Administrator (it creates and updates role-assignable
    groups). With -SkipAdminGroups, Groups Administrator is enough.
    Scopes: Group.ReadWrite.All, plus RoleManagement.ReadWrite.Directory unless -SkipAdminGroups
    (Microsoft Learn: needed to set isAssignableToRole and to change role-assignable groups).

.PARAMETER IncludeCodeGroups
    Also checks the three Copilot Code groups. Use it once Code is in your spending policy wizard (MC1519871).

.PARAMETER SkipAdminGroups
    Skips the role-assignable admin groups, so you don't need Privileged Role Administrator.

.PARAMETER RemoveRetiredGroups
    Deletes the groups in $retiredGroups. Without it they are only reported.

.PARAMETER Environment
    The Microsoft cloud to sign in to: Global (also GCC), USGov (GCC High) or USGovDoD.
    Leave it out and the script asks.

.EXAMPLE
    .\New-CopilotGroups.ps1 -WhatIf
    .\New-CopilotGroups.ps1
    .\New-CopilotGroups.ps1 -IncludeCodeGroups
    .\New-CopilotGroups.ps1 -SkipAdminGroups
    .\New-CopilotGroups.ps1 -RemoveRetiredGroups -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$IncludeCodeGroups,
    [switch]$SkipAdminGroups,
    [switch]$RemoveRetiredGroups,
    [switch]$DeleteEvenIfMembers,
    [string]$ExportFolder = ".\CopilotRetiredGroups-$(Get-Date -Format yyyyMMdd-HHmm)",
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

# ---------------------------------------------------------------------------
# The design. Change these tables, not the code below.
#   Name           = display name in Entra
#   Desc           = description; the script keeps the tenant in step with it
#   RoleAssignable = admin group (role-assignable, under PIM). Can't be changed after creation.
#   Code           = only with -IncludeCodeGroups
#   OldNames       = earlier names; a group found under one of them is renamed
# ---------------------------------------------------------------------------
$groups = @(
    # ---------- Feature access ----------
    @{ Name = "Copilot Access";                              Desc = "Baseline Microsoft Copilot users (group-based licensing). Assign the Copilot license here unless it comes with Microsoft 365 E7 (E5 does not include it). Keep the Microsoft Copilot with Graph-grounded chat service plan on." }
    @{ Name = "Copilot + Opal Access";                       Desc = "Opal (Frontier). Target of Copilot > Settings > Opal (Frontier). Group owner must also be a member. Also scope of the Opal spending policy (MC1540330)." }
    @{ Name = "Copilot + Autopilot Access";                  Desc = "Microsoft Autopilot (formerly Scout, Frontier). Pair with Copilot Frontier Access; scope of the Autopilot spending policy once Microsoft publishes it (MC1479277)." }
    @{ Name = "Copilot Studio Access";                       Desc = "Copilot Studio makers." }
    @{ Name = "Copilot App Builder Access";                  Desc = "Who can build apps in Copilot Studio (Managed Runtime preview). Set via pac admin update-tenant-settings enabledGroupsManagedAppsMcsPreview." }
    @{ Name = "Copilot Frontier Access";                     Desc = "Target of Copilot > Settings > Copilot Frontier. Gives public previews in Copilot, Teams, new Outlook, OneDrive and SharePoint (MC1529472). Required for Opal, Code, Autopilot, SpaceXAI models and Cowork app building. Keep flat (direct members)." }
    @{ Name = "Copilot Pilot Ring";                          Desc = "Early-validation users; scope of the Copilot New Services Pilot spending policy (auto-applies new credit-billed services, e.g. Copilot Code)." }

    # ---------- Spend (spending policies in Copilot > Cost Management) ----------
    # Cowork access is granted by these spending policies, so there is no separate Cowork access group.
    @{ Name = "Copilot + Cowork Spend Limit";                Desc = "Scope of the Cowork Limited spending policy. Per-user limit on (minimum 2,000 credits/month). Mutually exclusive with Unlimited." }
    @{ Name = "Copilot + Cowork Spend Unlimited";            Desc = "Scope of the Cowork Unlimited spending policy. No per-user limit. Mutually exclusive with Limit." }
    @{ Name = "Copilot + Cowork Spend Unlimited Temp";       Desc = "Scope of the Cowork Temporary Unlimited spending policy. Granted for 30 days by the Temporary Unlimited access package; only Spend Limit members can request it. Only one policy applies to a person at a time, and spending already used still counts." }
    @{ Name = "Copilot SharePoint OneDrive Advanced Access"; Desc = "Scope of the SharePoint OneDrive Advanced Work spending policy (Advanced work in SharePoint and OneDrive)." }
    @{ Name = "Copilot Work IQ API Access";                  Desc = "Scope of the Work IQ API spending policy: users of custom agents and apps that call the Work IQ API. Admin controls for Business Applications in Work IQ reach preview by Nov 17, 2026 (MC1518036)." }
    @{ Name = "Copilot Managed Runtime Access";              Desc = "Scope of the Managed Runtime spending policy: people who run apps built in Cowork, Copilot Studio or the CLI. No Copilot license needed." }
    @{ Name = "Copilot Intelligent Call Delegation Access";  Desc = "Scope of the Intelligent Call Delegation spending policy (Teams AI call screening, public preview, MC1537490)." }
    @{ Name = "Copilot Teams Phone Agent Accounts";          Desc = "Teams Phone Agent resource accounts only (no people). Scope of the Teams Phone Agent spending policy. One group and one policy per budget (MC1482800). Not managed by access packages." }

    # ---------- Copilot Code (rolling out to Frontier from late Oct 2026, MC1519871; -IncludeCodeGroups) ----------
    @{ Name = "Copilot + Code Spend Limit";                  Code = $true; Desc = "Scope of the Code Limited spending policy. Per-user limit on (minimum 2,000 credits/month). Mutually exclusive with Unlimited." }
    @{ Name = "Copilot + Code Spend Unlimited";              Code = $true; Desc = "Scope of the Code Unlimited spending policy. No per-user limit. Mutually exclusive with Limit." }
    @{ Name = "Copilot + Code Secure Execution Exemption";   Code = $true; Desc = "Policy exemption group for Copilot Code secure local execution - runs local projects outside the protected environment. Keep small." }

    # ---------- Models ----------
    @{ Name = "Copilot Anthropic Models Access";             Desc = "AI providers operating as Microsoft subprocessors > Anthropic." }
    @{ Name = "Copilot OpenAI Models Access";                Desc = "AI providers operating as Microsoft subprocessors > OpenAI (if restricting)." }
    @{ Name = "Copilot SpaceXAI Models Access";              Desc = "AI providers operating as Microsoft subprocessors > SpaceXAI (Frontier only): Grok models in Word, Excel, PowerPoint and, with usage-based billing, Chat. Cowork and Copilot Studio use the independent processor setting instead." }
    @{ Name = "Copilot Independent Processor Models Access"; Desc = "AI providers operating as independent processors, every provider (e.g. Mistral AI, Anthropic Models with Data Retention, and SpaceXAI for Cowork and Copilot Studio). Data leaves Microsoft terms - legal approval required. Global Admin configures." }

    # ---------- Capability and exceptions ----------
    @{ Name = "Copilot + Cowork Browser Access";             Desc = "Copilot > Settings > Browser use in Microsoft Copilot > Allow local browser use (renamed from Cowork settings, MC1515930). Also the Intune Edge policy CopilotCoworkToolActionsEnabled (Edge 152+)." }
    @{ Name = "Copilot Advanced Package Upload Access";      Desc = "Scope for Copilot > Settings > Advanced package uploads (agents/plugins with actions or MCP servers). The Oct 25, 2026 date has passed - set this now (MC1472007)." }
    @{ Name = "Copilot Agent Sharing Access";                Desc = "Who can share Agent Builder agents org-wide (Agents > Settings > Sharing)." }
    @{ Name = "Copilot Teams Policy Exceptions";             Desc = "Users assigned a non-default Teams meeting/calling AI policy. MeetingAI and TranscriptionWithMeetingAI replace the Copilot policy from December 2026 (MC1532253)." }
    @{ Name = "Copilot Cloud Policy Exceptions";             Desc = "Users with non-default Cloud Policy (web search, Pages/Notebooks, code previews, and the Clipchamp AI video policy from late Nov 2026, MC1518034)." }

    # ---------- Admin groups (role-assignable; roles and PIM in New-CopilotAdminPim.ps1) ----------
    @{ Name = "Copilot Platform Admin";             RoleAssignable = $true; Desc = "All-up Copilot administration (JIT via PIM). Activation grants every Copilot admin role." }
    @{ Name = "Copilot Delegated Admin";            RoleAssignable = $true; Desc = "Copilot settings administration." }
    @{ Name = "Copilot Agent Management Admin";     RoleAssignable = $true; Desc = "Agents node / Agent 365 administration." }
    @{ Name = "Copilot Agent Registry Admin";       RoleAssignable = $true; Desc = "Entra Agent Registry: agent metadata, collections and agent visibility." }
    @{ Name = "Copilot AI Reader";                  RoleAssignable = $true; Desc = "Read-only Copilot settings and agent inventory." }
    @{ Name = "Copilot Billing Admin";              RoleAssignable = $true; Desc = "Copilot > Cost Management spending policies." }
    @{ Name = "Copilot Cost Reader";                RoleAssignable = $true; Desc = "Read-only Copilot consumption reporting. Assign AI Reader, or retire and use Copilot AI Reader." }
    @{ Name = "Copilot Agent ID Admin";             RoleAssignable = $true; Desc = "Entra Agent ID identities and blueprints." }
    @{ Name = "Copilot Agent ID Developers";        RoleAssignable = $true; Desc = "Can create agent blueprints after 'Users can register agent identity blueprints' is set to No (MC1506733)." }
    @{ Name = "Copilot Office Apps Admin";          RoleAssignable = $true; Desc = "Cloud Policy (config.office.com) Copilot settings." }
    @{ Name = "Copilot Compliance Admin";           RoleAssignable = $true; Desc = "Purview DLP, audit, eDiscovery, DSPM." }
    @{ Name = "Copilot Teams Admin";                RoleAssignable = $true; Desc = "Teams meeting/calling Copilot policies." }
    @{ Name = "Copilot SharePoint Admin";           RoleAssignable = $true; Desc = "RCD/RAC, DAG reports, agent access insights." }
    @{ Name = "Copilot Studio Environment Admin";   RoleAssignable = $true; Desc = "PPAC data policies and Copilot Studio governance." }
    @{ Name = "Copilot Plugin Approvers";           RoleAssignable = $true; Desc = "Notification/ticket queue for org-wide agent and plugin publish requests. No Entra role or approver setting exists." }
    @{ Name = "Copilot Health Check Users";         RoleAssignable = $true; Desc = "People who run the Copilot Billing and Agent and Tools health checks (read-only). Holds AI Reader, Security Reader and Reports Reader through PIM. Scope of the health check Cowork plugins." }
    @{ Name = "Copilot Entra ID Operations Reader"; RoleAssignable = $true; Desc = "People who run the Entra ID Operations Report and Entra ID Security Review (read-only). Holds Global Reader through PIM. Scope of their Cowork plugins." }
)

# Groups this design no longer uses. Reported every run; deleted only with -RemoveRetiredGroups.
$retiredGroups = [ordered]@{
    "Copilot + Cowork Access"       = "Cowork access now comes only from the Cowork spend groups."
    "Copilot + Code Access"         = "Code access comes from the Code spend groups, like Cowork."
    "Copilot Preview Models Access" = "Replaced by Copilot Independent Processor Models Access."
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
function Connect-Cloud {
    # Which Microsoft cloud to sign in to. GCC uses Global, GCC High is USGov, DoD is USGovDoD.
    # Not every Copilot or agent API exists in every national cloud; check Microsoft's docs for yours.
    param([string]$Environment, [string[]]$Scopes)
    if (-not $Environment) {
        Get-MgEnvironment | Where-Object Name -in "Global", "USGov", "USGovDoD" | Select-Object Name, GraphEndpoint | Out-Host
        $choice = Read-Host "Type the cloud to connect to (Global, USGov or USGovDoD). Press Enter for Global"
        $Environment = if ($choice -in "Global", "USGov", "USGovDoD") { $choice } else { "Global" }
    }
    Connect-MgGraph -Environment $Environment -Scopes $Scopes -NoWelcome | Out-Null
    (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint
}

function Get-AllPages([string]$Uri) {
    while ($Uri) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        $page.value
        $Uri = $page.'@odata.nextLink'
    }
}

function Get-GroupByName([string]$Name) {
    $esc = $Name.Replace("'", "''")
    $filter = [uri]::EscapeDataString("displayName eq '$esc'")
    @(Get-AllPages "$graph/groups?`$filter=$filter&`$select=id,displayName,description,isAssignableToRole" | Where-Object { $_ })
}

function Get-MailNickname([string]$Name) {
    $nick = $Name -replace '[^A-Za-z0-9]', ''
    if ($nick.Length -gt 64) { $nick.Substring(0, 64) } else { $nick }
}

function Set-CopilotGroup {
    # Creates, renames or updates one group so it matches its row in $groups.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][hashtable]$Group)
    process {
        $roleAssignable = [bool]$Group.RoleAssignable
        $found = Get-GroupByName $Group.Name
        $renamedFrom = $null
        if ($found.Count -eq 0) {
            foreach ($old in @($Group.OldNames | Where-Object { $_ })) {
                $oldFound = Get-GroupByName $old
                if ($oldFound.Count -eq 1) { $found = $oldFound; $renamedFrom = $old; break }
            }
        }

        $result = if ($found.Count -gt 1) {
            "Skipped: $($found.Count) groups share this name"
        }
        elseif ($found.Count -eq 0) {
            if ($PSCmdlet.ShouldProcess($Group.Name, "Create group")) {
                $body = @{
                    displayName     = $Group.Name
                    description     = $Group.Desc
                    mailEnabled     = $false
                    mailNickname    = Get-MailNickname $Group.Name
                    securityEnabled = $true
                }
                if ($roleAssignable) { $body.isAssignableToRole = $true }
                try {
                    $new = Invoke-MgGraphRequest -Method POST -Uri "$graph/groups" -Body ($body | ConvertTo-Json) `
                        -ContentType "application/json" -OutputType PSObject
                    $found = @($new)
                    "Created"
                }
                catch { "Create failed: $($_.Exception.Message)" }
            }
            else { "WhatIf: create" }
        }
        else {
            $g = $found[0]
            $patch = @{}
            if ($renamedFrom) { $patch.displayName = $Group.Name }
            if ($g.description -ne $Group.Desc) { $patch.description = $Group.Desc }
            $what = @(if ($renamedFrom) { "rename from '$renamedFrom'" }; if ($patch.description) { "update description" }) -join " and "

            $fix = if ($patch.Count -eq 0) { "OK" }
            elseif ($PSCmdlet.ShouldProcess($Group.Name, $what)) {
                try {
                    Invoke-MgGraphRequest -Method PATCH -Uri "$graph/groups/$($g.id)" -Body ($patch | ConvertTo-Json) `
                        -ContentType "application/json" | Out-Null
                    "Fixed: $what"
                }
                catch { "Fix failed ($what): $($_.Exception.Message)" }
            }
            else { "WhatIf: $what" }

            if ($roleAssignable -and -not $g.isAssignableToRole) {
                "$fix. NOT role-assignable: roles can't be assigned; delete and recreate it"
            }
            else { $fix }
        }

        $Group | Select-Object @{ n = "Group"; e = { $Group.Name } },
            @{ n = "Type"; e = { if ($roleAssignable) { "Admin" } else { "Feature" } } },
            @{ n = "Result"; e = { $result } },
            @{ n = "Id"; e = { @($found)[0].id } }
    }
}

function Remove-RetiredGroup {
    # Reports a retired group, and with -RemoveRetiredGroups exports its members and owners and deletes it.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param([Parameter(ValueFromPipeline = $true)][string]$Name)
    process {
        $reason = $retiredGroups[$Name]
        $found = Get-GroupByName $Name
        $result = if ($found.Count -eq 0) { "Retired: not in tenant" }
        elseif ($found.Count -gt 1) { "Retired: skipped, $($found.Count) groups share this name" }
        elseif (-not $RemoveRetiredGroups) { "Retired: still in tenant ($reason) Add -RemoveRetiredGroups to delete" }
        else {
            $g = $found[0]
            $members = @(Get-AllPages "$graph/groups/$($g.id)/members?`$select=id,displayName,userPrincipalName" | Where-Object { $_ })
            $owners  = @(Get-AllPages "$graph/groups/$($g.id)/owners?`$select=id,displayName,userPrincipalName" | Where-Object { $_ })
            if ($members.Count -gt 0 -and -not $DeleteEvenIfMembers) {
                "Retired: skipped, $($members.Count) members (add -DeleteEvenIfMembers)"
            }
            elseif ($PSCmdlet.ShouldProcess("$Name ($($g.id)) - $reason", "DELETE group")) {
                if (-not (Test-Path $ExportFolder)) { New-Item -ItemType Directory -Path $ExportFolder | Out-Null }
                @(
                    $members | Select-Object @{ n = "Role"; e = { "Member" } }, id, displayName, userPrincipalName
                    $owners  | Select-Object @{ n = "Role"; e = { "Owner" } }, id, displayName, userPrincipalName
                ) | Export-Csv -Path (Join-Path $ExportFolder "$(Get-MailNickname $Name)-$($g.id).csv") -NoTypeInformation
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "$graph/groups/$($g.id)" | Out-Null
                    "Retired: deleted ($($members.Count) members, $($owners.Count) owners exported)"
                }
                catch { "Retired: delete failed: $($_.Exception.Message)" }
            }
            else { "Retired: WhatIf delete ($($members.Count) members)" }
        }
        $Name | Select-Object @{ n = "Group"; e = { $Name } }, @{ n = "Type"; e = { "Retired" } },
            @{ n = "Result"; e = { $result } }, @{ n = "Id"; e = { @($found)[0].id } }
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
$scopes = @("Group.ReadWrite.All"; if (-not $SkipAdminGroups) { "RoleManagement.ReadWrite.Directory" })
$graph = "$(Connect-Cloud -Environment $Environment -Scopes $scopes)/beta"

$results = @(
    $groups |
        Where-Object { $IncludeCodeGroups -or -not $_.Code } |
        Where-Object { -not ($SkipAdminGroups -and $_.RoleAssignable) } |
        Set-CopilotGroup
    @($retiredGroups.Keys) | Remove-RetiredGroup
)

$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotGroups-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
