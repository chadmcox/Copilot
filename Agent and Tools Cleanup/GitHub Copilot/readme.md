# Run the review in GitHub Copilot

Find unused agents, tools, agent identities and blueprints from **GitHub Copilot in VS Code** (agent mode) or the **GitHub Copilot CLI**. It uses the same two skills as the [Cowork setup](../Cowork/readme.md):

- **agent-tools-review**: agent identities and blueprints through the Enterprise MCP, or the whole report through `Get-AgentToolsReport.ps1`.
- **admin-center-tools-review**: the admin center **Agents > Tools** pages no API covers, through VS Code's browser tools.

**Read-only.** The skills never change your tenant. Copilot may run `Invoke-AgentToolsCleanup.ps1` only with `-WhatIf`, to show what would change. You run the real cleanup yourself.

> GitHub Copilot, VS Code, Agent 365 and the Enterprise MCP server change often, and parts are in preview. Test this in your own tenant first.

## Why use GitHub Copilot instead of Cowork

| | GitHub Copilot | Copilot Cowork |
| --- | --- | --- |
| Agents and plugins (Agent 365 catalog) and Defender activity | **Read live.** Copilot runs `Get-AgentToolsReport.ps1` for you, signed in as you | Attach Packages.csv. The Enterprise MCP can't read them |
| Admin center Tools pages | VS Code's browser tools | Cowork's Edge browser access |
| Enterprise MCP setup | One PowerShell command per tenant. VS Code is already registered | App registration, Teams Developer Portal, plugin upload |
| What would change | Copilot can run the cleanup with `-WhatIf` and explain it | Not available |
| Licenses | A GitHub Copilot plan | A Microsoft 365 Copilot license with Cowork |
| Clouds | Scripts: Global, GCC High, DoD. Enterprise MCP: Global only | Global only |

## VS Code, the CLI, or something else?

| Where | Works? | Notes |
| --- | --- | --- |
| **VS Code** with GitHub Copilot, agent mode | **Yes (recommended)** | Both skills, the scripts, the Enterprise MCP and the browser all work |
| **GitHub Copilot CLI** (`copilot` in a terminal) | Yes, with the scripts | Reads the same `~/.copilot/skills` folder. The Enterprise MCP sign-in is set up for VS Code only, and there's no browser, so use the scripts |
| Visual Studio | Not covered | Use VS Code |
| Copilot on github.com (cloud agent) | No | It runs in GitHub's cloud and can't sign in to your tenant |

So yes: VS Code needs its own setup (below). The CLI needs nothing extra once the skills are installed in your user folder.

## What you need

- **VS Code** with the **GitHub Copilot** extension, signed in to a GitHub account with Copilot, and Chat in **Agent** mode.
- **PowerShell 7** (or Windows PowerShell 5.1) with the **Microsoft.Graph.Authentication** module: `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`.
- Membership in **Copilot Health Check Users** (AI Reader, Security Reader, Reports Reader), activated in PIM before you start. See [Permissions and roles](../README.md#permissions-and-roles).
- For the live Enterprise MCP way only:
  - The tenant setup below, done once by an admin.
  - On **Copilot Business or Enterprise**, your GitHub org or enterprise must allow the **MCP servers in Copilot** policy.

## Set up (each person, about 5 minutes)

### 1. Get the files

Clone or download this repo, or download just the **Agent and Tools Cleanup** folder. If you download only `Install-GitHubCopilotSkill.ps1`, it downloads the rest from GitHub.

### 2. Install the skills

```powershell
cd "Agent and Tools Cleanup\GitHub Copilot"
.\Install-GitHubCopilotSkill.ps1                     # for you, in every workspace and the Copilot CLI
.\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Copilot Health Checks"   # for one folder
```

| Scope | Installs to | Use when |
| --- | --- | --- |
| **User** (default) | `~/.copilot/skills/agent-tools-review` and `~/.copilot/skills/admin-center-tools-review` | Just you. Works in any folder you open, and in the Copilot CLI |
| **Workspace** | `<folder>/.github/skills/...` and `<folder>/.vscode/mcp.json` | A shared folder your team opens in VS Code |

`agent-tools-review` gets a `scripts` folder with `Get-AgentToolsReport.ps1` and `Invoke-AgentToolsCleanup.ps1`. Run the installer again to update both skills.

### 3. Add the Enterprise MCP server (optional, for the live review)

Skip this if you only want Copilot to run the script.

- **Workspace scope:** the installer already wrote `.vscode/mcp.json`. Open the folder in VS Code and start the server when asked.
- **User scope:** use Microsoft's [Install Microsoft MCP Server for Enterprise](https://vscode.dev/redirect/mcp/install?name=Microsoft%20MCP%20Server%20for%20Enterprise&config=%7b%22name%22:%22Microsoft%20MCP%20Server%20for%20Enterprise%22%2c%22type%22:%22http%22%2c%22url%22:%22https://mcp.svc.cloud.microsoft/enterprise%22%7d) link, or run **MCP: Add Server** from the Command Palette, pick **HTTP**, and enter `https://mcp.svc.cloud.microsoft/enterprise`. [mcp.json](mcp.json) in this folder has the same entry to copy.

VS Code opens a browser to sign in. Use your admin account, the one in Copilot Health Check Users.

### 4. Turn on the browser tools (for admin-center-tools-review)

VS Code's browser tools are on by default. If Copilot says it has no browser, turn on the VS Code setting **workbench.browser.enableChatTools**. To keep the agent on Microsoft sites, turn on **chat.agent.networkFilter** and list `admin.microsoft.com` and `admin.cloud.microsoft` in **chat.agent.allowedNetworkDomains**. Copilot opens the admin center in VS Code's integrated browser; you sign in there yourself, with your role activated in PIM.

### 5. Test it

In Copilot Chat (Agent mode), type `/agent-tools-review`. You should see both skills. Then:

- **Script:** ask *"Run the agent and tools review with the script. Use the Global cloud and save the results to C:\Copilot Health Checks."*
- **Enterprise MCP:** ask *"How many agent identities are in my tenant?"* Copilot should call `microsoft_graph_get`.

## Tenant setup for the Enterprise MCP (admin, once per tenant)

You need **Application Administrator** or **Cloud Application Administrator**. If you already did step 1 of the [Cowork setup](../Cowork/readme.md#1-turn-on-the-enterprise-mcp-server-in-your-tenant), it's done: the same command sets up VS Code.

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

This registers the Microsoft MCP Server for Enterprise and grants Microsoft's **Visual Studio Code** app (appId `aebc6443-996d-45c2-90f0-388ff96faa56`) its read-only MCP scopes. No app registration, client secret or Teams Developer Portal step is needed. The MCP server acts as the signed-in person, so people still see only what their activated roles allow.

## Run it

### Way 1: Copilot runs the report script (full review)

Ask:

```text
Run the agent and tools review with the script. Count anything unused for 90 days as stale. Use the Global cloud and save the results to C:\Copilot Health Checks.
```

Copilot runs `scripts/Get-AgentToolsReport.ps1 -Environment Global -Days 90 -OutFolder ...` in the terminal, after you approve it. Finish the sign-in in the browser window. Copilot then reads Packages.csv, AgentIdentities.csv and Blueprints.csv and gives you the four tables, the counts per recommendation and the identities with no sponsor.

Use **USGov** for GCC High or **USGovDoD** for DoD. Add *"search 90 days of audit records"* for a slower, deeper check (`-AuditDays 90`).

### Way 2: live through the Enterprise MCP and the browser

Paste [the Cowork prompt](../Cowork/readme.md#the-prompt). Add Packages.csv to the chat if you have it (drag it in, or type `#` and pick the file). Copilot reads identities and blueprints live, then opens **Agents > Tools** in the browser for standalone MCP servers and skills.

Browser only: *"Check the admin center Tools registry and tell me which MCP servers, skills and plugins look unused."*

### See what the cleanup would change

```text
Show me what Invoke-AgentToolsCleanup.ps1 would change for the report in C:\Copilot Health Checks\AgentToolsReport-<date>, with -WhatIf.
```

Copilot runs it with `-WhatIf` only and explains the output. When you agree, run the command it gives you yourself (see [Clean up](../README.md#3-clean-up)). Keep the undo file it writes.

### In the Copilot CLI

Open a terminal in the folder where you want the results, run `copilot`, and ask the way 1 prompt. The CLI asks before it runs the script.

## Keep it read-only

- Approve each terminal command, tool call and browser action yourself. Don't turn on auto-approve for this workspace.
- The skills tell Copilot never to select **Block**, **Delete** or any button that changes a setting, and never to run the cleanup without `-WhatIf`. Your approvals are the backstop.
- Copilot drafts notes to sponsors but doesn't send them.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `/agent-tools-review` doesn't show up | Run **Developer: Reload Window**. Check the folders are in `~/.copilot/skills` (or `.github/skills` in the folder you opened) and each has SKILL.md. Run **Chat: Open Customizations** to see the skills VS Code found |
| No `microsoft_graph_get` tool | Use Agent mode, not Ask. Run **MCP: List Servers** and start the server. Check the tools picker in Chat. On Copilot Business or Enterprise, ask your GitHub admin about the MCP servers policy |
| Sign-in says the app needs permission or admin approval | The tenant setup above hasn't been done |
| Many 403s | Activate Copilot Health Check Users in PIM (My roles > Groups), then try again |
| Copilot has no browser | Turn on **workbench.browser.enableChatTools** and check **chat.agent.allowedNetworkDomains** |
| The script stops and waits | It's asking which cloud. Tell Copilot which cloud to use so it passes `-Environment` |
| `Connect-MgGraph` not found | `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser` |

## What's in this folder

| File | What it is |
| --- | --- |
| [Install-GitHubCopilotSkill.ps1](Install-GitHubCopilotSkill.ps1) | Installs both skills and the scripts for GitHub Copilot, and writes `.vscode/mcp.json` for a workspace |
| [mcp.json](mcp.json) | The Enterprise MCP entry for `.vscode/mcp.json`, if you'd rather copy it by hand |

The skills themselves live in [../Cowork/plugin/skills](../Cowork/plugin/skills/agent-tools-review/SKILL.md), so Cowork and GitHub Copilot always use the same rules.

## Privacy

The results name agents, sponsors and tenant objects. Keep the output folder out of source control (this repo's `.gitignore` already skips the usual file names) and share it only with the people who need it. GitHub Copilot sends what it reads to its model to answer you, so follow your organization's rules for GitHub Copilot and tenant data.

## Sources

- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [MCP configuration reference for VS Code](https://code.visualstudio.com/docs/agents/reference/mcp-configuration)
- [Browser tools for GitHub Copilot in VS Code are generally available](https://github.blog/changelog/2026-07-01-browser-tools-for-github-copilot-in-vs-code-are-generally-available)
- [Extending GitHub Copilot Chat with MCP (the MCP servers policy)](https://docs.github.com/copilot/how-tos/context/model-context-protocol/extending-copilot-chat-with-mcp)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
- [Overview of the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/overview)
