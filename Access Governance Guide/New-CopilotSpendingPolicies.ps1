<#PSScriptInfo
.VERSION 2026.11
.GUID 3e98f86b-cb9e-4ee4-b474-f61fe91ff970
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
Creates the Copilot Credits spending policies from the Access Governance Guide with the Graph cost management API.
url: Create spendingPolicy (Graph beta) - https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/spendingpolicy-create
#>

<#
.SYNOPSIS
    Creates the Copilot Credits spending policies from the Copilot Access Governance Guide with
    the new Microsoft Graph cost management API (beta, MC1521616). Graph only
    (Invoke-MgGraphRequest).

.DESCRIPTION
    PREVIEW. These APIs live on the Microsoft Graph /beta endpoint. Microsoft can change them
    and does not support them for production use. Run with -WhatIf first, and check the result
    in the Microsoft 365 admin center (Copilot > Cost management > Configuration).

    For each policy in the table below the script:
      1. Skips it if a policy with that name already exists (match on displayName). With
         -UpdateExisting it instead brings that policy in line: name (if found under an old
         name), limits, services, group and, with -AlertThresholdPercent, the alert.
      2. Creates it as a selectedGroupsSpendingPolicy with its period limit, per-user limit
         and services. A new policy is created DISABLED.
      3. Links its Entra group, which is what lets the service enable the policy.
      4. Optionally sets a notify-only email threshold alert and its recipients.

    What this script CANNOT do, because the API does not expose it (set these by hand in
    Copilot > Cost management > Configuration):
      - "Allow new Agents and services as they become available" (Auto-apply new services).
      - Model templates (model profiles).

    Rules the API enforces (so the script does too):
      - A policy name is 10-64 characters, letters, digits and spaces only. That is why the
        guide's policy names no longer contain a dash.
      - Every change to an existing policy needs the policy's current ETag in If-Match.
      - Two policies cannot cover the same group and the same service. Microsoft returns 409
        groupServiceConflict. A tenant-wide policy on the same service returns 409
        allUsersServiceConflict.
      - At least one service must stay enabled on a policy.
      - Microsoft asks for a per-user limit of at least 2,000 credits a month.

    Service IDs: Microsoft documents 'cowork' and 'workIQ'. The others below are best guesses
    and are PLACEHOLDERS. Get the real IDs from a policy you created in the admin center:
        .\New-CopilotSpendingPolicies.ps1 -ShowServiceIds
    then pass them in with -ServiceIdMap, for example:
        -ServiceIdMap @{ Code = 'code'; ManagedRuntime = 'copilotManagedRuntime' }

    Requirements:
      - Delegated permissions CopilotCostManagement-Policy.ReadWrite.All and
        CopilotCostManagement-Assignment.ReadWrite.All (app-only is not supported).
      - The Billing Administrator or Global Administrator role at runtime.
      - Run New-CopilotGroups.ps1 first, so the groups exist.

.PARAMETER BusinessUnits
    Also creates a set of tier policies for each business unit: "Copilot <business unit> <tier>",
    scoped to "Copilot Spend <business unit> <tier>". Run New-CopilotGroups.ps1 -BusinessUnits first.

.PARAMETER TierPeriodLimit
    Monthly policy limit for the Silver, Gold and Platinum tiers. Default 500,000 credits.
    Bronze uses -PeriodLimit. Size both to the number of people in each group.

.PARAMETER ServiceIdMap
    Overrides the service IDs. Keys: Cowork, SharePointAdvanced, OneDriveAdvanced, WorkIqApi,
    ManagedRuntime, TeamsPhoneAgent, Code.

.PARAMETER AlertRecipientUpn
    One or more user principal names to email when a policy reaches its threshold. Required if
    you use -AlertThresholdPercent.

.PARAMETER UpdateExisting
    For policies that already exist: rename a policy found under an old name, set the period
    and per-user limits to the values the script would create, turn on any missing service,
    link the group if it's missing, and turn on the alert if -AlertThresholdPercent is set.
    It never turns a service off or removes a group; it only reports extras.

.PARAMETER TempPeriodLimit
    Monthly cap for the Copilot Platinum Temporary policy. Its users have no per-user cap, so
    this is the safety net. Defaults to -PeriodLimit.

