# Tools Cleanup: unused agents, stale agent identities and blueprints

Updated Oct 30, 2026

These tools find Copilot agents nobody uses, Entra agent identities that haven't signed in, and agent identity blueprints with nothing active under them. Then they block or disable them, with an undo.

| File | What it does | Changes anything? |
| --- | --- | --- |
| [Get-StaleAgentReport.ps1](Get-StaleAgentReport.ps1) | Writes three CSVs with a status and recommendation for every agent, agent identity and blueprint | No |
| [Invoke-StaleAgentCleanup.ps1](Invoke-StaleAgentCleanup.ps1) | Blocks agents and disables identities and blueprint principals marked in the CSVs. Saves an undo file | Yes. Use `-WhatIf` first |
| [Cowork/](Cowork/readme.md) | The same review in Copilot Cowork, through the Microsoft MCP Server for Enterprise. Setup guide, plugin and skill | No |

Both scripts use only `Connect-MgGraph` and `Invoke-MgGraphRequest` (module Microsoft.Graph.Authentication) against Graph beta, and work in Windows PowerShell 5.1 and PowerShell 7.

## What Graph can and can't tell you

| Object | Graph API | Where "last used" comes from |
| --- | --- | --- |
| Agents (Agent 365 registry) | `GET /copilot/admin/catalog/packages` (preview) | **No Graph API gives per-agent usage yet.** The script uses the sign-in of the agent identity the package points to (`agentIdentityId`), plus the Agent usage report you export from the admin center |
| Agent identities | `GET /servicePrincipals/microsoft.graph.agentIdentity` | `GET /reports/servicePrincipalSignInActivities` (preview), matched on `appId` |
| Blueprint principals | `GET /servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal` | Same sign-in activity report, plus how many child identities are still active |
| Blueprints registered here | `GET /applications/microsoft.graph.agentIdentityBlueprint` | Used only to spot blueprints with no principal in this tenant |

Notes:
- The registry API needs a **Microsoft Agent 365** license (included in Microsoft 365 E7) and the **AI Administrator** role. Without it, run the report with `-SkipPackages`.
- The admin center Agent usage report (**Reports > Usage > Microsoft Copilot > Agents > Export**) covers only the last 7 or 30 days. An agent missing from the export wasn't used in that period. It may have been used before it.
- Not every agent has an agent identity. Agents built with older Copilot Studio or Foundry versions are classic app registrations and service principals. This tool doesn't cover those; review them with your normal app cleanup.
- The older Agent Registry API (`/agentRegistry/agentInstances`) is being replaced by the Agent 365 registry API above, so these tools don't use it.

## Permissions and roles

| Script | Delegated scopes | Role |
| --- | --- | --- |
| Get-StaleAgentReport.ps1 | Application.Read.All, AgentIdentityBlueprint.Read.All, AuditLog.Read.All, CopilotPackages.Read.All | Reports Reader (sign-in activity), plus AI Administrator for agents |
| Invoke-StaleAgentCleanup.ps1 | AgentIdentity.EnableDisable.All, AgentIdentityBlueprintPrincipal.EnableDisable.All, CopilotPackages.ReadWrite.All (only the ones you pick) | Agent ID Administrator, plus AI Administrator for agents |

Use PIM for the admin roles and activate them only for the run.

## Run it

### 1. Export the agent usage report (optional, recommended)

Microsoft 365 admin center > **Reports > Usage > Microsoft Copilot > Agents**. Pick 30 days and select **Export**. If names show as hashes, that's the report privacy setting. The script only needs the agent ID and last activity date columns.

### 2. Build the report

```powershell
.\Get-StaleAgentReport.ps1 -Days 90 -AgentUsageCsv .\AgentUsage.csv
```

