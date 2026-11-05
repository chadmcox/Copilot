# Run the health check in GitHub Copilot

Run the agent and tools health check from **GitHub Copilot in VS Code** (agent mode) or the **GitHub Copilot CLI**. It uses the same skill as the [Cowork setup](../Cowork/readme.md), so you get the same rules, scores and HTML report.

**Read-only.** The skill never changes your tenant, and VS Code asks you before it runs any command or tool.

> GitHub Copilot, VS Code and the Enterprise MCP server change often, and parts are in preview. Test this in your own tenant first.

## Why use GitHub Copilot instead of Cowork

| | GitHub Copilot | Copilot Cowork |
| --- | --- | --- |
| Agent 365 catalog and Defender's agent inventory | **Read live.** Copilot runs `Get-AgentToolsHealth.ps1` for you, signed in as you | Attach Packages.csv and DefenderAgents.csv. The Enterprise MCP can't read them |
| Enterprise MCP setup | One PowerShell command per tenant. VS Code is already registered | App registration, Teams Developer Portal, plugin upload |
| Where results go | A folder on your computer | Your OneDrive Cowork folder |
| Licenses | A GitHub Copilot plan | A Microsoft 365 Copilot license with Cowork |
| Manual checks (admin center settings) | VS Code's browser tools can read them | Cowork's Edge browser access |
| Clouds | Script: Global, GCC High, DoD. Enterprise MCP: Global only | Global only |

## VS Code, the CLI, or something else?

| Where | Works? | Notes |
| --- | --- | --- |
| **VS Code** with GitHub Copilot, agent mode | **Yes (recommended)** | The skill, the script and the Enterprise MCP all work |
| **GitHub Copilot CLI** (`copilot` in a terminal) | Yes, with the script | Reads the same `~/.copilot/skills` folder. The Enterprise MCP sign-in is set up for VS Code only, so use the script |
| Visual Studio | Not covered | Use VS Code |
| Copilot on github.com (cloud agent) | No | It runs in GitHub's cloud and can't sign in to your tenant |

So yes: VS Code needs its own setup (below). The CLI needs nothing extra once the skill is installed in your user folder.

## What you need

- **VS Code** with the **GitHub Copilot** extension, signed in to a GitHub account with Copilot, and Chat in **Agent** mode.
- **PowerShell 7** (or Windows PowerShell 5.1) with the **Microsoft.Graph.Authentication** module: `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`.
- Membership in **Copilot Health Check Users**, activated in PIM before you run the check. See [Who runs it](../README.md#who-runs-it-copilot-health-check-users). The script needs Security Reader for Defender; without it, run with `-SkipDefender`. It needs Reports Reader for Copilot agent adoption; without it, run with `-SkipCopilotUsage`.
- For the live Enterprise MCP way only:
  - The tenant setup below, done once by an admin.
  - On **Copilot Business or Enterprise**, your GitHub org or enterprise must allow the **MCP servers in Copilot** policy.

## Set up (each person, about 5 minutes)

### 1. Get the files

Clone or download this repo, or download just the **Agent and Tools Health Check** folder. If you download only `Install-GitHubCopilotSkill.ps1`, it downloads the rest from GitHub.

### 2. Install the skill

```powershell
cd "Agent and Tools Health Check\GitHub Copilot"
.\Install-GitHubCopilotSkill.ps1                     # for you, in every workspace and the Copilot CLI
.\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Copilot Health Checks"   # for one folder
```

| Scope | Installs to | Use when |
| --- | --- | --- |
| **User** (default) | `~/.copilot/skills/agent-tools-health` | Just you. Works in any folder you open, and in the Copilot CLI |
| **Workspace** | `<folder>/.github/skills/agent-tools-health` and `<folder>/.vscode/mcp.json` | A shared folder your team opens in VS Code |

The skill folder holds SKILL.md, the rules and guidance, the report template and `scripts/Get-AgentToolsHealth.ps1`. Run the installer again to update it.

### 3. Add the Enterprise MCP server (optional, for the live check)

Skip this if you only want Copilot to run the script.

- **Workspace scope:** the installer already wrote `.vscode/mcp.json`. Open the folder in VS Code and start the server when asked.
- **User scope:** use Microsoft's [Install Microsoft MCP Server for Enterprise](https://vscode.dev/redirect/mcp/install?name=Microsoft%20MCP%20Server%20for%20Enterprise&config=%7b%22name%22:%22Microsoft%20MCP%20Server%20for%20Enterprise%22%2c%22type%22:%22http%22%2c%22url%22:%22https://mcp.svc.cloud.microsoft/enterprise%22%7d) link, or run **MCP: Add Server** from the Command Palette, pick **HTTP**, and enter `https://mcp.svc.cloud.microsoft/enterprise`. [mcp.json](mcp.json) in this folder has the same entry to copy.

VS Code opens a browser to sign in. Use your admin account, the one in Copilot Health Check Users.

### 4. Test it

In Copilot Chat (Agent mode), type `/agent-tools-health`. You should see the skill. Then:

- **Script:** ask *"Run the agent and tools health check with the script. Use the Global cloud and save the results to C:\Copilot Health Checks."*
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

### Way 1: Copilot runs the script (full check)

Ask:

```text
Run the agent and tools health check with the script. Use the Global cloud and save the results to C:\Copilot Health Checks.
```

Copilot runs `scripts/Get-AgentToolsHealth.ps1 -Environment Global -OutputFolder ...` in the terminal, after you approve it. Finish the sign-in in the browser window. When it's done, Copilot reads Findings.csv and Scorecard.csv, gives you the score per area, the counts and the top 3 fixes, and points you to **Report.html**.

Use **USGov** for GCC High or **USGovDoD** for DoD. Add *"stale after 60 days"* (`-StaleDays 60`), *"skip Defender"* (`-SkipDefender`), *"skip Copilot usage"* (`-SkipCopilotUsage`) or *"no Agent 365 license"* (`-SkipPackages`) as needed.

### Way 2: live through the Enterprise MCP

Put Packages.csv and DefenderAgents.csv in your folder (ask Copilot to run the script with `-PackagesOnly`, or see [Get Packages.csv and DefenderAgents.csv](../Cowork/readme.md#get-packagescsv-and-defenderagentscsv)), add them to the chat (drag them in, or type `#` and pick the files), then paste [the Cowork prompt](../Cowork/readme.md#the-prompt). Copilot reads agent identities, blueprints, groups and Conditional Access live and builds **Agent and Tools Health.html** from the template.

### Way 3: explain results you already have

Add Findings.csv and Scorecard.csv to the chat and ask: *"Explain these agent and tools health results and give me the top 3 fixes."*

### In the Copilot CLI

Open a terminal in the folder where you want the results, run `copilot`, and ask the way 1 prompt. The CLI asks before it runs the script.

### Optional: read the manual checks in the browser

Some settings have no API (blueprint creation, the inactivity policy, external publishers, sharing). VS Code's browser tools let Copilot open those admin center pages and report what they're set to; the skill tells it to read only. Ask *"Also read the manual checks in the admin center."* Copilot opens the page in VS Code's integrated browser; sign in there yourself (and activate your role in PIM first). If Copilot has no browser tools, check that the VS Code setting **workbench.browser.enableChatTools** is on. To keep it to Microsoft sites, set **chat.agent.networkFilter** and list `admin.microsoft.com`, `admin.cloud.microsoft`, `entra.microsoft.com` and `security.microsoft.com` in **chat.agent.allowedNetworkDomains**.

## Keep it read-only

- Approve each terminal command and tool call yourself. Don't turn on auto-approve for this workspace.
- Copilot drafts notes to sponsors and owners but doesn't send them.
- The health check changes nothing. To block or disable what's stale, use [Agent and Tools Cleanup](../../Agent%20and%20Tools%20Cleanup/GitHub%20Copilot/readme.md).

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `/agent-tools-health` doesn't show up | Run **Developer: Reload Window**. Check the folder is `~/.copilot/skills/agent-tools-health` (or `.github/skills/...` in the folder you opened) and has SKILL.md. Run **Chat: Open Customizations** to see the skills VS Code found |
| No `microsoft_graph_get` tool | Use Agent mode, not Ask. Run **MCP: List Servers** and start the server. Check the tools picker in Chat. On Copilot Business or Enterprise, ask your GitHub admin about the MCP servers policy |
| Sign-in says the app needs permission or admin approval | The tenant setup above hasn't been done |
| Many 403s | Activate Copilot Health Check Users in PIM (My roles > Groups), then try again |
| The script stops and waits | It's asking which cloud. Tell Copilot which cloud to use so it passes `-Environment` |
| `Connect-MgGraph` not found | `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser` |

## What's in this folder

| File | What it is |
| --- | --- |
| [Install-GitHubCopilotSkill.ps1](Install-GitHubCopilotSkill.ps1) | Installs the skill and the script for GitHub Copilot, and writes `.vscode/mcp.json` for a workspace |
| [mcp.json](mcp.json) | The Enterprise MCP entry for `.vscode/mcp.json`, if you'd rather copy it by hand |

The skill itself lives in [../Cowork/plugin/skills/agent-tools-health](../Cowork/plugin/skills/agent-tools-health/SKILL.md), so Cowork and GitHub Copilot always use the same rules.

## Privacy

The results name agents, sponsors, groups and permissions. Keep the output folder out of source control (this repo's `.gitignore` already skips the usual file names) and share it only with the people who need it. GitHub Copilot sends what it reads to its model to answer you, so follow your organization's rules for GitHub Copilot and tenant data.

## Sources

- [Browser tools for GitHub Copilot in VS Code are generally available](https://github.blog/changelog/2026-07-01-browser-tools-for-github-copilot-in-vs-code-are-generally-available)
- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [MCP configuration reference for VS Code](https://code.visualstudio.com/docs/agents/reference/mcp-configuration)
- [Extending GitHub Copilot Chat with MCP (the MCP servers policy)](https://docs.github.com/copilot/how-tos/context/model-context-protocol/extending-copilot-chat-with-mcp)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
- [Overview of the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/overview)
