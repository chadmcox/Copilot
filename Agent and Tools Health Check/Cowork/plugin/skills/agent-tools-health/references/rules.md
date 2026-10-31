# Rules

Thresholds: stale after 90 days, credential warning 30 days before expiry, pending requests older than 14 days. The user can change them in the prompt.

**Unclear name**: empty, fewer than 4 characters, or contains a word starting with *test*, *demo*, *sample* or *sandbox*, or the words *temp*, *tmp*, *copy*, *draft*, *POC*, *untitled*, *dummy*, *delete me*, *do not use*; or starts with *new agent*, *my agent*, *new plugin*, *my bot* and similar; or ends with a number after agent/plugin/skill/bot (*Agent 2*) or a copy marker (*(1)*). For agent identities, ignore the " (Microsoft Copilot Studio)" suffix before checking.

**Poor description**: empty, under 20 characters, or the same as the name.

**High-privilege Microsoft Graph permissions**: `Directory.*`, `RoleManagement.*`, `Application.*`, `AppRoleAssignment.*`, `Policy.*`, `User.*`, `Group.*`, `GroupMember.*`, `Domain.*`, `Organization.*` when they're ReadWrite, plus `Mail.Send`, `Mail.ReadWrite`, `Sites.FullControl.All`, `Sites.ReadWrite.All`, `Files.ReadWrite.All`, `Directory.AccessAsUser.All`, `full_access_as_app`. Any other `*.ReadWrite.All` is **tenant-wide write**.

Every check also carries a **Reference** (CIS Controls v8.1 safeguards and the CISA risk category); see **guidance.md**.

Each finding has an **Area** (Agents, Tools, Agent identities, Blueprints, Tenant, Discovered agents, Agents without Agent ID), an **Item** (the agent, tool, identity, blueprint or setting), a **Category** (Access, Ownership, Permissions, Naming, Usage, Security, Identity, Inventory), a **Severity**, a **Check** and a **Fix**.

Microsoft-published agents and tools, and blueprints from other publishers (a blueprint principal with no blueprint registered in this tenant), aren't checked for names, descriptions or use. Packages of kind **App** (Office add-ins, tabs) aren't checked.

## Agents and tools (from Packages.csv)

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| Custom or external, `availableTo` is all users (`all` or `allowedForAll`) | High | Access | Make it available to specific groups |
| Custom or external, `deployedTo` is all users (`all` or `acquiredForAll`) | High | Access | Install it for a group, or let people install it themselves |
| `directUsers` more than 0 | Medium | Access | Assign it to a group instead |
| An assigned group no longer exists | Medium | Access | Assign it to the right group |
| An assigned group has fewer than two owners | Medium | Ownership | Add owners so there are at least two |
| An assigned group has no description | Low | Access | Describe the group and name the agent or tool it's for |
| Unclear name | Medium | Naming | Rename it so people can tell what it does and who owns it |
| Poor description (`shortDescription`) | Medium | Naming | Describe what it does, for whom, and what data it uses |
| `requestStatus` is pending and `lastModifiedDateTime` is more than 14 days ago | Low | Usage | Approve or reject it |
| Custom agent whose `elementTypes` include customEngine or bot, with no `agentIdentityId` | Low | Identity | Recreate it with Agent ID so it gets a sponsor, Conditional Access and lifecycle controls |
| Not blocked, no `activeUsers30d`, `lastUsedDateTime` empty or older than 90 days, and `lastModifiedDateTime` older than 90 days | Medium | Usage | Block it, or run Agent and Tools Cleanup |

## Agent identities

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| No sponsor | High | Ownership | Add a sponsor: the person accountable for what it does |
| A sponsor or owner no longer exists, or is disabled | High | Ownership | Replace them with an active person |
| High-privilege Microsoft Graph permissions (app roles or admin-consented delegated grants) | High | Permissions | Replace them with narrower permissions (least privilege), or remove them |
| Tenant-wide write permissions | Medium | Permissions | Check each one is needed; prefer Selected or narrower scopes |
| One sponsor and no owner | Medium | Ownership | Add an owner (technical admin) or a second sponsor |
| Unclear name | Medium | Naming | Rename the agent so people can tell what it does and who owns it |
| Enabled, last sign-in older than 90 days | Medium | Usage | Ask the sponsor if it's still needed, or run Agent and Tools Cleanup |
| Enabled, no sign-in recorded, created more than 90 days ago | Low | Usage | Ask the sponsor if it's still needed |
| Has an agent user account | Low | Permissions | Keep it only if the agent needs a mailbox or Teams presence |

## Blueprints (registered in this tenant)

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| No sponsor | High | Ownership | Add a sponsor |
| A sponsor or owner no longer exists, or is disabled | High | Ownership | Replace them with an active person |
| An inheritable permission has `inheritableScopes.kind` or `inheritableRoles.kind` = `allAllowed` | High | Permissions | List only the scopes its agents need (enumerated scopes) |
| The blueprint principal has high-privilege Graph permissions | High | Permissions | Replace them with narrower permissions, or remove them |
| One sponsor and no owner | Medium | Ownership | Add an owner or a second sponsor |
| Has a client secret (`passwordCredentials`) | Medium | Permissions | Use a certificate or a federated credential (managed identity) instead |
| A credential expired, or expires within 30 days | Medium | Permissions | Remove it, or roll it before then |
| Unclear name | Medium | Naming | Rename it so people can tell which agents it's for |
| Poor description | Medium | Naming | Describe its purpose, scope and owning team |
| No enabled agent identity signed in or created within 90 days, the blueprint hasn't signed in for 90 days, and it's older than 90 days | Low | Usage | Check it's still needed, or run Agent and Tools Cleanup |

