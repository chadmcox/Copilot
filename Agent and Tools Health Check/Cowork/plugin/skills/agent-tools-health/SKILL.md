---
name: agent-tools-health
description: |
  Read-only health check of Copilot agents and tools (plugins, skills, MCP servers), Entra agent
  identities, agent identity blueprints and Conditional Access for agents. Checks group-scoped
  access, sponsors and owners, least privilege, clear names and descriptions, and stale items, then
  scores each area and builds an HTML report. Use when the user asks to "run the agent and tools
  health check", "check my agents", "are my agents governed", "check agent sponsors / permissions /
  names", or attaches Packages.csv, Findings.csv or Scorecard.csv from Get-AgentToolsHealth.ps1.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Agent and tools health check

Find governance problems in agents, tools, agent identities, blueprints and the tenant settings
around them, then say how to fix each one. **Read-only.** Never create, change, disable, block or
delete anything in the tenant. Never send an email or Teams message unless the user asks and
approves it. For cleanup, point the user to the Agent and Tools Cleanup scripts in the Copilot repo.

## Step 1: Get the agents and tools

The Microsoft MCP Server for Enterprise can't read the Agent 365 catalog (no MCP scope covers it;
the call returns 403). Get it from a file the user attaches:

- **Packages.csv** from `Get-AgentToolsHealth.ps1 -PackagesOnly` (or from a full run). Columns: id,
  displayName, kind (Agent, Tool, App), elementTypes, type, publisher, shortDescription, isBlocked,
  availableTo, deployedTo, requestStatus, requestType, groupIds, groups, directUsers,
  lastModifiedDateTime, lastUsedDateTime, activeUsers30d, sessions30d.

Also attach **DefenderAgents.csv** (written by the same script) for agents Microsoft Defender found:
the Enterprise MCP server can't run Defender advanced hunting queries. Columns: AgentId, AgentName,
Platform, SourceAgentId, EntraAgentId, EntraBlueprintId, Availability, PublishedStatus,
LifecycleStatus, CreatedDateTime, LastUpdatedDateTime, OwnerCount, McpServerUrls (semicolon-separated),
SkillCount, ToolCount, LastActivity, Invocations30d, ToolCalls30d. The last three are Agent 365
activity from Defender's CloudAppEvents over the last 30 days. If Packages.csv isn't attached but
DefenderAgents.csv is, use Defender's agents as the agent list (rules.md says which checks apply). If it isn't attached and the
browser is available, you may open **Microsoft Defender portal > Investigation & response > Hunting >
Advanced hunting**, run this read-only query and read the results:
`AgentsInfo | summarize arg_max(Timestamp, *) by AgentId | where LifecycleStatus != "Deleted" | project AgentId, AgentName, Platform, SourceAgentId, EntraAgentId, Availability, LifecycleStatus, OwnerCount = array_length(Owners)`.
Otherwise say the Discovered agents area was skipped.

If no file is attached, say that agents and tools need Packages.csv, and carry on with Steps 2 to 4
(identities, blueprints, tenant). If the browser is available, you may read **Microsoft 365 admin
center > Agents > All agents > Registry** and **Agents > Tools** for names, descriptions and
availability instead; read only, never select a button that changes anything.

If the user attached **Findings.csv** and **Scorecard.csv** instead, and the Enterprise MCP
connector isn't available, skip to Step 6 and work from those files.

## Step 2: Read agent identities, blueprints and people

**Call the Enterprise MCP connector's `microsoft_graph_get` tool directly, one call per request.
Never write or run a script to call Microsoft Graph.** Scripts run in a sandbox that isn't signed
in to the tenant, so every read from a script fails. Scripts are fine afterwards, for scoring the
data you already read or writing the report file.

Use `$select`, and follow every `@odata.nextLink` with another `microsoft_graph_get` call. Only one
`$expand` is allowed per call. The server allows about 100 calls a minute, so read collections
rather than one object at a time where you can.

