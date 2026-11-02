---
name: entra-id-security-review
description: |
  Read-only Microsoft Entra ID security review against the CISA SCuBA Entra ID baseline, the
  CIS Microsoft 365 Foundations Benchmark (Entra sections), the Attack and Defense Playbook for
  Microsoft Entra, and Microsoft, NSA and Mandiant incident guidance (Solorigate, DEV-0537, APT29,
  consent phishing, on-premises compromise). Checks privileged access, authentication methods,
  Conditional Access and risk, app consent and credentials, hybrid and federation, guests and
  cross-tenant settings, tenant and device settings, and recent risky changes in the audit log.
  Reads the tenant through the Microsoft MCP Server for Enterprise, scores each area, maps every
  finding to the attack it helps stop, and builds an HTML report. Use when the user asks to "run
  the Entra ID security review", "check Entra against CISA SCuBA or CIS", "how exposed is my
  Entra tenant to Solorigate, consent phishing or AiTM", "Entra attack and defense review", or
  attaches the findings CSV exported from an earlier review.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Entra ID security review

Check a Microsoft Entra tenant against the CISA SCuBA Entra ID baseline, the CIS Microsoft 365
Foundations Benchmark, the Attack and Defense Playbook for Microsoft Entra and Microsoft's incident
guidance, then say how to fix each finding and which attack it helps stop. **Read-only.** Never
create, change, disable or delete anything in the tenant. Never send an email or Teams message
unless the user asks and approves it.

## If you're running in GitHub Copilot (VS Code or Copilot CLI)

Everything below works the same, with these differences:

- The Enterprise MCP tools (`microsoft_graph_get` and the rest) show up only if the user added the
  **Microsoft MCP Server for Enterprise** server in VS Code, in Agent mode. If they're missing, say
  so and point the user to the GitHub Copilot readme in the Copilot repo. Don't fall back to
  writing a Graph script.
- The Copilot CLI doesn't have the Enterprise MCP sign-in set up, so in the CLI you can only
  explain a findings CSV the user exported from an earlier review (Step 6, way B).
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

Ask the user which accounts are the **emergency access (break glass) accounts**, unless they already
said, and whether any recent changes (federation, new apps, role changes) were planned. If they
don't know or don't answer, carry on and use the guess in rules.md.

## Step 2: Read the tenant

Use `$select`, and follow every `@odata.nextLink` with another `microsoft_graph_get` call. Only one
`$expand` is allowed per call. The server allows about 100 calls a minute, so read collections
rather than one object at a time where you can. Calls with `$count=true` need the header
`ConsistencyLevel: eventual`. Use literal ISO 8601 dates for the lookback (today minus 30 days).

