<#
.SYNOPSIS
    Read-only report of Copilot Credits spending policies, using the Microsoft Graph cost
    management API (beta, MC1521616). Changes nothing. Graph only (Invoke-MgGraphRequest).

.DESCRIPTION
    PREVIEW. These APIs live on the Microsoft Graph /beta endpoint. Microsoft can change them
    and does not support them for production use.

    Default report:
      - Tenant credit balance, one row per billing method.
      - Every spending policy: status, period and per-user limits, billing method, services
        turned on, groups, and email alert settings.
      - Problems worth a look: policies that aren't enabled, policies with no group, all-users
        policies, and policies the Copilot Group Assignment Guide doesn't list.

    With -UserPrincipalName it also shows, for each person, every service they're covered for:
    which policy Microsoft picked, how much they've used this month (UTC), what's left, and
    whether they can use the service right now. Use it to:
      - answer "why can't this person use Cowork?"
      - test the 30-day temporary unlimited Cowork tier: check one person before, during and
        after their 30 days, to see which policy is picked and whether their usage carries over.

    What the API can't show: the "Allow new Agents and services as they become available"
    switch, model profiles, and credit request policies. Check those in the admin center.

    Permissions (delegated): CopilotCostManagement.Read.All, CopilotCostManagement-Policy.Read.All,
    CopilotCostManagement-Assignment.Read.All, and CopilotCostManagement-UserData.Read.All for
    -UserPrincipalName. Plus Group.Read.All and User.Read.All to show names.

.EXAMPLE
    .\Get-CopilotSpendingReport.ps1
    .\Get-CopilotSpendingReport.ps1 -UserPrincipalName "<person UPN>"
    .\Get-CopilotSpendingReport.ps1 -UserPrincipalName (Get-Content .\temp-tier-testers.txt) -ExportCsv
#>
[CmdletBinding()]
param(
    [string[]]$UserPrincipalName = @(),
    [switch]$ExportCsv,
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

$scopes = @(
    "CopilotCostManagement.Read.All",
    "CopilotCostManagement-Policy.Read.All",
    "CopilotCostManagement-Assignment.Read.All",
    "Group.Read.All",
    "User.Read.All"
)
if ($UserPrincipalName) { $scopes += "CopilotCostManagement-UserData.Read.All" }
# Which Microsoft cloud to sign in to. GCC uses Global, GCC High is USGov, DoD is USGovDoD.
# Not every Copilot or agent API exists in every national cloud; check Microsoft's docs for yours.
if (-not $Environment) {
    Get-MgEnvironment | Where-Object Name -in "Global", "USGov", "USGovDoD" | Select-Object Name, GraphEndpoint | Out-Host
    $choice = Read-Host "Type the cloud to connect to (Global, USGov or USGovDoD). Press Enter for Global"
    $Environment = if ($choice -in "Global", "USGov", "USGovDoD") { $choice } else { "Global" }
}
$graphEndpoint = (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint

Connect-MgGraph -Environment $Environment -NoWelcome -Scopes $scopes

$cm    = "$graphEndpoint/beta/copilot/costManagement"
$v1    = "$graphEndpoint/v1.0"
$stamp = Get-Date -Format yyyyMMdd-HHmm

# Policy names from the Copilot Group Assignment Guide, used to flag anything unexpected.
$guidePolicies = @(
    "Cowork Limited", "Cowork Unlimited", "Cowork Temporary Unlimited",
    "SharePoint OneDrive Advanced Work", "Work IQ API", "Managed Runtime", "Teams Phone Agent",
    "Copilot New Services Pilot", "Code Limited", "Code Unlimited"
)

function Get-All([string]$Uri) {
    while ($Uri) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        if ($page.PSObject.Properties.Name -contains "value") { $page.value } else { $page }
        $Uri = $page.'@odata.nextLink'
    }
}

function Format-Quantity($q) {
    if (-not $q) { return "" }
    if ("$($q.'@odata.type')" -like "*unlimited*") { "Unlimited" } else { "{0:N0}" -f [double]$q.value }
}

function Get-Safe([scriptblock]$Call) {
    try { & $Call } catch { $null }
}

# ---------------------------------------------------------------------------
# Tenant credit balance
# ---------------------------------------------------------------------------
Write-Host "`nTenant credit balance" -ForegroundColor Cyan
$balance = Get-Safe { Invoke-MgGraphRequest -Method GET -Uri "$cm/getTenantCreditBalance" -OutputType PSObject }
if ($balance) {
    $balance.billingMethodBalances |
        Select-Object billingMethod,
            @{ n = "Purchased"; e = { "{0:N0}" -f $_.purchasedQuantity } },
            @{ n = "Used";      e = { "{0:N0}" -f $_.consumedQuantity } },
            @{ n = "Left";      e = { "{0:N0}" -f $_.remainingQuantity } },
            @{ n = "AsOf";      e = { $_.dataStatus.lastModifiedDateTime } } |
        Format-Table -AutoSize
}
else { Write-Warning "Couldn't read the tenant credit balance (permission, or no billing set up)." }

# ---------------------------------------------------------------------------
# Policies
# ---------------------------------------------------------------------------
$policies = @(Get-All "$cm/spendingPolicies")
$policyName = @{}

$report = $policies | ForEach-Object {
    $p = $_
    $policyName[$p.id] = $p.displayName
    $isGroups = "$($p.'@odata.type')" -like "*selectedGroups*"

    $services = @(Get-All "$cm/spendingPolicies/$($p.id)/serviceSettings" | Where-Object state -eq "enabled" | ForEach-Object serviceId)
    $groups   = if ($isGroups) { @(Get-All "$cm/spendingPolicies/$($p.id)/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups") } else { @() }
    $alert    = Get-Safe { Invoke-MgGraphRequest -Method GET -Uri "$cm/spendingPolicies/$($p.id)/emailThresholdSettings" -OutputType PSObject }
    $recips   = if ($alert) { @(Get-Safe { Get-All "$cm/spendingPolicies/$($p.id)/emailThresholdSettings/recipients" }) } else { @() }

    $problems = @(
        if ($p.status -ne "enabled")                       { "status is $($p.status)" }
        if (-not $isGroups)                                { "covers ALL users" }
        if ($isGroups -and $groups.Count -eq 0)            { "no group linked" }
        if ($p.displayName -notin $guidePolicies)          { "not in the guide" }
        if (-not $alert -or -not $alert.isEnabled)         { "no email alert" }
    )

    [pscustomobject]@{
        Policy    = $p.displayName
        Status    = $p.status
        Scope     = if ($isGroups) { "Groups" } else { "All users" }
        Groups    = ($groups | ForEach-Object { if ($_.displayName) { $_.displayName } else { $_.id } }) -join "; "
        Services  = $services -join ", "
        Monthly   = Format-Quantity $p.periodLimit
        PerUser   = Format-Quantity $p.perUserLimit
        Billing   = $p.billingMethods
        Alert     = if ($alert -and $alert.isEnabled) { (($alert.thresholds | ForEach-Object { if ("$($_.'@odata.type')" -like "*percentage*") { "$($_.value)%" } else { "$($_.value) credits" } }) -join ", ") } else { "off" }
        Notify    = ($recips | ForEach-Object { if ($_.userPrincipalName) { $_.userPrincipalName } else { $_.id } }) -join "; "
        Check     = $problems -join "; "
        Id        = $p.id
    }
}

Write-Host "Spending policies" -ForegroundColor Cyan
if ($report) {
    $report | Format-Table Policy, Status, Scope, Groups, Services, Monthly, PerUser, Alert, Check -AutoSize -Wrap
}
else { Write-Host "No spending policies found." }

# The same group and service in two policies is refused by Microsoft, but a person can still be
# in two groups that both cover a service. List services covered by more than one policy.
$overlap = $report | Where-Object Status -ne "disabled" | ForEach-Object {
    $r = $_; $r.Services -split ", " | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Service = $_; Policy = $r.Policy } }
} | Group-Object Service | Where-Object Count -gt 1
if ($overlap) {
    Write-Host "Services covered by more than one policy (people in both groups get the higher per-user limit):" -ForegroundColor Cyan
    $overlap | Select-Object @{ n = "Service"; e = { $_.Name } }, @{ n = "Policies"; e = { ($_.Group.Policy) -join "; " } } | Format-Table -AutoSize -Wrap
}

Write-Host "Check by hand in Copilot > Cost management > Configuration: the 'Allow new Agents and services' switch (off everywhere except Copilot New Services Pilot) and the model profile on each Cowork policy." -ForegroundColor Yellow

# ---------------------------------------------------------------------------
# Per-person balances
# ---------------------------------------------------------------------------
$people = foreach ($upn in $UserPrincipalName) {
    $user = Get-Safe { Invoke-MgGraphRequest -Method GET -Uri "$v1/users/$([uri]::EscapeDataString($upn))?`$select=id,userPrincipalName" -OutputType PSObject }
    if (-not $user) { Write-Warning "User '$upn' not found."; continue }

    $bal = Get-Safe { Invoke-MgGraphRequest -Method GET -Uri "$cm/userBalances/$($user.id)?`$expand=serviceBalances" -OutputType PSObject }
    if (-not $bal) { Write-Warning "Couldn't read the balance for $upn (no policy covers them, or the source is unavailable)."; continue }

    $bal.serviceBalances | ForEach-Object {
        [pscustomobject]@{
            User     = $upn
            Service  = $_.serviceId
            Policy   = if ($policyName[$_.spendingPolicyId]) { $policyName[$_.spendingPolicyId] } else { $_.spendingPolicyId }
            Used     = "{0:N0}" -f [double]$_.consumedQuantity
            PerUser  = Format-Quantity $_.configuredPerUserLimit
            Left     = Format-Quantity $_.remainingQuantity
            CanUse   = $_.isConsumptionAllowed
            Reason   = $_.accessDecisionReason
            AsOf     = $_.dataStatus.lastModifiedDateTime
        }
    }
    $bal.unevaluatedServices | Where-Object { $_ } | ForEach-Object {
        [pscustomobject]@{ User = $upn; Service = $_.serviceId; Policy = ""; Used = ""; PerUser = ""; Left = ""; CanUse = $false; Reason = $_.reason; AsOf = "" }
    }
}

if ($people) {
    Write-Host "`nPer-person balances (this month, UTC)" -ForegroundColor Cyan
    $people | Format-Table User, Service, Policy, Used, PerUser, Left, CanUse, Reason -AutoSize -Wrap
}

if ($ExportCsv) {
    $report | Export-Csv ".\CopilotSpendingPolicies-Report-$stamp.csv" -NoTypeInformation
    if ($people) { $people | Export-Csv ".\CopilotSpendingPolicies-People-$stamp.csv" -NoTypeInformation }
    Write-Host "Saved CSV files to the current folder."
}
