# Agent and Tools Cleanup

Updated Oct 31, 2026

Find what nobody uses in Microsoft 365 Copilot and Agent 365, then block or disable it with an undo:

- **Agents** (admin center **Agents > All agents**): Copilot Studio, Agent Builder and custom engine agents.
- **Tools** (admin center **Agents > Tools**): plugins and the skills, MCP servers and connectors inside them.
- **Agent identities and blueprints** (Entra **Agent ID**): the identities agents sign in with, and the blueprints they're created from.

| File | What it does | Changes anything? |
| --- | --- | --- |
| [Get-AgentToolsReport.ps1](Get-AgentToolsReport.ps1) | Writes CSVs with a status and recommendation for every agent, tool, agent identity and blueprint | No |
| [Invoke-AgentToolsCleanup.ps1](Invoke-AgentToolsCleanup.ps1) | Blocks agents and tools, and disables identities and blueprint principals marked in the CSVs. Saves an undo file | Yes. Use `-WhatIf` first |
| [Cowork/](Cowork/readme.md) | The same review in Copilot Cowork: the Enterprise MCP for Entra data, and the browser for admin center pages no API covers | No |

Both scripts use only `Connect-MgGraph` and `Invoke-MgGraphRequest` (module Microsoft.Graph.Authentication) against Graph beta, and work in Windows PowerShell 5.1 and PowerShell 7.

## Where the data comes from

| Object | Inventory | Last used |
| --- | --- | --- |
| Agents and tools (plugins) | `GET /copilot/admin/catalog/packages` (preview) | `GET /copilot/admin/catalog/packages/{id}` returns `lastUsedDateTime`, `activeUsers` and `totalSessions` (last 30 days). Also: the package's agent identity sign-in, the admin center Agent usage export, and Copilot audit records with `-AuditDays` |
| Agent identities | `GET /servicePrincipals/microsoft.graph.agentIdentity` | `GET /reports/servicePrincipalSignInActivities` (preview), matched on `appId`, plus Agent 365 activity in Defender (below) |
| Agent 365 activity (Defender) | KQL through `POST /beta/security/runHuntingQuery` | `CloudAppEvents` (`InvokeAgent` and tool calls, last 30 days), joined to `AgentsInfo` for each agent's Entra Agent ID. Counts as use for agents and identities. Many Copilot Studio agents run without a sign-in of their own, so this catches use the sign-in report misses |
| Blueprint principals | `GET /servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal` | Same sign-in report, plus how many child identities are still active |
| Blueprints registered here | `GET /applications/microsoft.graph.agentIdentityBlueprint` | Used only to tell your own blueprints from Microsoft's and other publishers' |
| Standalone MCP servers and skills | **No Graph API yet** | Admin center only. Use the Cowork browser skill, or check by hand |

How each package is labelled, from its `elementTypes`:

| Kind | Element types | Can be auto-blocked? |
| --- | --- | --- |
| Agent | declarativeAgent, customEngine..., bot | Yes |
| Tool | anything with skill, connector, MCP, plugin or action in the name | Yes |
| App | everything else (Office add-ins, tabs, message extensions) | No, Review only |

Microsoft doesn't document every `elementTypes` value for plugins yet. Check the `elementTypes` column in `Packages.csv` the first time you run it, and tell me if a tool shows up as App.

Notes:
- The catalog API needs a **Microsoft Agent 365** license (included in Microsoft 365 E7) and the **AI Administrator** role. Without it, run with `-SkipPackages`.
- The detail call is one request per package, so a big catalog takes a while.
- Not every agent has an agent identity. Agents built with older Copilot Studio or Foundry versions are classic app registrations. Review those with your normal app cleanup.

## Permissions and roles

