# Agent and Tools Health Check

Updated Oct 31, 2026

A read-only check of how well your Copilot agents and tools, Entra agent identities and agent identity blueprints are set up, with a score per area and a fix for every finding. It works like the [Copilot Billing Health Check](../Billing%20Health%20Check/README.md): run it in **Copilot Cowork**, or from PowerShell.

> **Health check vs cleanup.** This folder asks *"is it set up right?"* [Agent and Tools Cleanup](../Agent%20and%20Tools%20Cleanup/README.md) asks *"is it used?"* and blocks or disables what isn't. The health check flags stale items and points you there.

## Run it

| Way | How |
| --- | --- |
| **Copilot Cowork** (recommended) | Set up the plugin once, attach `Packages.csv` and `DefenderAgents.csv`, paste the prompt. See **[Cowork/readme.md](Cowork/readme.md)** |
| **PowerShell** | `.\Get-AgentToolsHealth.ps1`. Writes Findings.csv, Scorecard.csv, Packages.csv, DefenderAgents.csv and Report.html |

```powershell
.\Get-AgentToolsHealth.ps1                  # full check
.\Get-AgentToolsHealth.ps1 -StaleDays 60    # stale after 60 days instead of 90
.\Get-AgentToolsHealth.ps1 -PackagesOnly    # just Packages.csv and DefenderAgents.csv, to attach in Cowork
.\Get-AgentToolsHealth.ps1 -SkipPackages    # no Agent 365 license
.\Get-AgentToolsHealth.ps1 -SkipDefender    # no Defender (or no Security Reader)
```

Both give the same HTML report from the same template: a score dial, a card per area, the well-governed funnel for agent identities, filterable findings, CSV export, print, and a manual checklist.

## What good looks like (the rules)

Based on Microsoft's [Entra Agent ID best practices](https://learn.microsoft.com/entra/agent-id/best-practices-agent-id): every agent has a sponsor and an owner, a clear name and description, least-privilege permissions, group-scoped access and Conditional Access, and gets reviewed when it stops being used. The full rule list is in [rules.md](Cowork/plugin/skills/agent-tools-health/references/rules.md).

| Area | Checks |
| --- | --- |
| **Agents and tools** | Available to or installed for everyone instead of groups (High). Assigned to people directly; groups with fewer than two owners or no description. Unclear name, missing description. Old pending requests. Not used in 90 days |
| **Agent identities** | No sponsor, or a sponsor or owner disabled or gone (High). High-privilege Graph permissions such as Mail.Send or Directory.ReadWrite.All (High). One sponsor and no owner. Unclear name. No sign-in for 90 days, or never. Agent user accounts |
| **Blueprints** | Inheritable permissions set to All allowed (High). No sponsor (High). Client secrets instead of certificates or federated credentials, expiring credentials. Unclear name, no description. Nothing active under it |
| **Tenant** | No Conditional Access policy for agent identities (High). Agent policies only report-only. No policy blocking high-risk agents |
| **Discovered agents** (Microsoft Defender, KQL) | Agents Defender found (`AgentsInfo`: Copilot Studio, Foundry, third-party) that aren't in the Agent 365 registry, especially ones available to everyone (High) or with no owner. Cloud agents with no Entra Agent ID. **MCP servers** the agents use: over plain http (High), or on a host outside this script's list of Microsoft domains (Low; check it against your approved tools). Local AI agents found on devices (needs Defender for Endpoint Plan 2). Without the Agent 365 catalog, Defender's list becomes the agent list |
| **Agents without Agent ID** | Older Copilot Studio agents still running as classic service principals (found by their `AgentCreatedBy:CopilotStudio`, `AgenticApp` and similar tags), which miss Agent ID controls such as agent Conditional Access and lifecycle policies. There's no in-place migration. Microsoft's guidance: retire unused ones, recreate lightly used ones with Agent ID, and leave busy production agents until Microsoft ships an automated migration path |

