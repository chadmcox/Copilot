<#PSScriptInfo
.VERSION 2026.11
.GUID 6d4a7bae-b7e1-4f80-b04b-5539a9bf562a
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
Checks the Copilot catalog, access packages, request policies and access reviews, and creates or fixes what is missing.
url: What is entitlement management? - https://learn.microsoft.com/entra/id-governance/entitlement-management-overview
#>

<#
.SYNOPSIS
    The one script for the Copilot access packages. Run it any time: it checks the catalog and
    each package in the table below and creates or fixes it. Graph only (Invoke-MgGraphRequest).

.DESCRIPTION
    1. Checks every group the packages use exists. If any are missing it lists them and stops:
       run New-CopilotGroups.ps1 first.
    2. Catalog ("Copilot Access Catalog"): creates it if missing, and adds any group not in it yet.
    3. For every package in $packages:
         - Missing: creates it.
         - Description differs: updates it.
         - Group in the table but not in the package: adds it.
         - Group in the package but not in the table: reports it (never removes it).
         - Request policy for its tier missing: creates it. Other policies on the package are
           reported, not removed (a tier change leaves the old policy for you to delete).
    4. Links packages that can't be held together (the spend tiers: one tier per person), both ways.
    5. Optional -CreateAdminGroupReviews: quarterly access reviews on the admin groups.

    Tiers: Standard (manager, 365 days, review every 6 months), Elevated (manager then approver
    group, 180 days, every 3 months), Admin (manager then admin approver group, 90 days, every
    3 months), Temporary (manager then approver group, 30 days, no extension, no review).

    HOW TO CHANGE THE DESIGN
      - New package: add a line to $packages. Its groups must be in New-CopilotGroups.ps1.
      - Grant another group: add it to the package's Groups.
      - Renamed package: change Name and put the old name in OldNames. The next run renames it.
      - Spend tiers: the rows with SpendTier. -BusinessUnits makes a copy per business unit.
      - Admin group: add it to $adminGroups (used by -IncludeAdminPackages and -CreateAdminGroupReviews).

    Requirements:
      - Microsoft Entra ID Governance (or Entra ID P2) for the users in scope.
      - Least-privileged role: Identity Governance Administrator. Adding role-assignable groups to
        the catalog (-IncludeAdminPackages) also needs Privileged Role Administrator.
      - For admin roles, Microsoft recommends PIM for Groups (New-CopilotAdminPim.ps1) over
        permanent membership through access packages.

.PARAMETER ApproverGroupName
    Approves the second stage of Elevated and Temporary packages, and is the fallback when a person has no manager.

.PARAMETER AdminApproverGroupName
    Approves Admin-tier packages and reviews admin groups. Use a group that isn't granted by these packages.

.PARAMETER BusinessUnits
    Also checks a set of tier packages for each business unit, granting the
    "Copilot Spend <business unit> <tier>" groups. Run New-CopilotGroups.ps1 -BusinessUnits first,
    with the same names. Every tier package (all business units) is incompatible with every other,
    so a person holds one tier in one business unit.

.PARAMETER IncludeCodePackages
    Also checks the Copilot Code packages (MC1519871). Run New-CopilotGroups.ps1 -IncludeCodeGroups first.

.PARAMETER IncludeAdminPackages
    Also checks one Admin-tier package per admin group. Not needed if you use PIM.

.PARAMETER CreateAdminGroupReviews
    Also checks a quarterly access review on each admin group, covering members added outside a package.

.PARAMETER Environment
    The Microsoft cloud to sign in to: Global (also GCC), USGov (GCC High) or USGovDoD.
    Leave it out and the script asks.

.EXAMPLE
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -WhatIf
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>"
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -IncludeCodePackages
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -BusinessUnits "Finance", "Revenue" -WhatIf
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -AdminApproverGroupName "<security group>" -IncludeAdminPackages -CreateAdminGroupReviews
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CatalogName            = "Copilot Access Catalog",
    [string]$ApproverGroupName      = "Copilot Delegated Admin",
    [string]$AdminApproverGroupName = "Copilot Delegated Admin",
    [switch]$IncludeAdminPackages,
    [switch]$CreateAdminGroupReviews,
    [switch]$IncludeCodePackages,
    [ValidatePattern('^[A-Za-z0-9 ]+$')][string[]]$BusinessUnits,
    [ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment
)

