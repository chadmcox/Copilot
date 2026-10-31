<#
.SYNOPSIS
    Puts the Copilot admin groups under PIM for Groups (just-in-time membership) and creates
    an all-up "Copilot Platform Admin" group. Uses raw Microsoft Graph calls
    (Invoke-MgGraphRequest).

.DESCRIPTION
    Model (PIM for Groups):
      - Each admin group holds its Entra role(s) as an ACTIVE assignment.
      - People are made ELIGIBLE members of the group, not permanent members.
      - To use the role, a person activates group membership in PIM (My roles > Groups),
        with MFA + justification, optional approval, for a limited number of hours.

    For each admin group the script:
      1. Creates the group if missing (role-assignable security group).
      2. Ensures each mapped Entra role is actively assigned to the group.
      3. Configures the group's PIM "member" policy: max activation hours, MFA, justification,
         approval (where set), eligibility expiration, and limits on permanent active members.
      4. Optional -MembersCsv: adds people as eligible members (CSV columns: Group,UserPrincipalName).
      5. Optional -ConvertDirectMembers: turns current direct (permanent) user members into
         eligible members, then removes their permanent membership.

    Idempotent and supports -WhatIf.

    Requirements:
      - Microsoft Entra ID P2 or Entra ID Governance licensing.
      - Privileged Role Administrator or Global Administrator.
      - Run New-CopilotGroups.ps1 first (this script creates only Copilot Platform Admin).

.PARAMETER ApproverGroupName
    Group whose members approve activations for groups that require approval. Use a group
    outside these admin groups (e.g. your security team). PIM never lets requesters approve
    their own activation.

.PARAMETER PlatformApproverGroupName
    Approver group for the all-up Copilot Platform Admin group. Defaults to ApproverGroupName.

.EXAMPLE
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "Security Operations" -WhatIf
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "Security Operations" -MembersCsv .\copilot-admins.csv
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "Security Operations" -ConvertDirectMembers
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$ApproverGroupName,
    [string]$PlatformApproverGroupName,
    [string]$MembersCsv,
    [switch]$ConvertDirectMembers,
    [int]$EligibilityDays = 365,
    [int]$MaxActiveAssignmentDays = 15
)

#Requires -Modules Microsoft.Graph.Authentication

if (-not $PlatformApproverGroupName) { $PlatformApproverGroupName = $ApproverGroupName }

Connect-MgGraph -NoWelcome -Scopes @(
    "Group.ReadWrite.All",
    "User.Read.All",
    "RoleManagement.ReadWrite.Directory",
    "RoleManagementPolicy.ReadWrite.AzureADGroup",
    "PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup",
    "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup"
)

$graph = "https://graph.microsoft.com/v1.0"

