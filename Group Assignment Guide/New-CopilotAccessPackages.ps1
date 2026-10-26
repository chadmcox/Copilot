<#
.SYNOPSIS
    Creates Entra ID Governance access packages and access reviews for the Copilot groups
    created by New-CopilotGroups.ps1. Uses raw Microsoft Graph calls (Invoke-MgGraphRequest).

.DESCRIPTION
    Builds:
      1. A catalog ("Copilot Access Catalog") and adds every referenced Copilot group to it.
      2. One access package per feature bundle. Bundles include prerequisite groups, so a user
         who requests "Copilot + Opal Access" also gets Copilot Access and Frontier in one request.
      3. One assignment policy per package, with approval, expiration and a recurring
         access review built in, based on a tier (Standard / Elevated / Admin / Temporary).
         The 30-day Temporary Unlimited Cowork package is visible and requestable only by
         members of Copilot + Cowork Spend Limit.
      4. Incompatible-package links so a user can't hold both Limited and Unlimited spend tiers.
      5. Optional (-IncludeCodePackages): Copilot Code packages. Code is rolling out to
         Frontier tenants (MC1519871); check Code is in your spending policy wizard first.
      6. Optional (-IncludeAdminPackages): packages for the role-assignable admin groups
         (not needed if you use New-CopilotAdminPim.ps1 for admin access).
      7. Optional (-CreateAdminGroupReviews): standalone recurring access reviews on the admin
         groups, covering members added outside an access package.

    Idempotent: existing catalog, packages, resource scopes, policies and reviews (matched by
    display name) are skipped. Supports -WhatIf.

    Requirements:
      - Microsoft Entra ID Governance (or Entra ID P2) licensing for the users in scope.
      - Run New-CopilotGroups.ps1 first.
      - Identity Governance Administrator to create catalogs, packages and reviews.
      - Adding ROLE-ASSIGNABLE groups to a catalog (-IncludeAdminPackages) additionally requires
        Global Administrator or Privileged Role Administrator.
      - For admin roles, Microsoft generally recommends PIM for Groups (just-in-time
        activation) on top of, or instead of, permanent membership via access packages.

.PARAMETER ApproverGroupName
    Group whose members approve the second stage for Elevated packages and are the fallback
    reviewer when a user has no manager.

.PARAMETER AdminApproverGroupName
    Group whose members approve Admin-tier packages and review admin groups. Use a group
    that is NOT itself granted through these packages (e.g. your security team) to avoid
    people approving their own access.

