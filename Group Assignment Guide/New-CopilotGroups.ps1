<#
.SYNOPSIS
    Creates Entra ID security groups for delegating Microsoft 365 Copilot feature access
    and Copilot administration, using raw Microsoft Graph calls (Invoke-MgGraphRequest).
    Optionally assigns Entra admin roles to the admin groups.

.DESCRIPTION
    - Only needs the Microsoft.Graph.Authentication module (Connect-MgGraph + Invoke-MgGraphRequest).
    - Idempotent: skips any group whose display name already exists.
    - Admin groups are created as role-assignable (isAssignableToRole). This can only be
      set at creation time and cannot be changed later.
    - Role assignment is OFF by default. Use -AssignRoles to grant the mapped Entra roles.
    - Supports -WhatIf to preview everything without making changes.

    Creating role-assignable groups and assigning roles requires Privileged Role
    Administrator or Global Administrator.

    This script only creates groups. You still point each feature setting at its group
    in the admin centers (Copilot Frontier, Opal, AI providers, Cost Management spending
    policies, Cowork browser access, etc.).

    Copilot Code groups are skipped unless -IncludeCodeGroups is used. Code began rolling out
    to Frontier tenants in late October 2026 (MC1519871) and is now a usage-based service, so
    use -IncludeCodeGroups once Code appears in your spending policy wizard.

.EXAMPLE
    .\New-CopilotGroups.ps1 -WhatIf
    .\New-CopilotGroups.ps1
    .\New-CopilotGroups.ps1 -AssignRoles
    .\New-CopilotGroups.ps1 -IncludeCodeGroups
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$AssignRoles,
    [switch]$IncludeCodeGroups
)

#Requires -Modules Microsoft.Graph.Authentication

$scopes = @("Group.ReadWrite.All")
if ($AssignRoles) { $scopes += "RoleManagement.ReadWrite.Directory" }
Connect-MgGraph -Scopes $scopes -NoWelcome

$graph = "https://graph.microsoft.com/v1.0"

