# Entra ID SME Skill

A skill that answers Microsoft Entra ID and identity-security questions and **checks every claim against Microsoft Learn and the Microsoft Graph API reference before stating it**. Each answer comes with source tags (`[MS Learn]`, `[Graph API]`, `[CISA]`, `[Author repo]`, `[3P]`) and a confidence line: Verified, Partially verified or Unverified.

Works in **Copilot Cowork** and **GitHub Copilot** (VS Code and the Copilot CLI). Both use the same skill files.

**Read-only.** The skill only runs or suggests read-only Graph GET calls. Any script that changes the tenant is handed to you to run, after a change list, a backup step and your explicit OK.

> Microsoft changes Entra, Cowork, GitHub Copilot and the Enterprise MCP server often. The skill re-checks the docs every time, but test anything it suggests in your own tenant first.

## Short version

1. Pick where to run it: [Copilot Cowork](Cowork/readme.md) or [GitHub Copilot](GitHub%20Copilot/readme.md).
2. Install the skill (about 2 minutes). The tenant connection (Microsoft MCP Server for Enterprise) is optional.
3. Ask an Entra ID question, for example: *"Is there a Graph property to block device code flow?"*

## What it covers

| Area | Examples |
| --- | --- |
| Conditional Access | Review my policies, break-glass exclusions, authentication strengths, token protection, device code flow |
| ID Protection | Risk-based CA, legacy risk policy migration (retired Oct 1, 2026), false positives from proxies |
| Authentication methods and PIM | Legacy MFA/SSPR policy migration, phishing-resistant admins, PIM approval settings |
| Hybrid identity | Entra Connect / Cloud Sync, password hash sync, federation, Primary Refresh Token |
| Defender for Identity | Sensors, posture assessments, AD CS assessments |
| Multitenant and guests | B2B collaboration, B2B direct connect, cross-tenant sync, multitenant organization, guest lifecycle |
| Attack and defend | Password spray, token theft, AiTM, consent phishing, on-premises to cloud pivot |
| Compliance mapping | CISA SCuBA / BOD 25-01, NIST SP 800-207, 800-63, 800-53/171, CMMC 2.0 (mapping, not attestation) |

## How it answers

| Request | Mode | You get |
| --- | --- | --- |
| AADSTS code, sign-in log, symptom | Diagnose | Likely cause, checks, KQL to confirm, fix |
| CA JSON, cross-tenant settings, architecture | Design / Review | Gaps against Microsoft and CISA SCuBA, ranked risks, policies in report-only first |
| An attack technique | Attack and Defend | Prevent, detect (KQL), respond, Microsoft guidance first |
| Two or more tenants, guests | Multitenant and Guest | Topology choice, trust settings, guest CA and lifecycle |
| A CMMC practice, NIST control or SCuBA ID | Compliance mapping | Control to Entra setting to Graph property, with a disclaimer |
| "Write a script / query" | Build | Graph PowerShell or KQL, read-only by default |
| "Explain this for stakeholders" | Explain | Plain-language summary with links |

## Sources it uses, in order

1. Microsoft Learn and the Microsoft Graph API reference
2. Microsoft Entra Blog (announcements, status, retirements)
3. CISA, NIST and DoD
4. The author's repos: [Azure_Active_Directory](https://github.com/chadmcox/Azure_Active_Directory) scripts, KQL and wiki, and [Sentinel-and-Defender-Queries](https://github.com/chadmcox/Sentinel-and-Defender-Queries). Labeled community, not official Microsoft guidance
5. Labeled third party, such as the [Attack and Defense Playbook for Microsoft Entra](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense)

The full list is in [sources.md](Cowork/plugin/skills/entra-id-sme/references/sources.md).

## What's in this folder

| Folder or file | What it is |
| --- | --- |
| [Cowork/](Cowork/readme.md) | Copilot Cowork setup, the plugin, and the skill (the only copy) |
| [Cowork/plugin/skills/entra-id-sme/SKILL.md](Cowork/plugin/skills/entra-id-sme/SKILL.md) | The skill: rules, verification workflow, modes, change safety |
| [Cowork/plugin/skills/entra-id-sme/references/](Cowork/plugin/skills/entra-id-sme/references) | Per-area pointers, author guidance, gotchas and test prompts |
| [GitHub Copilot/](GitHub%20Copilot/readme.md) | GitHub Copilot setup and installer |

## Contributing gotchas

Add a row to [gotchas.md](Cowork/plugin/skills/entra-id-sme/references/gotchas.md): `Symptom | Root cause | Fix | Source/verified link | Contributor | Date`. Every row needs a public source link. No tenant IDs, UPNs, organization names or secrets.

## Disclaimer

Community-shared skill. Not official Microsoft guidance or support. Compliance mapping isn't a compliance attestation.
