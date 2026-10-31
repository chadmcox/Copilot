---
name: stale-agent-review
description: Read-only review of unused Copilot agents, stale Entra agent identities and stale agent identity blueprints through the Microsoft MCP Server for Enterprise. Use when asked which agents nobody uses, which agent identities or blueprints are stale, or to explain AgentIdentities.csv, Blueprints.csv or AgentPackages.csv from Get-StaleAgentReport.ps1.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Stale agent review

Find agents nobody uses, agent identities that haven't signed in and blueprints with nothing active under them, then say what to block or disable.

**Read-only.** Never create, change, disable, block or delete anything. Never send an email or Teams message unless the user asks and approves it. For changes, point the user to `Invoke-StaleAgentCleanup.ps1` in the `Tools Cleanup` folder of the Copilot repo and tell them to run it with `-WhatIf` first.

## What the Enterprise MCP server can and can't read

Use the Microsoft MCP Server for Enterprise `microsoft_graph_get` tool on the **beta** endpoint. Follow `@odata.nextLink` until it's gone.

| Data | GET | Through the MCP |
| --- | --- | --- |
| Agent identities and sponsors | `/beta/servicePrincipals/graph.agentIdentity?$select=id,appId,displayName,accountEnabled,agentIdentityBlueprintId,createdDateTime&$expand=sponsors($select=id)` | Yes (MCP.Application.Read.All) |
| Blueprint principals | `/beta/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal?$select=id,appId,displayName,accountEnabled` | Yes (MCP.Application.Read.All) |
| Blueprints registered here | `/beta/applications/microsoft.graph.agentIdentityBlueprint?$select=id,appId,displayName,createdDateTime` | Yes (MCP.Application.Read.All) |
| Last sign-in of one identity or blueprint | `/beta/reports/servicePrincipalSignInActivities?$filter=appId eq '{appId}'` | Yes (MCP.AuditLog.Read.All) |
| All sign-in activity | `/beta/reports/servicePrincipalSignInActivities` | Yes, but large. Prefer the per-appId filter when there are fewer than about 200 identities |
| Agents in the Agent 365 registry | `/beta/copilot/admin/catalog/packages` | **No.** Returns 403: no MCP scope covers it |

For an agent identity, `appId` equals `id`. Use it in the sign-in filter.

For agents, use a file the user attaches:
- **AgentPackages.csv** from `Get-StaleAgentReport.ps1` (already has status and recommendation), or
- the **Agent usage report** exported from the Microsoft 365 admin center (Reports > Usage > Microsoft Copilot > Agents > Export). It lists agents used in the last 7 or 30 days, with Agent ID and Last activity date.

If neither is attached, review identities and blueprints only, and say that agents need one of those files.

If a call fails with 403, say which scope or role is missing and carry on with the other sections. The MCP server acts as the signed-in person, so they also need a role that can read these objects and sign-in reports (Global Reader works).

## Steps

1. Ask how many days without use counts as stale, unless the user said. Default 90.
2. **Agent identities.** Read them all. For each, read its last sign-in (`lastSignInActivity.lastSignInDateTime`). Status:
   - **Active**: signed in within the window.
   - **Stale**: last signed in before the window.
   - **New**: created within the window, never signed in.
   - **NoActivity**: older than the window, no sign-in recorded.
   Recommend **Disable** for Stale identities that are still enabled. Recommend **Review** for NoActivity: some agents (for example Copilot Studio agents) can be in use without a recorded sign-in for their identity, so check with the sponsor first. Already disabled: **AlreadyDisabled**. Flag any identity with no sponsor.
3. **Blueprints.** For each blueprint principal, count child identities (`agentIdentityBlueprintId` = the principal's `appId`) and how many are enabled and Active or New. Recommend **Disable** for the principal only when it has no active children and its last sign-in is before the window. Otherwise **Keep**, or **Review** if there's no sign-in at all. A blueprint principal with no matching blueprint registered in this tenant belongs to Microsoft or another publisher (for example the Copilot Studio agent identity blueprint): always **Review**, never Disable, because disabling it stops every agent built on it in this tenant. A blueprint registered here with no principal is **NoPrincipal**: recommend **Review**, because it may be used in other tenants.
4. **Agents.** If AgentPackages.csv is attached, use its status and recommendation. If only the admin center export is attached, list the agents in it with their last activity date, and say that agents missing from it weren't used in that export's period (7 or 30 days); the full list needs AgentPackages.csv.
5. If sign-in activity can't be read at all, mark every identity and blueprint **Review**, not Disable, and say why.

## Report

Give three short tables (agents, agent identities, blueprints) with name, status, days since last use and recommendation. Then the counts per recommendation, and the Graph calls you ran. Don't list sponsor or owner names or object IDs unless the user asks.

End with:
- Disable or block first; don't delete. Deleting a blueprint deletes all its agent identities.
- Turn on the Entra Agent ID default inactivity policy (Entra admin center > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID). It notifies at 60 days inactive, disables at 90 and deletes at 455.
- To make the changes, run `Get-StaleAgentReport.ps1`, review the CSVs, then `Invoke-StaleAgentCleanup.ps1 -WhatIf`.