.EXAMPLE
    .\New-CopilotAccessPackages.ps1 -WhatIf
    .\New-CopilotAccessPackages.ps1 -ApproverGroupName "Copilot Delegated Admin" `
        -AdminApproverGroupName "Security Operations" -IncludeAdminPackages -CreateAdminGroupReviews
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CatalogName            = "Copilot Access Catalog",
    [string]$ApproverGroupName      = "Copilot Delegated Admin",
    [string]$AdminApproverGroupName = "Copilot Delegated Admin",
    [switch]$IncludeAdminPackages,
    [switch]$CreateAdminGroupReviews,
    [switch]$IncludeCodePackages
)

#Requires -Modules Microsoft.Graph.Authentication

Connect-MgGraph -NoWelcome -Scopes @(
    "EntitlementManagement.ReadWrite.All",
    "AccessReview.ReadWrite.All",
    "Group.Read.All"
)

$graph = "https://graph.microsoft.com/v1.0"
$em    = "$graph/identityGovernance/entitlementManagement"

# First day of next month (UTC) as the start of review schedules.
$now        = (Get-Date).ToUniversalTime()
$reviewStart = (Get-Date -Year $now.Year -Month $now.Month -Day 1 -Hour 15 -Minute 0 -Second 0).AddMonths(1)
$reviewStartIso  = $reviewStart.ToString("yyyy-MM-ddTHH:mm:ssZ")
$reviewStartDate = $reviewStart.ToString("yyyy-MM-dd")

# ---------------------------------------------------------------------------
# Tiers: approval, expiration and built-in review for each assignment policy
# ---------------------------------------------------------------------------
$tiers = @{
    Standard = @{ ExpiryDays = 365; ReviewEveryMonths = 6; SecondStage = $false; ApproverGroup = $ApproverGroupName }
    Elevated = @{ ExpiryDays = 180; ReviewEveryMonths = 3; SecondStage = $true;  ApproverGroup = $ApproverGroupName }
    Admin    = @{ ExpiryDays = 90;  ReviewEveryMonths = 3; SecondStage = $true;  ApproverGroup = $AdminApproverGroupName }
    # Fixed 30-day grant: no extension, no recurring review (expiry removes access).
    Temporary = @{ ExpiryDays = 30; ReviewEveryMonths = 0; SecondStage = $true;  ApproverGroup = $ApproverGroupName; NoExtend = $true }
}

# ---------------------------------------------------------------------------
# Packages: name, tier, groups granted, optional incompatible package
# ---------------------------------------------------------------------------
$packages = @(
    @{ Name = "Copilot Access";                      Tier = "Standard"; Groups = @("Copilot Access") }
    # Cowork access comes from the spend groups (spending policies); no separate Cowork access group.
    @{ Name = "Copilot + Cowork Access (Limited)";   Tier = "Standard"; Groups = @("Copilot Access", "Copilot + Cowork Spend Limit");     Incompatible = "Copilot + Cowork Access (Unlimited)" }
    @{ Name = "Copilot + Cowork Access (Unlimited)"; Tier = "Elevated"; Groups = @("Copilot Access", "Copilot + Cowork Spend Unlimited") }
    # Only members of the Spend Limit group can see/request this; it grants only the Temp spend group.
    @{ Name = "Copilot + Cowork Access (Temporary Unlimited, 30 days)"; Tier = "Temporary"; Groups = @("Copilot + Cowork Spend Unlimited Temp"); AllowedGroup = "Copilot + Cowork Spend Limit"; Incompatible = "Copilot + Cowork Access (Unlimited)" }
    @{ Name = "Copilot + Cowork Browser Access";     Tier = "Elevated"; Groups = @("Copilot + Cowork Browser Access") }
    @{ Name = "Copilot SharePoint OneDrive Advanced Access"; Tier = "Standard"; Groups = @("Copilot Access", "Copilot SharePoint OneDrive Advanced Access") }
    @{ Name = "Copilot Work IQ API Access";          Tier = "Elevated"; Groups = @("Copilot Work IQ API Access") }
    # Managed Runtime users don't need a Copilot license, so Copilot Access isn't bundled.
    @{ Name = "Copilot Managed Runtime Access";      Tier = "Standard"; Groups = @("Copilot Managed Runtime Access") }
    # Copilot Code (rolling out to Frontier from late Oct 2026, MC1519871): -IncludeCodePackages
    @{ Name = "Copilot + Code Access (Limited)";     Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Code Spend Limit");     Incompatible = "Copilot + Code Access (Unlimited)"; Code = $true }
    @{ Name = "Copilot + Code Access (Unlimited)";   Tier = "Elevated"; Groups = @("Copilot Access", "Copilot Frontier Access", "Copilot + Code Spend Unlimited"); Code = $true }
    @{ Name = "Copilot + Code Secure Execution Exemption"; Tier = "Admin"; Groups = @("Copilot + Code Secure Execution Exemption"); Code = $true }
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

$adminGroups = @(
    "Copilot Delegated Admin", "Copilot Agent Management Admin", "Copilot Agent Registry Admin", "Copilot AI Reader",
    "Copilot Billing Admin", "Copilot Cost Reader", "Copilot Agent ID Admin", "Copilot Agent ID Developers",
    "Copilot Office Apps Admin", "Copilot Compliance Admin", "Copilot Teams Admin",
    "Copilot SharePoint Admin", "Copilot Studio Environment Admin", "Copilot Plugin Approvers"
)

if (-not $IncludeCodePackages) { $packages = @($packages | Where-Object { -not $_.Code }) }

if ($IncludeAdminPackages) {
    foreach ($ag in $adminGroups) {
        $packages += @{ Name = $ag; Tier = "Admin"; Groups = @($ag) }
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Invoke-Graph([string]$Method, [string]$Uri, $Body) {
    $p = @{ Method = $Method; Uri = $Uri; OutputType = "PSObject" }
    if ($null -ne $Body) {
        $p.Body = ($Body | ConvertTo-Json -Depth 20)
        $p.ContentType = "application/json"
    }
    Invoke-MgGraphRequest @p
}

function Get-Filtered([string]$BaseUri, [string]$Filter, [string]$Extra = "") {
    $uri = "$BaseUri`?`$filter=$([uri]::EscapeDataString($Filter))$Extra"
    (Invoke-Graph GET $uri).value
}

function Esc([string]$s) { $s.Replace("'", "''") }

$groupCache = @{}
function Get-GroupId([string]$Name) {
    if (-not $groupCache.ContainsKey($Name)) {
        $g = Get-Filtered "$graph/groups" "displayName eq '$(Esc $Name)'" | Select-Object -First 1
        if (-not $g) { throw "Group '$Name' not found. Run New-CopilotGroups.ps1 first." }
        $groupCache[$Name] = $g.id
    }
    $groupCache[$Name]
}

function New-ApprovalStage([string]$Tier) {
    $t = $tiers[$Tier]
    $fallback = @(@{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = (Get-GroupId $t.ApproverGroup) })

    $stages = @(@{
        durationBeforeAutomaticDenial   = "P14D"
        isApproverJustificationRequired = $true
        isEscalationEnabled             = $false
        primaryApprovers                = @(@{ "@odata.type" = "#microsoft.graph.requestorManager"; managerLevel = 1 })
        fallbackPrimaryApprovers        = $fallback
    })
    if ($t.SecondStage) {
        $stages += @{
            durationBeforeAutomaticDenial   = "P14D"
            isApproverJustificationRequired = $true
            isEscalationEnabled             = $false
            primaryApprovers                = $fallback
        }
    }
    $stages
}

function New-PolicyBody([string]$PackageId, [string]$PackageName, [string]$Tier, [string]$AllowedGroup) {
    $t = $tiers[$Tier]
    $fallbackReviewer = @(@{ "@odata.type" = "#microsoft.graph.groupMembers"; groupId = (Get-GroupId $t.ApproverGroup) })

    $reviewSettings = if ($t.ReviewEveryMonths -gt 0) {
        @{
            isEnabled                       = $true
            expirationBehavior              = "removeAccess"
            isRecommendationEnabled         = $true
            isReviewerJustificationRequired = $true
            isSelfReview                    = $false
            primaryReviewers                = @(@{ "@odata.type" = "#microsoft.graph.requestorManager"; managerLevel = 1 })
            fallbackReviewers               = $fallbackReviewer
            schedule = @{
                startDateTime = $reviewStartIso
                expiration    = @{ type = "afterDuration"; duration = "P14D" }
                recurrence    = @{
                    pattern = @{ type = "absoluteMonthly"; interval = $t.ReviewEveryMonths }
                    range   = @{ type = "noEnd"; startDate = $reviewStartDate }
                }
            }
        }
    } else {
        @{ isEnabled = $false }   # short fixed-term grant; expiration removes access
    }
    $reviewText = if ($t.ReviewEveryMonths -gt 0) { "reviewed every $($t.ReviewEveryMonths) months" } else { "no extension; removed automatically at expiry" }

    $who = if ($AllowedGroup) { "Members of $AllowedGroup request" } else { "Members request" }

    $body = @{
        displayName       = "$PackageName - $Tier request policy"
        description       = "$who; manager approval$(if ($t.SecondStage) { ' + ' + $t.ApproverGroup }); expires after $($t.ExpiryDays) days; $reviewText."
        allowedTargetScope = "allMemberUsers"
        expiration        = @{ type = "afterDuration"; duration = "P$($t.ExpiryDays)D" }
        requestorSettings = @{
            enableTargetsToSelfAddAccess        = $true
            enableTargetsToSelfUpdateAccess     = (-not $t.NoExtend)
            enableTargetsToSelfRemoveAccess     = $true
            allowCustomAssignmentSchedule       = $false
            enableOnBehalfRequestorsToAddAccess    = $false
            enableOnBehalfRequestorsToUpdateAccess = $false
            enableOnBehalfRequestorsToRemoveAccess = $false
        }
        requestApprovalSettings = @{
            isApprovalRequiredForAdd    = $true
            isApprovalRequiredForUpdate = $true
            stages                      = @(New-ApprovalStage $Tier)
        }
        reviewSettings = $reviewSettings
        accessPackage = @{ id = $PackageId }
    }

    # Restrict who can see and request the package to members of one group.
    if ($AllowedGroup) {
        $body.allowedTargetScope     = "specificDirectoryUsers"
        $body.specificAllowedTargets = @(@{
            "@odata.type" = "#microsoft.graph.groupMembers"
            groupId       = (Get-GroupId $AllowedGroup)
            description   = $AllowedGroup
        })
    }
    $body
}

# ---------------------------------------------------------------------------
# 1. Catalog
# ---------------------------------------------------------------------------
$catalog = Get-Filtered "$em/catalogs" "displayName eq '$(Esc $CatalogName)'" | Select-Object -First 1
if (-not $catalog -and $PSCmdlet.ShouldProcess($CatalogName, "Create catalog")) {
    $catalog = Invoke-Graph POST "$em/catalogs" @{
        displayName         = $CatalogName
        description         = "Microsoft 365 Copilot feature and administration access."
        isExternallyVisible = $false
    }
    Write-Host "Created catalog '$CatalogName'"
}
if (-not $catalog) { Write-Host "WhatIf: stopping before catalog-dependent steps."; return }

# ---------------------------------------------------------------------------
# 2. Add every referenced group to the catalog
# ---------------------------------------------------------------------------
$allGroupNames = $packages.Groups | Sort-Object -Unique
$catalogResources = @{}

foreach ($name in $allGroupNames) {
    $gid = Get-GroupId $name
    $res = Get-Filtered "$em/catalogs/$($catalog.id)/resources" "originId eq '$gid'" | Select-Object -First 1

    if (-not $res -and $PSCmdlet.ShouldProcess($name, "Add group to catalog")) {
        Invoke-Graph POST "$em/resourceRequests" @{
            requestType = "adminAdd"
            resource    = @{ originId = $gid; originSystem = "AadGroup" }
            catalog     = @{ id = $catalog.id }
        } | Out-Null

        for ($i = 1; $i -le 10 -and -not $res; $i++) {
            Start-Sleep -Seconds 3
            $res = Get-Filtered "$em/catalogs/$($catalog.id)/resources" "originId eq '$gid'" | Select-Object -First 1
        }
        if ($res) { Write-Host "Added '$name' to catalog" } else { Write-Warning "'$name' not visible in catalog yet." }
    }
    if ($res) { $catalogResources[$name] = $res }
}

function Get-MemberRole([string]$GroupName) {
    $res = $catalogResources[$GroupName]
    $f = "(originSystem eq 'AadGroup' and resource/id eq '$($res.id)')"
    Get-Filtered "$em/catalogs/$($catalog.id)/resourceRoles" $f "&`$expand=resource" |
        Where-Object { $_.originId -like "Member_*" } | Select-Object -First 1
}