## Tenant

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| No Conditional Access policy targets agent identities (`conditions.clientApplications.includeAgentIdServicePrincipals` or `agentIdServicePrincipalFilter`, `conditions.agents`, or `conditions.agentIdRiskLevels`) | High | Security | Create agent policies (start in report-only): block high-risk agents, and limit what non-production agents reach |
| Agent policies exist, but none is `enabled` | Medium | Security | Review the report-only results, then turn them on |
| No enabled policy with `agentIdRiskLevels` including high and a `block` grant | Medium | Security | Add a policy that blocks agent identities at high risk |

## Discovered agents (from DefenderAgents.csv)

Microsoft Defender's `AgentsInfo` inventory covers Copilot Studio, Foundry, third-party and local (endpoint) agents. An agent is **in the registry** when its `AgentId`, `SourceAgentId` or `EntraAgentId` matches a Packages.csv `id`, `appId`, `manifestId`, `assetId` or `agentIdentityId`. Skip the registry checks if Packages.csv isn't attached. Ignore agents whose `LifecycleStatus` is `Uninstalled`. Item name: "AgentName (Platform)".

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| Cloud agent (Platform isn't `LocalAgents`) not in the registry | Medium | Inventory | Add it to the registry (registry sync) with an owner, or remove it |
| Not in the registry, and `Availability` is all users | High | Inventory | Limit it to a group, then register it |
| Not in the registry, and `OwnerCount` is 0 | Medium | Ownership | Find who built it and make them the owner, or remove it |
| Cloud agent with no `EntraAgentId` | Medium | Identity | Recreate or register it with an Agent ID so it gets a sponsor, Conditional Access and lifecycle controls |
| An `McpServerUrls` entry starts with `http://` (no TLS) | High | Tools | Use HTTPS only, or remove the server |
| An `McpServerUrls` host isn't Microsoft-run (not under microsoft.com, cloud.microsoft, office.com, sharepoint.com, azure.com, azure-api.net, windows.net, dynamics.com, powerplatform.com, azurewebsites.net) | Low | Tools | Check it's on your approved tools list (Agents > Tools), and who runs it |
| **No Packages.csv** (no Agent 365 catalog): Defender's agents become the agent list. Cloud agent `Availability` is all users | High | Access | Make it available to specific groups |
| No Packages.csv: `OwnerCount` is 0 | Medium | Ownership | Find who built it and make them the owner, or remove it |
| No Packages.csv: unclear `AgentName` | Medium | Naming | Rename it so people can tell what it does and who owns it |

`LastActivity`, `Invocations30d` and `ToolCalls30d` come from Agent 365 activity in Defender (`CloudAppEvents`, last 30 days). When an agent in Packages.csv matches a Defender agent with a `LastActivity` within the stale period, it counts as used: don't report "Not used". A Defender agent without activity isn't proof it's unused, because only agents that send Agent 365 observability data appear there.
| Local agent (Platform `LocalAgents`), one finding per agent name with the device count | Low | Inventory | Check it's an approved tool; govern it with Defender for Endpoint and Intune |

## Agents without Agent ID (classic service principals)

Older Copilot Studio and Foundry agents run as ordinary service principals. Find them by tag: `AgentCreatedBy:CopilotStudio`, `AgenticApp`, `AIAgentBuilder`, `AgenticInstance`, or a tag starting with `power-virtual-agents-`. Leave out anything that's an agent identity or a blueprint principal.

| Check | Severity | Category | Fix |
| --- | --- | --- | --- |
| Runs as a classic service principal, not an Agent ID | Medium | Identity | Recreate it with Agent ID (there's no in-place migration), then retire this service principal |
| No owner | Medium | Ownership | Find who built it and make them the owner |
| Enabled, no sign-in for 90 days, older than 90 days | Low | Usage | Check with the owner, then retire it instead of recreating it |

## Scoring

Every item starts at 100: High −25, Medium −10, Low −3 (Info 0), never below 0. An area's score is the average of its items' scores; an area with no items scores 100. Rating: Green 80+, Amber 50–79, Red under 50. The Tenant area has one item, "Conditional Access". Discovered agents and Agents without Agent ID only appear when there is data for them.

## Well-governed funnel (agent identities)

1. Agent identities: all of them.
2. With an active sponsor: no "No sponsor", "no longer exists" or "is disabled" finding.
3. With a clear name: and no "Unclear name" finding.
4. Least privilege: and no "High-privilege" finding.
5. In use: and no "No sign-in" finding.

Well governed % = step 5 ÷ step 1.

## Manual checks (no API, or not readable through the Enterprise MCP)

- Entra > Entra ID > Users > User settings: **Users can register agent identity blueprints** is No.
- Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID: the **default inactivity policy** is on.
- Microsoft 365 admin center > Agents > Settings > **Agent and plugin access**: external publishers are off, or reviewed.
- Microsoft 365 admin center > Agents > Settings > **Sharing**: limited to a group.
- Agents > Tools > Registry: standalone MCP servers and skills have clear names, owners and group-scoped availability.
- Sponsors attested each agent in the last 12 months (the attestation API isn't readable through the Enterprise MCP).

If the browser is available in Cowork, read these pages and report what you see. Never change a setting.