# ---------------------------------------------------------------------------
# Admin groups: roles held by the group, activation length, approval
# ---------------------------------------------------------------------------
$adminGroups = @(
    @{ Name = "Copilot Platform Admin"; Hours = 4; Approval = $true; Approver = $PlatformApproverGroupName
       Desc = "All-up Copilot administration (JIT via PIM). Activation grants every role below."
       Roles = @(
           "AI Administrator", "Billing Administrator", "Agent ID Administrator",
           "Agent Registry Administrator",
           "Office Apps Administrator", "Compliance Administrator", "Teams Administrator",
           "SharePoint Administrator", "Power Platform Administrator",
           "Message Center Reader", "Service Support Administrator"
       ) }
    @{ Name = "Copilot Delegated Admin";          Hours = 8; Approval = $true;  Roles = @("AI Administrator") }
    @{ Name = "Copilot Agent Management Admin";   Hours = 8; Approval = $true;  Roles = @("AI Administrator") }
    @{ Name = "Copilot Agent Registry Admin";     Hours = 8; Approval = $true;  Roles = @("Agent Registry Administrator") }
    @{ Name = "Copilot AI Reader";                Hours = 8; Approval = $false; Roles = @("AI Reader") }
    @{ Name = "Copilot Billing Admin";            Hours = 4; Approval = $true;  Roles = @("Billing Administrator") }
    @{ Name = "Copilot Cost Reader";              Hours = 8; Approval = $false; Roles = @() }
    @{ Name = "Copilot Agent ID Admin";           Hours = 4; Approval = $true;  Roles = @("Agent ID Administrator") }
    @{ Name = "Copilot Agent ID Developers";      Hours = 8; Approval = $false; Roles = @("Agent ID Developer") }
    @{ Name = "Copilot Office Apps Admin";        Hours = 8; Approval = $false; Roles = @("Office Apps Administrator") }
    @{ Name = "Copilot Compliance Admin";         Hours = 4; Approval = $true;  Roles = @("Compliance Administrator") }
    @{ Name = "Copilot Teams Admin";              Hours = 8; Approval = $true;  Roles = @("Teams Administrator") }
    @{ Name = "Copilot SharePoint Admin";         Hours = 8; Approval = $true;  Roles = @("SharePoint Administrator") }
    @{ Name = "Copilot Studio Environment Admin"; Hours = 8; Approval = $true;  Roles = @("Power Platform Administrator") }
    @{ Name = "Copilot Plugin Approvers";         Hours = 8; Approval = $false; Roles = @() }
    # Read-only roles for the Copilot Billing and Agent and Tools health checks. No approval; MFA and a reason still apply.
    @{ Name = "Copilot Health Check Users";       Hours = 8; Approval = $false; Roles = @("AI Reader", "Security Reader", "Reports Reader")
       Desc = "People who run the Copilot Billing and Agent and Tools health checks (read-only). Scope of the health check Cowork plugins." }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Invoke-Graph([string]$Method, [string]$Uri, $Body) {
    $p = @{ Method = $Method; Uri = $Uri; OutputType = "PSObject" }
    if ($null -ne $Body) { $p.Body = ($Body | ConvertTo-Json -Depth 20); $p.ContentType = "application/json" }
    Invoke-MgGraphRequest @p
}
function Get-Filtered([string]$BaseUri, [string]$Filter) {
    (Invoke-Graph GET "$BaseUri`?`$filter=$([uri]::EscapeDataString($Filter))").value
}
function Esc([string]$s) { $s.Replace("'", "''") }

function Get-GroupByName([string]$Name) {
    Get-Filtered "$graph/groups" "displayName eq '$(Esc $Name)'" | Select-Object -First 1
}

$roleCache = @{}
function Get-RoleDefinitionId([string]$RoleName) {
    if (-not $roleCache.ContainsKey($RoleName)) {
        $def = Get-Filtered "$graph/roleManagement/directory/roleDefinitions" "displayName eq '$(Esc $RoleName)'" | Select-Object -First 1
        $roleCache[$RoleName] = $def.id
    }
    $roleCache[$RoleName]
}

function New-Target([string]$Caller, [string]$Level) {
    @{ caller = $Caller; operations = @("All"); level = $Level; inheritableSettings = @(); enforcedSettings = @() }
}

function Set-PolicyRule([string]$PolicyId, [hashtable]$Rule) {
    Invoke-Graph PATCH "$graph/policies/roleManagementPolicies/$PolicyId/rules/$($Rule.id)" $Rule | Out-Null
}

function Add-Eligibility([string]$GroupId, [string]$UserId, [string]$Label) {
    $existing = Get-Filtered "$graph/identityGovernance/privilegedAccess/group/eligibilitySchedules" `
        "groupId eq '$GroupId' and principalId eq '$UserId' and accessId eq 'member'"
    if ($existing) { return "Already eligible" }
    if (-not $PSCmdlet.ShouldProcess($Label, "Make eligible member")) { return "WhatIf" }

    Invoke-Graph POST "$graph/identityGovernance/privilegedAccess/group/eligibilityScheduleRequests" @{
        accessId      = "member"
        principalId   = $UserId
        groupId       = $GroupId
        action        = "adminAssign"
        justification = "Copilot admin access via PIM for Groups"
        scheduleInfo  = @{
            startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            expiration    = @{ type = "afterDuration"; duration = "P$($EligibilityDays)D" }
        }
    } | Out-Null
    "Eligible"
}

$csvRows = @()
if ($MembersCsv) { $csvRows = Import-Csv $MembersCsv }

$results = @()

foreach ($g in $adminGroups) {
    $approverName = if ($g.Approver) { $g.Approver } else { $ApproverGroupName }

    # 1. Group
    $group = Get-GroupByName $g.Name
    if (-not $group) {
        if ($g.Name -eq "Copilot Platform Admin" -and $PSCmdlet.ShouldProcess($g.Name, "Create role-assignable group")) {
            $group = Invoke-Graph POST "$graph/groups" @{
                displayName        = $g.Name
                description        = $g.Desc
                mailEnabled        = $false
                mailNickname       = "CopilotPlatformAdmin"
                securityEnabled    = $true
                isAssignableToRole = $true
            }
            Start-Sleep -Seconds 10   # allow replication before role assignment / PIM
        }
        else {
            Write-Warning "'$($g.Name)' not found. Run New-CopilotGroups.ps1 first."
            continue
        }
    }
    if ($g.Roles.Count -gt 0 -and -not $group.isAssignableToRole) {
        Write-Warning "'$($g.Name)' is not role-assignable; roles can't be assigned. Recreate it."
        continue
    }

    # 2. Active role assignments to the group
    foreach ($roleName in $g.Roles) {
        $roleId = Get-RoleDefinitionId $roleName
        if (-not $roleId) { Write-Warning "Role '$roleName' not found in tenant."; continue }
        $assigned = Get-Filtered "$graph/roleManagement/directory/roleAssignments" "principalId eq '$($group.id)' and roleDefinitionId eq '$roleId'"
        if (-not $assigned -and $PSCmdlet.ShouldProcess($g.Name, "Assign role '$roleName'")) {
            Invoke-Graph POST "$graph/roleManagement/directory/roleAssignments" @{
                principalId = $group.id; roleDefinitionId = $roleId; directoryScopeId = "/"
            } | Out-Null
        }
    }

    # 3. PIM for Groups policy (member)
    $policyStatus = ""
    $assignment = Get-Filtered "$graph/policies/roleManagementPolicyAssignments" `
        "scopeId eq '$($group.id)' and scopeType eq 'Group' and roleDefinitionId eq 'member'" | Select-Object -First 1

    if (-not $assignment) {
        $policyStatus = "No PIM policy found - open the group in PIM > Groups once, then re-run"
    }
    elseif ($PSCmdlet.ShouldProcess($g.Name, "Configure PIM member policy ($($g.Hours)h, approval=$($g.Approval))")) {
        $policyId = $assignment.policyId
        $approverGroup = Get-GroupByName $approverName
        if ($g.Approval -and -not $approverGroup) { throw "Approver group '$approverName' not found." }

        $approvers = if ($g.Approval) {
            @(@{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = $approverGroup.id; description = $approverName })
        } else { @() }

        Set-PolicyRule $policyId @{
            "@odata.type"        = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
            id                   = "Expiration_EndUser_Assignment"
            isExpirationRequired = $true
            maximumDuration      = "PT$($g.Hours)H"
            target               = (New-Target "EndUser" "Assignment")
        }
        Set-PolicyRule $policyId @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
            id            = "Enablement_EndUser_Assignment"
            enabledRules  = @("MultiFactorAuthentication", "Justification")
            target        = (New-Target "EndUser" "Assignment")
        }
        Set-PolicyRule $policyId @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
            id            = "Approval_EndUser_Assignment"
            target        = (New-Target "EndUser" "Assignment")
            setting       = @{
                isApprovalRequired               = [bool]$g.Approval
                isApprovalRequiredForExtension   = $false
                isRequestorJustificationRequired = $true
                approvalMode                     = "SingleStage"
                approvalStages                   = @(@{
                    approvalStageTimeOutInDays      = 1
                    isApproverJustificationRequired = $true
                    escalationTimeInMinutes         = 0
                    isEscalationEnabled             = $false
                    primaryApprovers                = $approvers
                    escalationApprovers             = @()
                })
            }
        }
        Set-PolicyRule $policyId @{
            "@odata.type"        = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
            id                   = "Expiration_Admin_Eligibility"
            isExpirationRequired = $true
            maximumDuration      = "P$($EligibilityDays)D"
            target               = (New-Target "Admin" "Eligibility")
        }
        Set-PolicyRule $policyId @{
            "@odata.type"        = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
            id                   = "Expiration_Admin_Assignment"
            isExpirationRequired = $true
            maximumDuration      = "P$($MaxActiveAssignmentDays)D"
            target               = (New-Target "Admin" "Assignment")
        }
        Set-PolicyRule $policyId @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
            id            = "Enablement_Admin_Assignment"
            enabledRules  = @("Justification", "MultiFactorAuthentication")
            target        = (New-Target "Admin" "Assignment")
        }
        $policyStatus = "Configured"
    }

    # 4. Eligible members from CSV
    $added = 0
    foreach ($row in $csvRows | Where-Object { $_.Group -eq $g.Name }) {
        try {
            $user = Invoke-Graph GET "$graph/users/$([uri]::EscapeDataString($row.UserPrincipalName))?`$select=id"
            if ((Add-Eligibility $group.id $user.id "$($row.UserPrincipalName) -> $($g.Name)") -eq "Eligible") { $added++ }
        }
        catch { Write-Warning "Could not add $($row.UserPrincipalName) to $($g.Name): $($_.Exception.Message)" }
    }

    # 5. Convert direct members to eligible
    $converted = 0
    if ($ConvertDirectMembers) {
        $members = (Invoke-Graph GET "$graph/groups/$($group.id)/members/microsoft.graph.user?`$select=id,userPrincipalName").value
        foreach ($m in $members) {
            $label = "$($m.userPrincipalName) in $($g.Name)"
            $r = Add-Eligibility $group.id $m.id $label
            if ($r -in @("Eligible", "Already eligible") -and $PSCmdlet.ShouldProcess($label, "Remove permanent membership")) {
                Invoke-Graph DELETE "$graph/groups/$($group.id)/members/$($m.id)/`$ref" | Out-Null
                $converted++
            }
        }
    }

    $results += [pscustomobject]@{
        Group           = $g.Name
        Roles           = ($g.Roles -join "; ")
        ActivationHours = $g.Hours
        Approval        = $g.Approval
        Policy          = $policyStatus
        EligibleAdded   = $added
        Converted       = $converted
    }
}

$results | Format-Table -AutoSize
$results | Export-Csv -Path ".\CopilotAdminPim-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
