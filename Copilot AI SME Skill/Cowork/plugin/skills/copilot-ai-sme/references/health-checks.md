# Health checks: Maester AI governance pack and Copilot repo health checks

Everything in this file is **[Author repo – community, not official Microsoft guidance]**, read on Nov 19, 2026 from:
- Maester AI governance pack (Maester Pack, tests `MP.AIGOV.1001`–`1055`, all **Preview**): https://github.com/chadmcox/maester-ai-governance-pack — install with `Install-MtPack chadmcox/maester-ai-governance-pack/pack`. Each test's logic, pass/fail rules and live-run notes: `docs/how-checks-work.md`. Framework mapping and gaps: `docs/coverage-matrix.md`.
- Copilot repo health checks: **Billing Health Check** (spending policies, groups, members, credit balances), **Agent and Tools Health Check** (agents, tools, MCP, skills, agent identities, blueprints, tenant settings, Defender-discovered agents, connectors), **Agent and Tools Cleanup** (unused items, block/disable with undo): https://github.com/chadmcox/Copilot
- Each health check rule names its matching Maester test; the repo's CI fails when a pack test isn't mapped.

Use this file for **Mode 10 (Health check)**: explain a finding or test ID, say why it matters, give the fix, point to the tool that checks it, and map it to frameworks. Before stating any Microsoft behavior (API, permission, limit, setting), verify it on Learn or the Graph reference: these repos test preview APIs that change.

## Which tool checks what

| Area | Maester tests | Copilot repo tool | Main data source (verify on Graph reference) |
|---|---|---|---|
| Spending policies (cap, scope, billing, alerts, overlap) | 1013, 1015, 1025, 1026 | Billing Health Check | Graph beta Copilot cost management spending policies; **delegated only**, `CopilotCostManagement-Policy.Read.All` |
| Spending policy groups and members | 1014, 1027, 1032 | Billing Health Check | Groups, members, sign-in activity, license assignment states |
| Agents and tools in the catalog (access, naming, usage, pending requests, adoption) | 1001, 1002, 1003, 1006, 1007, 1020, 1021 | Agent and Tools Health Check, Cleanup | Graph `copilot/admin/catalog/packages` (preview), `CopilotPackages.Read.All` |
| MCP servers and tools (HTTPS, allowlisted host, auth, destructive tools, steering text, baseline drift) | 1008, 1010, 1011, 1016, 1038, 1039 | Agent and Tools Health Check | Package details: `remoteMcpServer.mcpServerUrl`, authorization type, tool annotations and descriptions |
| Agent skills (weak description, exposed tenant-wide) | 1012 | Agent and Tools Health Check | Package details: skill frontmatter |
| Agent identities (sponsor, owners, risk, consent, Graph write permissions, naming) | 1004, 1018, 1019, 1022, 1023, 1036 | Agent and Tools Health Check, Cleanup | `servicePrincipals/microsoft.graph.agentIdentity`, sponsors, `identityProtection/riskyAgents` |
| Blueprints (secrets, expiring credentials, verified publisher, inheritable permissions) | 1009, 1035, 1041 | Agent and Tools Health Check | `applications/microsoft.graph.agentIdentityBlueprint`, blueprint principals |
| Classic Copilot Studio service principals (no Agent ID, no owner, unused) | 1005, 1024 | Agent and Tools Health Check, Cleanup | Service principals with Copilot Studio tags |
| Tenant: Conditional Access for agents, AI admin roles, web search | 1017, 1034, 1042 | Agent and Tools Health Check | CA policies; `roleAssignmentScheduleInstances`; `copilot/admin/policySettings/microsoft.copilot.allowwebsearch` (delegated only) |
| Defender-discovered and local agents | 1037, 1052, 1053, 1055 | Agent and Tools Health Check | Defender XDR advanced hunting `AgentsInfo` (needs Agent 365) |
| Copilot connectors | 1033 | Agent and Tools Health Check | `external/connections` |
| Data protection for Copilot | 1040, 1043, 1044 | — | Sensitivity labels (Graph); Copilot DLP and audit retention (Security & Compliance PowerShell) |
| SharePoint and agents | 1049, 1050, 1051 | — | SharePoint Online tenant settings (PnP) |
| Azure AI (Azure OpenAI / AI Services) | 1045, 1046, 1047, 1048 | — | Azure: Entra-only auth, network, Defender for AI, content filters, diagnostic logs, approved models |
| Entra agent risk logs | 1054 | — | `microsoft.aadiam` diagnostic settings (Azure) |

Maester connections: tests 1001–1042 need only Graph; others skip unless the service is connected (`Connect-Maester -Service Graph, ExchangeOnline, SecurityCompliance, Azure, SharePointOnline`).

