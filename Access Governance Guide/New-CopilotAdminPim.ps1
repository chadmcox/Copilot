<#PSScriptInfo
.VERSION 2026.11
.GUID 637a6ced-4709-440e-a0aa-73c29f66b44f
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
Checks the Copilot admin groups' Entra roles and PIM for Groups settings, and fixes what is missing or wrong.
url: Privileged Identity Management (PIM) for Groups - https://learn.microsoft.com/entra/id-governance/privileged-identity-management/concept-pim-for-groups
#>

<#
.SYNOPSIS
    The one script for the Copilot admin roles and PIM. Run it any time: it checks each admin
    group in the table below and fixes its roles and PIM settings. Graph only (Invoke-MgGraphRequest).

.DESCRIPTION
    Model (PIM for Groups):
      - Each admin group holds its Entra role(s) as an ACTIVE assignment.
      - People are ELIGIBLE members of the group, not permanent members.
      - To use the role, a person activates group membership in PIM (My roles > Groups),
        with MFA and a reason, approval where set, for a limited number of hours.

    For every group in $adminGroups:
      1. Checks the group exists and is role-assignable. It doesn't create groups:
         run New-CopilotGroups.ps1 first.
      2. Assigns any of its roles that are missing. Reports roles the group holds that aren't
         in the table (it never removes a role).
      3. Sets the group's PIM member policy: activation hours, MFA, reason, approval,
         eligibility expiry and the limit on permanent active members. Skip with -SkipPimPolicy.
      4. Optional -MembersCsv: makes people eligible members (CSV columns: Group,UserPrincipalName).
      5. Optional -ConvertDirectMembers: turns permanent user members into eligible members.

    HOW TO CHANGE THE DESIGN
      - New admin group: add it to $groups in New-CopilotGroups.ps1 (RoleAssignable = $true),
        then add a line here with its roles, hours and approval.
      - Role or setting change: change the line here. The next run fixes the tenant.

    Requirements:
      - Microsoft Entra ID P2 or Entra ID Governance for PIM (not needed with -SkipPimPolicy
        and no -MembersCsv or -ConvertDirectMembers).
      - Least-privileged role: Privileged Role Administrator.

.PARAMETER ApproverGroupName
    Group whose members approve activations for groups that require approval. Use a group outside
    these admin groups (for example your security team). Required unless -SkipPimPolicy.

.PARAMETER PlatformApproverGroupName
    Approver group for Copilot Platform Admin. Defaults to ApproverGroupName.

.PARAMETER SkipPimPolicy
    Only checks the groups and their roles. Use it when you don't have PIM licensing; the
    roles are then permanent for every member of the group.

.PARAMETER Environment
    The Microsoft cloud to sign in to: Global (also GCC), USGov (GCC High) or USGovDoD.
    Leave it out and the script asks.

.EXAMPLE
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>" -WhatIf
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>"
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>" -MembersCsv .\copilot-admins.csv
    .\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>" -ConvertDirectMembers
    .\New-CopilotAdminPim.ps1 -SkipPimPolicy
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ApproverGroupName,
    [string]$PlatformApproverGroupName,
    [string]$MembersCsv,
    [switch]$ConvertDirectMembers,
    [switch]$SkipPimPolicy,
    [int]$EligibilityDays = 365,
    [int]$MaxActiveAssignmentDays = 15,
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

if (-not $SkipPimPolicy -and -not $ApproverGroupName) {
    throw "Pass -ApproverGroupName (the group that approves activations), or -SkipPimPolicy to check only the roles."
}
if (-not $PlatformApproverGroupName) { $PlatformApproverGroupName = $ApproverGroupName }

