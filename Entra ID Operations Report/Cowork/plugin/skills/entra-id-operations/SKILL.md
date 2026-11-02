---
name: entra-id-operations
description: |
  Read-only Microsoft Entra ID operations report based on Microsoft's Entra operations reference
  guide: identity and access management (sync, licensing, All users groups), authentication
  (MFA, passwordless, password protection, app credentials, Conditional Access, legacy auth,
  consent grants, user settings), governance (emergency access, privileged roles and PIM, access
  reviews, guests, entitlement management) and operations (recommendations, health alerts,
  notifications). Reads the tenant through the Microsoft MCP Server for Enterprise, scores each
  area and builds an HTML report. Use when the user asks to "run the Entra ID operations report",
  "check Entra against the operations guide", "run the Entra ops guide checks", "how healthy is
  my Entra tenant", or attaches the findings CSV exported from an earlier report.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Entra ID operations report

Check a Microsoft Entra tenant against Microsoft's
[Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro),
then say how to fix each finding. **Read-only.** Never create, change, disable or delete anything
in the tenant. Never send an email or Teams message unless the user asks and approves it.

## If you're running in GitHub Copilot (VS Code or Copilot CLI)

Everything below works the same, with these differences:

- The Enterprise MCP tools (`microsoft_graph_get` and the rest) show up only if the user added the
  **Microsoft MCP Server for Enterprise** server in VS Code, in Agent mode. If they're missing, say
  so and point the user to the GitHub Copilot readme in the Copilot repo. Don't fall back to
  writing a Graph script.
- The Copilot CLI doesn't have the Enterprise MCP sign-in set up, so in the CLI you can only
  explain a findings CSV the user exported from an earlier report (Step 6, way B).
- There's no OneDrive output folder. Save the report in the folder the user names, or the open
  workspace folder, and remind the user not to commit it: it describes the tenant's weak spots.
- VS Code's browser tools stand in for the Cowork browser for the manual checks.

## Step 1: Test the connection

**Call the Enterprise MCP connector's `microsoft_graph_get` tool directly, one call per request.
Never write or run a script to call Microsoft Graph.** Scripts run in a sandbox that isn't signed
in to the tenant, so every read from a script fails. Scripts are fine afterwards, for scoring the
data you already read or writing the report file.

Start with `GET /beta/organization?$select=id,onPremisesSyncEnabled,onPremisesLastSyncDateTime`.
If it fails, stop and tell the user the connector can't read the tenant, with the error.

Then read the licenses once: `GET /beta/subscribedSkus?$select=skuPartNumber,capabilityStatus,servicePlans`.
rules.md says which checks need P1, P2 or ID Governance.

Ask the user which accounts are the **emergency access (break glass) accounts**, unless they already said.
If they don't know or don't answer, carry on and use the guess in rules.md.

## Step 2: Read the tenant

Use `$select`, and follow every `@odata.nextLink` with another `microsoft_graph_get` call. Only one
`$expand` is allowed per call. The server allows about 100 calls a minute, so read collections
rather than one object at a time where you can. Calls with `$count=true` or `$filter` on
collections like `onPremisesProvisioningErrors` need the header `ConsistencyLevel: eventual`.

| What | Graph call |
| --- | --- |
| Sync status, password hash sync and notification addresses | `GET /beta/organization?$select=onPremisesSyncEnabled,onPremisesLastSyncDateTime,onPremisesLastPasswordSyncDateTime,technicalNotificationMails` (count the addresses; don't report them). `onPremisesLastPasswordSyncDateTime` is beta only |
| Sync errors | `GET /beta/users?$filter=onPremisesProvisioningErrors/any(e:e/category eq 'PropertyConflict')&$count=true&$select=id,onPremisesProvisioningErrors` with `ConsistencyLevel: eventual`. Use `occurredDateTime` for the 100-day rule |
| License errors | `GET /beta/groups?$filter=hasMembersWithLicenseErrors eq true&$select=id,displayName` |
| Direct license assignments | `GET /beta/users?$filter=assignedLicenses/$count ne 0&$count=true&$select=id,licenseAssignmentStates&$top=999` with `ConsistencyLevel: eventual`. Stop after 20 pages in a large tenant and say the count is from a sample |
| Dynamic groups | `GET /beta/groups?$filter=groupTypes/any(g:g eq 'DynamicMembership')&$select=id,displayName,membershipRule&$top=999` |
| Domains | `GET /beta/domains?$select=id,authenticationType,passwordValidityPeriodInDays,isVerified` |
| Security defaults | `GET /beta/policies/identitySecurityDefaultsEnforcementPolicy?$select=isEnabled` |
| Authentication methods policy | `GET /beta/policies/authenticationMethodsPolicy` (no `$select`; it isn't allowed here) |
| Password protection and group creation | `GET /beta/settings?$select=displayName,values` (look for **Password Rule Settings** and **Group.Unified**) |
| Admins' registration | `GET /beta/reports/authenticationMethods/userRegistrationDetails?$filter=isAdmin eq true&$select=id,isMfaRegistered,isPasswordlessCapable,methodsRegistered` |
| Per-user MFA for an admin | `GET /beta/users/{id}/authentication/requirements` (only for privileged users, at most 50) |
| Conditional Access | `GET /beta/identity/conditionalAccess/policies?$select=id,displayName,state,conditions,grantControls` |
| Named locations | `GET /beta/identity/conditionalAccess/namedLocations?$select=displayName,isTrusted` |
| Risky users (P2) | `GET /beta/identityProtection/riskyUsers?$filter=riskState eq 'atRisk' and riskLevel eq 'high'&$select=id` |
| Legacy sign-ins (P1) | `GET /beta/auditLogs/signIns?$filter=createdDateTime ge {30 days ago, ISO 8601} and status/errorCode eq 0 and (clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'POP3' or clientAppUsed eq 'Authenticated SMTP' or clientAppUsed eq 'Other clients')&$select=clientAppUsed&$top=999`. Read at most 5 pages and say "at least" when there's more |
| App registrations and their credentials | `GET /beta/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials&$top=999` |
| Service principal secrets | `GET /beta/servicePrincipals?$select=id,appId,displayName,appOwnerOrganizationId,publisherName,passwordCredentials&$top=999` (keep only those with a password credential) |
| User consent and user settings | `GET /beta/policies/authorizationPolicy?$select=defaultUserRolePermissions,allowInvitesFrom,permissionGrantPolicyIdsAssignedToDefaultUserRole` |
| Admin consent workflow | `GET /beta/policies/adminConsentRequestPolicy?$select=isEnabled` |
| Delegated grants | `GET /beta/oauth2PermissionGrants?$select=clientId,consentType,resourceId,scope`, then for each client not yet seen `GET /beta/servicePrincipals/{clientId}?$select=displayName,appOwnerOrganizationId,publisherName` |
| Graph application permissions | `GET /beta/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?$select=id,appOwnerOrganizationId,appRoles` once (its `appOwnerOrganizationId` is Microsoft's, for spotting Microsoft apps), then `GET /beta/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')/appRoleAssignedTo?$select=principalId,principalDisplayName,principalType,appRoleId&$top=999` and match `appRoleId` to `appRoles[].id` → `value` |
| Privileged roles | `GET /beta/roleManagement/directory/roleDefinitions?$filter=isPrivileged eq true&$select=id,displayName` (no `$top` under 20) |
| Active role assignments | `GET /beta/roleManagement/directory/roleAssignmentSchedules?$filter=assignmentType eq 'Assigned'&$select=principalId,roleDefinitionId,memberType,scheduleInfo&$expand=principal($select=id,userType,onPremisesSyncEnabled)`. Without PIM (P2), use `GET /beta/roleManagement/directory/roleAssignments?$select=principalId,roleDefinitionId&$expand=principal($select=id,userType,onPremisesSyncEnabled)`: every assignment there is permanent |
| Eligible role assignments | `GET /beta/roleManagement/directory/roleEligibilitySchedules?$select=principalId,roleDefinitionId,memberType&$expand=principal($select=id,userType,onPremisesSyncEnabled)` |
| Privileged users' licenses | `GET /beta/users/{id}?$select=id,assignedPlans` for each privileged user (Exchange is `service` exchange, `capabilityStatus` Enabled) |
| PIM settings for a role | `GET /beta/policies/roleManagementPolicyAssignments?$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '{role id}'&$expand=policy($expand=rules)`, for Global Administrator (`62e90394-69f5-4237-9190-012177145e10`) and Privileged Role Administrator (`e8611ab8-c189-46e8-94e1-60213ab1f814`) |
| Access reviews | `GET /beta/identityGovernance/accessReviews/definitions?$select=id,displayName,status,scope,instanceEnumerationScope` |
| Guests | `GET /beta/users?$filter=userType eq 'Guest'&$select=id,createdDateTime,signInActivity&$top=999`. No `signInActivity` means no sign-in recorded |
| Access packages | `GET /beta/identityGovernance/entitlementManagement/accessPackages?$select=id&$top=1` |
| Entra recommendations | `GET /beta/directory/recommendations?$filter=status eq 'active'&$select=displayName,priority,featureAreas,impactType,currentScore,maxScore,actionSteps` |
| Entra Health alerts | `GET /beta/reports/healthMonitoring/alerts?$filter=state eq 'active'&$select=alertType,scenario,state,createdDateTime` |

**Not readable through the Enterprise MCP** (tested: the MCP returns 403 "not authorized by the
available scopes", because no MCP scope matches the Graph permission these APIs need):

- Entra Connect sync features and settings (`/directory/onPremisesSynchronization`, which needs
  `OnPremDirectorySynchronization.Read.All`). Outside the MCP it's also delegated only and
  Global Administrator is the only supported role, so a reader can't read it anyway. Password
  hash sync is still checked, from `organization.onPremisesLastPasswordSyncDateTime`; the other
  feature flags go on the manual checklist.
- Microsoft Secure Score (`/security/secureScores`, which needs `SecurityEvents.Read.All`). The
  API exists and works with Graph PowerShell or an app that has that permission, but not here.
  Use Entra recommendations instead: they're the items behind the Identity Secure Score, with
  `currentScore` and `maxScore` for each.
- Pass-through authentication agents and private network connectors
  (`/onPremisesPublishingProfiles/...`), and the tenant-wide registration counts
  (`usersRegisteredByFeature`).

They go on the manual checklist, or are covered by recommendations.

If a call returns 403, say which part was skipped and carry on. The person running the report
should be an activated member of **Copilot Entra ID Operations Reader** (Global Reader, through
PIM). If many calls return 403, ask whether they activated the group in PIM (My roles > Groups)
before going on. A 403 that mentions a license (for example on sign-in logs or risky users) means
the tenant doesn't have P1 or P2: skip those checks and say why.

**Don't put people's names, UPNs or email addresses in the results** unless the user asks. Counts
are enough ("4 admins aren't registered for MFA"). Apps, policies, groups and roles can be named.

## Step 3: Apply the rules

Use **references/rules.md**. Each finding has an Area, Item, Topic, Severity (High, Medium, Low,
Info), Check (what's wrong), Fix and Reference. The Reference is the guide section from the
rules table, written like "Ops guide: Authentication > Consent grants".

## Step 4: Score and funnel

Score each area the way rules.md says (each check is an item; passing checks score 100). Build the
well-protected admins funnel from rules.md.

## Step 5: Manual checks

List the manual checks from rules.md, grouped by area, including **Assign owners to key tasks**. If
the browser is available and the user allows it, open each admin center page, read the setting and
say what it's set to. Read only: never select Save, Delete or any button that changes a setting.

## Step 6: Report

The main result is an **HTML report** built from **assets/report-template.html**, a companion file
of this skill. **Always use that template. Never write your own report layout, Markdown report or
document instead**, even a short one. If you can't read the template, say so and stop.

1. Copy assets/report-template.html to the output folder as **Entra ID Operations Report.html**.
2. Replace only the JSON inside `<script id="report-data" type="application/json">` with this run's
   data. Don't change anything else in the file. Fill it like this:
   - `title`: "Entra ID Operations Report"; `generated`: the date and time; `source`: "Copilot
     Cowork" (or "GitHub Copilot"); `subjectLabel`: "Area"; `areaLabel`: "Topic"; `sample`: false.
   - `funnelTitle`: "Well-protected admins: {percent}%", and `funnel`: the five steps, each
     `{ "label", "count", "note" }`.
   - `scorecard`: one entry per area (Identity and access, Authentication, Governance,
     Operations): `name`, `score`, `rating`, `high`, `medium`, `low`, `info`, and `detail`
     ("14 checks run, 2 skipped").
   - `findings`: one entry per finding: `subject` (the area), `area` (the topic), `severity`,
     `target` (the item), `check`, and `fix` with the reference in brackets at the end, for
     example "Block legacy authentication with Conditional Access [Ops guide: Authentication > Legacy authentication]".
   - `fixFirst`: the three changes that lower the most risk, in plain words.
   - `manualChecks`: the manual checks from rules.md, with what you saw if you read them in the browser.
   - `graphCalls`: every Graph call you ran, without object IDs.
   - `notes`: start with "Based on Microsoft's Microsoft Entra operations reference guide. Severities
     and scores are the Copilot repo's choices, not Microsoft's." Then the checks skipped and why
     (403, no license), and anything else the user should know.
   - `prompt`: the prompt the user ran, so they can run it again.
   It must stay valid JSON: escape quotes and backslashes in names.
3. Use a script to write the file if that's easiest. Only Graph calls must not come from scripts.
4. Open the report in the session so the user sees it, and give a short summary in chat: the score
   per area, the well-protected admins %, how many High and Medium findings, and the three fixes.

If the user attached a findings CSV exported from an earlier report instead (way B), and the
Enterprise MCP connector isn't available, skip Steps 1 to 5: explain the findings, give the top 3
fixes, and rebuild the report from them (score each area from its findings as in rules.md, and say
the scores only count the checks that raised findings).

Use plain, short sentences. Treat the results as sensitive: they describe the tenant's weak spots.
Keep them in the user's session and output folder only.

## Follow-ups the user may ask for

- "Draft a note to the app owners about their secrets." Draft it; don't send it until the user approves.
- "Which Conditional Access gaps should I close first?" List the Conditional Access, legacy authentication and risk findings, High first.
- "Show only Governance" or "only High." The report's filters already do this; say so.
- "Make me a spreadsheet." Build an Excel workbook with Scorecard and Findings sheets from the same data.
- "Compare with last month's findings CSV." List new, fixed and unchanged findings.
- "Who owns each task?" Turn the Assign owners to key tasks list into a table with an Owner column for the user to fill in.