| Script | Delegated scopes | Role |
| --- | --- | --- |
| Get-AgentToolsReport.ps1 | Application.Read.All, AgentIdentityBlueprint.Read.All, AuditLog.Read.All, CopilotPackages.Read.All, ThreatHunting.Read.All (skip with `-SkipDefender`). Plus AuditLogsQuery.Read.All with `-AuditDays` | Reports Reader (sign-ins), AI Administrator (catalog), Security Reader (Defender), a Purview audit role (audit search) |
| Invoke-AgentToolsCleanup.ps1 | AgentIdentity.EnableDisable.All, AgentIdentityBlueprintPrincipal.EnableDisable.All, CopilotPackages.ReadWrite.All (only the ones you pick) | Agent ID Administrator, AI Administrator |

Use PIM for the admin roles and activate them only for the run.

## Run it

### 1. Build the report

```powershell
.\Get-AgentToolsReport.ps1 -Days 90
# Also search 90 days of Copilot audit records for plugin and agent use (slower)
.\Get-AgentToolsReport.ps1 -Days 90 -AuditDays 90
```

Output goes to `.\AgentToolsReport-<date-time>\`: `Packages.csv`, `AgentIdentities.csv`, `Blueprints.csv` and, with `-AuditDays`, `AuditUsage.csv`. Keep it out of source control (the `.gitignore` here already excludes it).

`-AuditDays` starts a Purview audit search for `CopilotInteraction` records and waits for it (up to 30 minutes). It reads `AISystemPlugin` (the plugins used in each interaction) and `AgentId` / `AgentName`, and keeps only the last use and a count per plugin or agent. No user names are saved.

| Status | Meaning |
| --- | --- |
| Active | Used within `-Days`, or has active users in the last 30 days |
| Stale | Last used before `-Days` |
| New | Created (or for packages, last changed) within `-Days`, never used |
| NoActivity | Older than `-Days`, no use recorded |
| NoPrincipal | Blueprint registered here but never added to this tenant. It may be used in other tenants |

| Recommendation | What the cleanup script does |
| --- | --- |
| Disable | Disables the agent identity or blueprint principal |
| Block | Blocks the agent or tool in the catalog |
| Keep, Review, AlreadyDisabled, AlreadyBlocked | Nothing |

Safety rules built into the recommendations:
- **Microsoft-built packages are Keep. Apps are Review.**
- **No sign-in data means Review, never Disable.**
- **NoActivity identities are Review, not Disable.** Copilot Studio agent identities can be in use without a recorded sign-in of their own. Only identities that signed in before and then stopped get Disable.
- **Blueprints from Microsoft or other publishers are Review.** A blueprint principal with no blueprint registered in your tenant (such as the Copilot Studio agent identity blueprint) backs every agent built on that product. Disabling it breaks all of them.

### 2. Review the CSVs

Change `recommendation` to `Keep` for anything you want to keep: seasonal agents, break-glass agents, anything a sponsor vouches for. On stale identities, `sponsorCount` and `ownerCount` of zero mean nobody is accountable for it.

### 3. Clean up

```powershell
# See what would change
.\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261031-0900 -DisableAgentIdentities -BlockPackages -WhatIf

# Do it (prompts for each change; add -Confirm:$false to skip the prompts)
.\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261031-0900 -DisableAgentIdentities -BlockPackages

