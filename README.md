# Copilot

Guides, scripts and Copilot Cowork and GitHub Copilot skills for running Microsoft 365 Copilot. Start with step 1 below. Each folder's readme has the full steps.

## Set up Copilot access

Do these in order.

| # | Folder | What it is | What you get |
| --- | --- | --- | --- |
| 1 | [Access Governance Guide](Access%20Governance%20Guide/readme.md) | Scripts and steps that create the Copilot groups, access packages and PIM admin groups, and say which admin center setting each group goes in | Copilot access managed through groups, so you add or remove people in one place |
| 2 | [Agents](Agents/readme.md) | The Agent Delegation Guide: who can build, share, publish and receive agents, using the groups from step 1 | Agent creation and sharing limited to the right people |

## Check that it's set up right

| Folder | What it is | What you get |
| --- | --- | --- |
| [Billing Health Check](Billing%20Health%20Check/README.md) | Read-only check of Copilot spending policies, their groups and members. PowerShell, Cowork or GitHub Copilot | A scored HTML report with a fix for every finding |
| [Agent and Tools Health Check](Agent%20and%20Tools%20Health%20Check/README.md) | Read-only check of agents, tools, Entra agent identities and blueprints: groups, sponsors, least privilege, names, stale items. PowerShell, Cowork or GitHub Copilot | A scored HTML report with a fix for every finding, mapped to CIS and CISA guidance |
| [Entra ID Operations Report](Entra%20ID%20Operations%20Report/README.md) | Read-only check of your Entra tenant against Microsoft's Entra operations reference guide. Cowork or GitHub Copilot through the Enterprise MCP | A scored HTML report with a fix for every finding, tied to the guide section it comes from |
| [Entra ID Security Review](Entra%20ID%20Security%20Review/README.md) | Read-only security review of your Entra tenant against CISA SCuBA, the CIS Microsoft 365 benchmark, the Entra Attack and Defense Playbook, and Microsoft, NSA and Mandiant incident guidance. Cowork or GitHub Copilot through the Enterprise MCP | A scored HTML report with the CISA BOD 25-01 count, the attack each finding helps stop, and a fix tied to its CISA, CIS or Playbook source |

## Clean up what isn't used

| Folder | What it is | What you get |
| --- | --- | --- |
| [Agent and Tools Cleanup](Agent%20and%20Tools%20Cleanup/README.md) | Finds unused agents, plugins, skills and MCP servers, plus stale agent identities and blueprints. Can block or disable them. PowerShell, Cowork or GitHub Copilot | A list of what to remove, and an undo file for anything it changes |

## Copilot Cowork prompts

| Folder | What it is | What you get |
| --- | --- | --- |
| [Daily Summary](Daily%20Summary/readme.md) | Cowork prompts you schedule to run every day, a few minutes apart, each emailing you its result | Daily summary emails that arrive in a predictable order |
| [Second Brain Project](Second%20Brain%20Project/readme.md) | Scheduled Cowork prompts that read your meetings, Teams, email and public sources | A personal "second brain" of Markdown notes in OneDrive that Copilot can search |

## Make Copilot work your way

| Folder | What it is | What you get |
| --- | --- | --- |
| [Personalization](Personalization/readme.md) | How to set Copilot custom instructions, with examples for different roles (Copilot admin, identity admin, students, HOA board member) | Better answers without repeating your role and preferences in every prompt |

## About this repo

Each of the five check and cleanup folders has a **Cowork** folder (Microsoft 365 Copilot Cowork) and a **GitHub Copilot** folder (GitHub Copilot in VS Code and the Copilot CLI). Both use the same skill files, so the rules and reports match.

Scripts use `Connect-MgGraph` and `Invoke-MgGraphRequest` against Microsoft Graph beta, not the other Microsoft Graph PowerShell modules (they change too often). Exchange Online PowerShell is used where Graph can't reach. The coding rules for people and AI coding agents are in [AGENTS.md](AGENTS.md). Reports the scripts write can name people and groups, so keep them out of source control.