#Requires -Modules Microsoft.Graph.Authentication

# ---------------------------------------------------------------------------
# The design. Change these tables, not the code below.
#   Groups       = groups the package grants (prerequisites included)
#   Incompatible = packages a person can't hold at the same time
#   AllowedGroup = only members of these groups can see and request the package
#   OldNames     = earlier package names; a package found under one of them is renamed
#   SpendTier    = spend tier row; tier packages are incompatible with each other (set at run time)
#   Code         = only with -IncludeCodePackages
# ---------------------------------------------------------------------------
$tiers = @{
    Standard  = @{ ExpiryDays = 365; ReviewEveryMonths = 6; SecondStage = $false; ApproverGroup = $ApproverGroupName }
    Elevated  = @{ ExpiryDays = 180; ReviewEveryMonths = 3; SecondStage = $true;  ApproverGroup = $ApproverGroupName }
    Admin     = @{ ExpiryDays = 90;  ReviewEveryMonths = 3; SecondStage = $true;  ApproverGroup = $AdminApproverGroupName }
    # Fixed 30-day grant: no extension, no recurring review (expiry removes access).
    Temporary = @{ ExpiryDays = 30;  ReviewEveryMonths = 0; SecondStage = $true;  ApproverGroup = $ApproverGroupName; NoExtend = $true }
}

