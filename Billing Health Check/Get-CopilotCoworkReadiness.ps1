<#
.SYNOPSIS
    Read-only. How many active Copilot users are set up to use Cowork, with billing in place?
    Shows a funnel from Copilot license to "can use Cowork now", and who drops out at each step.

.DESCRIPTION
    The funnel:
      1. Copilot license assigned       users with a license that includes the Copilot service plan
      2. Copilot turned on              the service plan isn't disabled and the assignment has no error
      3. Active in Copilot              any Copilot activity in the usage report for -Period
      4. Covered by a Cowork policy     in an enabled spending policy that selects Cowork
      5. Billing set                    that policy has a billing method (not "notSpecified")
      6. Can use Cowork now             Microsoft's own answer per person (only with -CheckBalances)

    Gaps reported:
      - Cowork users whose Copilot license is missing, turned off or in error (they can't use Cowork)
      - Cowork users whose policy has no billing method
      - Active Copilot users with no Cowork policy (candidates)
      - Cowork users with no Copilot activity in -Period
      - Licensed users with Copilot turned off or a license error

    If the usage report hides names (Microsoft 365 admin center > Settings > Org settings >
    Reports > "Display concealed user, group, and site names in all reports"), step 3 is a count
    only and can't be matched to people. The script tells you; it doesn't change the setting.

    Output in -OutputFolder: CoworkReadiness.csv (one row per person), CoworkGaps.csv and
    CoworkReadiness.html. They name people, so keep them private.

    Permissions (delegated): Organization.Read.All, User.Read.All, GroupMember.Read.All,
    Reports.Read.All, CopilotCostManagement.Read.All, CopilotCostManagement-Policy.Read.All,
    CopilotCostManagement-Assignment.Read.All, and CopilotCostManagement-UserData.Read.All
    with -CheckBalances.

.EXAMPLE
    .\Get-CopilotCoworkReadiness.ps1
    .\Get-CopilotCoworkReadiness.ps1 -Period D90 -CheckBalances
#>
[CmdletBinding()]
param(
    [ValidateSet("D7", "D28", "D90", "D180")]
    [string]$Period = "D28",
    [switch]$CheckBalances,
    [string]$OutputFolder = ".\CopilotCoworkReadiness-$(Get-Date -Format yyyyMMdd-HHmm)"
)

#Requires -Modules Microsoft.Graph.Authentication

Connect-MgGraph -NoWelcome -Scopes @(
    "Organization.Read.All", "User.Read.All", "GroupMember.Read.All", "Reports.Read.All",
    "CopilotCostManagement.Read.All", "CopilotCostManagement-Policy.Read.All", "CopilotCostManagement-Assignment.Read.All"
    if ($CheckBalances) { "CopilotCostManagement-UserData.Read.All" }
)

$graph = "https://graph.microsoft.com/beta"   # beta everywhere; it usually has more
$cm    = "$graph/copilot/costManagement"
$copilotServicePlan = "3f30311c-6b1e-48a4-ab79-725b469da960"   # M365_COPILOT_BUSINESS_CHAT
$eventual = @{ ConsistencyLevel = "eventual" }
$userSelect = "id,userPrincipalName,accountEnabled,assignedLicenses,licenseAssignmentStates"

# ---------------------------------------------------------------------------
# Graph helpers
# ---------------------------------------------------------------------------

function Get-GraphAll([string]$Uri, [hashtable]$Headers = @{}) {
    while ($Uri) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -Headers $Headers -OutputType PSObject
        $page.value
        $Uri = $page.'@odata.nextLink'
    }
}

function Get-GraphOptional([string]$Uri) {
    try { Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject } catch { $null }
}

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

function Get-CopilotSkuIds {
    Get-GraphAll "$graph/subscribedSkus?`$select=skuId,servicePlans" |
        Where-Object { $_.servicePlans.servicePlanId -contains $copilotServicePlan } |
        ForEach-Object skuId
}