# ---------------------------------------------------------------------------
# The design. Change this table, not the code below.
#   Roles    = Entra roles the group holds (active)
#   Hours    = longest PIM activation
#   Approval = activation needs approval from the approver group
# The groups themselves come from New-CopilotGroups.ps1.
# ---------------------------------------------------------------------------
$adminGroups = @(
    @{ Name = "Copilot Platform Admin"; Hours = 4; Approval = $true; Approver = $PlatformApproverGroupName
       Roles = @(
           "AI Administrator", "Billing Administrator", "Agent ID Administrator",
           "Agent Registry Administrator",
           "Office Apps Administrator", "Compliance Administrator", "Teams Administrator",
           "SharePoint Administrator", "Power Platform Administrator",
           "Message Center Reader", "Service Support Administrator"
       ) }
    @{ Name = "Copilot Delegated Admin";            Hours = 8; Approval = $true;  Roles = @("AI Administrator") }
    @{ Name = "Copilot Agent Management Admin";     Hours = 8; Approval = $true;  Roles = @("AI Administrator") }
    @{ Name = "Copilot Agent Registry Admin";       Hours = 8; Approval = $true;  Roles = @("Agent Registry Administrator") }
    @{ Name = "Copilot AI Reader";                  Hours = 8; Approval = $false; Roles = @("AI Reader") }
    @{ Name = "Copilot Billing Admin";              Hours = 4; Approval = $true;  Roles = @("Billing Administrator") }
    @{ Name = "Copilot Cost Reader";                Hours = 8; Approval = $false; Roles = @() }
    @{ Name = "Copilot Agent ID Admin";             Hours = 4; Approval = $true;  Roles = @("Agent ID Administrator") }
    @{ Name = "Copilot Agent ID Developers";        Hours = 8; Approval = $false; Roles = @("Agent ID Developer") }
    @{ Name = "Copilot Office Apps Admin";          Hours = 8; Approval = $false; Roles = @("Office Apps Administrator") }
    @{ Name = "Copilot Compliance Admin";           Hours = 4; Approval = $true;  Roles = @("Compliance Administrator") }
    @{ Name = "Copilot Teams Admin";                Hours = 8; Approval = $true;  Roles = @("Teams Administrator") }
    @{ Name = "Copilot SharePoint Admin";           Hours = 8; Approval = $true;  Roles = @("SharePoint Administrator") }
    @{ Name = "Copilot Studio Environment Admin";   Hours = 8; Approval = $true;  Roles = @("Power Platform Administrator") }
    @{ Name = "Copilot Plugin Approvers";           Hours = 8; Approval = $false; Roles = @() }
    # Approval on: Microsoft recommends approval for groups used to activate Entra roles, and AI Reader is privileged.
    @{ Name = "Copilot Health Check Users";         Hours = 8; Approval = $true;  Roles = @("AI Reader", "Security Reader", "Reports Reader") }
    # Approval on: Global Reader reads the whole tenant and Microsoft labels it a privileged role.
    @{ Name = "Copilot Entra ID Operations Reader"; Hours = 8; Approval = $true;  Roles = @("Global Reader") }
)

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

function Invoke-Graph([string]$Method, [string]$Uri, $Body) {
    $p = @{ Method = $Method; Uri = $Uri; OutputType = "PSObject" }
    if ($null -ne $Body) { $p.Body = ($Body | ConvertTo-Json -Depth 20); $p.ContentType = "application/json" }
    Invoke-MgGraphRequest @p
}

function Get-AllPages([string]$Uri) {
    while ($Uri) {
        $page = Invoke-Graph GET $Uri
        $page.value
        $Uri = $page.'@odata.nextLink'
    }
}

function Get-Filtered([string]$Path, [string]$Filter) {
    @(Get-AllPages "$graph/$Path`?`$filter=$([uri]::EscapeDataString($Filter))" | Where-Object { $_ })
}

function Get-GroupByName([string]$Name) {
    $esc = $Name.Replace("'", "''")
    Get-Filtered "groups" "displayName eq '$esc'"
}

$roleCache = @{}
function Get-RoleDefinitionId([string]$RoleName) {
    if (-not $roleCache.ContainsKey($RoleName)) {
        $esc = $RoleName.Replace("'", "''")
        $roleCache[$RoleName] = (Get-Filtered "roleManagement/directory/roleDefinitions" "displayName eq '$esc'" | Select-Object -First 1).id
    }
    $roleCache[$RoleName]
}

function New-Target([string]$Caller, [string]$Level) {
    @{ caller = $Caller; operations = @("All"); level = $Level; inheritableSettings = @(); enforcedSettings = @() }
}

