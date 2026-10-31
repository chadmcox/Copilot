# CISA and CIS guidance behind the checks

Every finding names the guidance it comes from, in brackets after the fix: the **CIS Controls v8.1 safeguards** and the **CISA risk category**. The safeguard numbers are this repo's mapping of the checks to CIS Controls v8.1, the version the CIS AI companion guides apply to agents. Check them against the companion guides themselves before you cite them in an audit.

## Sources

- **CISA and partners, *Careful Adoption of Agentic Artificial Intelligence (AI) Services*** (May 1, 2026). Joint guidance from CISA, NSA, Australia's ASD ACSC, the Canadian Centre for Cyber Security, New Zealand's NCSC and the UK's NCSC. It sorts agentic AI risk into five categories: **privilege**, **design and configuration**, **behavioral**, **structural** and **accountability**. It recommends building strong identity into agents, keeping least-privilege access, never giving agents broad or unrestricted access (especially to sensitive data or critical systems), starting with low-risk use cases, keeping detailed logs of agent actions, monitoring for anomalous behavior, and designing in human oversight. It asks organizations to fold agent security into the frameworks they already run (zero trust, defense in depth, least privilege) rather than start a new discipline. https://www.cisa.gov/resources-tools/resources/careful-adoption-agentic-ai-services
- **CIS, AI Agent Companion Guide and MCP Companion Guide for CIS Controls v8.1** (April 20, 2026, with Astrix Security and Cequence Security). They apply the CIS Controls to the agent layer (safe tool execution, governed autonomy, access to enterprise systems, tool allowlisting, least privilege, identity for every tool call, human approval for high-impact actions, auditability) and to MCP (secure tool access, management of non-human identities, auditable interactions). https://www.cisecurity.org/insights/white-papers/controls-v8-1-ai-agents-companion-guide

## CIS Controls v8.1 safeguards used

| Safeguard | Title | Why it applies to agents and tools |
| --- | --- | --- |
| 1.1 | Establish and Maintain Detailed Enterprise Asset Inventory | Every agent should be in one inventory (the Agent 365 registry) |
| 2.1 | Establish and Maintain a Software Inventory | Agents, plugins, skills and MCP servers are software; they need a name and purpose people can recognize |
| 2.3 | Address Unauthorized Software | Agents Defender finds outside the registry, and unapproved local agents |
| 2.5 | Allowlist Authorized Software | Local AI agents and tools should be on an approved list |
| 2.5 (MCP) | Allowlist Authorized Software | MCP servers outside Microsoft should be on the approved tools list |
| 3.10 | Encrypt Sensitive Data in Transit | Agents should reach MCP servers over HTTPS only |
| 3.3 | Configure Data Access Control Lists | Agents should reach only the data they need (least privilege) |
| 4.1 | Establish and Maintain a Secure Configuration Process | Credentials and Conditional Access for agents are part of their secure configuration |
| 5.1 | Establish and Maintain an Inventory of Accounts | Each agent identity has an accountable sponsor and owner |
| 5.3 | Disable Dormant Accounts | CIS sets 45 days of inactivity. These scripts default to 90; use `-StaleDays 45` to match CIS |
| 5.4 | Restrict Administrator Privileges to Dedicated Administrator Accounts | No high-privilege Graph permissions on agents |
| 5.5 | Establish and Maintain an Inventory of Service Accounts | Agent identities and agent user accounts are non-human accounts: inventory them with owner, purpose and review date, and review them at least quarterly |
| 5.6 | Centralize Account Management | Agents should use Entra Agent ID, not one-off service principals |
| 6.1 | Establish an Access Granting Process | Agents and tools are granted to groups through a process, not to everyone |
| 6.2 | Establish an Access Revoking Process | Unused agents and tools get blocked or disabled |
| 6.7 | Centralize Access Control | Conditional Access covers agent identities |
| 6.8 | Define and Maintain Role-Based Access Control | Access by group; inheritable permissions limited to what agents need |
| 15.1 | Establish and Maintain an Inventory of Service Providers | External MCP servers are third-party services the agent depends on |

## Checks mapped to the guidance

| Check | CIS v8.1 | CISA risk category |
| --- | --- | --- |
| Available to all users, installed for everyone, assigned to people instead of groups | 6.1, 6.8 | Privilege |
| Group with fewer than two owners | 5.1, 6.1 | Accountability |
| Group with no description | 6.1 | Accountability |
| No sponsor; sponsor or owner disabled or gone; one sponsor and no owner; no owner | 5.1, 5.5 | Accountability |
| High-privilege or tenant-wide write Graph permissions | 3.3, 5.4 | Privilege |
| Inheritable permissions set to All allowed | 3.3, 6.8 | Privilege, structural (one blueprint passes access to every agent built on it) |
| Client secret, expired or expiring credential | 4.1 | Design and configuration |
| Agent user account | 5.5 | Privilege |
| No Conditional Access policy for agents, or only report-only | 4.1, 6.7 | Design and configuration |
| No policy blocking high-risk agents | 6.7 | Behavioral |
| Unclear name, missing description | 2.1, 5.5 | Accountability |
| Not used or no sign-in for the stale period; blueprint with nothing active | 5.3, 6.2 | Accountability |
| Pending request older than 14 days | 6.1 | None |
| Found by Defender but not in the registry | 1.1, 2.1, 2.3 | Accountability |
| Local AI agent on devices | 2.1, 2.3, 2.5 | Design and configuration |
| MCP server reached over http (no TLS) | 3.10 | Design and configuration |
| MCP server outside Microsoft | 2.5, 15.1 | Design and configuration (third-party components) |
| No Entra Agent ID, or a classic service principal | 5.5, 5.6 | Strong agent identity (CISA's identity recommendation) |

## Not checked here, but in the guidance

- **Logging and monitoring** (CISA: detailed logs of agent actions and ongoing monitoring; CIS 8.2 Collect Audit Logs): confirm Purview audit is on and Defender monitors agent activity.
- **Human oversight** (CISA: designed-in human oversight; CIS AI Agent guide: human approval for high-impact actions): check in each agent's design (Copilot Studio, Foundry), not through Graph.
- **Tool allowlisting** (CIS AI Agent and MCP guides): this check flags MCP servers outside Microsoft and over http, from Defender's AgentsInfo. Use **Agents > Tools** to allow only approved MCP servers, and the Agent and Tools Cleanup scripts to block unused ones.
- **Starting with low-risk use cases** (CISA): a deployment decision; use group-scoped pilots.