.PARAMETER Environment
    The Microsoft cloud to sign in to: Global (also GCC), USGov (GCC High) or USGovDoD. China isn't offered.
    Leave it out and the script asks.

.EXAMPLE
    .\New-CopilotSpendingPolicies.ps1 -ShowServiceIds
    .\New-CopilotSpendingPolicies.ps1 -WhatIf
    .\New-CopilotSpendingPolicies.ps1 -UpdateExisting -TempPeriodLimit 20000 -WhatIf
    .\New-CopilotSpendingPolicies.ps1 -IncludeCodePolicies -AlertThresholdPercent 80 -AlertRecipientUpn "<copilot program owner UPN>"
    .\New-CopilotSpendingPolicies.ps1 -BusinessUnits "Finance", "Revenue" -AlertThresholdPercent 80 -AlertRecipientUpn "<budget owner UPN>" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$ShowServiceIds,
    [switch]$IncludeCodePolicies,
    [switch]$UpdateExisting,
    [ValidatePattern('^[A-Za-z0-9 ]+$')][string[]]$BusinessUnits,
    [int]$TierPeriodLimit = 500000,
    [hashtable]$ServiceIdMap = @{},
    [int]$PerUserLimit    = 2000,
    [int]$PeriodLimit     = 100000,
    [int]$TempPeriodLimit = 0,
    [int]$AlertThresholdPercent = 0,
    [string[]]$AlertRecipientUpn = @(),
    [ValidateSet("notSpecified", "prepaidCredits", "payAsYouGo", "prepaidCredits,payAsYouGo")]
    [string]$BillingMethods = "notSpecified",
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
    "CopilotCostManagement-Policy.ReadWrite.All",
    "CopilotCostManagement-Assignment.ReadWrite.All",
    "Group.Read.All",
    "User.Read.All"
)

$beta = "$graphEndpoint/beta"
$cm   = "$beta/copilot/costManagement"
$v1   = "$graphEndpoint/v1.0"

# ---------------------------------------------------------------------------
# Service IDs. 'cowork' and 'workIQ' come from Microsoft's documentation.
# The rest are placeholders - confirm them with -ShowServiceIds.
# ---------------------------------------------------------------------------
$svc = @{
    Cowork             = "cowork"
    WorkIqApi          = "workIQ"
    SharePointAdvanced = "sharePointAdvancedWork"
    OneDriveAdvanced   = "oneDriveAdvancedWork"
    ManagedRuntime     = "copilotManagedRuntime"
    TeamsPhoneAgent    = "teamsPhoneAgent"
    Code               = "code"
}
foreach ($k in $ServiceIdMap.Keys) { $svc[$k] = $ServiceIdMap[$k] }

$documentedIds = @("cowork", "workIQ")

