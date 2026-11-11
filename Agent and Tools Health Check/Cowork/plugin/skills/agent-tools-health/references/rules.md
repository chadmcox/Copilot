# Rules

Thresholds: stale after 90 days, credential warning 30 days before expiry, pending requests older than 14 days. The user can change them in the prompt. Copilot agent adoption uses a fixed 90-day usage report and a 5% threshold, and isn't one of the prompt-configurable thresholds.

**Unclear name** (this repo's list, not Microsoft's; Microsoft recommends a naming convention but publishes no word list): empty, fewer than 4 characters, or contains a word starting with *test*, *demo*, *sample* or *sandbox*, or the words *temp*, *tmp*, *copy*, *draft*, *POC*, *untitled*, *dummy*, *delete me*, *do not use*; or starts with *new agent*, *my agent*, *new plugin*, *my bot* and similar; or ends with a number after agent/plugin/skill/bot (*Agent 2*) or a copy marker (*(1)*). For agent identities, ignore the " (Microsoft Copilot Studio)" suffix before checking.

**Poor description**: empty, under 20 characters, or the same as the name.

**High-privilege Microsoft Graph permissions** (this repo's list; Microsoft's guidance is least privilege, with no fixed list): `Directory.*`, `RoleManagement.*`, `Application.*`, `AppRoleAssignment.*`, `Policy.*`, `User.*`, `Group.*`, `GroupMember.*`, `Domain.*`, `Organization.*` when they're ReadWrite, plus `Mail.Send`, `Mail.ReadWrite`, `Sites.FullControl.All`, `Sites.ReadWrite.All`, `Files.ReadWrite.All`, `Directory.AccessAsUser.All`, `full_access_as_app`. Any other `*.ReadWrite.All` is **tenant-wide write**.

Every check also carries a **Reference** (CIS Controls v8.1 safeguards and the CISA risk category); see **guidance.md**.

**Maester** is the matching test in the [Maester AI governance pack](https://github.com/chadmcox/maester-ai-governance-pack) (— means the pack has no matching test). The coverage workflow in `.github/workflows/maester-coverage.yml` fails when a pack test isn't listed here.

Each finding has an **Area** (Agents, Tools, Agent identities, Blueprints, Tenant, Copilot adoption, Discovered agents, Agents without Agent ID, Connectors), an **Item** (the agent, tool, identity, blueprint or setting), a **Category** (Access, Ownership, Permissions, Naming, Usage, Security, Identity, Inventory), a **Severity**, a **Check** and a **Fix**.

**Only what users can reach.** Skip the access and MCP checks for a package that's blocked (`isBlocked` true) or available to no one (`availableTo` is `allowedForNone` or `none`). Empty values count as reachable.

Microsoft-published agents and tools, and blueprints from other publishers (a blueprint principal with no blueprint registered in this tenant), aren't checked for names, descriptions or use. Packages of kind **App** (Office add-ins, tabs) aren't checked.

## Agents and tools (from Packages.csv)

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| Custom or external, reachable, `availableTo` is all users (`all` or `allowedForAll`) | High | Access | Make it available to specific groups | MP.AIGOV.1007 |
| Custom or external, reachable, `deployedTo` is all users (`all` or `acquiredForAll`) | High | Access | Install it for a group, or let people install it themselves | MP.AIGOV.1007 |
| Reachable, an `mcpServers` entry starts with `http://` (no TLS) | High | Tools | Use HTTPS only, or remove the server | MP.AIGOV.1008 |
| Reachable, an `mcpServers` host isn't on this repo's list of Microsoft domains (same list as Discovered agents) | Low | Tools | Check it's on your approved tools list (Agents > Tools), and who runs it | MP.AIGOV.1010 |
| Reachable, an `mcpAuth` type is `None` | High | Tools | Require OAuth (Microsoft Entra ID) on the server, or remove it | MP.AIGOV.1016 |
| Reachable, custom or external, an `mcpAuth` type is `Unspecified` (no authorization block). Microsoft's own connectors have none and are authenticated by the platform, so skip Microsoft packages | Medium | Tools | Confirm how it authenticates, and require OAuth if it doesn't | MP.AIGOV.1016 |
| Reachable, an `mcpAuth` type is `ApiKeyPluginVault`, `AzureKeyVault` or `ConnectionVault` (a static secret). `OAuthPluginVault` and `DynamicClientRegistration` pass | Medium | Tools | Move it to OAuth so access follows the user, and rotate the secret until then | MP.AIGOV.1016 |
| Reachable, available or installed for all users, and `mcpRiskyTools` isn't empty | High | Tools | Limit the package to a group that needs these tools, or remove the tools | MP.AIGOV.1011 |
| Reachable, custom or external, available or installed for all users, and `skillsExposed` isn't empty (agent skills with `expose_skill_to_copilot` on) | Medium | Access | Limit the package to a group, or turn off expose to Copilot until the skill is reviewed | MP.AIGOV.1012 |
| Custom or external, `skillsWeakDescription` isn't empty (an agent skill's `SKILL.md` description is empty or under 40 characters; Copilot reads it to decide when to use the skill) | Medium | Naming | Describe when Copilot should use the skill and what it does | MP.AIGOV.1012 |
| `directUsers` more than 0 | Medium | Access | Assign it to a group instead | MP.AIGOV.1003 |
| An assigned group no longer exists | Medium | Access | Assign it to the right group | MP.AIGOV.1021 |
| An assigned group has fewer than two owners | Medium | Ownership | Add owners so there are at least two | MP.AIGOV.1021 |
| An assigned group has no description | Low | Access | Describe the group and name the agent or tool it's for | MP.AIGOV.1021 |
| Unclear name | Medium | Naming | Rename it so people can tell what it does and who owns it | MP.AIGOV.1006 |
| Poor description (`shortDescription`) | Medium | Naming | Describe what it does, for whom, and what data it uses | MP.AIGOV.1006 |
| `requestStatus` is pending, `isBlocked` is false, and `lastModifiedDateTime` is more than 14 days ago | Low | Usage | Approve or reject it | — |
| Custom agent whose `elementTypes` include customEngine or bot, with no `agentIdentityId` | Low | Identity | If it's a custom agent you own, move it to Agent ID so it gets a sponsor, Conditional Access and lifecycle controls | — |
| Not blocked, no `activeUsers30d`, `lastUsedDateTime` empty or older than 90 days, and `lastModifiedDateTime` older than 90 days | Medium | Usage | Block it, or run Agent and Tools Cleanup | MP.AIGOV.1020 |
| `isBlocked` is true and `requestStatus` is still pending | Low | Access | Tell the requester why it's blocked, or unblock it if that's no longer accurate | MP.AIGOV.1002 |