**Unclear names** (this repo's list, not Microsoft's; Microsoft only recommends [a naming convention](https://learn.microsoft.com/entra/agent-id/best-practices-agent-id#govern-the-agent-lifecycle), such as a department prefix) are flagged when a name has *test*, *demo*, *temp*, *copy*, *draft*, *sample*, *POC*, *sandbox*, *untitled*, *dummy*, *do not use*, starts with *new agent* or *my agent*, ends in *Agent 2* or *(1)*, or is under four characters. Change the list with `-UnclearNamePattern`. **High-privilege permissions** are also this repo's list (`-HighPrivilegePattern`); Microsoft's guidance is least privilege, without a fixed list.

**Guidance**: every finding names the CIS Controls v8.1 safeguards and the CISA risk category behind it, in the Reference column of Findings.csv and in brackets after the fix in the report. See [CISA and CIS guidance](#cisa-and-cis-guidance).

**Scores**: every item starts at 100 (High −25, Medium −10, Low −3); an area's score is the average of its items. Green 80+, Amber 50–79, Red under 50.

Microsoft-published agents and tools, and blueprints from other publishers, aren't checked for names, descriptions or use, because they aren't yours to fix.

## CISA and CIS guidance

The checks follow two recent government and industry sources, plus Microsoft's own best practices. The full mapping, check by check, is in [guidance.md](Cowork/plugin/skills/agent-tools-health/references/guidance.md).

- **CISA, NSA and partner agencies from Australia, Canada, New Zealand and the UK: [*Careful Adoption of Agentic AI Services*](https://www.cisa.gov/resources-tools/resources/careful-adoption-agentic-ai-services)** (reports date it April 30 or May 1, 2026). It sorts agent risk into five categories: privilege, design and configuration, behavioral, structural, and accountability. Reports on it stress least privilege. *I couldn't open the cisa.gov page when writing this; the categories and date come from several published summaries. Read the original before you cite it.*
- **CIS: [AI Agent](https://www.cisecurity.org/insights/white-papers/controls-v8-1-ai-agents-companion-guide) and [MCP](https://www.cisecurity.org/insights/white-papers/controls-v8-1-model-context-protocol-companion-guide) Companion Guides for CIS Controls v8.1** (April 20, 2026). Per CIS, the agent guide covers safe tool execution, governed autonomy and appropriate access to enterprise systems; the MCP guide covers secure tool access, non-human identity management and auditable interactions.

| What this check covers | CIS v8.1 (our mapping) | CISA risk category (our mapping) |
| --- | --- | --- |
| One inventory of agents; unregistered and local agents | 1.1, 2.1, 2.3, 2.5 | Accountability; design and configuration |
| Sponsors, owners, clear names and descriptions | 5.1, 5.5, 2.1 | Accountability |
| Group-scoped access instead of everyone | 6.1, 6.8 | Privilege |
| Least-privilege permissions; no All allowed inheritance | 3.3, 5.4, 6.8 | Privilege; structural |
| Agent ID instead of classic service principals | 5.5, 5.6 | Design and configuration; accountability |
| Credentials and Conditional Access for agents | 4.1, 6.7 | Design and configuration; behavioral |
| Stale agents and tools | 5.3, 6.2 | Accountability |

**Stale threshold:** CIS Safeguard 5.3 says to delete or disable dormant accounts after **45 days** of inactivity, where supported. The default here is 90; run `-StaleDays 45` to match CIS. (Entra's own default inactivity policy notifies at 60 days and disables at 90.)

**Not checked here:** logging of agent actions (CIS 8.2; confirm Purview audit and Defender are on), human oversight of high-impact actions (set in each agent's design), and which tools are approved (Agents > Tools; block unused ones with [Agent and Tools Cleanup](../Agent%20and%20Tools%20Cleanup/README.md)).

The safeguard titles are CIS's. **Which safeguard and which CISA category each check maps to is this repo's judgment**, not something CIS or CISA published. Check it against the guides before you cite it in an audit.

## KQL through Microsoft Graph

The Defender parts run KQL through Graph advanced hunting (`POST /beta/security/runHuntingQuery`, scope ThreatHunting.Read.All, role Security Reader, Global Reader, Security Operator or Security Administrator). The script asks for 30 days (`timespan` P30D, also the API's default).

- **AgentsInfo**: the agent inventory, with each agent's Entra Agent ID, availability, owners, MCP servers, skills and tools. Local agents have `Platform == "LocalAgents"`; each of their rows is one installation (one agent, device and account).
- **CloudAppEvents**: Agent 365 activity (`InvokeAgent`, `ExecuteToolByMCPServer` and other tool calls), used as another "last used" date. Per Microsoft's [attribute reference](https://learn.microsoft.com/microsoft-agent-365/developer/observability-attribute-reference), the invoked agent on an `InvokeAgent` record is `RawEventData.TargetAgentId` (its `AgentId` is the *calling* agent, all zeros when a person invoked it); on tool calls it's `RawEventData.AgentId`. Both are the agent's Entra appId, which the script matches to `AgentsInfo.EntraAgentId` (the same value for Agent ID agents). That match is ours; Microsoft doesn't document a join between the two tables. Only agents that send Agent 365 observability data show up, and the table needs the Microsoft 365 app connector in Defender for Cloud Apps, so no activity here isn't proof an agent is unused.

The same queries work in the Defender portal under **Hunting > Advanced hunting**; they're in the script (`Get-DefenderAgent`, `Get-DefenderActivity`).

## Not covered by any API (manual checklist in the report)

- **Users can register agent identity blueprints** (Microsoft docs call it *Users can create agent blueprints*) is No (Entra > Entra ID > Users > User settings). It's Yes by default.
- The **Agent ID default inactivity policy** (preview) is on (Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID (Preview)). It notifies sponsors and owners at 60 days, disables at 90 and deletes at 455.
- **Allow agents and plugins built by external publishers** is off or reviewed (admin center > Agents > Settings > Agent and plugin access), and **Sharing** is set to specific users (Agents > Settings > Sharing; it applies only to Agent Builder agents).
- **Standalone MCP servers and skills** in Agents > Tools > Registry have clear names, owners and group-scoped availability.
- Sponsors **attested** each agent in the last 12 months (Microsoft suggests every 6 to 12 months).

With browser access on, Cowork can read these pages and report what they're set to.

## Who runs it: Copilot Health Check Users

Put the people who run the health checks in one group: **Copilot Health Check Users**. The same group runs both the [Billing](../Billing%20Health%20Check/README.md) and [Agent and Tools](../Agent%20and%20Tools%20Health%20Check/README.md) health checks.

1. **Create it as a role-assignable security group, and put it under PIM.** `New-CopilotGroups.ps1` and `New-CopilotAdminPim.ps1` in the [Group Assignment Guide](../Group%20Assignment%20Guide/readme.md#copilot-health-check-users) do both. The roles sit on the group, so Groups Administrators and User Administrators can't change its members (only Global Administrators, Privileged Role Administrators and the group's owners can; give it no owners). People activate it for 8 hours with MFA, a reason and approval instead of holding reader roles all the time. Microsoft recommends approval for groups used to activate Entra roles, and labels AI Reader a privileged role.
2. **Give the group reader roles only** (table below). Prefer these to Global Reader, which reads the whole tenant.
3. **Scope the Cowork plugin to the group** when you upload it: Agents > Tools > Registry > Upload > Scope users > Specific users or groups > Copilot Health Check Users.
4. Members also need a Microsoft 365 Copilot license and Cowork access to run the check in Copilot Cowork. The Enterprise MCP server acts as the signed-in person, so they see only what their activated roles allow.

| Entra role | What this check reads with it |
| --- | --- |
| **AI Reader** | Copilot agents and settings; agent identities, blueprints, blueprint principals, sponsors, owners; their app permissions and delegated grants; groups, users and agent users. *See the note below* |
| **Security Reader** | Sign-in activity, Conditional Access policies (Microsoft's least-privileged role for reading them), and Microsoft Defender advanced hunting (AgentsInfo, CloudAppEvents) |
| **Reports Reader** | Sign-in activity (also covered by Security Reader) |

**AI Reader and agent identities: test it.** The [Entra roles reference](https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference#ai-reader) gives AI Reader read access to agent identities, blueprints and blueprint principals. But the Graph pages for listing them ([agent identities](https://learn.microsoft.com/graph/api/agentidentity-list?view=graph-rest-beta), [blueprints](https://learn.microsoft.com/graph/api/agentidentityblueprint-list?view=graph-rest-beta), [blueprint principals](https://learn.microsoft.com/graph/api/agentidentityblueprintprincipal-list)) name only **Agent ID Administrator** for people who don't own them. If those reads return 403 with AI Reader active, that's the gap: use Global Reader for the run, or activate Copilot Agent ID Admin.

**The Agent 365 catalog** (agents and tools) is documented for AI Administrator or Global Administrator. Test it with AI Reader first. If it returns 403, either activate **Copilot Agent Management Admin** for that run, or use `-SkipPackages` and let the check use Defender's agent list instead.

**Making changes** (blocking agents and tools, disabling agent identities with [Agent and Tools Cleanup](../Agent%20and%20Tools%20Cleanup/README.md)) isn't part of the health check. Use **Copilot Agent Management Admin** and **Copilot Agent ID Admin** for that.

## Permissions (PowerShell)

Delegated: CopilotPackages.Read.All, Application.Read.All, AgentIdentity.Read.All, AgentIdentityBlueprint.Read.All, AgentIdentityBlueprintPrincipal.Read.All, AuditLog.Read.All, User.Read.All, Group.Read.All, Policy.Read.All, ThreatHunting.Read.All. Roles: activate **Copilot Health Check Users** (AI Reader, Security Reader, Reports Reader) in PIM for the run; see above. The catalog also needs a Microsoft Agent 365 license or Microsoft 365 E7.

Only `Connect-MgGraph` and `Invoke-MgGraphRequest` (module Microsoft.Graph.Authentication), Graph beta, Windows PowerShell 5.1 and PowerShell 7.

The output files name agents, groups and permissions. Keep them private; the `.gitignore` here excludes them.

## What's in this folder

| File | What it is |
| --- | --- |
| [Get-AgentToolsHealth.ps1](Get-AgentToolsHealth.ps1) | The PowerShell check, and `-PackagesOnly` to make Packages.csv for Cowork |
| [Cowork/](Cowork/readme.md) | Cowork setup guide, plugin, skill, rules and report template |

## References

- [Best practices for Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/best-practices-agent-id)
- [Inheritable permissions in Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/concept-inheritable-permissions)
- [Conditional Access for agents](https://learn.microsoft.com/entra/identity/conditional-access/agent-id)
- [Governing agent identities (sponsors)](https://learn.microsoft.com/entra/id-governance/agent-id-governance-overview)
- [Understand agent details: availability and installation](https://learn.microsoft.com/microsoft-agent-365/admin/agent-details)
- [Agent 365 Package Management API](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/admin-settings/package/overview)
- [Agent ID default inactivity policy](https://learn.microsoft.com/entra/id-governance/agent-default-inactivity-policy)
- [Discover AI agents with Microsoft Defender](https://learn.microsoft.com/defender-xdr/security-for-ai/ai-agent-inventory) and the [AgentsInfo table](https://learn.microsoft.com/defender-xdr/advanced-hunting-agentsinfo-table)
- [Recreate Copilot Studio agents in Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/migrate-copilot-studio-agents-to-agent-id) (tags that mark older agents)
- [runHuntingQuery](https://learn.microsoft.com/graph/api/security-security-runhuntingquery)
- [Agent 365 observability attribute reference](https://learn.microsoft.com/microsoft-agent-365/developer/observability-attribute-reference) (CloudAppEvents fields) and [Discover local AI agents](https://learn.microsoft.com/defender-endpoint/discover-local-ai-agents)
- [Agent settings in the Microsoft 365 admin center](https://learn.microsoft.com/microsoft-agent-365/admin/agent-settings) and [Restrict who can create agents](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-app-roles#restrict-who-can-create-applications-and-agents)

## What's verified and what isn't

Checked against Microsoft Learn, CIS and published summaries of the CISA guidance on Oct 31, 2026.

**Confirmed in Microsoft docs:** the Graph endpoints and their scopes; the AgentsInfo columns and the `LocalAgents` platform; the CloudAppEvents action types and the TargetAgentId/AgentId fields; the Copilot Studio tags and that there's no in-place migration; inheritable permissions' All allowed pattern; the inactivity policy path and its 60/90/455 days; the setting names on the manual checklist; the plugin upload and scoping path; the roles for advanced hunting, sign-in activity and reading Conditional Access; and Agent 365 being included in Microsoft 365 E7.

**Confirmed with CIS:** the companion guides' date, the safeguard titles, 5.3's 45 days and 5.5's quarterly reviews.

**This repo's own choices, not Microsoft's or CIS's:** the unclear-name and high-privilege lists, the Microsoft domain list for MCP hosts, severities and scores, the 90-day default, and the CIS and CISA mapping.

**Not confirmed:** whether AI Reader is enough for the agent identity reads (see the note above) and for the Agent 365 catalog; the join from CloudAppEvents to AgentsInfo on appId; and the CISA details, which come from summaries because the cisa.gov page couldn't be opened.