# Everyone with a Copilot license assigned, once each.
function Get-LicensedUser([string[]]$SkuIds) {
    $SkuIds | ForEach-Object {
        $filter = [uri]::EscapeDataString("assignedLicenses/any(x:x/skuId eq $_)")
        Get-GraphAll "$graph/users?`$filter=$filter&`$select=$userSelect&`$count=true&`$top=999" $eventual
    } | Sort-Object id -Unique
}

# Working, Turned off (service plan disabled), Error (assignment failed) or None.
function Get-LicenseState($User, [string[]]$SkuIds) {
    $copilot = @($User.assignedLicenses | Where-Object { $_.skuId -in $SkuIds })
    if (-not $copilot) { return "None" }
    $states = @($User.licenseAssignmentStates | Where-Object { $_.skuId -in $SkuIds })
    if ($states -and -not ($states | Where-Object { $_.state -in "Active", "ActiveWithError" })) { return "Error" }
    if (-not ($copilot | Where-Object { $copilotServicePlan -notin $_.disabledPlans })) { return "Turned off" }
    "Working"
}

# Copilot activity per person from the usage report. Names may be hidden (hashed).
function Get-CopilotActivity {
    Get-GraphAll "$graph/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')" |
        Select-Object @{ n = "Upn"; e = { "$($_.userPrincipalName)".ToLower() } },
            @{ n = "LastActivity"; e = { $_.lastActivityDate } },
            @{ n = "Active"; e = { [bool]$_.lastActivityDate } }
}

# Enabled spending policies that select Cowork, with their groups and billing method.
function Get-CoworkPolicy {
    Get-GraphAll "$cm/spendingPolicies" | Where-Object status -eq "enabled" |
        Select-Object @{ n = "Id"; e = { $_.id } }, @{ n = "Name"; e = { $_.displayName } },
            @{ n = "AllUsers"; e = { "$($_.'@odata.type')" -notlike "*selectedGroups*" } },
            @{ n = "BillingSet"; e = { $_.billingMethods -and $_.billingMethods -ne "notSpecified" } },
            @{ n = "Billing"; e = { $_.billingMethods } },
            @{ n = "Cowork"; e = { [bool](Get-GraphAll "$cm/spendingPolicies/$($_.id)/serviceSettings" | Where-Object { $_.serviceId -eq "cowork" -and $_.state -eq "enabled" }) } },
            @{ n = "GroupIds"; e = { if ("$($_.'@odata.type')" -like "*selectedGroups*") { @(Get-GraphAll "$cm/spendingPolicies/$($_.id)/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups" | ForEach-Object id) } } } |
        Where-Object Cowork
}

# One row per person a Cowork policy covers: user id, policy name, billing set.
function Get-CoworkCoverage {
    process {
        $policy = $_
        $members = if ($policy.AllUsers) { Get-GraphAll "$graph/users?`$select=id&`$top=999" }
                   else { $policy.GroupIds | ForEach-Object { Get-GraphAll "$graph/groups/$_/transitiveMembers/microsoft.graph.user?`$select=id&`$top=999" } }
        $members | Select-Object @{ n = "UserId"; e = { $_.id } }, @{ n = "Policy"; e = { $policy.Name } }, @{ n = "BillingSet"; e = { $policy.BillingSet } }
    }
}