Start with one test call, `GET /beta/servicePrincipals/graph.agentIdentity?$select=id&$top=1`. If it
fails, stop and tell the user the connector can't read the tenant, with the error.

| What | Graph call |
| --- | --- |
| Agent identities with sponsors | `GET /beta/servicePrincipals/graph.agentIdentity?$select=id,appId,displayName,accountEnabled,agentIdentityBlueprintId,createdDateTime&$expand=sponsors($select=id)` |
| Owners of an identity | `GET /beta/servicePrincipals/{id}/owners?$select=id` |
| App permissions of an identity or blueprint principal | `GET /beta/servicePrincipals/{id}/appRoleAssignments?$select=appRoleId,resourceId,resourceDisplayName` |
| Microsoft Graph app role names (once) | `GET /beta/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?$select=id,appRoles` and match `appRoleId` to `appRoles[].id` → `value` |
| Delegated grants | `GET /beta/oauth2PermissionGrants?$filter=clientId eq '{id}'` and read `scope` where `resourceId` is the Microsoft Graph service principal |
| Last sign-in | `GET /beta/reports/servicePrincipalSignInActivities?$filter=appId eq '{appId}'` (for an agent identity, `appId` equals `id`). Empty means no sign-in recorded |
| Blueprints registered here | `GET /beta/applications/microsoft.graph.agentIdentityBlueprint?$select=id,appId,displayName,description,createdDateTime,passwordCredentials,keyCredentials&$expand=sponsors($select=id)` |
| Owners of a blueprint | `GET /beta/applications/{id}/owners?$select=id` |
| Inheritable permissions | `GET /beta/applications/{id}/microsoft.graph.agentIdentityBlueprint/inheritablePermissions` |
| Blueprint principals | `GET /beta/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal?$select=id,appId,displayName` |
| Agent user accounts | `GET /beta/users/microsoft.graph.agentUser?$select=id,displayName,identityParentId` |
| Sponsors and owners (are they active?) | `GET /beta/users/{id}?$select=id,displayName,accountEnabled`. A 404 means the person is gone |
| Groups from Packages.csv `groupIds` | `GET /beta/groups/{id}?$select=id,displayName,description` and `GET /beta/groups/{id}/owners?$select=id` |
| Conditional Access | `GET /beta/identity/conditionalAccess/policies?$select=displayName,state,conditions,grantControls` |
| Agents without Agent ID | `GET /beta/servicePrincipals?$filter=tags/any(t:t eq 'AgentCreatedBy:CopilotStudio')&$select=id,appId,displayName,accountEnabled,tags,createdDateTime`, then the same for `AgenticApp`, `AIAgentBuilder` and `AgenticInstance`, and `tags/any(t:startswith(t,'power-virtual-agents-'))`. Leave out IDs that are agent identities or blueprint principals. Then owners and last sign-in as above |

Not readable through the Enterprise MCP: the agent attestation date (`.../lifecycle` returns 403),
the Agent 365 catalog, Defender advanced hunting (`getRunHuntingQuery` returns 403), and admin
center settings. They go on the manual checklist.

If a call returns 403, say which permission is missing and carry on with the rest. The person running the check should be an activated member of **Copilot Health Check Users** (AI Reader, Security Reader, Reports Reader, through PIM). If many calls return 403, ask whether they activated the group in PIM (My roles > Groups) before going on. Don't list
sponsor or owner names in the results unless the user asks; "a sponsor is disabled" is enough.

## Step 3: Apply the rules

