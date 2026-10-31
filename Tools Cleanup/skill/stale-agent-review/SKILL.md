---
name: stale-agent-review
description: Review unused Copilot agents, stale Entra agent identities and stale agent identity blueprints through Microsoft Graph, and say what to block or disable. Read-only.
---

# Stale agent review

Use this skill when someone asks which agents nobody uses, which agent identities are stale, or which agent identity blueprints can be cleaned up.

This skill only reads. It never blocks, disables or deletes anything. For changes, point the person to `Invoke-StaleAgentCleanup.ps1` in the `Tools Cleanup` folder of the Copilot repo, and tell them to run it with `-WhatIf` first.

## Tools

Use a Microsoft Graph MCP server that can run GET requests (for example the Microsoft MCP Server for Enterprise `microsoft_graph_get` tool). Use the **beta** endpoint. Follow `@odata.nextLink` until it's gone. If a call fails with 403, say which permission or role is missing (table below) and carry on with the other sections.

| Data | GET | Needs |
| --- | --- | --- |
| Service principal sign-in activity | `/beta/reports/servicePrincipalSignInActivities` | AuditLog.Read.All, Reports Reader |
| Agent identities | `/beta/servicePrincipals/microsoft.graph.agentIdentity?$select=id,appId,displayName,accountEnabled,agentIdentityBlueprintId,createdDateTime` | Application.Read.All |
| Blueprint principals | `/beta/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal?$select=id,appId,displayName,accountEnabled` | Application.Read.All |
| Blueprints registered here | `/beta/applications/microsoft.graph.agentIdentityBlueprint?$select=id,appId,displayName,createdDateTime` | AgentIdentityBlueprint.Read.All |
| Agents in the registry | `/beta/copilot/admin/catalog/packages?$filter=supportedHosts/any(h:h eq 'Copilot')` | CopilotPackages.Read.All, AI Administrator, Agent 365 license |
| Sponsors of one identity | `/beta/servicePrincipals/{id}/microsoft.graph.agentIdentity/sponsors?$select=id` | Application.Read.All |

## Steps

1. Ask how many days without use counts as stale. Default 90.
2. Read sign-in activity and index it by `appId`. Use `lastSignInActivity.lastSignInDateTime`.
3. **Agent identities.** Match each identity's `appId` to sign-in activity. Status: Active (signed in within the window), Stale (signed in before it), New (created within it, never signed in), NoActivity (older, never signed in). Recommend Disable for Stale and NoActivity identities that are still enabled. For those, count sponsors; flag any with no sponsor and no owner.
4. **Blueprints.** For each blueprint principal, count child identities (`agentIdentityBlueprintId` = blueprint `appId`) and how many are enabled and Active or New. Recommend Disable for the principal only when it has no active children and hasn't signed in within the window. A blueprint registered here with no principal is NoPrincipal: recommend Review, because it may be used in other tenants.
5. **Agents.** For each package, last used = the newest of: the sign-in of its `agentIdentityId`, and the Last activity date for its `id`, `manifestId` or `appId` in the admin center Agent usage export, if the person attached one. Recommend Block for custom, shared and external agents with no use in the window. Keep Microsoft agents. If there's no usage source at all, say NoUsageData and recommend Review.
6. If sign-in activity couldn't be read, mark every identity and blueprint Review, not Disable, and say why.

## Report

Give three short tables (agents, agent identities, blueprints) with name, status, days since last use and recommendation, then the counts per recommendation. Don't list sponsor or owner names.

End with these points:
- No Graph API gives per-agent usage yet. Usage comes from agent identity sign-ins and the admin center Agent usage report (Reports > Usage > Microsoft Copilot > Agents), which covers only 7 or 30 days.
- Disable or block first; don't delete. Deleting a blueprint deletes all its agent identities.
- Turn on the Entra Agent ID default inactivity policy (ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID). It notifies at 60 days, disables at 90 and deletes at 455.
- To make the changes, run `Invoke-StaleAgentCleanup.ps1 -WhatIf` on the CSVs from `Get-StaleAgentReport.ps1`.