# Microsoft's answer to "can this person use Cowork right now?"
function Get-CoworkAccess([string]$UserId) {
    $row = Get-GraphOptional "$cm/userBalances/$UserId/serviceBalances/cowork"
    if ($row) { if ($row.isConsumptionAllowed) { "Yes" } else { "No ($($row.accessDecisionReason))" } } else { "Unknown" }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

$skuIds = @(Get-CopilotSkuIds)
if (-not $skuIds) { Write-Warning "No license in this tenant includes the Copilot service plan." }

$licensed = @(if ($skuIds) { Get-LicensedUser $skuIds })
Write-Host "Copilot licenses assigned: $($licensed.Count)"

$activity  = @(Get-CopilotActivity)
$concealed = [bool]($activity | Where-Object { $_.Upn -and $_.Upn -notlike "*@*" } | Select-Object -First 1)
$activeByUpn = $activity | Where-Object Active | Group-Object Upn -AsHashTable -AsString
if (-not $activeByUpn) { $activeByUpn = @{} }
if ($concealed) { Write-Warning "The usage report hides names, so active users are counted but not matched to people. To match them, turn off 'Display concealed user, group, and site names in all reports' in Microsoft 365 admin center > Settings > Org settings > Reports, then run this again." }

$policies = @(Get-CoworkPolicy)
$coverage = @($policies | Get-CoworkCoverage)
$coveredById = $coverage | Group-Object UserId -AsHashTable -AsString
if (-not $coveredById) { $coveredById = @{} }
Write-Host "Enabled Cowork spending policies: $($policies.Count); people covered: $($coveredById.Count)"

# Covered people who don't have a Copilot license still need a row.
$licensedIds = @($licensed.id)
$extra = @($coveredById.Keys | Where-Object { $_ -notin $licensedIds } | ForEach-Object { Get-GraphOptional "$graph/users/$_`?`$select=$userSelect" } | Where-Object { $_ })

$people = @(@($licensed; $extra) | Select-Object @{ n = "User"; e = { $_.userPrincipalName } },
    @{ n = "UserId"; e = { $_.id } },
    @{ n = "Enabled"; e = { $_.accountEnabled } },
    @{ n = "License"; e = { Get-LicenseState $_ $skuIds } },
    @{ n = "Active"; e = { if ($concealed) { "Unknown" } elseif ($activeByUpn.ContainsKey("$($_.userPrincipalName)".ToLower())) { "Yes" } else { "No" } } },
    @{ n = "LastActivity"; e = { if (-not $concealed) { ($activeByUpn["$($_.userPrincipalName)".ToLower()] | Select-Object -First 1).LastActivity } } },
    @{ n = "CoworkPolicy"; e = { ($coveredById[$_.id].Policy | Sort-Object -Unique) -join "; " } },
    @{ n = "BillingSet"; e = { if ($coveredById[$_.id]) { [bool]($coveredById[$_.id] | Where-Object BillingSet) } } } |
    Select-Object *, @{ n = "CanUseCowork"; e = { if ($CheckBalances -and $_.CoworkPolicy) { Get-CoworkAccess $_.UserId } } })

# ---------------------------------------------------------------------------
# Funnel and gaps
# ---------------------------------------------------------------------------

function Measure-Where([scriptblock]$Filter) { @($people | Where-Object $Filter).Count }

$working     = { $_.License -eq "Working" -and $_.Enabled }
$activeCount = if ($concealed) { @($activity | Where-Object Active).Count } else { Measure-Where { (& $working) -and $_.Active -eq "Yes" } }
$readyFilter = { (& $working) -and ($concealed -or $_.Active -eq "Yes") -and $_.CoworkPolicy -and $_.BillingSet }

$funnel = @(
    "Copilot license assigned"  | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { $licensed.Count } }, @{ n = "note"; e = { "License includes the Copilot service plan" } }
    "Copilot turned on"         | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { Measure-Where $working } }, @{ n = "note"; e = { "Plan enabled, no license error, account enabled" } }
    "Active in Copilot"         | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { $activeCount } }, @{ n = "note"; e = { if ($concealed) { "Count only: the usage report hides names" } else { "Any Copilot activity in $Period" } } }
    "Covered by a Cowork policy" | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { Measure-Where { (& $working) -and ($concealed -or $_.Active -eq "Yes") -and $_.CoworkPolicy } } }, @{ n = "note"; e = { "Enabled spending policy that selects Cowork" } }
    "Billing set"               | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { Measure-Where $readyFilter } }, @{ n = "note"; e = { "The policy has a billing method" } }
    if ($CheckBalances) { "Can use Cowork now" | Select-Object @{ n = "label"; e = { $_ } }, @{ n = "count"; e = { Measure-Where { (& $readyFilter) -and $_.CanUseCowork -eq "Yes" } } }, @{ n = "note"; e = { "Microsoft's answer per person" } } }
)

