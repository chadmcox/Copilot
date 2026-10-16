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

.EXAMPLE
    .\New-CopilotGroups.ps1 -WhatIf
    .\New-CopilotGroups.ps1
    .\New-CopilotGroups.ps1 -AssignRoles
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$AssignRoles
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
    @{ Name = "Copilot Access";                             Desc = "Baseline Microsoft 365 Copilot license/access." }
    @{ Name = "Copilot + Cowork Access";                    Desc = "Copilot Cowork access. Must be in exactly one Cowork spend group." }
    @{ Name = "Copilot + Opal Access";                      Desc = "Opal (Frontier). Target of Copilot > Settings > Opal (Frontier). Group owner must also be a member." }
    @{ Name = "Copilot + Code Access";                      Desc = "Copilot Code (Frontier). Members also need Frontier enrollment and a Code spending policy." }
    @{ Name = "Copilot + Autopilot Access";                 Desc = "Autopilot - confirm intended product (GitHub Copilot CLI autopilot is governed on GitHub, not M365)." }
    @{ Name = "Copilot Studio Access";                      Desc = "Copilot Studio makers." }
    @{ Name = "Copilot Frontier Access";                    Desc = "Target of Copilot > Settings > Copilot Frontier. Required for Code, Opal, Azure DevOps data." }
    @{ Name = "Copilot Pilot Ring";                         Desc = "Early-validation users for new Copilot settings." }

    # ---------- Spend (spending policies in Copilot > Cost Management) ----------
    @{ Name = "Copilot + Cowork Spend Limit";               Desc = "Spending policy selecting Cowork with a per-user limit. Mutually exclusive with Unlimited." }
    @{ Name = "Copilot + Cowork Spend Unlimited";           Desc = "Spending policy selecting Cowork with no per-user limit. Mutually exclusive with Limit." }
    @{ Name = "Copilot + Code Spend Limit";                 Desc = "Spending policy selecting Copilot Code with a per-user limit. Mutually exclusive with Unlimited." }
    @{ Name = "Copilot + Code Spend Unlimited";             Desc = "Spending policy selecting Copilot Code with no per-user limit. Mutually exclusive with Limit." }

    # ---------- Models ----------
    @{ Name = "Copilot Anthropic Models Access";            Desc = "Scope for AI providers > Anthropic. Required for Word/Excel/PowerPoint Agents." }
    @{ Name = "Copilot OpenAI Models Access";               Desc = "Scope for AI providers > OpenAI-operated models (if restricting)." }
    @{ Name = "Copilot Preview Models Access";              Desc = "Preview/experimental models, incl. models with provider data retention." }

    # ---------- Capability scoping ----------
    @{ Name = "Copilot + Cowork Browser Access";            Desc = "Scope for Cowork settings > Allow browser access (off by default)." }
    @{ Name = "Copilot Advanced Package Upload Access";     Desc = "Who can upload agent/plugin packages with actions or MCP servers." }
    @{ Name = "Copilot Agent Sharing Access";               Desc = "Who can share Agent Builder agents org-wide." }
    @{ Name = "Copilot + Code Secure Execution Exemption";  Desc = "Copilot Code policy exemption group - runs local projects outside the protected environment. Keep small." }
    @{ Name = "Copilot Teams Policy Exceptions";            Desc = "Users assigned a non-default Teams meeting/calling Copilot policy." }
    @{ Name = "Copilot Cloud Policy Exceptions";            Desc = "Users with non-default Cloud Policy (web search, Pages/Notebooks, code previews)." }

    # ---------- Delegated administration (role-assignable) ----------
    @{ Name = "Copilot Delegated Admin";                    Desc = "Copilot settings administration.";                  RoleAssignable = $true; Role = "AI Administrator" }
    @{ Name = "Copilot Agent Management Admin";             Desc = "Agents node / Agent 365 administration.";             RoleAssignable = $true; Role = "AI Administrator" }
    @{ Name = "Copilot AI Reader";                          Desc = "Read-only Copilot settings and agent inventory.";     RoleAssignable = $true; Role = "AI Reader" }
    @{ Name = "Copilot Billing Admin";                      Desc = "Copilot > Cost Management spending policies.";        RoleAssignable = $true; Role = "Billing Administrator" }
    @{ Name = "Copilot Cost Reader";                        Desc = "Read-only consumption reporting. Assign a supported reader role manually."; RoleAssignable = $true; Role = $null }
    @{ Name = "Copilot Agent ID Admin";                     Desc = "Entra Agent ID identities and blueprints.";           RoleAssignable = $true; Role = "Agent ID Administrator" }
    @{ Name = "Copilot Office Apps Admin";                  Desc = "Cloud Policy (config.office.com) Copilot settings.";  RoleAssignable = $true; Role = "Office Apps Administrator" }
    @{ Name = "Copilot Compliance Admin";                   Desc = "Purview DLP, audit, eDiscovery, DSPM for AI.";        RoleAssignable = $true; Role = "Compliance Administrator" }
    @{ Name = "Copilot Teams Admin";                        Desc = "Teams meeting/calling Copilot policies.";             RoleAssignable = $true; Role = "Teams Administrator" }
    @{ Name = "Copilot SharePoint Admin";                   Desc = "RCD/RAC, DAG reports, agent access insights.";        RoleAssignable = $true; Role = "SharePoint Administrator" }
    @{ Name = "Copilot Studio Environment Admin";           Desc = "PPAC data policies and Copilot Studio governance.";   RoleAssignable = $true; Role = "Power Platform Administrator" }
    @{ Name = "Copilot Plugin Approvers";                   Desc = "Reviewers for org-wide agent/plugin publish requests. No Entra role mapped."; RoleAssignable = $true; Role = $null }
)

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