# Role = Entra role display name to assign when -AssignRoles is used ($null = no role).
# RoleAssignable = create as a role-assignable group (cannot be changed later).
$groups = @(
    # ---------- Feature access ----------
    @{ Name = "Copilot Access";                             Desc = "Baseline Microsoft Copilot users. Assign the Copilot license here unless it comes with Microsoft 365 E7 (E5 does not include it). Also the base scope for Copilot features." }
    @{ Name = "Copilot + Opal Access";                      Desc = "Opal (Frontier). Target of Copilot > Settings > Opal (Frontier). Group owner must also be a member." }
    @{ Name = "Copilot + Autopilot Access";                 Desc = "Microsoft Autopilot (formerly Scout, Frontier). Pair with Copilot Frontier Access; scope of the Autopilot spending policy once Microsoft publishes it (MC1479277)." }
    @{ Name = "Copilot Studio Access";                      Desc = "Copilot Studio makers." }
    @{ Name = "Copilot App Builder Access";                 Desc = "Who can build apps in Copilot Studio (Managed Runtime preview). Set via pac admin update-tenant-settings enabledGroupsManagedAppsMcsPreview." }
    @{ Name = "Copilot Frontier Access";                    Desc = "Target of Copilot > Settings > Copilot Frontier. Required for Opal, Code, SpaceXAI subprocessor models, Azure DevOps data. Keep flat (direct members)." }
    @{ Name = "Copilot Pilot Ring";                         Desc = "Early-validation users; scope of the New Services Pilot spending policy (auto-enrolls new credit-billed services)." }

    # ---------- Spend (spending policies in Copilot > Cost Management) ----------
    # Cowork access is granted by these spending policies, so there is no separate Cowork access group.
    @{ Name = "Copilot + Cowork Spend Limit";               Desc = "Spending policy selecting Cowork with a per-user limit. Mutually exclusive with Unlimited." }
    @{ Name = "Copilot + Cowork Spend Unlimited";           Desc = "Spending policy selecting Cowork with no per-user limit. Mutually exclusive with Limit." }
    @{ Name = "Copilot + Cowork Spend Unlimited Temp";      Desc = "Temporary (30-day) unlimited Cowork spend; only requestable by Spend Limit members; membership auto-expires (highest per-user limit wins while it overlaps Limit)." }
    @{ Name = "Copilot SharePoint OneDrive Advanced Access"; Desc = "Spending policy selecting Advanced work in SharePoint and OneDrive (Copilot license required)." }
    @{ Name = "Copilot Work IQ API Access";                 Desc = "Spending policy selecting Work IQ API for custom apps and agents." }
    @{ Name = "Copilot Managed Runtime Access";             Desc = "Spending policy selecting Copilot Managed Runtime (running internal apps; no Copilot license required)." }
    @{ Name = "Copilot Teams Phone Agent Accounts";         Desc = "Teams Phone Agent RESOURCE ACCOUNTS only (no people). Scope of the Teams Phone Agent spending policy. Owned by Teams voice admins." }

    # ---------- Copilot Code (rolling out to Frontier from late Oct 2026, MC1519871; use -IncludeCodeGroups) ----------
    @{ Name = "Copilot + Code Spend Limit";                 Desc = "Scope of the Code Limited spending policy. Per-user limit on (minimum 2,000 credits/month). Mutually exclusive with Unlimited."; Code = $true }
    @{ Name = "Copilot + Code Spend Unlimited";             Desc = "Scope of the Code Unlimited spending policy. No per-user limit. Mutually exclusive with Limit.";   Code = $true }
    @{ Name = "Copilot + Code Secure Execution Exemption";  Desc = "Policy exemption group for Copilot Code secure local execution - runs local projects outside the protected environment. Keep small."; Code = $true }

    # ---------- Models ----------
    @{ Name = "Copilot Anthropic Models Access";            Desc = "AI providers operating as Microsoft subprocessors > Anthropic. Required for Word/Excel/PowerPoint Agents." }
    @{ Name = "Copilot OpenAI Models Access";               Desc = "AI providers operating as Microsoft subprocessors > OpenAI (if restricting)." }
    @{ Name = "Copilot SpaceXAI Models Access";             Desc = "SpaceXAI models (Frontier only). On Oct 23, 2026 SpaceXAI appeared under AI providers operating as independent processors, not subprocessors - use the page where you see it." }
    @{ Name = "Copilot Independent Processor Models Access"; Desc = "AI providers operating as independent processors, every provider except SpaceXAI (e.g. Mistral AI, Anthropic Models with Data Retention). Data leaves Microsoft terms - legal approval required. Global Admin configures." }

    # ---------- Capability scoping ----------
    @{ Name = "Copilot + Cowork Browser Access";            Desc = "Copilot > Settings > Browser use in Microsoft Copilot > Allow local browser use (renamed from Cowork settings, MC1515930). Also the Intune Edge policy CopilotCoworkToolActionsEnabled (Edge 152+)." }
    @{ Name = "Copilot Advanced Package Upload Access";     Desc = "Who can upload agent/plugin packages with actions or MCP servers." }
    @{ Name = "Copilot Agent Sharing Access";               Desc = "Who can share Agent Builder agents org-wide." }
    @{ Name = "Copilot Teams Policy Exceptions";            Desc = "Users assigned a non-default Teams meeting/calling Copilot policy." }
    @{ Name = "Copilot Cloud Policy Exceptions";            Desc = "Users with non-default Cloud Policy (web search, Pages/Notebooks, code previews)." }

    # ---------- Delegated administration (role-assignable) ----------
    @{ Name = "Copilot Delegated Admin";                    Desc = "Copilot settings administration.";                  RoleAssignable = $true; Role = "AI Administrator" }
    @{ Name = "Copilot Agent Management Admin";             Desc = "Agents node / Agent 365 administration.";             RoleAssignable = $true; Role = "AI Administrator" }
    @{ Name = "Copilot Agent Registry Admin";               Desc = "Entra Agent Registry: agent metadata, collections and agent visibility.";   RoleAssignable = $true; Role = "Agent Registry Administrator" }
    @{ Name = "Copilot AI Reader";                          Desc = "Read-only Copilot settings and agent inventory.";     RoleAssignable = $true; Role = "AI Reader" }
    @{ Name = "Copilot Billing Admin";                      Desc = "Copilot > Cost Management spending policies.";        RoleAssignable = $true; Role = "Billing Administrator" }
    @{ Name = "Copilot Cost Reader";                        Desc = "Read-only consumption reporting. Assign a supported reader role manually."; RoleAssignable = $true; Role = $null }
    @{ Name = "Copilot Agent ID Admin";                     Desc = "Entra Agent ID identities and blueprints.";           RoleAssignable = $true; Role = "Agent ID Administrator" }
    @{ Name = "Copilot Agent ID Developers";                Desc = "Can create agent blueprints after 'Users can register agent identity blueprints' is set to No (MC1506733).";  RoleAssignable = $true; Role = "Agent ID Developer" }
    @{ Name = "Copilot Office Apps Admin";                  Desc = "Cloud Policy (config.office.com) Copilot settings.";  RoleAssignable = $true; Role = "Office Apps Administrator" }
    @{ Name = "Copilot Compliance Admin";                   Desc = "Purview DLP, audit, eDiscovery, DSPM for AI.";        RoleAssignable = $true; Role = "Compliance Administrator" }
    @{ Name = "Copilot Teams Admin";                        Desc = "Teams meeting/calling Copilot policies.";             RoleAssignable = $true; Role = "Teams Administrator" }
    @{ Name = "Copilot SharePoint Admin";                   Desc = "RCD/RAC, DAG reports, agent access insights.";        RoleAssignable = $true; Role = "SharePoint Administrator" }
    @{ Name = "Copilot Studio Environment Admin";           Desc = "PPAC data policies and Copilot Studio governance.";   RoleAssignable = $true; Role = "Power Platform Administrator" }
    @{ Name = "Copilot Plugin Approvers";                   Desc = "Reviewers for org-wide agent/plugin publish requests. No Entra role mapped."; RoleAssignable = $true; Role = $null }
)

