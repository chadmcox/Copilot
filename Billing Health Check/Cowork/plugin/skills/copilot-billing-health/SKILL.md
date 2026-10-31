---
name: copilot-billing-health
description: |
  Read-only health check of Microsoft 365 Copilot spending policies, the groups they use and the
  people in those groups. Use when the user asks to "run the Copilot billing health check",
  "check my spending policies", "check the Cowork groups", "who shouldn't be in this spending
  policy", or attaches Policies.csv, Findings.csv or Scorecard.csv from Get-CopilotBillingHealth.ps1.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Copilot billing health check

Find problems in Copilot Credits spending policies, their groups and their members, then say
how to fix each one. **Read-only.** Never create, change or delete anything in the tenant.
Never send an email or Teams message unless the user asks and approves it.

## Step 1: Get the policies

The Microsoft MCP Server for Enterprise can't read spending policies (it has no cost management
scope). Get them from a file the user attaches:

- **Policies.csv** from `Get-CopilotBillingHealth.ps1` (or `-PoliciesOnly`). Columns: Policy,
  Status, Scope, Groups, GroupIds, Services, PerUserLimit, MonthlyLimit, Billing, AlertOn,
  AlertRecipients.
- Or the same columns typed in by hand from **Copilot > Cost management > Configuration**.
  GroupIds can be blank; then find each group by its exact display name.

If no file is attached, ask for one. Don't guess the policies.

If the user attached **Findings.csv** and **Scorecard.csv** instead, and the Enterprise MCP
connector isn't available, skip to Step 4 and work from those files.

## Step 2: Read each group and its people

**Call the Enterprise MCP connector's `microsoft_graph_get` tool directly, one call per request.
Never write or run a script to call Microsoft Graph.** Scripts run in a sandbox that isn't signed
in to the tenant, so every read from a script fails. Scripts are fine afterwards, for scoring the
data you already read or building the Excel workbook.

Use `$select`, `$top=999`, and follow every `@odata.nextLink` with another `microsoft_graph_get`
call. The server allows about 100 calls a minute, so don't read users one at a time.

Start with one test call, `GET /beta/subscribedSkus?$select=skuId,servicePlans`. If it fails,
stop and tell the user the connector can't read the tenant, with the error. Don't continue.

| What | Graph call |
| --- | --- |
| Copilot licenses | `GET /beta/subscribedSkus?$select=skuId,skuPartNumber,servicePlans`. A SKU is a Copilot license when one of its servicePlans has servicePlanId `3f30311c-6b1e-48a4-ab79-725b469da960`. Don't match on the name; Microsoft 365 E7 includes Copilot but its name doesn't say so. |
| Group | `GET /beta/groups/{id}?$select=id,displayName,description,groupTypes,securityEnabled,membershipRule` |
| Owners | `GET /beta/groups/{id}/owners?$select=id,userPrincipalName,accountEnabled` |
| Nested groups | `GET /beta/groups/{id}/members/microsoft.graph.group?$select=id,displayName` |
| Everyone, including nested | `GET /beta/groups/{id}/transitiveMembers/microsoft.graph.user?$select=id,userPrincipalName,accountEnabled,userType,assignedLicenses,licenseAssignmentStates&$top=999` |
| Inactive people (one call for the whole tenant) | `GET /beta/users?$filter=signInActivity/lastSuccessfulSignInDateTime le {today minus 90 days, ISO 8601}&$select=id,userPrincipalName,signInActivity&$top=999`, then match by id |
| Alert recipients | `GET /beta/users/{id or UPN}?$select=id,userPrincipalName,accountEnabled` |
| Access reviews (optional) | `GET /beta/identityGovernance/accessReviews/definitions?$select=id,displayName,scope` and look for the group id in each scope query |

If a call returns 403, say which permission is missing and carry on with the rest.

If you couldn't read any of the groups, stop before Step 3. Tell the user how many groups you read
(0) and the errors you got. Don't score or report findings from Policies.csv alone: without the
groups and members the score would be wrong.

When you search for a group by name, encode `+` as `%2B` (for example
`startswith(displayName,'Copilot %2B Cowork')`). A bare `+` in a URL is read as a space, so
groups like "Copilot + Cowork Spend Limit" look like they don't exist.

## Step 3: Apply the rules

Use **references/rules.md**. Each finding has a Policy, Area, Severity (High, Medium, Low,
Info), Target (the person, group or policy), Check (what's wrong) and Fix.

## Step 4: Score

For each policy, start at 100. Take off 25 for each High, 10 for each Medium and 3 for each Low
(Info doesn't count). The lowest score is 0. Rating: Green at 80 or more, Amber at 50 to 79, Red under 50.

## Step 5: Report

The main result is an **HTML report** built from **assets/report-template.html**, a companion file
of this skill. **Always use that template. Never write your own report layout, Markdown report or
document instead**, even a short one: the template has the score dial, policy cards, filters,
search, CSV export and print that people expect. If you can't read the template, say so and stop;
don't improvise. Don't make a spreadsheet unless the user asks for one.

1. Copy assets/report-template.html to the output folder as **Copilot Billing Health.html**.
2. Replace only the JSON inside `<script id="report-data" type="application/json">` with this
   run's data. Don't change anything else in the file. Fill it like this:
   - `title`: "Copilot Billing Health"; `generated`: the date and time; `source`: "Copilot Cowork";
     `subjectLabel`: "Policy"; `sample`: false.
   - `scorecard`: one entry per policy: `name`, `score`, `rating`, `high`, `medium`, `low`, `info`,
     and `detail` (for example "Group: Copilot + Cowork Spend Limit · 12 members").
   - `findings`: one entry per finding: `subject` (the policy), `area`, `severity`, `target`,
     `check`, `fix`.
   - `fixFirst`: the three changes that raise the most scores, in plain words.
   - `manualChecks`: the three checks by hand:
     - Allow new Agents and services is off on every policy except the pilot one.
     - Each Cowork policy has the right model profile.
     - Credit request policies point at the access packages.
   - `graphCalls`: every Graph call you ran, without IDs of people.
   - `notes`: anything the user should know, such as calls that failed or checks you skipped.
   It must stay valid JSON: escape quotes and backslashes in names.
3. Use a script to write the file if that's easiest. That's fine here; only Graph calls must not
   come from scripts.
4. Open the report in the session so the user sees it, and give a short summary in chat: the
   average score, how many High and Medium findings, and the three fixes.

The report works offline and has filters, search, CSV export and print, so there's no need for a
separate CSV or workbook. Use plain, short sentences. Treat the results as sensitive: they name
people. Keep them in the user's session and OneDrive output folder only.

## Follow-ups the user may ask for

- "Draft a note to each group owner listing the people to remove." Draft it; don't send it until the user approves.
- "Show only High findings" or "only the Cowork policies." The report's filters already do this; say so.
- "Make me a spreadsheet." Build an Excel workbook with Scorecard and Findings sheets from the same data.
- "Compare with last month's Findings.csv." List new, fixed and unchanged findings.