Use **references/rules.md**. Each finding has an Area, Item, Category, Severity (High, Medium, Low,
Info), Check (what's wrong), Fix and Reference. Take the Reference from **references/guidance.md**:
the CIS Controls v8.1 safeguards and the CISA risk category for that check, written like
"CIS 5.1, 5.5 | CISA: accountability". Skip the name, description and use checks for
Microsoft-published packages and for blueprints from other publishers.

## Step 4: Score and funnel

For each item, start at 100. Take off 25 for each High, 10 for each Medium and 3 for each Low; the
lowest is 0. An area's score is the average of its items. Rating: Green 80+, Amber 50–79, Red under 50.
Build the well-governed funnel for agent identities from rules.md.

## Step 5: Manual checks

List the manual checks from rules.md. If the browser is available and the user allows it, open each
admin center page, read the setting and say what it's set to. Read only: never select Save, Block,
Delete or any button that changes a setting.

## Step 6: Report

The main result is an **HTML report** built from **assets/report-template.html**, a companion file
of this skill. **Always use that template. Never write your own report layout, Markdown report or
document instead**, even a short one. If you can't read the template, say so and stop.

1. Copy assets/report-template.html to the output folder as **Agent and Tools Health.html**.
2. Replace only the JSON inside `<script id="report-data" type="application/json">` with this run's
   data. Don't change anything else in the file. Fill it like this:
   - `title`: "Agent and Tools Health"; `generated`: the date and time; `source`: "Copilot Cowork";
     `subjectLabel`: "Area"; `areaLabel`: "Category"; `sample`: false.
   - `funnelTitle`: "Well-governed agent identities: {percent}%", and `funnel`: the five steps,
     each `{ "label", "count", "note" }`.
   - `scorecard`: one entry per area (Agents, Tools, Agent identities, Blueprints, Tenant, and
     Discovered agents and Agents without Agent ID when you have data for them): `name`,
     `score`, `rating`, `high`, `medium`, `low`, `info`, and `detail` ("12 items checked").
   - `findings`: one entry per finding: `subject` (the area), `area` (the category), `severity`,
     `target` (the item), `check`, and `fix` with the reference in brackets at the end, for example
     "Add a sponsor [CIS 5.1, 5.5 | CISA: accountability]".
   - `fixFirst`: the three changes that raise the most scores, in plain words.
   - `manualChecks`: the manual checks from rules.md, with what you saw if you read them in the browser.
   - `graphCalls`: every Graph call you ran, without object IDs.
   - `notes`: start with "References in brackets: this repo's mapping of each check to CIS Controls
     v8.1 safeguards (AI Agent and MCP Companion Guides, April 2026) and to the CISA risk categories
     in Careful Adoption of Agentic AI Services (2026). The mapping is a judgment, not published by
     CIS or CISA." Then anything else the user should know, such as calls that failed or areas you skipped.
   It must stay valid JSON: escape quotes and backslashes in names.
3. Use a script to write the file if that's easiest. Only Graph calls must not come from scripts.
4. Open the report in the session so the user sees it, and give a short summary in chat: the score
   per area, the well-governed %, how many High and Medium findings, and the three fixes.

Use plain, short sentences. Treat the results as sensitive: they name agents, groups and
permissions. Keep them in the user's session and OneDrive output folder only.

## Follow-ups the user may ask for

- "Draft a note to each sponsor listing what to fix on their agents." Draft it; don't send it until the user approves.
- "Which agents aren't in the registry?" or "Which agents have no Agent ID?" List the Discovered agents and Agents without Agent ID findings.
- "How does this map to CISA or CIS?" Use references/guidance.md: group the findings by CIS safeguard or CISA risk category, say the mapping is this repo's judgment, and list what this check doesn't cover (logging, human oversight, approved tools). Don't quote CISA recommendations beyond the five risk categories: the guidance file says why.
- "Which agents are stale?" List the Usage findings, and point to Agent and Tools Cleanup to block or disable them with an undo file.
- "Show only High findings" or "only blueprints." The report's filters already do this; say so.
- "Make me a spreadsheet." Build an Excel workbook with Scorecard and Findings sheets from the same data.
- "Compare with last month's Findings.csv." List new, fixed and unchanged findings.