if (-not $IncludeCodeGroups) { $groups = $groups | Where-Object { -not $_.Code } }

function Get-MailNickname([string]$name) {
    $nick = ($name -replace '[^A-Za-z0-9]', '')
    if ($nick.Length -gt 64) { $nick = $nick.Substring(0, 64) }
    return $nick
}

function Get-Filtered([string]$path, [string]$filter) {
    $uri = "$graph/$path`?`$filter=$([uri]::EscapeDataString($filter))"
    (Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject).value
}

$roleCache = @{}
function Get-RoleDefinitionId([string]$roleName) {
    if (-not $roleCache.ContainsKey($roleName)) {
        $esc = $roleName.Replace("'", "''")
        $def = Get-Filtered "roleManagement/directory/roleDefinitions" "displayName eq '$esc'" | Select-Object -First 1
        $roleCache[$roleName] = $def.id
    }
    return $roleCache[$roleName]
}

$results = foreach ($g in $groups) {
    $displayName    = $g.Name
    $roleAssignable = [bool]$g.RoleAssignable
    $esc            = $displayName.Replace("'", "''")

    $group = Get-Filtered "groups" "displayName eq '$esc'" | Select-Object -First 1

    if ($group) {
        $status = "Exists"
        if ($roleAssignable -and -not $group.isAssignableToRole) {
            Write-Warning "'$displayName' exists but is NOT role-assignable. Roles cannot be assigned to it; recreate it if needed."
        }
    }
    elseif ($PSCmdlet.ShouldProcess($displayName, "POST /groups")) {
        $body = @{
            displayName     = $displayName
            description     = $g.Desc
            mailEnabled     = $false
            mailNickname    = Get-MailNickname $displayName
            securityEnabled = $true
        }
        if ($roleAssignable) { $body.isAssignableToRole = $true }

        $group = Invoke-MgGraphRequest -Method POST -Uri "$graph/groups" `
            -Body ($body | ConvertTo-Json) -ContentType "application/json" -OutputType PSObject
        $status = "Created"
    }
    else {
        $status = "WhatIf"
    }

    $roleStatus = ""
    if ($AssignRoles -and $g.Role -and $group) {
        $roleId = Get-RoleDefinitionId $g.Role
        if (-not $roleId) {
            $roleStatus = "Role '$($g.Role)' not found in tenant"
        }
        elseif (Get-Filtered "roleManagement/directory/roleAssignments" "principalId eq '$($group.id)' and roleDefinitionId eq '$roleId'") {
            $roleStatus = "Already assigned"
        }
        elseif ($PSCmdlet.ShouldProcess($displayName, "Assign role '$($g.Role)'")) {
            $assignBody = @{
                principalId      = $group.id
                roleDefinitionId = $roleId
                directoryScopeId = "/"
            } | ConvertTo-Json

            # A newly created group can take a few seconds to replicate; retry briefly.
            for ($i = 1; $i -le 5; $i++) {
                try {
                    Invoke-MgGraphRequest -Method POST -Uri "$graph/roleManagement/directory/roleAssignments" `
                        -Body $assignBody -ContentType "application/json" | Out-Null
                    $roleStatus = "Assigned"
                    break
                }
                catch {
                    if ($i -eq 5) { $roleStatus = "Failed: $($_.Exception.Message)" }
                    else { Start-Sleep -Seconds (5 * $i) }
                }
            }
        }
    }

    [pscustomobject]@{
        Group          = $displayName
        Status         = $status
        RoleAssignable = $roleAssignable
        Role           = $g.Role
        RoleStatus     = $roleStatus
        Id             = $group.id
    }
}

$results | Format-Table -AutoSize
$results | Export-Csv -Path ".\CopilotGroups-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
