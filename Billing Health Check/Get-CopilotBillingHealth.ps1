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

    Output (in -OutputFolder): Findings.csv, Scorecard.csv, Policies.csv and Report.html.
    The files show each person's spending. Keep them private and out of source control.

    Policies.csv is also the file you attach in Copilot Cowork. The Enterprise MCP server
    can't read spending policies, so Cowork reads them from this file and reads groups,
    members, licenses and sign-ins live. Report.html includes the Cowork prompt.
    Use -PoliciesOnly to write just Policies.csv (quick, no group or member checks).

    Permissions (delegated): CopilotCostManagement-Policy.Read.All,
    CopilotCostManagement-Assignment.Read.All, CopilotCostManagement-UserData.Read.All,
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
    [string[]]$CopilotServicePlanIds = @("3f30311c-6b1e-48a4-ab79-725b469da960")
)

#Requires -Modules Microsoft.Graph.Authentication

Connect-MgGraph -NoWelcome -Scopes @(
    "CopilotCostManagement-Policy.Read.All",
    "CopilotCostManagement-Assignment.Read.All",
    "CopilotCostManagement-UserData.Read.All",
    "Group.Read.All",
    "GroupMember.Read.All",
    "User.Read.All",
    "AuditLog.Read.All",
    "Organization.Read.All"
)

$cm = "https://graph.microsoft.com/beta/copilot/costManagement"
$graph = "https://graph.microsoft.com/beta"   # beta everywhere; it usually has more

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

$scorecard = @($policies | Get-Score $findings | Sort-Object Score)

$findings  | Sort-Object @{ e = { @("High", "Medium", "Low", "Info").IndexOf($_.Severity) } }, Policy |
    Export-Csv (Join-Path $OutputFolder "Findings.csv") -NoTypeInformation
$scorecard | Export-Csv (Join-Path $OutputFolder "Scorecard.csv") -NoTypeInformation

# The same check in Copilot Cowork, so people can rerun it and follow up without PowerShell.
$coworkPrompt = @"
Run the Copilot billing health check.

Use the attached Policies.csv for the spending policies. Use the Microsoft MCP Server for Enterprise to read, for every group in that file: the group type, owners, description, nested groups, and every member (including members of nested groups). For each member, read whether the account is enabled, the user type, the last successful sign-in, and their licenses. Use subscribedSkus to find which licenses include the Copilot service plan 3f30311c-6b1e-48a4-ab79-725b469da960.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the copilot-billing-health rules and give me:
1. A scorecard: one row per policy with a score out of 100 (High -25, Medium -10, Low -3) and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the person or group, what's wrong, and the fix.
3. The top 3 fixes to do first.
4. The Microsoft Graph calls you ran.
5. The HTML report from the skill's report template, named Copilot Billing Health.html.
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
        scorecard    = @($scorecard | Select-Object @{ n = "name"; e = { $_.Policy } },
                          @{ n = "score"; e = { $_.Score } }, @{ n = "rating"; e = { $_.Rating } },
                          @{ n = "high"; e = { $_.High } }, @{ n = "medium"; e = { $_.Medium } },
                          @{ n = "low"; e = { $_.Low } }, @{ n = "info"; e = { $_.Info } },
                          @{ n = "detail"; e = { $name = $_.Policy; "Groups: " + ((($policies | Where-Object Name -eq $name).GroupIds | ForEach-Object { Get-GroupName $_ }) -join ", ") } })
        findings     = @($findings | Select-Object @{ n = "subject"; e = { $_.Policy } },
                          @{ n = "area"; e = { $_.Area } }, @{ n = "severity"; e = { $_.Severity } },
                          @{ n = "target"; e = { $_.Target } }, @{ n = "check"; e = { $_.Check } }, @{ n = "fix"; e = { $_.Fix } })
        fixFirst     = @($findings | Where-Object Severity -in "High", "Medium" |
                          Sort-Object @{ e = { @("High", "Medium").IndexOf($_.Severity) } } |
                          Select-Object -First 3 | ForEach-Object { "$($_.Fix): $($_.Target) ($($_.Policy))." })
        manualChecks = @(
                          "Allow new Agents and services is off on every policy except the pilot one."
                          "Each Cowork policy has the right model profile."
                          "Credit request policies point at your access packages.")
        graphCalls   = @(
                          "GET /beta/copilot/costManagement/spendingPolicies (+ serviceSettings, assignedGroups, emailThresholdSettings)"
                          "GET /beta/subscribedSkus?`$select=skuId,servicePlans"
                          "GET /beta/groups/{id} (+ owners, members/microsoft.graph.group, transitiveMembers/microsoft.graph.user)"
                          "GET /beta/users/{id}?`$select=accountEnabled,userType,assignedLicenses,licenseAssignmentStates,signInActivity"
                          "GET /beta/copilot/costManagement/userBalances/{id}/serviceBalances")
        notes        = @("Scores start at 100: High -25, Medium -10, Low -3.")
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
Write-Host "Saved Findings.csv, Scorecard.csv, Policies.csv and Report.html to $OutputFolder. Keep these files private."