function Set-GroupRoles($Def, $Group) {
    # Assigns missing roles and reports extra ones. Returns one line of text.
    $wantedIds = @{}
    $lines = @(foreach ($roleName in $Def.Roles) {
        $roleId = Get-RoleDefinitionId $roleName
        if (-not $roleId) { "$($roleName): not in tenant"; continue }
        $wantedIds[$roleId] = $roleName
        if (Get-Filtered "roleManagement/directory/roleAssignments" "principalId eq '$($Group.id)' and roleDefinitionId eq '$roleId'") { continue }
        if ($PSCmdlet.ShouldProcess($Def.Name, "Assign role '$roleName'")) {
            try {
                Invoke-Graph POST "$graph/roleManagement/directory/roleAssignments" @{
                    principalId = $Group.id; roleDefinitionId = $roleId; directoryScopeId = "/"
                } | Out-Null
                "$($roleName): assigned"
            }
            catch { "$($roleName): assign failed: $($_.Exception.Message)" }
        }
        else { "$($roleName): WhatIf assign" }
    })
    # Roles on the group that aren't in the table. Reported only; nothing is removed.
    $extra = Get-Filtered "roleManagement/directory/roleAssignments" "principalId eq '$($Group.id)'" |
        Where-Object { -not $wantedIds.ContainsKey($_.roleDefinitionId) } |
        ForEach-Object { (Invoke-Graph GET "$graph/roleManagement/directory/roleDefinitions/$($_.roleDefinitionId)?`$select=displayName").displayName }
    $lines = @($lines; $extra | ForEach-Object { "$($_): extra, not in the design (not removed)" })
    if ($lines.Count -eq 0) { "OK" } else { $lines -join "; " }
}

function Set-GroupPimPolicy($Def, $Group) {
    # Sets the PIM for Groups member policy. Returns one line of text.
    $assignment = Get-Filtered "policies/roleManagementPolicyAssignments" `
        "scopeId eq '$($Group.id)' and scopeType eq 'Group' and roleDefinitionId eq 'member'" | Select-Object -First 1
    if (-not $assignment) { return "No PIM policy yet: open the group in PIM > Groups once, then run again" }
    if (-not $PSCmdlet.ShouldProcess($Def.Name, "Set PIM member policy ($($Def.Hours)h, approval=$($Def.Approval))")) { return "WhatIf" }

    $approverName = if ($Def.Approver) { $Def.Approver } else { $ApproverGroupName }
    $approvers = if ($Def.Approval) {
        $approverGroup = Get-GroupByName $approverName | Select-Object -First 1
        if (-not $approverGroup) { return "Failed: approver group '$approverName' not found" }
        @(@{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = $approverGroup.id; description = $approverName })
    } else { @() }

    $rules = @(
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"; id = "Expiration_EndUser_Assignment"
           isExpirationRequired = $true; maximumDuration = "PT$($Def.Hours)H"; target = (New-Target "EndUser" "Assignment") }
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"; id = "Enablement_EndUser_Assignment"
           enabledRules = @("MultiFactorAuthentication", "Justification"); target = (New-Target "EndUser" "Assignment") }
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"; id = "Approval_EndUser_Assignment"
           target = (New-Target "EndUser" "Assignment")
           setting = @{
               isApprovalRequired = [bool]$Def.Approval; isApprovalRequiredForExtension = $false
               isRequestorJustificationRequired = $true; approvalMode = "SingleStage"
               approvalStages = @(@{
                   approvalStageTimeOutInDays = 1; isApproverJustificationRequired = $true
                   escalationTimeInMinutes = 0; isEscalationEnabled = $false
                   primaryApprovers = $approvers; escalationApprovers = @()
               })
           } }
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"; id = "Expiration_Admin_Eligibility"
           isExpirationRequired = $true; maximumDuration = "P$($EligibilityDays)D"; target = (New-Target "Admin" "Eligibility") }
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"; id = "Expiration_Admin_Assignment"
           isExpirationRequired = $true; maximumDuration = "P$($MaxActiveAssignmentDays)D"; target = (New-Target "Admin" "Assignment") }
        @{ "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"; id = "Enablement_Admin_Assignment"
           enabledRules = @("Justification", "MultiFactorAuthentication"); target = (New-Target "Admin" "Assignment") }
    )
    try {
        $rules | ForEach-Object { Invoke-Graph PATCH "$graph/policies/roleManagementPolicies/$($assignment.policyId)/rules/$($_.id)" $_ | Out-Null }
        "Set"
    }
    catch { "Failed: $($_.Exception.Message)" }
}

function Add-Eligibility([string]$GroupId, [string]$UserId, [string]$Label) {
    if (Get-Filtered "identityGovernance/privilegedAccess/group/eligibilitySchedules" `
            "groupId eq '$GroupId' and principalId eq '$UserId' and accessId eq 'member'") { return "Already eligible" }
    if (-not $PSCmdlet.ShouldProcess($Label, "Make eligible member")) { return "WhatIf" }
    Invoke-Graph POST "$graph/identityGovernance/privilegedAccess/group/eligibilityScheduleRequests" @{
        accessId = "member"; principalId = $UserId; groupId = $GroupId; action = "adminAssign"
        justification = "Copilot admin access via PIM for Groups"
        scheduleInfo = @{
            startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            expiration    = @{ type = "afterDuration"; duration = "P$($EligibilityDays)D" }
        }
    } | Out-Null
    "Eligible"
}

