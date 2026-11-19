# Use the Copilot AI SME skill in GitHub Copilot

Ask **GitHub Copilot in VS Code** (agent mode) or the **Copilot CLI** about Copilot, Cowork, Autopilot, Copilot Studio, agent governance, FinOps and AI security. It's the same skill as the [Cowork setup](../Cowork/readme.md).

**Read-only.** The skill never changes your tenant, and VS Code asks you before it runs any tool.

> GitHub Copilot, VS Code and the MCP servers change often, and parts are in preview. Test this in your own tenant first.

## Short version

1. Get the files and run `Install-GitHubCopilotSkill.ps1` from this folder (about 2 minutes).
2. Add the **Microsoft Learn** and **Microsoft Release Communications** MCP servers (no sign-in). Optionally add the **Microsoft MCP Server for Enterprise** for read-only tenant reads.
3. Open Copilot Chat in **Agent** mode and type `/copilot-ai-sme`, or just ask.

## The MCP servers it uses

| Server | URL | Sign-in | Used for |
| --- | --- | --- | --- |
| Microsoft Learn | `https://learn.microsoft.com/api/mcp` | None | Checking every claim against Microsoft docs |
| Microsoft Release Communications | `https://www.microsoft.com/releasecommunications/mcp` | None | Microsoft Copilot Roadmap and Azure Updates |
| Microsoft MCP Server for Enterprise (optional) | `https://mcp.svc.cloud.microsoft/enterprise` | Work account; admin turns it on once per tenant | Read-only Graph: Message Center, licenses |

Without the Learn server, the skill uses whatever web tool the session has, or marks answers **Unverified** and lists the pages to check.

## Set up (each person)

### 1. Get the files

Clone or download this repo, or just the **Copilot AI SME Skill** folder. If you download only `Install-GitHubCopilotSkill.ps1`, it downloads the rest from GitHub.

### 2. Install the skill

```powershell
cd "Copilot AI SME Skill\GitHub Copilot"
.\Install-GitHubCopilotSkill.ps1                                                   # for you, in every workspace
.\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Copilot AI SME"   # for one folder
```

| Scope | Installs to | Use when |
| --- | --- | --- |
| **User** (default) | `~/.copilot/skills/copilot-ai-sme` | Just you. Works in any folder you open |
| **Workspace** | `<folder>/.github/skills/copilot-ai-sme` and `<folder>/.vscode/mcp.json` with all three servers | A shared folder your team opens in VS Code |

Run it again to update the skill. Add `-NoMcpConfig` to skip writing `mcp.json`.

### 3. Add the MCP servers (User scope)

In VS Code: **Command Palette > MCP: Add Server > HTTP**, once per URL in the table above. Or copy [mcp.json](mcp.json) into your workspace's `.vscode` folder.

For the Enterprise MCP, an admin turns it on once per tenant (step 1 of the [Entra ID Security Review tenant setup](../../Entra%20ID%20Security%20Review/Cowork/readme.md#1-turn-on-the-enterprise-mcp-server-in-your-tenant)).

On **Copilot Business or Enterprise**, your GitHub org or enterprise must allow the **MCP servers in Copilot** policy.

## Ask it

- *"What's included in a Microsoft 365 Copilot license, and what costs extra?"*
- *"What changed in the Copilot roadmap for Cowork this month?"*
- *"Map this agent design to the NIST AI RMF and the OWASP Agentic Top 10."*
- *"Write a read-only Graph PowerShell script that lists this month's Message Center posts about Copilot."*

Scripts it writes go in the open workspace folder. Don't commit output that holds tenant data.

## What's in this folder

| File | What it is |
| --- | --- |
| [Install-GitHubCopilotSkill.ps1](Install-GitHubCopilotSkill.ps1) | Copies the skill from `Cowork/plugin/skills/` (or downloads it) into a folder GitHub Copilot reads, and optionally writes `mcp.json` |
| [mcp.json](mcp.json) | The three MCP server entries for `.vscode/mcp.json` |

## Sources

- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [Microsoft Learn MCP Server](https://learn.microsoft.com/training/support/mcp)
- [Microsoft Release Communications MCP Server](https://learn.microsoft.com/microsoft-365/admin/manage/mrc-mcp)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