Output goes to `.\StaleAgentReport-<date-time>\`. Keep it out of source control (the `.gitignore` here already excludes it).

| Status | Meaning |
| --- | --- |
| Active | Used within `-Days` |
| Stale | Last used before `-Days` |
| New | Created (or for agents, last changed) within `-Days`, never used |
| NoActivity | Older than `-Days`, no use recorded |
| NoUsageData | Agent with no identity and no usage export to check |
| NoPrincipal | Blueprint registered here but never added to this tenant. It may be used in other tenants |

| Recommendation | What the cleanup script does |
| --- | --- |
| Disable | Disables the agent identity or blueprint principal |
| Block | Blocks the agent in the registry |
| Keep, Review, AlreadyDisabled, AlreadyBlocked | Nothing |

The script never recommends Disable when it couldn't read sign-in activity; you get Review instead. Microsoft-built agents are always Keep.

Two more safety rules, from testing in a live tenant:
- **NoActivity is Review, not Disable.** Copilot Studio agent identities can be in use without a recorded sign-in of their own, so an identity that has never signed in needs a sponsor check first. Only identities that signed in before and then stopped (Stale) get Disable.
- **Blueprints from Microsoft or other publishers are Review.** A blueprint principal with no blueprint registered in your tenant (such as the Copilot Studio agent identity blueprint) backs every agent built on that product. Disabling it breaks all of them.

### 3. Review the CSVs

Open the CSVs and change `recommendation` to `Keep` for anything you want to keep: seasonal agents, break-glass agents, anything a sponsor vouches for. Check `sponsorCount` and `ownerCount` on stale identities; zero for both means nobody is accountable for it.

### 4. Clean up

```powershell
# See what would change
.\Invoke-StaleAgentCleanup.ps1 -ReportFolder .\StaleAgentReport-20261030-2100 -DisableAgentIdentities -BlockPackages -WhatIf

# Do it (prompts for each change; add -Confirm:$false to skip the prompts)
.\Invoke-StaleAgentCleanup.ps1 -ReportFolder .\StaleAgentReport-20261030-2100 -DisableAgentIdentities -BlockPackages

# Blueprints last, after their agents have been disabled for a while
.\Invoke-StaleAgentCleanup.ps1 -ReportFolder .\StaleAgentReport-20261030-2100 -DisableBlueprints
```

Disabling a blueprint principal stops every agent identity under it from getting tokens in this tenant.

### 5. Undo

Each run writes `cleanup-undo-<date-time>.json` to the report folder.

```powershell
.\Invoke-StaleAgentCleanup.ps1 -ReportFolder .\StaleAgentReport-20261030-2100 -Restore -UndoFile .\StaleAgentReport-20261030-2100\cleanup-undo-20261030-2115.json
```

## Why disable instead of delete

- A disabled identity keeps its permissions, owners and sponsors, so you can turn it back on.
- Deleting a blueprint or its principal deletes every child agent identity and agent user account with it (cascade cleanup). The 30-day soft-delete window is the only way back.
- Let Entra do the deleting. Turn on the **Agent ID default inactivity policy** (preview, no extra license): Entra admin center > **ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID (Preview)**. It notifies sponsors and owners at 60 days inactive, disables at 90 and deletes at 455. Use **All Agent IDs except selected** to exclude seasonal agents. Custom lifecycle policies need an ID Governance license.

## Run it in Copilot Cowork

See **[Cowork/readme.md](Cowork/readme.md)** for setup. Cowork reads agent identities, blueprints and sign-in activity live through the Microsoft MCP Server for Enterprise. The MCP server can't read the Agent 365 registry (no MCP scope covers it, so the call returns 403), so for agents you attach `AgentPackages.csv` or the admin center Agent usage export.

- **Changes stay in the script.** Blocking and disabling need write scopes, `-WhatIf` and an undo file, so keep them in `Invoke-StaleAgentCleanup.ps1` rather than giving an agent write access.

## References

- [Graph API for agent registry and agent details](https://learn.microsoft.com/microsoft-agent-365/admin/graph-api)
- [List packages](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/copilotpackages-list) and [copilotPackage resource](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/resources/copilotpackage)
- [Block a package](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/copilotpackage-block)
- [agentIdentity resource](https://learn.microsoft.com/graph/api/resources/agentidentity?view=graph-rest-beta) and [Update agentIdentity](https://learn.microsoft.com/graph/api/agentidentity-update?view=graph-rest-beta)
- [Update agentIdentityBlueprintPrincipal](https://learn.microsoft.com/graph/api/agentidentityblueprintprincipal-update?view=graph-rest-1.0)
- [List servicePrincipalSignInActivities](https://learn.microsoft.com/graph/api/reportroot-list-serviceprincipalsigninactivities?view=graph-rest-beta)
- [Agent identity deletion (cascade cleanup)](https://learn.microsoft.com/entra/agent-id/concept-agent-identity-deletion)
- [Disable agent identities](https://learn.microsoft.com/entra/agent-id/disable-agent-identities)
- [Agent ID default inactivity policy](https://learn.microsoft.com/entra/id-governance/agent-default-inactivity-policy)
- [Microsoft Copilot Agents usage report](https://learn.microsoft.com/microsoft-365/admin/activity-reports/microsoft-365-copilot-agents-new)