# Blueprints last, after their agents have been disabled for a while
.\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261031-0900 -DisableBlueprints
```

`-BlockPackages` blocks both agents and tools. Disabling a blueprint principal stops every agent identity under it from getting tokens in this tenant.

### 4. Undo

Each run writes `cleanup-undo-<date-time>.json` to the report folder.

```powershell
.\Invoke-AgentToolsCleanup.ps1 -ReportFolder .\AgentToolsReport-20261031-0900 -Restore -UndoFile .\AgentToolsReport-20261031-0900\cleanup-undo-20261031-0915.json
```

## Why disable or block instead of delete

- A disabled identity keeps its permissions, owners and sponsors, and a blocked package keeps its settings, so you can turn either back on.
- Deleting a blueprint or its principal deletes every child agent identity and agent user account with it (cascade cleanup). The 30-day soft-delete window is the only way back.
- Let Entra do the deleting. Turn on the **Agent ID default inactivity policy** (preview, no extra license): Entra admin center > **ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID (Preview)**. It notifies sponsors and owners at 60 days inactive, disables at 90 and deletes at 455. Use **All Agent IDs except selected** to exclude seasonal agents. Custom lifecycle policies need an ID Governance license.

## CISA and CIS guidance

Cleaning up unused agents, tools and identities is what both sources ask for:

- **CIS Controls v8.1 5.3, Disable Dormant Accounts**: CIS sets **45 days** of inactivity. This folder defaults to 90 days; run `.\Get-AgentToolsReport.ps1 -Days 45` to match CIS. **6.2, Establish an Access Revoking Process**: block or disable what isn't used, with a record (the undo file). **5.5, Inventory of Service Accounts**: agent identities are non-human accounts to review at least quarterly. **2.3, Address Unauthorized Software**: block tools nobody approved or uses. The [CIS AI Agent and MCP Companion Guides](https://www.cisecurity.org/insights/white-papers/controls-v8-1-ai-agents-companion-guide) (April 2026) apply these controls to agents and MCP.
- **CISA and partners, [*Careful Adoption of Agentic AI Services*](https://www.cisa.gov/resources-tools/resources/careful-adoption-agentic-ai-services)** (May 2026): unused agents with standing access add to the **privilege** and **accountability** risk categories, and the guidance asks for least privilege and no broad or unrestricted access. Disabling instead of deleting keeps the audit trail it asks for.

For the full check-by-check mapping, see the [Agent and Tools Health Check](../Agent%20and%20Tools%20Health%20Check/README.md#cisa-and-cis-guidance).

## Run it in Copilot Cowork

See **[Cowork/readme.md](Cowork/readme.md)**. The plugin has two skills:

- **agent-tools-review** reads agent identities, blueprints and sign-ins live through the Microsoft MCP Server for Enterprise. The MCP server can't read the Agent 365 catalog or the audit log (no MCP scope covers them; the catalog returns 403), so for agents and tools you attach `Packages.csv`.
- **admin-center-tools-review** uses Cowork's browser to read the admin center pages that have no API (standalone MCP servers and skills, plugin status, the agent usage report) and recommends what to clean up. It only reads.

Changes stay in the script. Blocking and disabling need write scopes, `-WhatIf` and an undo file, so keep them in `Invoke-AgentToolsCleanup.ps1` rather than giving an agent write access.

## References

- [Agent 365 Package Management API overview](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/overview)
- [List packages](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/copilotpackages-list), [Get package details](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/copilotpackagedetail-get) and [copilotPackageDetail](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/resources/copilotpackagedetail)
- [Block a package](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/copilotpackage-block)
- [Overview of the Tools page](https://learn.microsoft.com/microsoft-agent-365/admin/agent-tools-overview) and [Manage plugins, skills, and MCP servers](https://learn.microsoft.com/microsoft-agent-365/admin/manage-plugins-skills-mcp-servers)
- [Audit logs for Copilot and AI applications](https://learn.microsoft.com/purview/audit-copilot) and [Create auditLogQuery](https://learn.microsoft.com/graph/api/security-auditcoreroot-post-auditlogqueries?view=graph-rest-beta)
- [agentIdentity resource](https://learn.microsoft.com/graph/api/resources/agentidentity?view=graph-rest-beta) and [Update agentIdentity](https://learn.microsoft.com/graph/api/agentidentity-update?view=graph-rest-beta)
- [Update agentIdentityBlueprintPrincipal](https://learn.microsoft.com/graph/api/agentidentityblueprintprincipal-update?view=graph-rest-1.0)
- [List servicePrincipalSignInActivities](https://learn.microsoft.com/graph/api/reportroot-list-serviceprincipalsigninactivities?view=graph-rest-beta)
- [Agent identity deletion (cascade cleanup)](https://learn.microsoft.com/entra/agent-id/concept-agent-identity-deletion)
- [Agent ID default inactivity policy](https://learn.microsoft.com/entra/id-governance/agent-default-inactivity-policy)