# ---------------------------------------------------------------------------
# 3-4. Packages, resource scopes, policies
# ---------------------------------------------------------------------------
$packageIds = @{}
$results = @()

foreach ($p in $packages) {
    $pkg = Get-Filtered "$em/accessPackages" "displayName eq '$(Esc $p.Name)'" "&`$expand=catalog" |
        Where-Object { $_.catalog.id -eq $catalog.id } | Select-Object -First 1
    $status = "Exists"

    if (-not $pkg) {
        if ($PSCmdlet.ShouldProcess($p.Name, "Create access package")) {
            $pkg = Invoke-Graph POST "$em/accessPackages" @{
                displayName = $p.Name
                description = "Grants: $($p.Groups -join ', '). Tier: $($p.Tier)."
                isHidden    = $false
                catalog     = @{ id = $catalog.id }
            }
            $status = "Created"
        }
        else { $results += [pscustomobject]@{ Package = $p.Name; Tier = $p.Tier; Status = "WhatIf" }; continue }
    }
    $packageIds[$p.Name] = $pkg.id

    # Resource role scopes (group Member role)
    $existingScopes = (Invoke-Graph GET "$em/accessPackages/$($pkg.id)?`$expand=resourceRoleScopes(`$expand=role,scope)").resourceRoleScopes
    foreach ($gname in $p.Groups) {
        $gid = Get-GroupId $gname
        if ($existingScopes | Where-Object { $_.scope.originId -eq $gid }) { continue }
        $role = Get-MemberRole $gname
        if (-not $role) { Write-Warning "No Member role found for '$gname'; skipped."; continue }

        if ($PSCmdlet.ShouldProcess("$($p.Name)", "Add '$gname' Member role")) {
            Invoke-Graph POST "$em/accessPackages/$($pkg.id)/resourceRoleScopes" @{
                role  = @{
                    id           = $role.id
                    displayName  = $role.displayName
                    originSystem = "AadGroup"
                    originId     = $role.originId
                    resource     = @{ id = $catalogResources[$gname].id; originId = $gid; originSystem = "AadGroup" }
                }
                scope = @{ originId = $gid; originSystem = "AadGroup" }
            } | Out-Null
        }
    }

    # Assignment policy
    $policyName = "$($p.Name) - $($p.Tier) request policy"
    $existingPolicies = (Invoke-Graph GET "$em/accessPackages/$($pkg.id)?`$expand=assignmentPolicies").assignmentPolicies
    if (-not ($existingPolicies | Where-Object { $_.displayName -eq $policyName }) -and
        $PSCmdlet.ShouldProcess($p.Name, "Create assignment policy ($($p.Tier))")) {
        Invoke-Graph POST "$em/assignmentPolicies" (New-PolicyBody $pkg.id $p.Name $p.Tier $p.AllowedGroup) | Out-Null
    }

    $results += [pscustomobject]@{ Package = $p.Name; Tier = $p.Tier; Status = $status; Id = $pkg.id }
}