| What | Graph call |
| --- | --- |
| Domains | `GET /beta/domains?$select=id,authenticationType,passwordValidityPeriodInDays,isVerified` |
| Security defaults | `GET /beta/policies/identitySecurityDefaultsEnforcementPolicy?$select=isEnabled` |
| Authorization policy (user, consent and guest settings) | `GET /beta/policies/authorizationPolicy?$select=allowInvitesFrom,guestUserRoleId,allowedToSignUpEmailBasedSubscriptions,allowEmailVerifiedUsersToJoinOrganization,allowUserConsentForRiskyApps,defaultUserRolePermissions,permissionGrantPolicyIdsAssignedToDefaultUserRole` |
| Directory settings (password rules, consent policy, group creation) | `GET /beta/settings?$select=displayName,values` (look for **Password Rule Settings**, **Consent Policy Settings** and **Group.Unified**) |
| Admin consent workflow | `GET /beta/policies/adminConsentRequestPolicy?$select=isEnabled,notifyReviewers,reviewers` |
| App management policies | `GET /beta/policies/defaultAppManagementPolicy` and `GET /beta/policies/appManagementPolicies?$select=id,displayName,isEnabled,restrictions` |
| Authentication methods policy | `GET /beta/policies/authenticationMethodsPolicy` (no `$select`). It has the method states, `policyMigrationState`, `systemCredentialPreferences` and `reportSuspiciousActivitySettings` |
| Microsoft Authenticator, FIDO2 and TAP settings | `GET /beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/MicrosoftAuthenticator`, then `.../Fido2` and `.../TemporaryAccessPass`. The full policy above doesn't include their `featureSettings` |
| Authentication strengths | `GET /beta/policies/authenticationStrengthPolicies?$select=id,displayName,policyType,allowedCombinations` |
| Conditional Access | `GET /beta/identity/conditionalAccess/policies?$select=id,displayName,state,conditions,grantControls,sessionControls`. `conditions.authenticationFlows` and `agentIdRiskLevels` appear only when they're set |
| Named locations | `GET /beta/identity/conditionalAccess/namedLocations?$select=id,displayName,isTrusted` |
| Device registration policy | `GET /beta/policies/deviceRegistrationPolicy` |
| Cross-tenant access | `GET /beta/policies/crossTenantAccessPolicy/default` and `GET /beta/policies/crossTenantAccessPolicy/partners?$select=tenantId,inboundTrust,isServiceProvider,identitySynchronization` |
| Role definitions | `GET /beta/roleManagement/directory/roleDefinitions?$filter=isPrivileged eq true&$select=id,displayName` (add Exchange and SharePoint Administrator from rules.md) |
| Active role assignments | `GET /beta/roleManagement/directory/roleAssignmentSchedules?$filter=assignmentType eq 'Assigned'&$select=principalId,roleDefinitionId,memberType,scheduleInfo&$expand=principal($select=id,userType,onPremisesSyncEnabled,onPremisesImmutableId)`. Without P2, use `GET /beta/roleManagement/directory/roleAssignments?$select=principalId,roleDefinitionId&$expand=principal($select=id,userType,onPremisesSyncEnabled,onPremisesImmutableId)`: every assignment there is permanent |
| Eligible role assignments | `GET /beta/roleManagement/directory/roleEligibilitySchedules?$select=principalId,roleDefinitionId,memberType&$expand=principal($select=id,userType,onPremisesSyncEnabled,onPremisesImmutableId)` |
| Sync account role | `GET /beta/roleManagement/directory/roleAssignments?$filter=roleDefinitionId eq 'd29b2b05-8046-44ba-8758-1e26182fcf32'&$select=principalId&$expand=principal($select=id,displayName)` |
| Admins' registration | `GET /beta/reports/authenticationMethods/userRegistrationDetails?$filter=isAdmin eq true&$select=id,isMfaRegistered,isPasswordlessCapable,methodsRegistered` |
| Members' MFA capability (P1) | `GET /beta/reports/authenticationMethods/userRegistrationDetails?$filter=userType eq 'member'&$select=id,isMfaCapable&$top=999`. Stop after 20 pages in a large tenant and say the count is from a sample |
| Privileged users' licenses | `GET /beta/users/{id}?$select=id,assignedPlans` for each highly privileged user (Exchange, SharePoint or Teams with `capabilityStatus` Enabled means a day-to-day account) |
| Per-user MFA for an admin | `GET /beta/users/{id}/authentication/requirements` (only for highly privileged users, at most 50) |
| Owners of role-assignable groups | `GET /beta/groups?$filter=isAssignableToRole eq true&$select=id,displayName&$expand=owners($select=id)` |
| PIM settings for a role | `GET /beta/policies/roleManagementPolicyAssignments?$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '{role id}'&$expand=policy($expand=rules)`, for each highly privileged role. Read the approval, enablement, authentication context and notification rules |
| Risky users (P2) | `GET /beta/identityProtection/riskyUsers?$filter=riskState eq 'atRisk' and riskLevel eq 'high'&$select=id` |
| Risky service principals (P2, Workload ID) | `GET /beta/identityProtection/riskyServicePrincipals?$filter=riskState eq 'atRisk'&$select=id,displayName,riskLevel` |
| Legacy sign-ins (P1) | `GET /beta/auditLogs/signIns?$filter=createdDateTime ge {30 days ago} and status/errorCode eq 0 and (clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'POP3' or clientAppUsed eq 'Authenticated SMTP' or clientAppUsed eq 'Other clients')&$select=clientAppUsed&$top=999`. Read at most 5 pages and say "at least" when there's more |
| App registrations | `GET /beta/applications?$select=id,appId,displayName,signInAudience,passwordCredentials,keyCredentials,servicePrincipalLockConfiguration,web,spa,publicClient&$expand=owners($select=id)&$top=999` |
| Service principals | `GET /beta/servicePrincipals?$filter=servicePrincipalType eq 'Application'&$select=id,appId,displayName,appOwnerOrganizationId,publisherName,passwordCredentials,keyCredentials&$expand=owners($select=id)&$top=999` |
| Delegated grants | `GET /beta/oauth2PermissionGrants?$select=clientId,consentType,principalId,resourceId,scope` (count principals; don't report them), then for each client not yet seen `GET /beta/servicePrincipals/{clientId}?$select=displayName,appOwnerOrganizationId,publisherName` |
| Graph application permissions | `GET /beta/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?$select=id,appOwnerOrganizationId,appRoles` once (its `appOwnerOrganizationId` is Microsoft's), then `GET /beta/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')/appRoleAssignedTo?$select=principalId,principalDisplayName,principalType,appRoleId&$top=999` and match `appRoleId` to `appRoles[].id` → `value` |
| Exchange application permissions | The same two calls for `appId='00000002-0000-0ff1-ce00-000000000000'` (look for `full_access_as_app`) |
| Guests | `GET /beta/users?$filter=userType eq 'Guest'&$select=id,createdDateTime,signInActivity&$top=999`. No `signInActivity` means no sign-in recorded |
| Access reviews (P2 or ID Governance) | `GET /beta/identityGovernance/accessReviews/definitions?$select=id,displayName,status,scope,instanceEnumerationScope` |
| Dynamic groups (only if sync is on) | `GET /beta/groups?$filter=groupTypes/any(g:g eq 'DynamicMembership')&$select=id,displayName,membershipRule,isAssignableToRole&$top=999` |
| Recent changes (audit log) | `GET /beta/auditLogs/directoryAudits?$filter=activityDateTime ge {30 days ago} and (activityDisplayName eq 'Set domain authentication' or activityDisplayName eq 'Set federation settings on domain' or activityDisplayName eq 'Add service principal credentials' or activityDisplayName eq 'Add app role assignment to service principal' or activityDisplayName eq 'Add owner to application' or activityDisplayName eq 'Add owner to service principal' or activityDisplayName eq 'Set DirSync feature')&$select=activityDateTime,activityDisplayName,loggedByService,initiatedBy,targetResources&$top=999` |
| Direct role assignments (audit log) | `GET /beta/auditLogs/directoryAudits?$filter=activityDateTime ge {30 days ago} and activityDisplayName eq 'Add member to role' and loggedByService eq 'Core Directory'&$select=activityDateTime,initiatedBy,targetResources&$top=999` |
| App credential changes (audit log) | `GET /beta/auditLogs/directoryAudits?$filter=activityDateTime ge {30 days ago} and activityDisplayName eq 'Update application – Certificates and secrets management '&$select=activityDateTime,initiatedBy,targetResources&$top=999` (the activity name has an en dash and a trailing space; keep both) |
| Conditional Access changes (audit log) | `GET /beta/auditLogs/directoryAudits?$filter=activityDateTime ge {30 days ago} and (activityDisplayName eq 'Update conditional access policy' or activityDisplayName eq 'Delete conditional access policy')&$select=activityDateTime,targetResources&$top=999` |
| TAPs and password resets (audit log) | `GET /beta/auditLogs/directoryAudits?$filter=activityDateTime ge {30 days ago} and (activityDisplayName eq 'Reset user password' or activityDisplayName eq 'Admin registered security info')&$select=activityDateTime,activityDisplayName,resultReason,targetResources&$top=999`, then keep only targets that are admins or sync accounts (a TAP shows as `Admin registered security info` with `resultReason` "Admin registered temporary access pass method for user") |

**Not readable through the Enterprise MCP** (tested: the MCP returns 403 "not authorized by the
available scopes"): domain federation configuration (`/domains/{id}/federationConfiguration`),
Entra Connect sync features (`/directory/onPremisesSynchronization`), partner relationships
(`/tenantRelationships/delegatedAdminRelationships`) and risky agents
(`/identityProtection/riskyAgents`). They go on the manual checklist.

If a call returns 403, say which part was skipped and carry on. The person running the review
should be an activated member of **Copilot Entra ID Operations Reader** (Global Reader, through
PIM). If many calls return 403, ask whether they activated the group in PIM (My roles > Groups)
before going on. A 403 that mentions a license (for example on sign-in logs or risky users) means
the tenant doesn't have P1 or P2: skip those checks and say why.

**Don't put people's names, UPNs or email addresses in the results** unless the user asks. Counts
are enough ("3 Global Administrators are synced from on-premises"). Apps, policies, groups and
roles can be named.

## Step 3: Apply the rules

Use **references/rules.md**. Each finding has an Area, Item, Topic (the attack scenario),
Severity (High, Medium, Low, Info), Check (what's wrong), Fix and Sources. Put the sources in
brackets at the end of the fix, like "[CISA MS.AAD.1.1v1 · CIS 5.2.2.3 · Playbook: Password spray]".
**references/guidance.md** has the full name and link for every source.

## Step 4: Score, BOD 25-01 and funnel

Score each area the way rules.md says (each check is an item; passing checks score 100). Count the
CISA BOD 25-01 policies met out of those you could check. Build the phishing-resistant admins
funnel from rules.md.

## Step 5: Manual checks

List the manual checks from rules.md, grouped by area. If the browser is available and the user
allows it, open each admin center page, read the setting and say what it's set to. Read only:
never select Save, Delete or any button that changes a setting.

## Step 6: Report

The main result is an **HTML report** built from **assets/report-template.html**, a companion file
of this skill. **Always use that template. Never write your own report layout, Markdown report or
document instead**, even a short one. If you can't read the template, say so and stop.

1. Copy assets/report-template.html to the output folder as **Entra ID Security Review.html**.
2. Replace only the JSON inside `<script id="report-data" type="application/json">` with this run's
   data. Don't change anything else in the file. Fill it like this:
   - `title`: "Entra ID Security Review"; `generated`: the date and time; `source`: "Copilot
     Cowork" (or "GitHub Copilot"); `subjectLabel`: "Area"; `areaLabel`: "Attack"; `sample`: false.
   - `tiles`: `[ { "value": "16 of 22", "label": "CISA BOD 25-01 policies met" } ]` with this run's numbers.
   - `funnelTitle`: "Phishing-resistant admins: {percent}%", and `funnel`: the five steps, each
     `{ "label", "count", "note" }`.
   - `scorecard`: one entry per area (Privileged access, Authentication, Conditional Access and
     risk, Applications and consent, Hybrid and federation, External identities, Tenant and
     devices, Recent changes): `name`, `score`, `rating`, `high`, `medium`, `low`, `info`, and
     `detail` ("14 checks run, 2 skipped").
   - `findings`: one entry per finding: `subject` (the area), `area` (the topic, which is the
     attack), `severity`, `target` (the item), `check`, and `fix` with the sources in brackets at
     the end.
   - `fixFirst`: the three changes that close the most attack paths, in plain words. Order them
     the way Microsoft's security roadmap does: MFA and legacy authentication first, then
     privileged access, then apps and consent.
   - `manualChecks`: the manual checks from rules.md, with what you saw if you read them in the browser.
   - `graphCalls`: every Graph call you ran, without object IDs.
   - `notes`: start with "Based on the CISA SCuBA Entra ID baseline, CIS Microsoft 365 Foundations
     Benchmark v7.0.0, the Attack and Defense Playbook for Microsoft Entra and Microsoft, NSA and
     Mandiant guidance. Severities, scores and the mapping of checks to sources are the Copilot
     repo's choices." Then the BOD 25-01 policies not met, the checks skipped and why (403, no
     license), and anything else the user should know.
   - `prompt`: the prompt the user ran, so they can run it again.
   It must stay valid JSON: escape quotes and backslashes in names.
3. Use a script to write the file if that's easiest. Only Graph calls must not come from scripts.
4. Open the report in the session so the user sees it, and give a short summary in chat: the score
   per area, the BOD 25-01 count, the phishing-resistant admins %, how many High and Medium
   findings, the attacks with the most High findings, and the three fixes.

If the user attached a findings CSV exported from an earlier review instead (way B), and the
Enterprise MCP connector isn't available, skip Steps 1 to 5: explain the findings, give the top 3
fixes, and rebuild the report from them (score each area from its findings as in rules.md, and say
the scores only count the checks that raised findings).

Use plain, short sentences. Treat the results as sensitive: they describe the tenant's weak spots.
Keep them in the user's session and output folder only.

## Follow-ups the user may ask for

- "Show only what CISA requires" or "only BOD 25-01." Filter to findings whose sources include a BOD 25-01 policy (guidance.md lists them).
- "Which attacks am I most exposed to?" Group the High and Medium findings by topic and explain each attack in two sentences, using the Playbook chapter.
- "Draft a note to the app owners about their secrets or permissions." Draft it; don't send it until the user approves.
- "Make me a spreadsheet." Build an Excel workbook with Scorecard, Findings and CISA sheets from the same data.
- "Compare with last month's findings CSV." List new, fixed and unchanged findings.
- "What would an attacker do first?" Walk through the most likely path in this tenant from the High findings (for example, consent phishing to an app with Mail.Read, or a synced admin from a fallen AD), and the fix that breaks it.