# ---------------------------------------------------------------------------
# Policies. Names: letters, digits and spaces only, 10-64 characters.
# Unlimited = no per-user cap (unlimitedCostManagementQuantity).
# ---------------------------------------------------------------------------
# Spend tiers (Cowork and Work IQ API). PerUserValue overrides -PerUserLimit. OldNames are the
# policies from the earlier Limited/Unlimited design; -UpdateExisting renames them.
$tierPolicies = @(
    @{ Name = "Copilot Bronze";             Tier = "Bronze";        Services = @($svc.WorkIqApi);              PerUser = "limited";   PerUserValue = 2000 }
    @{ Name = "Copilot Silver";             Tier = "Silver";        Services = @($svc.Cowork, $svc.WorkIqApi); PerUser = "limited";   PerUserValue = 5000;  Period = $TierPeriodLimit; OldNames = @("Cowork Limited") }
    @{ Name = "Copilot Gold";               Tier = "Gold";          Services = @($svc.Cowork, $svc.WorkIqApi); PerUser = "limited";   PerUserValue = 10000; Period = $TierPeriodLimit }
    @{ Name = "Copilot Platinum";           Tier = "Platinum";      Services = @($svc.Cowork, $svc.WorkIqApi); PerUser = "unlimited"; Period = $TierPeriodLimit; OldNames = @("Cowork Unlimited") }
    @{ Name = "Copilot Platinum Temporary"; Tier = "Platinum Temp"; Services = @($svc.Cowork, $svc.WorkIqApi); PerUser = "unlimited"; Period = $TempPeriodLimit; OldNames = @("Cowork Temporary Unlimited") }
)
$policies = @(
    $tierPolicies | ForEach-Object { $_.Group = "Copilot Spend $($_.Tier)"; $_ }
    foreach ($bu in $BusinessUnits) {
        $tierPolicies | ForEach-Object {
            @{ Name = "Copilot $bu $($_.Tier -replace ' Temp$', ' Temporary')"; Group = "Copilot Spend $bu $($_.Tier)"
               Services = $_.Services; PerUser = $_.PerUser; PerUserValue = $_.PerUserValue; Period = $_.Period }
        }
    }
    @{ Name = "SharePoint OneDrive Advanced Work"; Group = "Copilot SharePoint OneDrive Advanced Access"; Services = @($svc.SharePointAdvanced, $svc.OneDriveAdvanced); PerUser = "limited" }
    @{ Name = "Work IQ API";                      Group = "Copilot Work IQ API Access";                  Services = @($svc.WorkIqApi); PerUser = "limited" }
    @{ Name = "Managed Runtime";                  Group = "Copilot Managed Runtime Access";              Services = @($svc.ManagedRuntime); PerUser = "limited" }
    @{ Name = "Teams Phone Agent";                Group = "Copilot Teams Phone Agent Accounts";          Services = @($svc.TeamsPhoneAgent); PerUser = "limited" }
    @{ Name = "Code Limited";                     Group = "Copilot + Code Spend Limit";                  Services = @($svc.Code); PerUser = "limited"; Code = $true }
    @{ Name = "Code Unlimited";                   Group = "Copilot + Code Spend Unlimited";              Services = @($svc.Code); PerUser = "unlimited"; Code = $true }
)
if (-not $IncludeCodePolicies) { $policies = @($policies | Where-Object { -not $_.Code }) }

# The Copilot New Services Pilot policy is deliberately left out: its whole point is the
# "Allow new Agents and services as they become available" switch, which the API cannot set.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Invoke-Graph([string]$Method, [string]$Uri, $Body, [hashtable]$Headers) {
    $p = @{ Method = $Method; Uri = $Uri; OutputType = "PSObject" }
    if ($null -ne $Body)    { $p.Body = ($Body | ConvertTo-Json -Depth 20); $p.ContentType = "application/json" }
    if ($null -ne $Headers) { $p.Headers = $Headers }
    Invoke-MgGraphRequest @p
}

function Get-AllPages([string]$Uri) {
    $items = @()
    while ($Uri) {
        $page  = Invoke-Graph GET $Uri $null $null
        $items += $page.value
        $Uri    = $page.'@odata.nextLink'
    }
    $items
}

function Esc([string]$s) { $s.Replace("'", "''") }

$groupCache = @{}
function Get-GroupId([string]$Name) {
    if (-not $groupCache.ContainsKey($Name)) {
        $uri = "$v1/groups?`$filter=$([uri]::EscapeDataString("displayName eq '$(Esc $Name)'"))&`$select=id,displayName"
        $g = (Invoke-Graph GET $uri $null $null).value | Select-Object -First 1
        if (-not $g) { throw "Group '$Name' not found. Run New-CopilotGroups.ps1 first." }
        $groupCache[$Name] = $g.id
    }
    $groupCache[$Name]
}

function Get-UserId([string]$Upn) {
    (Invoke-Graph GET "$v1/users/$([uri]::EscapeDataString($Upn))?`$select=id" $null $null).id
}

# Most changes need the policy's current ETag in If-Match. Read it from the response header,
# and fall back to the body's @odata.etag when the header isn't exposed.
function Get-PolicyEtag([string]$Id) {
    $headers = $null
    $policy  = Invoke-MgGraphRequest -Method GET -Uri "$cm/spendingPolicies/$Id" `
                   -OutputType PSObject -ResponseHeadersVariable headers
    $etag = $null
    if ($headers) {
        foreach ($key in @("ETag", "etag")) {
            if ($headers.ContainsKey($key)) { $etag = @($headers[$key])[0]; break }
        }
    }
    if (-not $etag) { $etag = $policy.'@odata.etag' }
    if (-not $etag) { throw "Could not read the ETag for policy $Id." }
    $etag
}

function New-Quantity([string]$Kind, [int]$Value) {
    if ($Kind -eq "unlimited") {
        @{ "@odata.type" = "#microsoft.graph.unlimitedCostManagementQuantity"; unit = "copilotCredit" }
    }
    else {
        @{ "@odata.type" = "#microsoft.graph.limitedCostManagementQuantity"; value = $Value; unit = "copilotCredit" }
    }
}

function Test-PolicyName([string]$Name) {
    if ($Name.Length -lt 10 -or $Name.Length -gt 64) { return "name must be 10-64 characters" }
    if ($Name -notmatch '^[A-Za-z0-9 ]+$')           { return "name may only contain letters, digits and spaces" }
    return $null
}

function Test-SameQuantity($a, $b) {
    $ta = "$($a.'@odata.type')".TrimStart('#'); $tb = "$($b.'@odata.type')".TrimStart('#')
    if ($ta -ne $tb) { return $false }
    if ($ta -like "*unlimited*") { return $true }
    [double]$a.value -eq [double]$b.value
}

# -UpdateExisting: bring an existing policy in line with the table. Only adds; never removes.
function Sync-Policy([string]$Id, $Want, [string]$GroupId, [hashtable]$Desired) {
    $notes  = @()
    $policy = Invoke-Graph GET "$cm/spendingPolicies/$Id" $null $null

    $patch = @{}
    if (-not (Test-SameQuantity $policy.periodLimit  $Desired.periodLimit))  { $patch.periodLimit  = $Desired.periodLimit }
    if (-not (Test-SameQuantity $policy.perUserLimit $Desired.perUserLimit)) { $patch.perUserLimit = $Desired.perUserLimit }
    if ($script:BillingSet) {
        if ($policy.billingMethods -ne $Desired.billingMethods) { $patch.billingMethods = $Desired.billingMethods }
    }
    if ($patch.Count -gt 0 -and $PSCmdlet.ShouldProcess($Want.Name, "PATCH limits ($($patch.Keys -join ', '))")) {
        Invoke-Graph PATCH "$cm/spendingPolicies/$Id" $patch @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
        $notes += "updated $($patch.Keys -join ', ')"
    }

    $current = Get-AllPages "$cm/spendingPolicies/$Id/serviceSettings"
    foreach ($sid in $Want.Services) {
        $row = $current | Where-Object { $_.serviceId -ceq $sid } | Select-Object -First 1
        if (-not $row) {
            if ($PSCmdlet.ShouldProcess($Want.Name, "Add service $sid")) {
                Invoke-Graph POST "$cm/spendingPolicies/$Id/serviceSettings" @{ serviceId = $sid; state = "enabled" } @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
                $notes += "added $sid"
            }
        }
        elseif ($row.state -ne "enabled") {
            if ($PSCmdlet.ShouldProcess($Want.Name, "Enable service $sid")) {
                Invoke-Graph PATCH "$cm/spendingPolicies/$Id/serviceSettings/$sid" @{ state = "enabled" } @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
                $notes += "enabled $sid"
            }
        }
    }
    $extra = $current | Where-Object { $_.state -eq "enabled" -and $_.serviceId -cnotin $Want.Services } | ForEach-Object serviceId
    if ($extra) { $notes += "EXTRA services on (left alone): $($extra -join ', ')" }

    $groups = Get-AllPages "$cm/spendingPolicies/$Id/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups"
    if ($GroupId -notin $groups.id) {
        if ($PSCmdlet.ShouldProcess($Want.Name, "Link group $($Want.Group)")) {
            Invoke-Graph POST "$cm/spendingPolicies/$Id/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups/`$ref" `
                @{ "@odata.id" = "$beta/groups/$GroupId" } @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
            $notes += "linked $($Want.Group)"
        }
    }
    $others = @($groups | Where-Object { $_.id -ne $GroupId })
    if ($others) { $notes += "EXTRA groups (left alone): $(($others | ForEach-Object displayName) -join ', ')" }

    if ($AlertThresholdPercent -gt 0) {
        $alert = Invoke-Graph GET "$cm/spendingPolicies/$Id/emailThresholdSettings" $null $null
        if (-not $alert.isEnabled -and $PSCmdlet.ShouldProcess($Want.Name, "Turn on alert at $AlertThresholdPercent%")) {
            Set-PolicyAlert $Id
            $notes += "alert on at $AlertThresholdPercent%"
        }
    }

    if (-not $notes) { "already matches" } else { $notes -join "; " }
}