$packages = @(
    @{ Name = "Copilot Access";                      Tier = "Standard"; Groups = @("Copilot Access") }
    # Spend tiers (Cowork and Work IQ API). One tier per person: the tier packages are made incompatible
    # with each other at run time. The old Limited, Unlimited and Temporary packages are renamed.
    @{ Name = "Copilot Spend Bronze";   SpendTier = "Bronze";   Tier = "Standard"; Groups = @("Copilot Access", "Copilot Spend Bronze") }
    @{ Name = "Copilot Spend Silver";   SpendTier = "Silver";   Tier = "Standard"; Groups = @("Copilot Access", "Copilot Spend Silver"); OldNames = @("Copilot + Cowork Access (Limited)") }
    @{ Name = "Copilot Spend Gold";     SpendTier = "Gold";     Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Spend Gold") }
    @{ Name = "Copilot Spend Platinum"; SpendTier = "Platinum"; Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Spend Platinum"); OldNames = @("Copilot + Cowork Access (Unlimited)") }
    # Only Silver and Gold members can see/request this; it grants only the Temp group, for 30 days.
    @{ Name = "Copilot Spend Platinum (Temporary, 30 days)"; SpendTier = "Platinum Temp"; Tier = "Temporary"; Groups = @("Copilot Spend Platinum Temp")
       AllowedGroup = @("Copilot Spend Silver", "Copilot Spend Gold"); Incompatible = @("Copilot Spend Platinum"); OldNames = @("Copilot + Cowork Access (Temporary Unlimited, 30 days)") }
    @{ Name = "Copilot + Cowork Browser Access";     Tier = "Elevated"; Groups = @("Copilot + Cowork Browser Access") }
    @{ Name = "Copilot SharePoint OneDrive Advanced Access"; Tier = "Standard"; Groups = @("Copilot Access", "Copilot SharePoint OneDrive Advanced Access") }
    @{ Name = "Copilot Work IQ API Access";          Tier = "Elevated"; Groups = @("Copilot Work IQ API Access") }
    # Managed Runtime users don't need a Copilot license, so Copilot Access isn't bundled.
    @{ Name = "Copilot Managed Runtime Access";      Tier = "Standard"; Groups = @("Copilot Managed Runtime Access") }
    @{ Name = "Copilot Intelligent Call Delegation Access"; Tier = "Standard"; Groups = @("Copilot Access", "Copilot Intelligent Call Delegation Access") }
    # Copilot Code (rolling out to Frontier from late Oct 2026, MC1519871): -IncludeCodePackages
    @{ Name = "Copilot + Code Access (Limited)";     Tier = "Elevated"; Code = $true; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Code Spend Limit"); Incompatible = "Copilot + Code Access (Unlimited)" }
    @{ Name = "Copilot + Code Access (Unlimited)";   Tier = "Elevated"; Code = $true; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Code Spend Unlimited") }
    @{ Name = "Copilot + Code Secure Execution Exemption"; Tier = "Admin"; Code = $true; Groups = @("Copilot + Code Secure Execution Exemption") }
    @{ Name = "Copilot + Opal Access";               Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Opal Access") }
    # Autopilot (formerly Scout) is Frontier-only for now.
    @{ Name = "Copilot + Autopilot Access";          Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Autopilot Access") }
    @{ Name = "Copilot Frontier Access";             Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access") }
    @{ Name = "Copilot Pilot Ring";                  Tier = "Elevated"; Groups = @("Copilot Pilot Ring") }
    @{ Name = "Copilot Anthropic Models Access";     Tier = "Standard"; Groups = @("Copilot Anthropic Models Access") }
    @{ Name = "Copilot OpenAI Models Access";        Tier = "Standard"; Groups = @("Copilot OpenAI Models Access") }
    # SpaceXAI as a subprocessor is Frontier-only.
    @{ Name = "Copilot SpaceXAI Models Access";      Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot SpaceXAI Models Access") }
    # Independent processors: data processed under the provider's own terms, outside Microsoft's DPA.
    @{ Name = "Copilot Independent Processor Models Access"; Tier = "Admin"; Groups = @("Copilot Independent Processor Models Access") }
    @{ Name = "Copilot Studio Access";               Tier = "Standard"; Groups = @("Copilot Studio Access") }
    @{ Name = "Copilot App Builder Access";          Tier = "Elevated"; Groups = @("Copilot Studio Access", "Copilot App Builder Access") }
    @{ Name = "Copilot Agent Sharing Access";        Tier = "Standard"; Groups = @("Copilot Agent Sharing Access") }
    @{ Name = "Copilot Advanced Package Upload Access"; Tier = "Elevated"; Groups = @("Copilot Advanced Package Upload Access") }
    @{ Name = "Copilot Teams Policy Exceptions";     Tier = "Elevated"; Groups = @("Copilot Teams Policy Exceptions") }
    @{ Name = "Copilot Cloud Policy Exceptions";     Tier = "Elevated"; Groups = @("Copilot Cloud Policy Exceptions") }
)

# Admin groups for -IncludeAdminPackages and -CreateAdminGroupReviews. Copilot Platform Admin is left
# out on purpose: it is reached only through PIM.
$adminGroups = @(
    "Copilot Delegated Admin", "Copilot Agent Management Admin", "Copilot Agent Registry Admin", "Copilot AI Reader",
    "Copilot Billing Admin", "Copilot Cost Reader", "Copilot Agent ID Admin", "Copilot Agent ID Developers",
    "Copilot Office Apps Admin", "Copilot Compliance Admin", "Copilot Teams Admin",
    "Copilot SharePoint Admin", "Copilot Studio Environment Admin", "Copilot Plugin Approvers",
    "Copilot Health Check Users", "Copilot Entra ID Operations Reader"
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

function Get-Filtered([string]$BaseUri, [string]$Filter, [string]$Extra = "") {
    @(Get-AllPages "$BaseUri`?`$filter=$([uri]::EscapeDataString($Filter))$Extra" | Where-Object { $_ })
}

function Esc([string]$s) { $s.Replace("'", "''") }

$groupIds = @{}
function Get-GroupId([string]$Name) {
    if (-not $groupIds.ContainsKey($Name)) {
        $groupIds[$Name] = (Get-Filtered "$graph/groups" "displayName eq '$(Esc $Name)'" | Select-Object -First 1).id
    }
    $groupIds[$Name]
}

function Get-ApproverRef([string]$Tier) {
    @(@{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = (Get-GroupId $tiers[$Tier].ApproverGroup) })
}

function New-PolicyBody([string]$PackageId, $Package) {
    $t = $tiers[$Package.Tier]
    $manager = @{ "@odata.type" = "#microsoft.graph.requestorManager"; managerLevel = 1 }
    $approver = Get-ApproverRef $Package.Tier

    $stages = @(
        @{ durationBeforeAutomaticDenial = "P14D"; isApproverJustificationRequired = $true; isEscalationEnabled = $false
           primaryApprovers = @($manager); fallbackPrimaryApprovers = $approver }
        if ($t.SecondStage) {
            @{ durationBeforeAutomaticDenial = "P14D"; isApproverJustificationRequired = $true; isEscalationEnabled = $false
               primaryApprovers = $approver }
        }
    )
    $reviewSettings = if ($t.ReviewEveryMonths -gt 0) {
        @{
            isEnabled = $true; expirationBehavior = "removeAccess"; isRecommendationEnabled = $true
            isReviewerJustificationRequired = $true; isSelfReview = $false
            primaryReviewers = @($manager); fallbackReviewers = $approver
            schedule = @{
                startDateTime = $reviewStart.ToString("yyyy-MM-ddTHH:mm:ssZ")
                expiration    = @{ type = "afterDuration"; duration = "P14D" }
                recurrence    = @{
                    pattern = @{ type = "absoluteMonthly"; interval = $t.ReviewEveryMonths }
                    range   = @{ type = "noEnd"; startDate = $reviewStart.ToString("yyyy-MM-dd") }
                }
            }
        }
    } else { @{ isEnabled = $false } }   # short fixed-term grant; expiration removes access
    $reviewText = if ($t.ReviewEveryMonths -gt 0) { "reviewed every $($t.ReviewEveryMonths) months" } else { "no extension; removed automatically at expiry" }
    $who = if ($Package.AllowedGroup) { "Members of $($Package.AllowedGroup -join ' or ') request" } else { "Members request" }

    $body = @{
        displayName        = "$($Package.Name) - $($Package.Tier) request policy"
        description        = "$who; manager approval$(if ($t.SecondStage) { ' + ' + $t.ApproverGroup }); expires after $($t.ExpiryDays) days; $reviewText."
        allowedTargetScope = "allMemberUsers"
        expiration         = @{ type = "afterDuration"; duration = "P$($t.ExpiryDays)D" }
        requestorSettings  = @{
            enableTargetsToSelfAddAccess = $true; enableTargetsToSelfUpdateAccess = (-not $t.NoExtend)
            enableTargetsToSelfRemoveAccess = $true; allowCustomAssignmentSchedule = $false
            enableOnBehalfRequestorsToAddAccess = $false; enableOnBehalfRequestorsToUpdateAccess = $false
            enableOnBehalfRequestorsToRemoveAccess = $false
        }
        requestApprovalSettings = @{ isApprovalRequiredForAdd = $true; isApprovalRequiredForUpdate = $true; stages = $stages }
        reviewSettings     = $reviewSettings
        accessPackage      = @{ id = $PackageId }
    }
    # Restrict who can see and request the package to members of one group.
    if ($Package.AllowedGroup) {
        $body.allowedTargetScope     = "specificDirectoryUsers"
        $body.specificAllowedTargets = @($Package.AllowedGroup | ForEach-Object { @{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = (Get-GroupId $_); description = $_ } })
    }
    $body
}

function Set-CatalogResource {
    # Adds one group to the catalog if it isn't there yet.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][string]$Name)
    process {
        $gid = Get-GroupId $Name
        $res = Get-Filtered "$em/catalogs/$($catalog.id)/resources" "originId eq '$gid'" | Select-Object -First 1
        if (-not $res -and $PSCmdlet.ShouldProcess($Name, "Add group to catalog")) {
            Invoke-Graph POST "$em/resourceRequests" @{
                requestType = "adminAdd"
                resource    = @{ originId = $gid; originSystem = "AadGroup" }
                catalog     = @{ id = $catalog.id }
            } | Out-Null
            for ($i = 1; $i -le 10 -and -not $res; $i++) {
                Start-Sleep -Seconds 3
                $res = Get-Filtered "$em/catalogs/$($catalog.id)/resources" "originId eq '$gid'" | Select-Object -First 1
            }
            if (-not $res) { Write-Warning "'$Name' not visible in the catalog yet. Run the script again in a few minutes." }
        }
        if ($res) { $catalogResources[$Name] = $res }
    }
}

function Get-MemberRole([string]$GroupName) {
    $f = "(originSystem eq 'AadGroup' and resource/id eq '$($catalogResources[$GroupName].id)')"
    Get-Filtered "$em/catalogs/$($catalog.id)/resourceRoles" $f "&`$expand=resource" |
        Where-Object { $_.originId -like "Member_*" } | Select-Object -First 1
}

function Set-CopilotAccessPackage {
    # Creates or fixes one package: the package, its description, its groups and its tier policy.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][hashtable]$Package)
    process {
        $desc = "Grants: $($Package.Groups -join ', '). Tier: $($Package.Tier)."
        $find = { param($n) Get-Filtered "$em/accessPackages" "displayName eq '$(Esc $n)'" "&`$expand=catalog" |
            Where-Object { $_.catalog.id -eq $catalog.id } | Select-Object -First 1 }
        $pkg = & $find $Package.Name
        $renamedFrom = $null
        if (-not $pkg) {
            foreach ($old in @($Package.OldNames | Where-Object { $_ })) {
                $pkg = & $find $old
                if ($pkg) { $renamedFrom = $old; break }
            }
        }

        $notes = @(
            if ($renamedFrom) {
                if ($PSCmdlet.ShouldProcess($Package.Name, "Rename from '$renamedFrom'")) {
                    Invoke-Graph PATCH "$em/accessPackages/$($pkg.id)" @{ displayName = $Package.Name } | Out-Null
                    "Renamed from '$renamedFrom'"
                }
                else { "WhatIf: rename from '$renamedFrom'" }
            }
            if (-not $pkg) {
                if ($PSCmdlet.ShouldProcess($Package.Name, "Create access package")) {
                    $pkg = Invoke-Graph POST "$em/accessPackages" @{ displayName = $Package.Name; description = $desc; isHidden = $false; catalog = @{ id = $catalog.id } }
                    "Created"
                }
                else { "WhatIf: create" }
            }
            elseif ($pkg.description -ne $desc) {
                if ($PSCmdlet.ShouldProcess($Package.Name, "Update description")) {
                    Invoke-Graph PATCH "$em/accessPackages/$($pkg.id)" @{ description = $desc } | Out-Null
                    "Description updated"
                }
                else { "WhatIf: update description" }
            }

            if ($pkg) {
                # Groups: add missing, report extra.
                $scopes = @((Invoke-Graph GET "$em/accessPackages/$($pkg.id)?`$expand=resourceRoleScopes(`$expand=role,scope)").resourceRoleScopes)
                $wanted = @($Package.Groups | ForEach-Object { Get-GroupId $_ })
                foreach ($gname in $Package.Groups) {
                    $gid = Get-GroupId $gname
                    if ($scopes | Where-Object { $_.scope.originId -eq $gid }) { continue }
                    $role = Get-MemberRole $gname
                    if (-not $role) { "No Member role for '$gname' in the catalog"; continue }
                    if ($PSCmdlet.ShouldProcess($Package.Name, "Add '$gname' Member role")) {
                        Invoke-Graph POST "$em/accessPackages/$($pkg.id)/resourceRoleScopes" @{
                            role  = @{ id = $role.id; displayName = $role.displayName; originSystem = "AadGroup"; originId = $role.originId
                                       resource = @{ id = $catalogResources[$gname].id; originId = $gid; originSystem = "AadGroup" } }
                            scope = @{ originId = $gid; originSystem = "AadGroup" }
                        } | Out-Null
                        "Added $gname"
                    }
                    else { "WhatIf: add $gname" }
                }
                $scopes | Where-Object { $_.scope.originId -notin $wanted } |
                    ForEach-Object { "Extra group '$(if ($_.scope.displayName) { $_.scope.displayName } else { $_.scope.originId })' not in the design (not removed)" }

                # Tier policy: create if missing, report others.
                $policyName = "$($Package.Name) - $($Package.Tier) request policy"
                $policies = @((Invoke-Graph GET "$em/accessPackages/$($pkg.id)?`$expand=assignmentPolicies").assignmentPolicies)
                if (-not ($policies | Where-Object { $_.displayName -eq $policyName })) {
                    if ($PSCmdlet.ShouldProcess($Package.Name, "Create $($Package.Tier) request policy")) {
                        Invoke-Graph POST "$em/assignmentPolicies" (New-PolicyBody $pkg.id $Package) | Out-Null
                        "$($Package.Tier) policy created"
                    }
                    else { "WhatIf: create $($Package.Tier) policy" }
                }
                $policies | Where-Object { $_.displayName -ne $policyName } |
                    ForEach-Object { "Other policy '$($_.displayName)' (not removed)" }
            }
        )
        if ($pkg) { $packageIds[$Package.Name] = $pkg.id }

        $Package | Select-Object @{ n = "Package"; e = { $Package.Name } },
            @{ n = "Tier"; e = { $Package.Tier } },
            @{ n = "Result"; e = { if ($notes.Count -eq 0) { "OK" } else { $notes -join "; " } } },
            @{ n = "Id"; e = { $pkg.id } }
    }
}

function Set-IncompatiblePackage {
    # Marks two packages as incompatible, both ways.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][hashtable]$Package)
    process {
        foreach ($other in $Package.Incompatible) {
            $a = $packageIds[$Package.Name]; $b = $packageIds[$other]
            if (-not $a -or -not $b) { continue }
            foreach ($pair in @(@($a, $b), @($b, $a))) {
                $existing = Get-AllPages "$em/accessPackages/$($pair[0])/incompatibleAccessPackages"
                if ($existing | Where-Object { $_.id -eq $pair[1] }) { continue }
                if ($PSCmdlet.ShouldProcess($Package.Name, "Mark incompatible with $other")) {
                    Invoke-Graph POST "$em/accessPackages/$($pair[0])/incompatibleAccessPackages/`$ref" @{ "@odata.id" = "$em/accessPackages/$($pair[1])" } | Out-Null
                }
            }
        }
    }
}

function Set-AdminGroupReview {
    # Quarterly membership review on one admin group, covering members added outside a package.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(ValueFromPipeline = $true)][string]$Name)
    process {
        $rname = "$Name - quarterly membership review"
        $result = if (Get-Filtered "$graph/identityGovernance/accessReviews/definitions" "displayName eq '$(Esc $rname)'") { "OK" }
        elseif ($PSCmdlet.ShouldProcess($Name, "Create quarterly access review")) {
            Invoke-Graph POST "$graph/identityGovernance/accessReviews/definitions" @{
                displayName             = $rname
                descriptionForAdmins    = "Quarterly review of $Name membership (Copilot administration)."
                descriptionForReviewers = "Confirm each member still needs Copilot admin access via '$Name'."
                scope     = @{ "@odata.type" = "#microsoft.graph.accessReviewQueryScope"; query = "/groups/$(Get-GroupId $Name)/transitiveMembers"; queryType = "MicrosoftGraph" }
                reviewers = @(@{ query = "/groups/$(Get-GroupId $AdminApproverGroupName)/transitiveMembers"; queryType = "MicrosoftGraph" })
                settings  = @{
                    mailNotificationsEnabled = $true; reminderNotificationsEnabled = $true; justificationRequiredOnApproval = $true
                    defaultDecisionEnabled = $true; defaultDecision = "Deny"; instanceDurationInDays = 14
                    autoApplyDecisionsEnabled = $true; recommendationsEnabled = $true
                    recurrence = @{ pattern = @{ type = "absoluteMonthly"; interval = 3 }; range = @{ type = "noEnd"; startDate = $reviewStart.ToString("yyyy-MM-dd") } }
                }
            } | Out-Null
            "Created"
        }
        else { "WhatIf: create" }
        $Name | Select-Object @{ n = "Package"; e = { $rname } }, @{ n = "Tier"; e = { "Review" } }, @{ n = "Result"; e = { $result } }, @{ n = "Id"; e = { $null } }
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
$scopes = @(
    "EntitlementManagement.ReadWrite.All"
    "Group.Read.All"
    if ($CreateAdminGroupReviews) { "AccessReview.ReadWrite.All" }
)
# Stays on v1.0: the beta entitlement management API uses different paths
# (accessPackageCatalogs, accessPackageAssignmentPolicies), so these calls would break on beta.
$graph = "$(Connect-Cloud -Environment $Environment -Scopes $scopes)/v1.0"
$em    = "$graph/identityGovernance/entitlementManagement"

# Reviews start on the first day of next month (UTC).
$now = (Get-Date).ToUniversalTime()
$reviewStart = (Get-Date -Year $now.Year -Month $now.Month -Day 1 -Hour 15 -Minute 0 -Second 0).AddMonths(1)

# One set of tier packages per business unit, made from the SpendTier rows.
$tierRows = @($packages | Where-Object SpendTier)
$packages = @(
    $packages | Where-Object { $IncludeCodePackages -or -not $_.Code }
    foreach ($bu in $BusinessUnits) {
        $tierRows | ForEach-Object {
            $row = $_
            $p = @{ Name = $row.Name -replace '^Copilot Spend ', "Copilot Spend $bu "; SpendTier = $row.SpendTier; Tier = $row.Tier
                    Groups = @($row.Groups | ForEach-Object { $_ -replace '^Copilot Spend ', "Copilot Spend $bu " }) }
            if ($row.AllowedGroup) { $p.AllowedGroup = @($row.AllowedGroup | ForEach-Object { $_ -replace '^Copilot Spend ', "Copilot Spend $bu " }) }
            if ($row.Incompatible) { $p.Incompatible = @($row.Incompatible | ForEach-Object { $_ -replace '^Copilot Spend ', "Copilot Spend $bu " }) }
            $p
        }
    }
    if ($IncludeAdminPackages) { $adminGroups | ForEach-Object { @{ Name = $_; Tier = "Admin"; Groups = @($_) } } }
)

# One tier per person: every Bronze, Silver, Gold and Platinum package (all business units) is
# incompatible with every other. The Temporary package keeps its own list.
$fullTiers = @($packages | Where-Object { $_.SpendTier -and $_.SpendTier -ne "Platinum Temp" })
$fullTiers | ForEach-Object { $self = $_.Name; $_.Incompatible = @($fullTiers.Name | Where-Object { $_ -ne $self }) }

# 1. Every group the packages, approvers and reviews use must exist.
$needed = @(
    $packages.Groups; $packages.AllowedGroup | Where-Object { $_ }
    $tiers.Values.ApproverGroup
    if ($CreateAdminGroupReviews) { $adminGroups }
) | Sort-Object -Unique
$missing = @($needed | Where-Object { -not (Get-GroupId $_) })
if ($missing.Count -gt 0) {
    throw "These groups aren't in the tenant. Run New-CopilotGroups.ps1 first (add -IncludeCodeGroups for Code):`n  $($missing -join "`n  ")"
}

# 2. Catalog and its groups
$catalog = Get-Filtered "$em/catalogs" "displayName eq '$(Esc $CatalogName)'" | Select-Object -First 1
if (-not $catalog -and $PSCmdlet.ShouldProcess($CatalogName, "Create catalog")) {
    $catalog = Invoke-Graph POST "$em/catalogs" @{ displayName = $CatalogName; description = "Microsoft 365 Copilot feature and administration access."; isExternallyVisible = $false }
    Write-Host "Created catalog '$CatalogName'"
}
if (-not $catalog) { Write-Host "WhatIf: catalog '$CatalogName' would be created. Stopping before the steps that need it."; return }

$catalogResources = @{}
$packages.Groups | Sort-Object -Unique | Set-CatalogResource

# 3-5. Packages, incompatible pairs, admin reviews
$packageIds = @{}
$results = @(
    $packages | Set-CopilotAccessPackage
    if ($CreateAdminGroupReviews) { $adminGroups | Set-AdminGroupReview }
)
$packages | Where-Object { $_.Incompatible } | Set-IncompatiblePackage

$results | Format-Table -AutoSize -Wrap
$results | Export-Csv -Path ".\CopilotAccessPackages-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