$licenseText = @{ None = "has no Copilot license"; "Turned off" = "has Copilot turned off in their license"; Error = "has a Copilot license assignment error" }

function New-Gap([string]$Stage, [string]$Severity, [string]$Check, [string]$Fix) {
    process {
        $_ | Select-Object @{ n = "subject"; e = { $Stage } }, @{ n = "area"; e = { if ($_.CoworkPolicy) { $_.CoworkPolicy } else { "No Cowork policy" } } },
            @{ n = "severity"; e = { $Severity } }, @{ n = "target"; e = { $_.User } }, @{ n = "check"; e = { $Check } }, @{ n = "fix"; e = { $Fix } }
    }
}

$gaps = @(
    $people | Where-Object { $_.CoworkPolicy -and $_.License -ne "Working" } | ForEach-Object { $_ | New-Gap "License" "High" "Covered for Cowork, but $($licenseText[$_.License])" "Assign a working Copilot license, or remove them from the Cowork group" }
    $people | Where-Object { $_.CoworkPolicy -and -not $_.Enabled } | New-Gap "License" "Medium" "Covered for Cowork, but the account is disabled" "Remove them from the Cowork group"
    $people | Where-Object { $_.CoworkPolicy -and -not $_.BillingSet } | New-Gap "Billing" "Medium" "Their Cowork policy has no billing method" "Set prepaid credits or pay-as-you-go on the policy"
    $people | Where-Object { -not $_.CoworkPolicy -and $_.License -in "Turned off", "Error" } | ForEach-Object { $_ | New-Gap "License" "Medium" "Licensed, but $($licenseText[$_.License])" "Turn on the Copilot service plan, or fix the license assignment" }
    if (-not $concealed) {
        $people | Where-Object { $_.CoworkPolicy -and $_.Active -eq "No" } | New-Gap "Activity" "Low" "Covered for Cowork, but no Copilot activity in $Period" "Check they need Cowork"
        $people | Where-Object { -not $_.CoworkPolicy -and (& $working) -and $_.Active -eq "Yes" } | New-Gap "Coverage" "Info" "Active Copilot user without Cowork" "Candidate for a Cowork spending policy"
    }
    # Only when everything else looks right but Microsoft still says no.
    $people | Where-Object $readyFilter | Where-Object { $_.CanUseCowork -like "No*" } | ForEach-Object { $_ | New-Gap "Access" "High" "Looks ready, but Microsoft says they can't use Cowork: $($_.CanUseCowork)" "Check their policy limits and license in Copilot > Cost management" }
)

# One card per Cowork policy: the share of its people who are ready.
$cards = @($policies | Select-Object @{ n = "name"; e = { $_.Name } },
    @{ n = "members"; e = { $name = $_.Name; @($people | Where-Object { $_.CoworkPolicy -split "; " -contains $name }) } } |
    Select-Object name, @{ n = "score"; e = { if ($_.members.Count) { [int][math]::Round(100 * @($_.members | Where-Object $readyFilter).Count / $_.members.Count) } else { 0 } } },
        @{ n = "detail"; e = { "$(@($_.members | Where-Object $readyFilter).Count) of $($_.members.Count) people ready" } },
        @{ n = "high"; e = { 0 } }, @{ n = "medium"; e = { 0 } }, @{ n = "low"; e = { 0 } }, @{ n = "info"; e = { 0 } } |
    Select-Object *, @{ n = "rating"; e = { if ($_.score -ge 80) { "Green" } elseif ($_.score -ge 50) { "Amber" } else { "Red" } } })

$readyCount = Measure-Where $readyFilter
$dialValue  = if ($activeCount) { [int][math]::Min(100, [math]::Round(100 * $readyCount / $activeCount)) } else { 0 }

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

function Get-ReportTemplate {
    $local = Join-Path $PSScriptRoot "Cowork/plugin/skills/copilot-billing-health/assets/report-template.html"
    if (Test-Path $local) { return Get-Content $local -Raw }
    try { (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chadmcox/Copilot/main/Billing%20Health%20Check/Cowork/plugin/skills/copilot-billing-health/assets/report-template.html" -UseBasicParsing).Content }
    catch { Write-Warning "Couldn't get the report template, so the HTML report is skipped." }
}

function New-HtmlReport([string]$Template, [string]$Path) {
    $balance = Get-GraphOptional "$cm/getTenantCreditBalance"
    $data = [ordered]@{
        title        = "Copilot Cowork Readiness"
        generated    = Get-Date -Format "yyyy-MM-dd HH:mm"
        source       = "PowerShell: Get-CopilotCoworkReadiness.ps1"
        subjectLabel = "Step"
        sample       = $false
        dial         = [ordered]@{ value = $dialValue; label = "of active users ready" }
        funnel       = $funnel
        scorecard    = $cards
        findings     = $gaps
        fixFirst     = @($gaps | Where-Object severity -in "High", "Medium" | Group-Object fix |
                          Sort-Object @{ e = { @("High", "Medium").IndexOf($_.Group[0].severity) } }, @{ e = { $_.Count }; Descending = $true } |
                          Select-Object -First 3 | ForEach-Object { "$($_.Name): $($_.Count) $(if ($_.Count -eq 1) { 'person' } else { 'people' }) ($(($_.Group.target | Select-Object -First 3) -join ', ')$(if ($_.Count -gt 3) { ', …' }))." })
        manualChecks = @("Cowork is discoverable for the people you want (Copilot > Settings > AI experiences enabled by usage-based billing).",
                         "Allow new Agents and services is off on every policy except the pilot one.")
        graphCalls   = @("GET /beta/subscribedSkus", "GET /beta/users?`$filter=assignedLicenses/any(x:x/skuId eq {sku})",
                         "GET /beta/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')",
                         "GET /beta/copilot/costManagement/spendingPolicies (+ serviceSettings, assignedGroups)",
                         "GET /beta/groups/{id}/transitiveMembers/microsoft.graph.user", "GET /beta/copilot/costManagement/getTenantCreditBalance",
                         "GET /beta/copilot/costManagement/userBalances/{id}/serviceBalances/cowork (with -CheckBalances)")
        notes        = @(
            "Ready means: working Copilot license, active in $Period, in an enabled Cowork spending policy that has a billing method."
            if ($concealed) { "The usage report hides names, so 'active' is a count only and the dial uses it as the base." }
            if (-not $policies) { "No enabled spending policy selects Cowork, so nobody can use Cowork yet." }
            $balance.billingMethodBalances | Where-Object { $_ } | ForEach-Object { "Tenant credits ($($_.billingMethod)): $($_.remainingQuantity) left of $($_.purchasedQuantity)." }
        )
    }
    $json = ($data | ConvertTo-Json -Depth 6).Replace("</", "<\/")
    $html = [regex]::Replace($Template, '(?s)(<script id="report-data" type="application/json">).*?(</script>)', { param($m) $m.Groups[1].Value + "`n" + $json + "`n" + $m.Groups[2].Value })
    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
}

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$people | Select-Object User, Enabled, License, Active, LastActivity, CoworkPolicy, BillingSet, CanUseCowork |
    Export-Csv (Join-Path $OutputFolder "CoworkReadiness.csv") -NoTypeInformation
$gaps | Export-Csv (Join-Path $OutputFolder "CoworkGaps.csv") -NoTypeInformation
$template = Get-ReportTemplate
if ($template) { New-HtmlReport $template (Join-Path ((Resolve-Path $OutputFolder).Path) "CoworkReadiness.html") }

$funnel | Format-Table @{ n = "Step"; e = { $_.label } }, @{ n = "People"; e = { $_.count } }, @{ n = "Note"; e = { $_.note } } -AutoSize
Write-Host "$dialValue% of active Copilot users are ready for Cowork. Saved CoworkReadiness.csv, CoworkGaps.csv and CoworkReadiness.html to $OutputFolder. They name people; keep them private."