## Agent identities

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| No sponsor | High | Ownership | Add a sponsor: the person accountable for what it does | — |
| A sponsor or owner no longer exists, or is disabled | High | Ownership | Replace them with an active person | — |
| High-privilege Microsoft Graph permissions (app roles or admin-consented delegated grants) | High | Permissions | Replace them with narrower permissions (least privilege), or remove them | MP.AIGOV.1022 |
| Tenant-wide write permissions | Medium | Permissions | Check each one is needed; prefer Selected or narrower scopes | MP.AIGOV.1022 |
| Delegated grants a person consented to themselves (`consentType` is `Principal`), on any API. High if a scope is on the high-privilege list | Medium | Permissions | Revoke the user consents, grant only what it needs through admin consent, and turn off user consent for apps if it's on | MP.AIGOV.1019 |
| At risk in Identity Protection (`identityProtection/riskyAgents`, `riskState` is `atRisk`, not deleted). Confirmed compromised, confirmed safe, dismissed and remediated agents are already handled | High | Security | Investigate its sign-ins and activity, then confirm it compromised (blocks it) or dismiss the risk | MP.AIGOV.1018 |
| One sponsor and no owner | Medium | Ownership | Add an owner (technical admin) or a second sponsor | MP.AIGOV.1004 |
| Unclear name | Medium | Naming | Rename the agent so people can tell what it does and who owns it | MP.AIGOV.1023 |
| Enabled, last sign-in older than 90 days | Medium | Usage | Ask the sponsor if it's still needed, or run Agent and Tools Cleanup | — |
| Enabled, no sign-in recorded, created more than 90 days ago | Low | Usage | Ask the sponsor if it's still needed | — |
| Has an agent user account | Low | Permissions | Keep it only if the agent needs a mailbox or Teams presence | — |