function Set-CopilotAdminGroup {
    # Checks one admin group: exists, role-assignable, roles, PIM policy, eligible members.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][hashtable]$Def)
    process {
        $found = Get-GroupByName $Def.Name
        $group = $found | Select-Object -First 1
        $check = if ($found.Count -eq 0) { "Missing: run New-CopilotGroups.ps1" }
            elseif ($found.Count -gt 1) { "Skipped: $($found.Count) groups share this name" }
            elseif ($Def.Roles.Count -gt 0 -and -not $group.isAssignableToRole) { "Not role-assignable: delete and recreate it with New-CopilotGroups.ps1" }
            else { "OK" }

        $roles = $policy = $members = ""
        if ($check -eq "OK") {
            $roles = Set-GroupRoles $Def $group
            $policy = if ($SkipPimPolicy) { "Skipped" } else { Set-GroupPimPolicy $Def $group }

            $members = @(
                $csvRows | Where-Object { $_.Group -eq $Def.Name } | ForEach-Object {
                    $upn = $_.UserPrincipalName
                    try {
                        $user = Invoke-Graph GET "$graph/users/$([uri]::EscapeDataString($upn))?`$select=id"
                        "$($upn): $(Add-Eligibility $group.id $user.id "$upn -> $($Def.Name)")"
                    }
                    catch { "$($upn): failed: $($_.Exception.Message)" }
                }
                if ($ConvertDirectMembers) {
                    Get-AllPages "$graph/groups/$($group.id)/members/microsoft.graph.user?`$select=id,userPrincipalName" | Where-Object { $_ } | ForEach-Object {
                        $label = "$($_.userPrincipalName) in $($Def.Name)"
                        $r = Add-Eligibility $group.id $_.id $label
                        if (($r -in @("Eligible", "Already eligible")) -and $PSCmdlet.ShouldProcess($label, "Remove permanent membership")) {
                            Invoke-Graph DELETE "$graph/groups/$($group.id)/members/$($_.id)/`$ref" | Out-Null
                            "$($_.userPrincipalName): converted to eligible"
                        }
                        else { "$($_.userPrincipalName): $r" }
                    }
                }
            ) -join "; "
        }

        $Def | Select-Object @{ n = "Group"; e = { $Def.Name } },
            @{ n = "Check"; e = { $check } },
            @{ n = "Roles"; e = { $roles } },
            @{ n = "ActivationHours"; e = { $Def.Hours } },
            @{ n = "Approval"; e = { $Def.Approval } },
            @{ n = "PimPolicy"; e = { $policy } },
            @{ n = "Members"; e = { $members } }
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
$scopes = @(
    "Group.Read.All"
    "RoleManagement.ReadWrite.Directory"
    if (-not $SkipPimPolicy) { "RoleManagementPolicy.ReadWrite.AzureADGroup" }
    if ($MembersCsv -or $ConvertDirectMembers) { "PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup" }
    if ($MembersCsv) { "User.ReadBasic.All" }
    if ($ConvertDirectMembers) { "GroupMember.ReadWrite.All" }
)
$graph = "$(Connect-Cloud -Environment $Environment -Scopes $scopes)/beta"
$csvRows = @(if ($MembersCsv) { Import-Csv $MembersCsv })

$results = @($adminGroups | Set-CopilotAdminGroup)
$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotAdminPim-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
