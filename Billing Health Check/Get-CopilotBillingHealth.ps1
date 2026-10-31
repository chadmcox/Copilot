<#
.SYNOPSIS
    Read-only health check for Microsoft 365 Copilot spending policies, the groups they use and
    the people in those groups. Proof of concept.

.DESCRIPTION
    Uses only Connect-MgGraph and Invoke-MgGraphRequest (module Microsoft.Graph.Authentication).
    Changes nothing.

    PREVIEW: the Copilot cost management API is on the Graph /beta endpoint and needs a
    signed-in admin (app-only isn't supported).

    It checks:
      - Policies: all-users scope, status, limits, billing method, alerts, alert recipients.
      - Groups: missing, empty, Microsoft 365 group, dynamic, nested, owners, description.
      - Members: disabled, guest, inactive, no Copilot license, near or at their limit.
      - Across policies: people in both Cowork Limited and Cowork Unlimited, and Temp members
        who aren't in Limited.
      - Cowork readiness: how many active Copilot users are set up to use Cowork with billing.
        Funnel: Copilot license assigned > Copilot turned on > active in Copilot (-Period) >
        covered by an enabled Cowork policy > billing set > can use Cowork now (unless
        -SkipBalances). Also lists active Copilot users without Cowork, Cowork users with no
        Copilot activity, and licenses with Copilot turned off or in error.

    If the Copilot usage report hides names (admin center > Settings > Org settings > Reports),
    "active" is a count only. The script tells you; it doesn't change the setting.

    Output (in -OutputFolder): Findings.csv, Scorecard.csv, Readiness.csv, Policies.csv and
    Report.html.
    The files show each person's spending. Keep them private and out of source control.

    Policies.csv is also the file you attach in Copilot Cowork. The Enterprise MCP server
    can't read spending policies, so Cowork reads them from this file and reads groups,
    members, licenses and sign-ins live. Report.html includes the Cowork prompt.
    Use -PoliciesOnly to write just Policies.csv (quick, no group or member checks).

    Permissions (delegated): CopilotCostManagement-Policy.Read.All,
    CopilotCostManagement-Assignment.Read.All, CopilotCostManagement-UserData.Read.All,
    Reports.Read.All (Copilot usage), CopilotCostManagement.Read.All (tenant credits),
    Group.Read.All, GroupMember.Read.All, User.Read.All, AuditLog.Read.All (sign-in dates,
    needs Entra ID P1), Organization.Read.All (license names).

.EXAMPLE
    .\Get-CopilotBillingHealth.ps1
    .\Get-CopilotBillingHealth.ps1 -SkipBalances -InactiveDays 60
    .\Get-CopilotBillingHealth.ps1 -PoliciesOnly
#>
[CmdletBinding()]
param(
    [int]$MinPerUserLimit  = 2000,
    [int]$InactiveDays     = 90,
    [int]$NearLimitPercent = 80,
    [switch]$SkipBalances,
    [switch]$PoliciesOnly,
    [ValidateSet("D7", "D28", "D90", "D180")]
    [string]$Period = "D28",
    [string]$OutputFolder  = ".\CopilotBillingHealth-$(Get-Date -Format yyyyMMdd-HHmm)",

    # Policy names used for the Cowork tier checks (from the Copilot Group Assignment Guide).
    [string]$LimitedPolicy   = "Cowork Limited",
    [string]$UnlimitedPolicy = "Cowork Unlimited",
    [string]$TempPolicy      = "Cowork Temporary Unlimited",

    # Services that only work for people with a Copilot license.
    [string[]]$LicensedServices = @("cowork", "code"),

    # A license counts as Copilot when it includes one of these service plans.
    # 3f30311c-... is M365_COPILOT_BUSINESS_CHAT ("Microsoft Copilot with Graph-grounded chat"),
    # which is in every Microsoft 365 Copilot SKU.
    [string[]]$CopilotServicePlanIds = @("3f30311c-6b1e-48a4-ab79-725b469da960"),
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

Connect-MgGraph -Environment $Environment -NoWelcome -Scopes @(
    "CopilotCostManagement-Policy.Read.All",
    "CopilotCostManagement-Assignment.Read.All",
    "CopilotCostManagement-UserData.Read.All",
    "CopilotCostManagement.Read.All",
    "Reports.Read.All",
    "Group.Read.All",
    "GroupMember.Read.All",
    "User.Read.All",
    "AuditLog.Read.All",
    "Organization.Read.All"
)

$cm = "$graphEndpoint/beta/copilot/costManagement"
$graph = "$graphEndpoint/beta"   # beta everywhere; it usually has more

$userCache = @{}
$groupCache = @{}

# ---------------------------------------------------------------------------
# Graph helpers
# ---------------------------------------------------------------------------

# GET every page of a collection and send each item down the pipeline.
function Get-GraphAll([string]$Uri) {
    while ($Uri) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        $page.value
        $Uri = $page.'@odata.nextLink'
    }
}

# GET one object. Returns $null when it doesn't exist (for example, a policy with no alert).
function Get-GraphOptional([string]$Uri) {
    try { Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject }
    catch { $null }
}

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

function Get-CopilotSkuIds {
    Get-GraphAll "$graph/subscribedSkus?`$select=skuId,servicePlans" |
        Where-Object { $_.servicePlans.servicePlanId | Where-Object { $_ -in $CopilotServicePlanIds } } |
        ForEach-Object skuId
}

# Takes spending policies from the pipeline and adds their services, groups and alert settings.
function Get-Policy {
    process {
        $_ | Select-Object @{ n = "Id"; e = { $_.id } },
            @{ n = "Name";        e = { $_.displayName } },
            @{ n = "Status";      e = { $_.status } },
            @{ n = "AllUsers";    e = { "$($_.'@odata.type')" -notlike "*selectedGroups*" } },
            @{ n = "PeriodLimit"; e = { $_.periodLimit } },
            @{ n = "PerUser";     e = { $_.perUserLimit } },
            @{ n = "Billing";     e = { $_.billingMethods } },
            @{ n = "Services";    e = { Get-GraphAll "$cm/spendingPolicies/$($_.id)/serviceSettings" | Where-Object state -eq "enabled" | ForEach-Object serviceId } },
            @{ n = "GroupIds";    e = { if ("$($_.'@odata.type')" -like "*selectedGroups*") { Get-GraphAll "$cm/spendingPolicies/$($_.id)/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups" | ForEach-Object id } } },
            @{ n = "AlertOn";     e = { [bool](Get-GraphOptional "$cm/spendingPolicies/$($_.id)/emailThresholdSettings").isEnabled } },
            @{ n = "Recipients";  e = { try { Get-GraphAll "$cm/spendingPolicies/$($_.id)/emailThresholdSettings/recipients" | ForEach-Object id } catch { } } }
    }
}

function Get-Group([string]$Id) {
    if (-not $groupCache.ContainsKey($Id)) {
        $groupCache[$Id] = Get-GraphOptional "$graph/groups/$Id`?`$select=id,displayName,description,groupTypes,securityEnabled" |
            Select-Object @{ n = "Id"; e = { $_.id } },
                @{ n = "Name";        e = { $_.displayName } },
                @{ n = "Description"; e = { $_.description } },
                @{ n = "Unified";     e = { $_.groupTypes -contains "Unified" } },
                @{ n = "Dynamic";     e = { $_.groupTypes -contains "DynamicMembership" } },
                @{ n = "Security";    e = { $_.securityEnabled } },
                @{ n = "Owners";      e = { Get-GraphAll "$graph/groups/$($_.id)/owners?`$select=id" | ForEach-Object id } },
                @{ n = "Nested";      e = { Get-GraphAll "$graph/groups/$($_.id)/members/microsoft.graph.group?`$select=displayName" | ForEach-Object displayName } },
                @{ n = "MemberIds";   e = { Get-GraphAll "$graph/groups/$($_.id)/transitiveMembers/microsoft.graph.user?`$select=id" | ForEach-Object id } }
    }
    $groupCache[$Id]
}

# signInActivity needs AuditLog.Read.All and Entra ID P1. If that read fails, read the user
# without it, so the other checks still run (the inactive check is then skipped).
function Get-User([string]$Id) {
    if (-not $userCache.ContainsKey($Id)) {
        $select = "id,userPrincipalName,accountEnabled,userType,assignedLicenses,licenseAssignmentStates"
        $user = Get-GraphOptional "$graph/users/$Id`?`$select=$select,signInActivity"
        if (-not $user) { $user = Get-GraphOptional "$graph/users/$Id`?`$select=$select" }
        $userCache[$Id] = $user
    }
    $userCache[$Id]
}

# A person's UPN, or their ID when the account is gone.
function Get-UserName([string]$Id) {
    $user = Get-User $Id
    if ($user) { $user.userPrincipalName } else { $Id }
}

function Get-GroupName([string]$Id) {
    if ($groupCache[$Id]) { return $groupCache[$Id].Name }
    $g = Get-GraphOptional "$graph/groups/$Id`?`$select=displayName"
    if ($g) { $g.displayName } else { "(deleted group)" }
}

function Format-Quantity($Quantity) {
    if (-not $Quantity) { "" }
    elseif (Test-Unlimited $Quantity) { "Unlimited" }
    else { "$($Quantity.value)" }
}

# One row per policy, from the pipeline. This is the file to attach in Copilot Cowork.
function Select-PolicyRow {
    process {
        $_ | Select-Object @{ n = "Policy"; e = { $_.Name } }, Status,
            @{ n = "Scope";           e = { if ($_.AllUsers) { "All users" } else { "Groups" } } },
            @{ n = "Groups";          e = { ($_.GroupIds | ForEach-Object { Get-GroupName $_ }) -join "; " } },
            @{ n = "GroupIds";        e = { $_.GroupIds -join "; " } },
            @{ n = "Services";        e = { $_.Services -join "; " } },
            @{ n = "PerUserLimit";    e = { Format-Quantity $_.PerUser } },
            @{ n = "MonthlyLimit";    e = { Format-Quantity $_.PeriodLimit } },
            Billing, AlertOn,
            @{ n = "AlertRecipients"; e = { ($_.Recipients | ForEach-Object { Get-UserName $_ }) -join "; " } }
    }
}

function Get-Balance([string]$UserId, [string]$PolicyId) {
    Get-GraphAll "$cm/userBalances/$UserId/serviceBalances" | Where-Object spendingPolicyId -eq $PolicyId
}

# ---------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------

# The target (a policy, group or person) goes down the pipeline and picks up the finding details.
function New-Finding([string]$Policy, [string]$Area, [string]$Severity, [string]$Target, [string]$Check, [string]$Fix) {
    $Target | Select-Object @{ n = "Policy"; e = { $Policy } },
        @{ n = "Area";     e = { $Area } },
        @{ n = "Severity"; e = { $Severity } },
        @{ n = "Target";   e = { $_ } },
        @{ n = "Check";    e = { $Check } },
        @{ n = "Fix";      e = { $Fix } }
}

function Test-Unlimited($Quantity) { "$($Quantity.'@odata.type')" -like "*unlimited*" }

function Test-Policy($P) {
    if ($P.AllUsers) { New-Finding $P.Name "Policy" "High" $P.Name "Covers all users" "Limit it to a security group" }
    if ($P.Status -ne "enabled") { New-Finding $P.Name "Policy" "High" $P.Name "Status is $($P.Status)" "Link a group, or recreate the policy" }
    if (-not $P.AllUsers -and $P.GroupIds.Count -eq 0) { New-Finding $P.Name "Policy" "High" $P.Name "No group linked" "Link the policy's group" }
    if ((Test-Unlimited $P.PerUser) -and (Test-Unlimited $P.PeriodLimit)) { New-Finding $P.Name "Policy" "High" $P.Name "No per-user limit and no monthly limit" "Set a monthly limit" }
    if (-not (Test-Unlimited $P.PerUser) -and [double]$P.PerUser.value -lt $MinPerUserLimit) { New-Finding $P.Name "Policy" "Medium" $P.Name "Per-user limit $($P.PerUser.value) is under $MinPerUserLimit" "Raise it to at least $MinPerUserLimit credits" }
    if ($P.Billing -eq "notSpecified") { New-Finding $P.Name "Policy" "Medium" $P.Name "Billing method not set" "Pick prepaid credits or pay-as-you-go" }
    if (-not $P.AlertOn) { New-Finding $P.Name "Policy" "Medium" $P.Name "No email alert" "Turn on an alert at 80% with two owners as recipients" }
    if ($P.AlertOn -and $P.Recipients.Count -lt 2) { New-Finding $P.Name "Policy" "Low" $P.Name "Only $($P.Recipients.Count) alert recipient" "Add a second recipient" }
    $P.Recipients | Where-Object { $user = Get-User $_; -not $user -or -not $user.accountEnabled } |
        ForEach-Object { New-Finding $P.Name "Policy" "Medium" (Get-UserName $_) "Alert recipient is disabled or gone" "Replace the recipient" }
}

function Test-Group($P, $G) {
    if (-not $G) { return New-Finding $P.Name "Group" "High" "(deleted group)" "Linked group no longer exists" "Link the right group" }
    if ($G.Unified -or -not $G.Security) { New-Finding $P.Name "Group" "Medium" $G.Name "Not a security group" "Use a security group" }
    if ($G.Nested.Count -gt 0) { New-Finding $P.Name "Group" "Medium" $G.Name "Has nested groups: $($G.Nested -join ', ')" "Add people directly; nested membership isn't documented for spending policies" }
    if ($G.Owners.Count -lt 2) { New-Finding $P.Name "Group" "Medium" $G.Name "Has $($G.Owners.Count) owner(s)" "Add owners so there are at least two" }
    if ($G.MemberIds.Count -eq 0) { New-Finding $P.Name "Group" "Low" $G.Name "Group is empty" "Retire the policy, or fill the group" }
    if ($G.Dynamic) { New-Finding $P.Name "Group" "Info" $G.Name "Dynamic group" "Fine for broad audiences; spend tiers should use access packages instead" }
    if (-not $G.Description) { New-Finding $P.Name "Group" "Low" $G.Name "No description" "Describe the group and name its policy" }
}

# Working, Turned off (service plan disabled), Error (assignment failed) or None.
function Get-LicenseState($User, [string[]]$SkuIds) {
    $copilot = @($User.assignedLicenses | Where-Object { $_.skuId -in $SkuIds })
    if (-not $copilot) { return "None" }
    $states = @($User.licenseAssignmentStates | Where-Object { $_.skuId -in $SkuIds })
    if ($states -and -not ($states | Where-Object { $_.state -in "Active", "ActiveWithError" })) { return "Error" }
    if (-not ($copilot | Where-Object { $disabled = $_.disabledPlans; $CopilotServicePlanIds | Where-Object { $_ -notin $disabled } })) { return "Turned off" }
    "Working"
}

function Test-Member($P, $G, $User, [string[]]$CopilotSkus) {
    $upn = $User.userPrincipalName
    $lastSignIn = $User.signInActivity.lastSuccessfulSignInDateTime
    $needsLicense = [bool]($P.Services | Where-Object { $_ -in $LicensedServices })

    if (-not $User.accountEnabled) { New-Finding $P.Name "Member" "Medium" $upn "Account is disabled" "Remove them from $($G.Name)" }
    if ($User.userType -eq "Guest") { New-Finding $P.Name "Member" "Medium" $upn "Guest account" "Remove them, unless guests should spend credits" }
    if ($User.signInActivity -and (-not $lastSignIn -or [datetime]$lastSignIn -lt (Get-Date).AddDays(-$InactiveDays))) {
        New-Finding $P.Name "Member" "Medium" $upn "No sign-in for $InactiveDays days" "Remove them from $($G.Name)"
    }
    $license = Get-LicenseState $User $CopilotSkus
    if ($needsLicense -and $license -ne "Working") {
        $why = @{ None = "No Copilot license"; "Turned off" = "Copilot is turned off in their license"; Error = "Their Copilot license assignment has an error" }[$license]
        New-Finding $P.Name "Member" "Medium" $upn "$why, but $($P.Services -join ', ') needs one" "Assign a working Copilot license, or remove them"
    }

    if ($SkipBalances) { return }
    Get-Balance $User.id $P.Id | ForEach-Object {
        if ($_.accessDecisionReason -eq "limitExhausted") {
            New-Finding $P.Name "Usage" "Info" $upn "Hit the limit for $($_.serviceId)" "Candidate for the Temp or Unlimited tier"
        }
        elseif (-not (Test-Unlimited $_.configuredPerUserLimit) -and [double]$_.configuredPerUserLimit.value -gt 0 -and
                ([double]$_.consumedQuantity / [double]$_.configuredPerUserLimit.value * 100) -ge $NearLimitPercent) {
            New-Finding $P.Name "Usage" "Info" $upn "Used $NearLimitPercent% or more of $($_.serviceId) this month" "Watch, or move to a higher tier"
        }
        elseif ([double]$_.consumedQuantity -eq 0) {
            New-Finding $P.Name "Usage" "Info" $upn "No $($_.serviceId) usage this month" "Candidate to remove if it stays at zero"
        }
    }
}

function Test-CoworkTiers($Policies) {
    $members = { param($Name) $Policies | Where-Object Name -eq $Name | ForEach-Object { $_.GroupIds } | ForEach-Object { (Get-Group $_).MemberIds } }
    $limited   = @(& $members $LimitedPolicy)
    $unlimited = @(& $members $UnlimitedPolicy)
    $temp      = @(& $members $TempPolicy)

    $limited | Where-Object { $_ -in $unlimited } | ForEach-Object {
        New-Finding $UnlimitedPolicy "Member" "High" (Get-UserName $_) "In both $LimitedPolicy and $UnlimitedPolicy" "Remove one; the higher limit always wins"
    }
    $temp | Where-Object { $_ -notin $limited } | ForEach-Object {
        New-Finding $TempPolicy "Member" "Medium" (Get-UserName $_) "In $TempPolicy but not in $LimitedPolicy" "Check how they were added; Temp is only for Limited members"
    }
}

# Takes policies from the pipeline and scores each one from its findings.
function Get-Score($Findings) {
    begin {
        $weights = @{ High = 25; Medium = 10; Low = 3; Info = 0 }
        $byPolicy = $Findings | Group-Object Policy -AsHashTable -AsString
        if (-not $byPolicy) { $byPolicy = @{} }
    }
    process {
        $_ | Select-Object @{ n = "Policy"; e = { $_.Name } },
            @{ n = "Score";  e = { [math]::Max(0, 100 - ($byPolicy[$_.Name] | ForEach-Object { $weights[$_.Severity] } | Measure-Object -Sum).Sum) } },
            @{ n = "High";   e = { @($byPolicy[$_.Name] | Where-Object Severity -eq "High").Count } },
            @{ n = "Medium"; e = { @($byPolicy[$_.Name] | Where-Object Severity -eq "Medium").Count } },
            @{ n = "Low";    e = { @($byPolicy[$_.Name] | Where-Object Severity -eq "Low").Count } },
            @{ n = "Info";   e = { @($byPolicy[$_.Name] | Where-Object Severity -eq "Info").Count } } |
        Select-Object Policy, Score,
            @{ n = "Rating"; e = { if ($_.Score -ge 80) { "Green" } elseif ($_.Score -ge 50) { "Amber" } else { "Red" } } },
            High, Medium, Low, Info
    }
}


# ---------------------------------------------------------------------------
# Cowork readiness: how many active Copilot users are set up for Cowork and billing
# ---------------------------------------------------------------------------

# Everyone with a Copilot license assigned, once each.
function Get-LicensedUser([string[]]$SkuIds) {
    $SkuIds | ForEach-Object {
        $filter = [uri]::EscapeDataString("assignedLicenses/any(x:x/skuId eq $_)")
        $page = "$graph/users?`$filter=$filter&`$select=id,userPrincipalName,accountEnabled,assignedLicenses,licenseAssignmentStates&`$count=true&`$top=999"
        while ($page) {
            $result = Invoke-MgGraphRequest -Method GET -Uri $page -Headers @{ ConsistencyLevel = "eventual" } -OutputType PSObject
            $result.value
            $page = $result.'@odata.nextLink'
        }
    } | Sort-Object id -Unique
}

# Copilot activity per person. Names may be hidden (hashed) by the tenant's report setting.
function Get-CopilotActivity {
    Get-GraphAll "$graph/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')" |
        Select-Object @{ n = "Upn"; e = { "$($_.userPrincipalName)".ToLower() } }, @{ n = "LastActivity"; e = { $_.lastActivityDate } }
}

# One row per person a Cowork policy covers. An all-users policy covers every licensed person.
function Get-CoworkCoverage([string[]]$LicensedIds) {
    process {
        $policy = $_
        $ids = if ($policy.AllUsers) { $LicensedIds } else { $policy.GroupIds | ForEach-Object { (Get-Group $_).MemberIds } }
        $ids | Select-Object @{ n = "UserId"; e = { $_ } }, @{ n = "Policy"; e = { $policy.Name } },
            @{ n = "BillingSet"; e = { $policy.Billing -and $policy.Billing -ne "notSpecified" } }
    }
}

function Get-CoworkAccess([string]$UserId) {
    $row = Get-GraphOptional "$cm/userBalances/$UserId/serviceBalances/cowork"
    if ($row) { if ($row.isConsumptionAllowed) { "Yes" } else { "No ($($row.accessDecisionReason))" } } else { "Unknown" }
}

function New-ReadinessFinding([string]$Policy, [string]$Severity, [string]$Check, [string]$Fix) {
    process { New-Finding $Policy "Readiness" $Severity $_.User $Check $Fix }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

$policies = @(Get-GraphAll "$cm/spendingPolicies" | Get-Policy)

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$policies | Select-PolicyRow | Export-Csv (Join-Path $OutputFolder "Policies.csv") -NoTypeInformation
if ($PoliciesOnly) {
    Write-Host "Saved Policies.csv to $OutputFolder. Attach it in Copilot Cowork with the prompt in the Cowork folder of this repo."
    return
}

$copilotSkus = @(Get-CopilotSkuIds)

$findings = @(
    $policies | ForEach-Object {
        $p = $_
        Test-Policy $p
        $p.GroupIds | ForEach-Object {
            $g = Get-Group $_
            Test-Group $p $g
            $g.MemberIds | ForEach-Object { Get-User $_ } | Where-Object { $_ } | ForEach-Object { Test-Member $p $g $_ $copilotSkus }
        }
    }
    Test-CoworkTiers $policies
)

# Cowork readiness. Reuses the groups and members already read above.
$licensed    = @(if ($copilotSkus) { Get-LicensedUser $copilotSkus })
$activity    = @(Get-CopilotActivity)
$concealed   = [bool]($activity | Where-Object { $_.Upn -and $_.Upn -notlike "*@*" } | Select-Object -First 1)
$activeByUpn = $activity | Where-Object LastActivity | Group-Object Upn -AsHashTable -AsString
if (-not $activeByUpn) { $activeByUpn = @{} }
if ($concealed) { Write-Warning "The Copilot usage report hides names, so active users are counted but not matched to people. Turn off 'Display concealed user, group, and site names in all reports' in Microsoft 365 admin center > Settings > Org settings > Reports to match them." }

$coworkPolicies = @($policies | Where-Object { $_.Status -eq "enabled" -and $_.Services -contains "cowork" })
$coveredById = $coworkPolicies | Get-CoworkCoverage @($licensed.id) | Group-Object UserId -AsHashTable -AsString
if (-not $coveredById) { $coveredById = @{} }
$licensedIds = @($licensed.id)

$people = @(@($licensed; $coveredById.Keys | Where-Object { $_ -notin $licensedIds } | ForEach-Object { Get-User $_ } | Where-Object { $_ }) |
    Select-Object @{ n = "User"; e = { $_.userPrincipalName } }, @{ n = "UserId"; e = { $_.id } },
        @{ n = "Enabled"; e = { $_.accountEnabled } },
        @{ n = "License"; e = { Get-LicenseState $_ $copilotSkus } },
        @{ n = "Active"; e = { if ($concealed) { "Unknown" } elseif ($activeByUpn.ContainsKey("$($_.userPrincipalName)".ToLower())) { "Yes" } else { "No" } } },
        @{ n = "LastActivity"; e = { if (-not $concealed) { ($activeByUpn["$($_.userPrincipalName)".ToLower()] | Select-Object -First 1).LastActivity } } },
        @{ n = "CoworkPolicy"; e = { ($coveredById[$_.id].Policy | Sort-Object -Unique) -join "; " } },
        @{ n = "BillingSet"; e = { if ($coveredById[$_.id]) { [bool]($coveredById[$_.id] | Where-Object BillingSet) } } })

$working     = { $_.License -eq "Working" -and $_.Enabled }
$isActive    = { $concealed -or $_.Active -eq "Yes" }
$readyFilter = { (& $working) -and (& $isActive) -and $_.CoworkPolicy -and $_.BillingSet }
$people = @($people | Select-Object *, @{ n = "CanUseCowork"; e = { if (-not $SkipBalances -and (& $readyFilter)) { Get-CoworkAccess $_.UserId } } })

function Measure-People([scriptblock]$Filter) { @($people | Where-Object $Filter).Count }
$activeCount = if ($concealed) { @($activity | Where-Object LastActivity).Count } else { Measure-People { (& $working) -and $_.Active -eq "Yes" } }
$readyCount  = Measure-People $readyFilter
$readyPercent = if ($activeCount) { [int][math]::Min(100, [math]::Round(100 * $readyCount / $activeCount)) } else { 0 }

function New-FunnelStep([string]$Label, [int]$Count, [string]$Note) {
    $Label | Select-Object @{ n = "label"; e = { $Label } }, @{ n = "count"; e = { $Count } }, @{ n = "note"; e = { $Note } }
}

$funnel = @(
    New-FunnelStep "Copilot license assigned" $licensed.Count "License includes the Copilot service plan"
    New-FunnelStep "Copilot turned on" (Measure-People $working) "Plan enabled, no license error, account enabled"
    New-FunnelStep "Active in Copilot" $activeCount $(if ($concealed) { "Count only: the usage report hides names" } else { "Any Copilot activity in $Period" })
    New-FunnelStep "Covered by a Cowork policy" (Measure-People { (& $working) -and (& $isActive) -and $_.CoworkPolicy }) "Enabled spending policy that selects Cowork"
    New-FunnelStep "Billing set" $readyCount "That policy has a billing method"
    if (-not $SkipBalances) { New-FunnelStep "Can use Cowork now" (Measure-People { (& $readyFilter) -and $_.CanUseCowork -eq "Yes" }) "Microsoft's answer per person" }
)

# Readiness findings that the policy, group and member checks don't already cover.
$findings = @(
    $findings
    $people | Where-Object { -not $_.CoworkPolicy -and $_.License -in "Turned off", "Error" } | ForEach-Object {
        $_ | New-ReadinessFinding "(Copilot licenses)" "Medium" $(if ($_.License -eq "Error") { "Copilot license assignment has an error" } else { "Copilot is turned off in their license" }) "Turn on the Copilot service plan, or fix the license assignment"
    }
    $people | Where-Object $readyFilter | Where-Object { $_.CanUseCowork -like "No*" } | ForEach-Object {
        $_ | New-ReadinessFinding (($_.CoworkPolicy -split "; ")[0]) "High" "Looks ready, but Microsoft says they can't use Cowork: $($_.CanUseCowork)" "Check their policy limits and license in Copilot > Cost management"
    }
    if (-not $concealed) {
        $people | Where-Object { $_.CoworkPolicy -and $_.Active -eq "No" } | ForEach-Object {
            $_ | New-ReadinessFinding (($_.CoworkPolicy -split "; ")[0]) "Info" "Covered for Cowork, but no Copilot activity in $Period" "Check they need Cowork"
        }
        $people | Where-Object { -not $_.CoworkPolicy -and (& $working) -and $_.Active -eq "Yes" } |
            New-ReadinessFinding "(no Cowork policy)" "Info" "Active Copilot user without Cowork" "Candidate for a Cowork spending policy"
    }
)

$scorecard = @($policies | Get-Score $findings | Sort-Object Score)

$findings  | Sort-Object @{ e = { @("High", "Medium", "Low", "Info").IndexOf($_.Severity) } }, Policy |
    Export-Csv (Join-Path $OutputFolder "Findings.csv") -NoTypeInformation
$scorecard | Export-Csv (Join-Path $OutputFolder "Scorecard.csv") -NoTypeInformation
$people | Select-Object User, Enabled, License, Active, LastActivity, CoworkPolicy, BillingSet, CanUseCowork |
    Export-Csv (Join-Path $OutputFolder "Readiness.csv") -NoTypeInformation

# The same check in Copilot Cowork, so people can rerun it and follow up without PowerShell.
$coworkPrompt = @"
Run the Copilot billing health check.

Use the attached Policies.csv for the spending policies. Use the Microsoft MCP Server for Enterprise to read, for every group in that file: the group type, owners, description, nested groups, and every member (including members of nested groups). For each member, read whether the account is enabled, the user type, the last successful sign-in, and their licenses. Use subscribedSkus to find which licenses include the Copilot service plan 3f30311c-6b1e-48a4-ab79-725b469da960.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the copilot-billing-health rules and give me:
1. A scorecard: one row per policy with a score out of 100 (High -25, Medium -10, Low -3) and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the person or group, what's wrong, and the fix.
3. The top 3 fixes to do first.
4. The Cowork readiness funnel: Copilot license assigned, Copilot turned on, active in Copilot in the last 28 days, covered by a Cowork policy, billing set, and the % of active Copilot users who are ready.
5. The Microsoft Graph calls you ran.
6. The HTML report from the skill's report template, named Copilot Billing Health.html.
"@

# The report template ships with the Cowork skill. Use the local copy, or download it from GitHub.
function Get-ReportTemplate {
    $local = Join-Path $PSScriptRoot "Cowork/plugin/skills/copilot-billing-health/assets/report-template.html"
    if (Test-Path $local) { return Get-Content $local -Raw }
    try { (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chadmcox/Copilot/main/Billing%20Health%20Check/Cowork/plugin/skills/copilot-billing-health/assets/report-template.html" -UseBasicParsing).Content }
    catch { Write-Warning "Couldn't get the report template, so Report.html is skipped. The CSV files are still saved." }
}

# Puts this run's data into the template's report-data block.
function New-HtmlReport([string]$Template, [string]$Path) {
    $data = [ordered]@{
        title        = "Copilot Billing Health"
        generated    = Get-Date -Format "yyyy-MM-dd HH:mm"
        source       = "PowerShell: Get-CopilotBillingHealth.ps1"
        subjectLabel = "Policy"
        sample       = $false
        funnelTitle  = "Cowork readiness: $readyPercent% of active Copilot users are ready"
        funnel       = $funnel
        scorecard    = @($scorecard | Select-Object @{ n = "name"; e = { $_.Policy } },
                          @{ n = "score"; e = { $_.Score } }, @{ n = "rating"; e = { $_.Rating } },
                          @{ n = "high"; e = { $_.High } }, @{ n = "medium"; e = { $_.Medium } },
                          @{ n = "low"; e = { $_.Low } }, @{ n = "info"; e = { $_.Info } },
                          @{ n = "detail"; e = { $name = $_.Policy; "Groups: " + ((($policies | Where-Object Name -eq $name).GroupIds | ForEach-Object { Get-GroupName $_ }) -join ", ") } })
        findings     = @($findings | Select-Object @{ n = "subject"; e = { $_.Policy } },
                          @{ n = "area"; e = { $_.Area } }, @{ n = "severity"; e = { $_.Severity } },
                          @{ n = "target"; e = { $_.Target } }, @{ n = "check"; e = { $_.Check } }, @{ n = "fix"; e = { $_.Fix } })
        fixFirst     = @($findings | Where-Object Severity -in "High", "Medium" | Group-Object Fix |
                          Sort-Object @{ e = { @("High", "Medium").IndexOf($_.Group[0].Severity) } }, @{ e = { $_.Count }; Descending = $true } |
                          Select-Object -First 3 | ForEach-Object { "$($_.Name): $($_.Count) $(if ($_.Count -eq 1) { 'item' } else { 'items' }) ($(($_.Group.Target | Select-Object -First 3) -join ', ')$(if ($_.Count -gt 3) { ', …' }))." })
        manualChecks = @(
                          "Allow new Agents and services is off on every policy except the pilot one."
                          "Each Cowork policy has the right model profile."
                          "Credit request policies point at your access packages.")
        graphCalls   = @(
                          "GET /beta/copilot/costManagement/spendingPolicies (+ serviceSettings, assignedGroups, emailThresholdSettings)"
                          "GET /beta/subscribedSkus?`$select=skuId,servicePlans"
                          "GET /beta/groups/{id} (+ owners, members/microsoft.graph.group, transitiveMembers/microsoft.graph.user)"
                          "GET /beta/users/{id}?`$select=accountEnabled,userType,assignedLicenses,licenseAssignmentStates,signInActivity"
                          "GET /beta/copilot/costManagement/userBalances/{id}/serviceBalances"
                          "GET /beta/users?`$filter=assignedLicenses/any(x:x/skuId eq {sku}) (ConsistencyLevel: eventual)"
                          "GET /beta/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')"
                          "GET /beta/copilot/costManagement/getTenantCreditBalance")
        notes        = @(
                          "Scores start at 100: High -25, Medium -10, Low -3. Readiness findings outside a policy don't change any score."
                          "Ready for Cowork means: working Copilot license, active in $Period, in an enabled Cowork spending policy that has a billing method."
                          if ($concealed) { "The Copilot usage report hides names, so 'Active in Copilot' is a count only." }
                          if (-not $coworkPolicies) { "No enabled spending policy selects Cowork, so nobody can use Cowork yet." }
                          (Get-GraphOptional "$cm/getTenantCreditBalance").billingMethodBalances | Where-Object { $_ } | ForEach-Object { "Tenant credits ($($_.billingMethod)): $($_.remainingQuantity) left of $($_.purchasedQuantity)." })
        prompt       = $coworkPrompt
    }
    # "</" inside the JSON would end the script block early, so escape it.
    $json = ($data | ConvertTo-Json -Depth 6).Replace("</", "<\/")
    $html = [regex]::Replace($Template, '(?s)(<script id="report-data" type="application/json">).*?(</script>)', { param($m) $m.Groups[1].Value + "`n" + $json + "`n" + $m.Groups[2].Value })
    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
}

$template = Get-ReportTemplate
if ($template) { New-HtmlReport $template (Join-Path ((Resolve-Path $OutputFolder).Path) "Report.html") }

$scorecard | Format-Table -AutoSize
$funnel | Format-Table @{ n = "Cowork readiness"; e = { $_.label } }, @{ n = "People"; e = { $_.count } } -AutoSize
Write-Host "$readyPercent% of active Copilot users are ready for Cowork."
Write-Host "Saved Findings.csv, Scorecard.csv, Readiness.csv, Policies.csv and Report.html to $OutputFolder. Keep these files private."