## Blueprints (registered in this tenant)

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| No sponsor | High | Ownership | Add a sponsor | — |
| A sponsor or owner no longer exists, or is disabled | High | Ownership | Replace them with an active person | — |
| An inheritable permission has `inheritableScopes.kind` or `inheritableRoles.kind` = `allAllowed` | High | Permissions | List only the scopes its agents need (enumerated scopes) | — |
| The blueprint principal has high-privilege Graph permissions | High | Permissions | Replace them with narrower permissions, or remove them | MP.AIGOV.1022 |
| One sponsor and no owner | Medium | Ownership | Add an owner or a second sponsor | MP.AIGOV.1004 |
| Has a client secret (`passwordCredentials`) | Medium | Permissions | Use a certificate or a federated credential (managed identity) instead | — |
| A credential expired, or expires within 30 days | Medium | Permissions | Remove it, or roll it before then | MP.AIGOV.1009 |
| Unclear name | Medium | Naming | Rename it so people can tell which agents it's for | MP.AIGOV.1023 |
| Poor description | Medium | Naming | Describe its purpose, scope and owning team | MP.AIGOV.1023 |
| No enabled agent identity signed in or created within 90 days, the blueprint hasn't signed in for 90 days, and it's older than 90 days | Low | Usage | Check it's still needed, or run Agent and Tools Cleanup | — |

## Tenant

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| No Conditional Access policy targets agent identities (`conditions.clientApplications.includeAgentIdServicePrincipals` or `agentIdServicePrincipalFilter`, `conditions.agents`, or `conditions.agentIdRiskLevels`) | High | Security | Create agent policies (start in report-only): block high-risk agents, and limit what non-production agents reach | MP.AIGOV.1017 |
| Agent policies exist, but none is `enabled` | Medium | Security | Review the report-only results, then turn them on | MP.AIGOV.1017 |
| No enabled policy with `agentIdRiskLevels` including high and a `block` grant | Medium | Security | Add a policy that blocks agent identities at high risk | — |

## Copilot adoption

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| Agents exist in the catalog, but fewer than 5% of licensed Microsoft 365 Copilot users used one in the last 90 days, out of at least 20 reported users (Microsoft 365 Copilot usage report, `getMicrosoft365CopilotUsageUserDetail`) | Low | Usage | Check that agents are pinned and discoverable, and that people know they exist; recheck after any awareness push | MP.AIGOV.1001 |

## Discovered agents (from DefenderAgents.csv)

