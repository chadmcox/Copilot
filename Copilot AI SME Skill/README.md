# Copilot AI SME Skill

A skill that answers Microsoft Copilot, Cowork, Autopilot, Copilot Studio, agent governance, Copilot FinOps and AI security questions, and **checks every setting, credit rate, status and date against Microsoft Learn, the Microsoft Copilot Roadmap, Message Center and official Microsoft blogs before stating it**. Each answer comes with source tags (`[MS Learn]`, `[Roadmap]`, `[MS Blog]`, `[CISA]`, `[NIST]`, `[OWASP]`, `[Author repo]`, `[3P]`), a status label (GA, Preview, Frontier, Rolling out) and a confidence line.

Works in **Copilot Cowork** and **GitHub Copilot** (VS Code and the Copilot CLI). Both use the same skill files. For Entra ID identity questions, use the [Entra ID SME Skill](../Entra%20ID%20SME%20Skill/README.md).

**Read-only.** The skill only runs or suggests read-only checks. Any change to billing, spending policies, agents or data policies is handed to you, with a change list, the cost impact and your explicit OK first.

> Copilot features and billing change monthly. The skill re-checks the sources every time, but test anything it suggests in your own tenant first.

## Short version

1. Pick where to run it: [Copilot Cowork](Cowork/readme.md) or [GitHub Copilot](GitHub%20Copilot/readme.md).
2. Install the skill (about 2 minutes). In GitHub Copilot, add the Microsoft Learn and Release Communications MCP servers too (no sign-in needed).
3. Ask, for example: *"Who can use Cowork in my tenant, and what controls the cost?"*

## What it covers

| Area | Examples |
| --- | --- |
| Microsoft 365 Copilot and Copilot Chat | Licensing, what's included, agents for unlicensed users |
| Copilot Cowork | Access through spending policies, plugins, skills, connectors, model templates |
| Microsoft Copilot Autopilot | Frontier setup, spending policy coverage, approvals, memory and data export, troubleshooting |
| Copilot Studio | Environments, data policies, sharing limits, credit rates, capacity |
| Agent governance | Agent 365 registry, Entra Agent ID, lifecycle, plugin and agent access |
| FinOps | Copilot Credits, spending policies, capacity packs, P3, pay-as-you-go, reconciling to the Azure bill |
| What's new | Roadmap, Message Center and blog digests with IDs, dates and status |
| Security and compliance | Mapping to CISA (incl. *Careful Adoption of Agentic AI Services*), NIST, CIS, OWASP, MITRE ATLAS, ISO, and OT/automotive/defense guidance |
| Threat modeling | Agents walked through the OWASP Top 10 for Agentic Applications and CISA's agentic risk categories |

"Autopilot" means Microsoft Copilot Autopilot, not Windows Autopilot.

## How it answers

| Request | Mode | You get |
| --- | --- | --- |
| Cost, credits, spending policy | FinOps | Cost drivers, billing option, limits and alerts, showback, reconciliation |
| Which tool to build with | Design | Recommended approach, ranked options, auth, data reach, cost driver, "Before you deploy" table |
| Who can build, share or use agents | Governance | Registry, identity, data policies, sharing limits, lifecycle |
| Autopilot setup or problems | Autopilot | Prerequisite checklist and ordered troubleshooting |
| What changed | What's new | Table of roadmap, Message Center and blog items with status |
| A framework control | Compliance mapping | Control → Microsoft setting → where to verify → evidence, with a disclaimer |
| "Threat model this agent" | Threat model | ASI01–ASI10 walk, gaps, fixes |
| Build a plugin, skill or script | Build | Manifest, skill files, Graph PowerShell or KQL, read-only by default |
| An error | Troubleshoot | Likely cause, ordered checks, fix |

## Sources it uses, in order

1. Microsoft Learn and the Microsoft Graph reference
2. Microsoft Copilot Roadmap, Message Center, release plans
3. Official Microsoft blogs (Microsoft 365 Copilot, Copilot Studio, Cowork release log, Microsoft 365, Power Platform, Entra, Security, FinOps)
4. Dated licensing guides
5. CISA, NIST, CIS, OWASP, MITRE, ISO and industry guidance
6. The author's repos, labeled community
7. Labeled third party

Full list: [sources.md](Cowork/plugin/skills/copilot-ai-sme/references/sources.md). Blog rules: [blogs-and-feeds.md](Cowork/plugin/skills/copilot-ai-sme/references/blogs-and-feeds.md).

## What's in this folder

| Folder or file | What it is |
| --- | --- |
| [Cowork/](Cowork/readme.md) | Copilot Cowork setup, the plugin, and the skill (the only copy) |
| [Cowork/plugin/skills/copilot-ai-sme/SKILL.md](Cowork/plugin/skills/copilot-ai-sme/SKILL.md) | The skill: rules, modes, verification workflow, output format, change safety |
| [Cowork/plugin/skills/copilot-ai-sme/references/](Cowork/plugin/skills/copilot-ai-sme/references) | FinOps, licensing, Autopilot, Cowork, Copilot Studio, governance, frameworks, threat model, what's new, gotchas, tests |
| [GitHub Copilot/](GitHub%20Copilot/readme.md) | GitHub Copilot setup, installer and `mcp.json` |

## Contributing gotchas

Add a row to [gotchas.md](Cowork/plugin/skills/copilot-ai-sme/references/gotchas.md): `Symptom | Root cause | Fix | Source/verified link | Contributor | Date`. Every row needs a public source link. No tenant IDs, UPNs, organization names, contract prices or secrets.

## Disclaimer

Community-shared skill. Not official Microsoft guidance or support. Credit estimates aren't quotes. Framework mapping isn't a compliance attestation.