# Incompatible packages (Limited vs Unlimited spend tiers), both directions
foreach ($p in $packages | Where-Object { $_.Incompatible }) {
    $a = $packageIds[$p.Name]; $b = $packageIds[$p.Incompatible]
    if (-not $a -or -not $b) { continue }
    foreach ($pair in @(@($a, $b), @($b, $a))) {
        $existing = (Invoke-Graph GET "$em/accessPackages/$($pair[0])/incompatibleAccessPackages").value
        if ($existing | Where-Object { $_.id -eq $pair[1] }) { continue }
        if ($PSCmdlet.ShouldProcess($p.Name, "Mark incompatible with $($p.Incompatible)")) {
            Invoke-Graph POST "$em/accessPackages/$($pair[0])/incompatibleAccessPackages/`$ref" @{
                "@odata.id" = "$em/accessPackages/$($pair[1])"
            } | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# 5. Standalone access reviews on admin groups (catch direct assignments)
# ---------------------------------------------------------------------------
if ($CreateAdminGroupReviews) {
    $reviewerGroupId = Get-GroupId $AdminApproverGroupName
    foreach ($ag in $adminGroups) {
        $gid   = Get-GroupId $ag
        $rname = "$ag - quarterly membership review"
        $existing = Get-Filtered "$graph/identityGovernance/accessReviews/definitions" "displayName eq '$(Esc $rname)'"
        if ($existing) { continue }

        if ($PSCmdlet.ShouldProcess($ag, "Create quarterly access review")) {
            Invoke-Graph POST "$graph/identityGovernance/accessReviews/definitions" @{
                displayName             = $rname
                descriptionForAdmins    = "Quarterly review of $ag membership (Copilot administration)."
                descriptionForReviewers = "Confirm each member still needs Copilot admin access via '$ag'."
                scope = @{
                    "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
                    query         = "/groups/$gid/transitiveMembers"
                    queryType     = "MicrosoftGraph"
                }
                reviewers = @(@{ query = "/groups/$reviewerGroupId/transitiveMembers"; queryType = "MicrosoftGraph" })
                settings = @{
                    mailNotificationsEnabled        = $true
                    reminderNotificationsEnabled    = $true
                    justificationRequiredOnApproval = $true
                    defaultDecisionEnabled          = $true
                    defaultDecision                 = "Deny"
                    instanceDurationInDays          = 14
                    autoApplyDecisionsEnabled       = $true
                    recommendationsEnabled          = $true
                    recurrence = @{
                        pattern = @{ type = "absoluteMonthly"; interval = 3 }
                        range   = @{ type = "noEnd"; startDate = $reviewStartDate }
                    }
                }
            } | Out-Null
            Write-Host "Created review '$rname'"
        }
    }
}

$results | Format-Table -AutoSize
$results | Export-Csv -Path ".\CopilotAccessPackages-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation
