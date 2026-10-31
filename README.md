# Copilot

Guides, scripts and Copilot Cowork prompts for running Microsoft 365 Copilot. Each folder below is one thing, with a one-line explanation of what it is and what you get from it. Open a folder's readme for the full steps.

## Set up Copilot access

Do these in order.

| # | Folder | What it is | What you get |
| --- | --- | --- | --- |
| 1 | [Group Assignment Guide](Group%20Assignment%20Guide/readme.md) | Scripts and steps that create the Copilot groups, access packages and PIM admin groups, and say which admin center setting each group goes in | Copilot access managed through groups, so you add or remove people in one place |
| 2 | [Agents](Agents/readme.md) | The Agent Delegation Guide: who can build, share, publish and receive agents, using the groups from step 1 | Agent creation and sharing limited to the right people |

## Check that it's set up right

| Folder | What it is | What you get |
| --- | --- | --- |
| [Billing Health Check](Billing%20Health%20Check/README.md) | A read-only check of your Copilot spending policies, their groups and their members. Run it in PowerShell or Copilot Cowork | A scored HTML report with a fix for every finding |
| [Agent and Tools Health Check](Agent%20and%20Tools%20Health%20Check/README.md) | A read-only check of agents, tools, Entra agent identities and blueprints against best practices: groups, sponsors, least privilege, clear names, stale items | A scored HTML report with a fix for every finding, mapped to CIS and CISA guidance |

## Clean up what isn't used

| Folder | What it is | What you get |
| --- | --- | --- |
| [Agent and Tools Cleanup](Agent%20and%20Tools%20Cleanup/README.md) | Finds agents, plugins, skills and MCP servers nobody uses, plus stale agent identities and blueprints. Can block or disable them | A list of what to remove, and an undo file for anything it changes |

## Copilot Cowork prompts

| Folder | What it is | What you get |
| --- | --- | --- |
| [Daily Summary](Daily%20Summary/readme.md) | Cowork prompts you schedule to run every day, a few minutes apart, each emailing you its result | Daily summary emails that arrive in a predictable order |
| [Second Brain Project](Second%20Brain%20Project/readme.md) | Scheduled Cowork prompts that read your meetings, Teams, email and public sources | A personal "second brain" of Markdown notes in OneDrive that Copilot can search |

## Make Copilot work your way

| Folder | What it is | What you get |
| --- | --- | --- |
| [Personalization](Personalization/readme.md) | How to set Copilot custom instructions, with examples for different roles (Copilot admin, identity admin, students, HOA board member) | Better answers without repeating your role and preferences in every prompt |
| [MCP](MCP/readme.md) | A link to Microsoft's guide for the Microsoft Learn MCP server | Copilot or another AI tool that can look up official Microsoft docs |

## About this repo

Scripts use only `Connect-MgGraph` and `Invoke-MgGraphRequest` against Microsoft Graph beta. The coding rules for people and AI coding agents are in [AGENTS.md](AGENTS.md). Reports the scripts write can name people and groups, so keep them out of source control.