# Microsoft's order: set the alert disabled, add the recipients, then enable it.
function Set-PolicyAlert([string]$Id) {
    Invoke-Graph PATCH "$cm/spendingPolicies/$Id/emailThresholdSettings" `
        @{ isEnabled = $false; thresholds = @(@{ "@odata.type" = "#microsoft.graph.percentageCostManagementAlertThreshold"; value = $AlertThresholdPercent }) } `
        @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
    foreach ($upn in $AlertRecipientUpn) {
        $uid = Get-UserId $upn
        try {
            Invoke-Graph POST "$cm/spendingPolicies/$Id/emailThresholdSettings/recipients/`$ref" `
                @{ "@odata.id" = "$beta/users/$uid" } @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
        }
        catch { Write-Verbose "Recipient $upn not added (it may already be there): $($_.Exception.Message)" }
    }
    Invoke-Graph PATCH "$cm/spendingPolicies/$Id/emailThresholdSettings" `
        @{ isEnabled = $true } @{ "If-Match" = (Get-PolicyEtag $Id) } | Out-Null
}

# ---------------------------------------------------------------------------
# -ShowServiceIds: read the service IDs off the policies already in the tenant
# ---------------------------------------------------------------------------
if ($ShowServiceIds) {
    $existing = Get-AllPages "$cm/spendingPolicies?`$select=id,displayName,status"
    if (-not $existing) {
        Write-Host "No spending policies found. Create one in the admin center first, then run this again."
        return
    }
    $rows = foreach ($p in $existing) {
        foreach ($s in (Get-AllPages "$cm/spendingPolicies/$($p.id)/serviceSettings")) {
            [pscustomobject]@{ Policy = $p.displayName; Status = $p.status; ServiceId = $s.serviceId; State = $s.state }
        }
    }
    $rows | Sort-Object ServiceId, Policy | Format-Table -AutoSize
    Write-Host "Pass any ID that differs from this script's defaults with -ServiceIdMap."
    return
}

if ($AlertThresholdPercent -gt 0 -and $AlertRecipientUpn.Count -eq 0) {
    throw "-AlertThresholdPercent needs at least one -AlertRecipientUpn. Microsoft refuses alerting with no recipient."
}
if ($AlertThresholdPercent -lt 0 -or $AlertThresholdPercent -gt 100) {
    throw "-AlertThresholdPercent must be between 1 and 100."
}

$unknown = $policies.Services | Sort-Object -Unique | Where-Object { $_ -notin $documentedIds }
if ($unknown) {
    Write-Warning ("These service IDs are placeholders, not documented by Microsoft: {0}. Confirm them with -ShowServiceIds and pass -ServiceIdMap." -f ($unknown -join ", "))
}

# ---------------------------------------------------------------------------
# Create the policies
# ---------------------------------------------------------------------------
$script:BillingSet = $PSBoundParameters.ContainsKey("BillingMethods")
$existingPolicies = Get-AllPages "$cm/spendingPolicies?`$select=id,displayName,status"
$results = @()

foreach ($p in $policies) {
    $nameProblem = Test-PolicyName $p.Name
    if ($nameProblem) {
        $results += [pscustomobject]@{ Policy = $p.Name; Status = "Skipped"; Detail = $nameProblem }
        continue
    }

    $period = if ($p.Period) { $p.Period } else { $PeriodLimit }
    $desired = @{
        periodLimit    = (New-Quantity "limited" $period)
        perUserLimit   = (New-Quantity $p.PerUser $(if ($p.PerUserValue) { $p.PerUserValue } else { $PerUserLimit }))
        billingMethods = $BillingMethods
    }

    $already = $existingPolicies | Where-Object { $_.displayName -eq $p.Name } | Select-Object -First 1
    $oldName = $null
    if (-not $already) {
        $already = $existingPolicies | Where-Object { $_.displayName -in @($p.OldNames) } | Select-Object -First 1
        if ($already) { $oldName = $already.displayName }
    }
    if ($already) {
        if (-not $UpdateExisting) {
            $results += [pscustomobject]@{ Policy = $p.Name; Status = "Exists"; Detail = "status $($already.status); id $($already.id)$(if ($oldName) { "; found under old name '$oldName'" }). Use -UpdateExisting to sync it" }
            continue
        }
        try {
            if ($oldName -and $PSCmdlet.ShouldProcess($oldName, "Rename policy to '$($p.Name)'")) {
                Invoke-Graph PATCH "$cm/spendingPolicies/$($already.id)" @{ displayName = $p.Name } @{ "If-Match" = (Get-PolicyEtag $already.id) } | Out-Null
            }
            $note = Sync-Policy $already.id $p (Get-GroupId $p.Group) $desired
            if ($oldName) { $note = "renamed from '$oldName'; $note" }
            $results += [pscustomobject]@{ Policy = $p.Name; Status = "Checked"; Detail = "status $($already.status); $note" }
        }
        catch {
            $results += [pscustomobject]@{ Policy = $p.Name; Status = "Failed"; Detail = "update: $($_.Exception.Message)" }
        }
        continue
    }

    $groupId = Get-GroupId $p.Group

    if (-not $PSCmdlet.ShouldProcess($p.Name, "POST /beta/copilot/costManagement/spendingPolicies")) {
        $results += [pscustomobject]@{ Policy = $p.Name; Status = "WhatIf"; Detail = "group $($p.Group); services $($p.Services -join ', ')" }
        continue
    }

    $body = @{
        "@odata.type"   = "#microsoft.graph.selectedGroupsSpendingPolicy"
        displayName     = $p.Name
        periodLimit     = $desired.periodLimit
        perUserLimit    = $desired.perUserLimit
        billingMethods  = $desired.billingMethods
        serviceSettings = @($p.Services | ForEach-Object { @{ serviceId = $_; state = "enabled" } })
    }

    try {
        # Create disabled with no audience, then link the group (Microsoft's safe-create order).
        $created = Invoke-Graph POST "$cm/spendingPolicies" $body $null
    }
    catch {
        $results += [pscustomobject]@{ Policy = $p.Name; Status = "Failed"; Detail = "create: $($_.Exception.Message)" }
        continue
    }

    $detail = "created disabled; id $($created.id)"

    try {
        Invoke-Graph POST "$cm/spendingPolicies/$($created.id)/microsoft.graph.selectedGroupsSpendingPolicy/assignedGroups/`$ref" `
            @{ "@odata.id" = "$beta/groups/$groupId" } @{ "If-Match" = (Get-PolicyEtag $created.id) } | Out-Null
        $detail += "; group linked"
    }
    catch {
        $results += [pscustomobject]@{ Policy = $p.Name; Status = "Partial"; Detail = "$detail; group link failed: $($_.Exception.Message)" }
        continue
    }

    if ($AlertThresholdPercent -gt 0) {
        try {
            Set-PolicyAlert $created.id
            $detail += "; alert at $AlertThresholdPercent%"
        }
        catch {
            $detail += "; alert failed: $($_.Exception.Message)"
        }
    }

    $results += [pscustomobject]@{ Policy = $p.Name; Status = "Created"; Detail = $detail }
}

$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotSpendingPolicies-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation

Write-Host ""
Write-Host "Still to do by hand in Copilot > Cost management > Configuration:"
Write-Host "  1. Turn OFF 'Allow new Agents and services as they become available' on every policy above."
Write-Host "  2. Create the Copilot New Services Pilot policy and leave that switch ON for Copilot Pilot Ring only."
Write-Host "  3. Pick a model template on each policy that includes Cowork."
Write-Host "  4. Check each policy turned itself on (status enabled)."
