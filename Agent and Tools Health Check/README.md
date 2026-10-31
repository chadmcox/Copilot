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
| **Discovered agents** (Microsoft Defender) | Agents Defender found (`AgentsInfo`: Copilot Studio, Foundry, third-party) that aren't in the Agent 365 registry, especially ones available to everyone (High) or with no owner. Cloud agents with no Entra Agent ID. Local AI agents seen on devices |
| **Agents without Agent ID** | Older Copilot Studio and Foundry agents still running as classic service principals (found by their `AgentCreatedBy:CopilotStudio`, `AgenticApp` and similar tags), with no blueprint, sponsor or agent-specific controls. Recreate them with Agent ID; there's no in-place migration |

**Unclear names** are flagged when a name has *test*, *demo*, *temp*, *copy*, *draft*, *sample*, *POC*, *sandbox*, *untitled*, *dummy*, *do not use*, starts with *new agent* or *my agent*, ends in *Agent 2* or *(1)*, or is under four characters. Change the list with `-UnclearNamePattern`.

**Guidance**: every finding names the CIS Controls v8.1 safeguards and the CISA risk category behind it, in the Reference column of Findings.csv and in brackets after the fix in the report. See [CISA and CIS guidance](#cisa-and-cis-guidance).

**Scores**: every item starts at 100 (High −25, Medium −10, Low −3); an area's score is the average of its items. Green 80+, Amber 50–79, Red under 50.

Microsoft-published agents and tools, and blueprints from other publishers, aren't checked for names, descriptions or use, because they aren't yours to fix.

## CISA and CIS guidance

The checks follow two recent government and industry sources, plus Microsoft's own best practices. The full mapping, check by check, is in [guidance.md](Cowork/plugin/skills/agent-tools-health/references/guidance.md).

- **CISA, NSA and Five Eyes partners: [*Careful Adoption of Agentic AI Services*](https://www.cisa.gov/resources-tools/resources/careful-adoption-agentic-ai-services)** (May 1, 2026). Sorts agent risk into five categories (privilege, design and configuration, behavioral, structural, accountability) and asks for strong agent identity, least privilege, no broad or unrestricted access, detailed logs, monitoring and human oversight, built into the frameworks you already run.
- **CIS: [AI Agent and MCP Companion Guides](https://www.cisecurity.org/insights/white-papers/controls-v8-1-ai-agents-companion-guide) for CIS Controls v8.1** (April 20, 2026). Apply the CIS Controls to agents and MCP: tool allowlisting, least privilege, identity for every tool call, human approval for high-impact actions, auditability, and non-human identity management.

| What this check covers | CIS v8.1 | CISA risk category |
| --- | --- | --- |
| One inventory of agents; unregistered and local agents | 1.1, 2.1, 2.3, 2.5 | Accountability; design and configuration |
| Sponsors, owners, clear names and descriptions | 5.1, 5.5, 2.1 | Accountability |
| Group-scoped access instead of everyone | 6.1, 6.8 | Privilege |
| Least-privilege permissions; no All allowed inheritance | 3.3, 5.4, 6.8 | Privilege; structural |
| Agent ID instead of classic service principals | 5.5, 5.6 | Strong agent identity |
| Credentials and Conditional Access for agents | 4.1, 6.7 | Design and configuration; behavioral |
| Stale agents and tools | 5.3, 6.2 | Accountability |

**Stale threshold:** CIS 5.3 disables dormant accounts after **45 days**. The default here is 90; run `-StaleDays 45` to match CIS.

**Not checked here, but in the guidance:** logging and monitoring of agent actions (CIS 8.2; confirm Purview audit and Defender), human approval for high-impact actions (set in each agent's design), and tool allowlisting (Agents > Tools; block unused tools with [Agent and Tools Cleanup](../Agent%20and%20Tools%20Cleanup/README.md)).

The CIS safeguard numbers are this repo's mapping to CIS Controls v8.1; check them against the companion guides before citing them in an audit.

## Not covered by any API (manual checklist in the report)

- **Users can register agent identity blueprints** is No (Entra > Users > User settings).
- The **Agent ID default inactivity policy** is on (Entra > ID Governance > Lifecycle Workflows > Lifecycle Policies > Agent ID).
- **External publishers** are off or reviewed, and **Sharing** is limited to a group (admin center > Agents > Settings).
- **Standalone MCP servers and skills** in Agents > Tools > Registry have clear names, owners and group-scoped availability.
- Sponsors **attested** each agent in the last 12 months.

With browser access on, Cowork can read these pages and report what they're set to.

## Permissions (PowerShell)

Delegated: CopilotPackages.Read.All, Application.Read.All, AgentIdentityBlueprint.Read.All, AuditLog.Read.All, User.Read.All, Group.Read.All, Policy.Read.All, ThreatHunting.Read.All. Roles: **AI Administrator** (catalog; needs a Microsoft Agent 365 license or Microsoft 365 E7), **Security Reader** (Defender hunting) and **Global Reader**. Activate them in PIM for the run.

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