Microsoft Defender's `AgentsInfo` inventory covers Copilot Studio, Foundry, third-party and local (endpoint) agents. An agent is **in the registry** when its `AgentId`, `SourceAgentId` or `EntraAgentId` matches a Packages.csv `id`, `appId`, `manifestId`, `assetId` or `agentIdentityId`. Skip the registry checks if Packages.csv isn't attached. Ignore agents whose `LifecycleStatus` is `Uninstalled`. Item name: "AgentName (Platform)".

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| Cloud agent (Platform isn't `LocalAgents`) not in the registry | Medium | Inventory | Add it to the registry (registry sync) with an owner, or remove it | — |
| Not in the registry, and `Availability` is all users | High | Inventory | Limit it to a group, then register it | — |
| Not in the registry, and `OwnerCount` is 0 | Medium | Ownership | Find who built it and make them the owner, or remove it | — |
| Cloud agent with no `EntraAgentId` | Medium | Identity | Find who owns it and whether its platform supports Agent ID; an agent identity adds a sponsor, Conditional Access and lifecycle controls | — |
| An `McpServerUrls` entry starts with `http://` (no TLS). Skip a scheme and host that a matching Packages.csv row already lists in `mcpServers` | High | Tools | Use HTTPS only, or remove the server | — |
| An `McpServerUrls` host isn't on this repo's list of Microsoft domains (not a Microsoft-published list: not under microsoft.com, cloud.microsoft, office.com, sharepoint.com, azure.com, azure-api.net, windows.net, dynamics.com, powerplatform.com, azurewebsites.net) | Low | Tools | Check it's on your approved tools list (Agents > Tools), and who runs it | — |
| **No Packages.csv** (no Agent 365 catalog): Defender's agents become the agent list. Cloud agent `Availability` is all users | High | Access | Make it available to specific groups | — |
| No Packages.csv: `OwnerCount` is 0 | Medium | Ownership | Find who built it and make them the owner, or remove it | — |
| No Packages.csv: unclear `AgentName` | Medium | Naming | Rename it so people can tell what it does and who owns it | — |

`LastActivity`, `Invocations30d` and `ToolCalls30d` come from Agent 365 activity in Defender (`CloudAppEvents`, last 30 days), matched on the agent's Entra appId (the invoked agent is `TargetAgentId` on `InvokeAgent` records and `AgentId` on tool calls). The match to AgentsInfo on `EntraAgentId` is this repo's, not a documented join. When an agent in Packages.csv matches a Defender agent with a `LastActivity` within the stale period, it counts as used: don't report "Not used". A Defender agent without activity isn't proof it's unused, because only agents that send Agent 365 observability data appear there.
| Local agent (Platform `LocalAgents`, not Uninstalled), one finding per agent name with the installation count (each row is one agent on one device for one account) | Low | Inventory | Check it's an approved tool; govern it with Defender for Endpoint and Intune | — |

## Connectors (synced Copilot connectors, from Connectors.csv)

Only connections users can search: `state` is ready, or limitExceeded (the index is full but what's in it is still searchable). The rollout audience and per-item access rules aren't in Graph; they're a manual check.

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| An `authorizedAppIds` entry has no service principal in this tenant | Medium | Security | Remove it from the connection, or find out what it is before you keep it | MP.AIGOV.1033 |
| An authorized app's `appOwnerOrganizationId` isn't this tenant or Microsoft's (f8cdef31-a31e-4b4a-93e4-5f571e91255a, 72f988bf-86f1-41af-91ab-2d7cd011db47) | Medium | Security | Confirm the vendor and what it indexes, or remove it from the connection | MP.AIGOV.1033 |
| `state` is limitExceeded | Low | Usage | Raise the index quota, or narrow what the connector indexes | MP.AIGOV.1033 |
| No `description` | Low | Naming | Describe what the connection holds and who it's for | MP.AIGOV.1033 |

## Agents without Agent ID (classic service principals)

Older Copilot Studio agents run as ordinary service principals. Find them by the tags Microsoft documents for Copilot Studio: `AgentCreatedBy:CopilotStudio`, `AgenticApp`, `AIAgentBuilder`, `AgenticInstance`, or a tag starting with `power-virtual-agents-`. Leave out anything that's an agent identity or a blueprint principal.

| Check | Severity | Category | Fix | Maester |
| --- | --- | --- | --- | --- |
| Runs as a classic service principal, not an Agent ID | Medium | Identity | There's no in-place migration. Unused: retire it. Lightly used: recreate it with Agent ID, then retire this one. Busy production agent: Microsoft says wait for an automated migration path | MP.AIGOV.1005 |
| No owner | Medium | Ownership | Find who built it and make them the owner | MP.AIGOV.1024 |
| Enabled, no sign-in for 90 days, older than 90 days | Low | Usage | Check with the owner, then retire it instead of recreating it | MP.AIGOV.1024 |

## Scoring

Every item starts at 100: High −25, Medium −10, Low −3 (Info 0), never below 0. An area's score is the average of its items' scores; an area with no items scores 100. Rating: Green 80+, Amber 50–79, Red under 50. Copilot adoption is its own area, with one item ("Copilot agent adoption", only when the Copilot usage report was read) kept separate from Tenant so it never averages with "Conditional Access" and can't pad or dilute either area's score. Discovered agents and Agents without Agent ID only appear when there is data for them.

## Well-governed funnel (agent identities)

1. Agent identities: all of them.
2. With an active sponsor: no "No sponsor", "no longer exists" or "is disabled" finding.
3. With a clear name: and no "Unclear name" finding.
4. Least privilege: and no "High-privilege" finding.
5. In use: and no "No sign-in" finding.

Well governed % = step 5 ÷ step 1.

## Manual checks (no API, or not readable through the Enterprise MCP)

- Entra > Entra ID > Users > User settings: **Users can register agent identity blueprints** (Microsoft docs call it *Users can create agent blueprints*) is No. It's Yes by default.
- Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID (Preview): the **default inactivity policy** (preview) is on. It notifies at 60 days, disables at 90, deletes at 455.
- Microsoft 365 admin center > Agents > Settings > **Agent and plugin access**: **Allow agents and plugins built by external publishers** is off, or reviewed.
- Microsoft 365 admin center > Agents > Settings > **Sharing**: Specific users, not All users (applies only to Agent Builder agents).
- Agents > Tools > Registry: standalone MCP servers and skills have clear names, owners and group-scoped availability.
- Copilot > Connectors > Your connections: each synced connector is rolled out to the right people, and none is set so every user sees all content.
- Sponsors attested each agent in the last 12 months (Microsoft suggests every 6 to 12 months) (the attestation API isn't readable through the Enterprise MCP).

If the browser is available in Cowork, read these pages and report what you see. Never change a setting.
