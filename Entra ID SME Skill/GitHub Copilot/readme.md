# Use the Entra ID SME skill in GitHub Copilot

Ask **GitHub Copilot in VS Code** (agent mode) or the **Copilot CLI** Entra ID questions and get answers checked against Microsoft Learn and the Microsoft Graph API reference. It's the same skill as the [Cowork setup](../Cowork/readme.md).

**Read-only.** The skill never changes your tenant, and VS Code asks you before it runs any tool.

> GitHub Copilot, VS Code and the Enterprise MCP server change often, and parts are in preview. Test this in your own tenant first.

## Short version

1. Get the files and run `Install-GitHubCopilotSkill.ps1` from this folder (about 2 minutes).
2. Optional: add the Microsoft MCP Server for Enterprise in VS Code for live, read-only tenant reads.
3. Open Copilot Chat in **Agent** mode and type `/entra-id-sme`, or just ask an Entra ID question.

## Where it works

| Where | Works? | Notes |
| --- | --- | --- |
| **VS Code** with GitHub Copilot, agent mode | **Yes (recommended)** | Doc checks, and live tenant reads if the Enterprise MCP is added |
| **GitHub Copilot CLI** | Yes, without tenant reads | Reads the same `~/.copilot/skills` folder. The Enterprise MCP sign-in is set up for VS Code only |
| Copilot on github.com (cloud agent) | Not covered | It can't sign in to your tenant |

The skill checks every claim against Microsoft Learn. If the session has no web search or fetch tool, it marks answers **Unverified** and lists the pages to check rather than answering from memory.

## Set up (each person)

### 1. Get the files

Clone or download this repo, or just the **Entra ID SME Skill** folder. If you download only `Install-GitHubCopilotSkill.ps1`, it downloads the rest from GitHub.

### 2. Install the skill

```powershell
cd "Entra ID SME Skill\GitHub Copilot"
.\Install-GitHubCopilotSkill.ps1                                               # for you, in every workspace
.\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Entra ID SME"   # for one folder
```

| Scope | Installs to | Use when |
| --- | --- | --- |
| **User** (default) | `~/.copilot/skills/entra-id-sme` | Just you. Works in any folder you open |
| **Workspace** | `<folder>/.github/skills/entra-id-sme` and `<folder>/.vscode/mcp.json` | A shared folder your team opens in VS Code |

Run it again to update the skill. Add `-NoMcpConfig` to skip writing `mcp.json`.

### 3. Optional: add the Enterprise MCP for tenant reads

An admin turns on the Enterprise MCP server once per tenant (step 1 of the [Entra ID Security Review tenant setup](../../Entra%20ID%20Security%20Review/Cowork/readme.md#1-turn-on-the-enterprise-mcp-server-in-your-tenant)). Then, in VS Code: **Command Palette > MCP: Add Server > HTTP >** `https://mcp.svc.cloud.microsoft/enterprise`. The workspace install writes this for you in [mcp.json](mcp.json).

On **Copilot Business or Enterprise**, your GitHub org or enterprise must allow the **MCP servers in Copilot** policy.

## Ask it

- *"Is there a Graph property to block device code flow?"*
- *"Review the CA policies in this folder for missing break-glass exclusions."*
- *"Write a read-only Graph PowerShell script that lists stale guests."*
- *"Which Defender for Identity posture assessments cover AD CS?"*

Scripts it writes go in the open workspace folder. Don't commit output that holds tenant data.

## What's in this folder

| File | What it is |
| --- | --- |
| [Install-GitHubCopilotSkill.ps1](Install-GitHubCopilotSkill.ps1) | Copies the skill from `Cowork/plugin/skills/` (or downloads it) into a folder GitHub Copilot reads |
| [mcp.json](mcp.json) | The Enterprise MCP server entry for `.vscode/mcp.json` |

## Sources

- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