## Billing Health Check rules (summary)
| Check | Severity |
|---|---|
| Policy scope is All users | High |
| Policy not enabled; or scoped to Groups with no group | High |
| Per-user and monthly limits both Unlimited | High |
| Per-user limit under 2,000 credits | Medium |
| Billing method not specified | Medium |
| No alert, a disabled/missing recipient | Medium |
| Only one alert recipient | Low |
| Group missing | High |
| Microsoft 365 (not security) group, or nested groups | Medium |
| Fewer than two group owners; no access review | Medium |
| No members; no description | Low |
| Member disabled, guest, no sign-in in 90 days, or no working Copilot license when the policy covers Cowork or Code | Medium |
| Person in both Cowork Limited and Cowork Unlimited; a group policy's per-user limit overridden by Unlimited for the same person and service | High |

Key behavior used by these rules (verify on Learn): when several policies cover a person, the higher per-user limit wins and limits don't combine.

## Agent and Tools Health Check rules (highlights)
| Check | Severity |
|---|---|
| Custom/external package available or installed for all users | High |
| MCP server over `http://`; MCP auth `None`; risky (destructive/open-world) tools in a tenant-wide package | High |
| MCP auth is a static secret (API key, Key Vault, connection vault); auth unspecified on custom packages | Medium |
| MCP tool description or schema contains model-steering text | Medium |
| Agent identity: no sponsor, sponsor/owner gone or disabled, high-privilege Graph permissions, at risk | High |
| Agent identity: tenant-wide write permissions, user-consented delegated grants, one sponsor and no owner, unclear name, no sign-in in 90 days | Medium |
| Blueprint: inheritable permissions `allAllowed`; high-privilege principal; no sponsor | High |
| Blueprint: client secret; credential expiring within 30 days; unverified external publisher | Medium |
| No CA policy targets agent identities | High |
| AI Administrator / Agent ID Administrator / Agent Registry Administrator: permanent (not PIM), held by guests or non-humans | High |
| More than 3 holders of those roles | Medium |
| Copilot web search on for everyone | Low |
| Defender-discovered cloud agent not in the registry; available to all users | High (all users) / Medium |
| Local agent with auto-approve on, or untrusted host process | Medium |

Scoring (both health checks): each item starts at 100; High −25, Medium −10, Low −3; area score capped at 75 with any High, 90 with any Medium, 97 with any Low. Agent identity "well-governed funnel": all → active sponsor → clear name → least privilege → in use.

## Manual checks (no API through Graph or the Enterprise MCP, per the repos)
- Resource-based spending policies (scope "All environments", no per-agent limit, overlapping policies): not in the Graph `spendingPolicy` type yet.
- **Auto-apply new services** on identity policies (Message Center MC1470425, Sept 2026).
- Synced Copilot connector rollout audience and item access rules.
- AI Builder credits aren't covered by resource-based spending policies.
- Entra user setting **Users can register agent identity blueprints** (default Yes) → set No.
- Agent ID default inactivity lifecycle policy (preview).
- **Agents > Settings > Agent and plugin access**: external publishers off or reviewed; **Sharing**: specific users.
- Sponsor attestation in the last 6–12 months.
- Framework items with no automated check: Copilot Studio public publishing and non-Microsoft channels, knowledge-source protection, Power Platform DLP coverage and tenant isolation, Copilot Studio external threat detection ("Block the query"), Restricted Content Discovery on high-risk sites, endpoint DLP for third-party AI sites, retention for Enterprise and Other AI apps, Communication Compliance for AI, Global Secure Access for agent traffic, DSPM for AI, data risk assessment before rollout, red-teaming and an incident plan for a compromised agent.

## Framework sources the repos map to
- CISA SCuBA: `aad.md` (MS.AAD.9.1, ScubaGear 2.0.0), Power Platform baseline, and the **draft** "SI / SI Agents" baseline MS.SI.1.1–13.6 (rationale still TBD at review) — say "draft" every time.
- CISA/NSA/Five Eyes *Careful Adoption of Agentic AI Services* (May 1, 2026).
- CIS Microsoft 365 Foundations Benchmark v7.0.0 (May 19, 2026; one AI item, 3.2.3) and CIS Controls v8.1 (with AI companion guides for LLM, agents and MCP, Apr 20, 2026).
- NIST AI RMF 1.0 / AI 600-1 and SP 800-53 control IDs; Microsoft cloud security benchmark v2 AI controls; OWASP Agentic Top 10.
Verify versions and dates at runtime (security-frameworks.md).

## How to answer a health-check question
1. Name the check (Maester ID and/or health-check rule), severity and area.
2. Why it matters, in one or two lines; map to CISA category / CIS safeguard / OWASP ASI where the repo does.
3. Fix: the Microsoft setting or action, verified on Learn, with change-safety rules (SKILL.md).
4. How to re-check: the Maester test, the health check (Cowork, GitHub Copilot or PowerShell), or the manual step.
5. Label preview APIs and delegated-only endpoints; add the framework disclaimer if you mapped controls.
