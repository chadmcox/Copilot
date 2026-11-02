# Run the Entra ID operations report in GitHub Copilot

Run the Entra ID operations report from **GitHub Copilot in VS Code** (agent mode). It uses the same skill as the [Cowork setup](../Cowork/readme.md), so you get the same rules, scores and HTML report. Copilot reads your tenant live through the **Microsoft MCP Server for Enterprise**.

**Read-only.** The skill never changes your tenant, and VS Code asks you before it runs any tool.

> GitHub Copilot, VS Code and the Enterprise MCP server change often, and parts are in preview. Test this in your own tenant first.

## Why use GitHub Copilot instead of Cowork

| | GitHub Copilot | Copilot Cowork |
| --- | --- | --- |
| Enterprise MCP setup | One PowerShell command per tenant. VS Code is already registered | App registration, Teams Developer Portal, plugin upload |
| Where results go | A folder on your computer | Your OneDrive Cowork folder |
| Licenses | A GitHub Copilot plan | A Microsoft 365 Copilot license with Cowork |
| Manual checks (admin center settings) | VS Code's browser tools can read them | Cowork's Edge browser access |
| Clouds | Global only (the Enterprise MCP is global only) | Global only |

## VS Code, the CLI, or something else?

| Where | Works? | Notes |
| --- | --- | --- |
| **VS Code** with GitHub Copilot, agent mode | **Yes (recommended)** | The skill and the Enterprise MCP both work |
| **GitHub Copilot CLI** (`copilot` in a terminal) | Explain only | It reads the same `~/.copilot/skills` folder, but the Enterprise MCP sign-in is set up for VS Code only, so it can only explain a findings CSV you already have |
| Visual Studio | Not covered | Use VS Code |
| Copilot on github.com (cloud agent) | No | It runs in GitHub's cloud and can't sign in to your tenant |

## What you need

- **VS Code** with the **GitHub Copilot** extension, signed in to a GitHub account with Copilot, and Chat in **Agent** mode.
- **PowerShell** to run the installer (Windows PowerShell 5.1 or PowerShell 7). No modules needed.
- Membership in **Copilot Entra ID Operations Reader**, activated in PIM before you run the report. See [Who runs it](../README.md#who-runs-it-copilot-entra-id-operations-reader).
- The tenant setup below, done once by an admin.
- On **Copilot Business or Enterprise**, your GitHub org or enterprise must allow the **MCP servers in Copilot** policy.

## Set up (each person, about 5 minutes)

### 1. Get the files

Clone or download this repo, or download just the **Entra ID Operations Report** folder. If you download only `Install-GitHubCopilotSkill.ps1`, it downloads the rest from GitHub.

### 2. Install the skill

```powershell
cd "Entra ID Operations Report\GitHub Copilot"
.\Install-GitHubCopilotSkill.ps1                     # for you, in every workspace
.\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Entra Operations"   # for one folder
```

| Scope | Installs to | Use when |
| --- | --- | --- |
| **User** (default) | `~/.copilot/skills/entra-id-operations` | Just you. Works in any folder you open |
| **Workspace** | `<folder>/.github/skills/entra-id-operations` and `<folder>/.vscode/mcp.json` | A shared folder your team opens in VS Code |

The skill folder holds SKILL.md, the rules and the report template. Run the installer again to update it.

### 3. Add the Enterprise MCP server

- **Workspace scope:** the installer already wrote `.vscode/mcp.json`. Open the folder in VS Code and start the server when asked.
- **User scope:** use Microsoft's [Install Microsoft MCP Server for Enterprise](https://vscode.dev/redirect/mcp/install?name=Microsoft%20MCP%20Server%20for%20Enterprise&config=%7b%22name%22:%22Microsoft%20MCP%20Server%20for%20Enterprise%22%2c%22type%22:%22http%22%2c%22url%22:%22https://mcp.svc.cloud.microsoft/enterprise%22%7d) link, or run **MCP: Add Server** from the Command Palette, pick **HTTP**, and enter `https://mcp.svc.cloud.microsoft/enterprise`. [mcp.json](mcp.json) in this folder has the same entry to copy.

VS Code opens a browser to sign in. Use your admin account, the one in Copilot Entra ID Operations Reader.

### 4. Test it

In Copilot Chat (Agent mode), type `/entra-id-operations`. You should see the skill. Then ask *"How many Global Administrators are in my tenant?"* Copilot should call `microsoft_graph_get`.

## Tenant setup for the Enterprise MCP (admin, once per tenant)

You need **Application Administrator** or **Cloud Application Administrator**. If you already did step 1 of the [Cowork setup](../Cowork/readme.md#1-turn-on-the-enterprise-mcp-server-in-your-tenant), or set up another solution in this repo for VS Code, it's done: the same command sets up VS Code.

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

This registers the Microsoft MCP Server for Enterprise and grants Microsoft's **Visual Studio Code** app (appId `aebc6443-996d-45c2-90f0-388ff96faa56`) all its read-only MCP scopes, which include every scope this report uses. No app registration, client secret or Teams Developer Portal step is needed. The MCP server acts as the signed-in person, so people still see only what their activated roles allow.

## Run it

1. Activate **Copilot Entra ID Operations Reader** in PIM (My roles > Groups).
2. In Copilot Chat (Agent mode), paste [the prompt](../Cowork/readme.md#the-prompt), and add *"Save the report to C:\Entra Operations."*
3. Approve the tool calls as they come. Copilot reads the tenant, applies the rules and builds **Entra ID Operations Report.html** from the template, then gives you the score per area, the well-protected admins %, the counts and the top 3 fixes.

To explain an earlier report, add the findings CSV from its **Export CSV** button to the chat and ask: *"Explain these Entra ID operations results and give me the top 3 fixes."* This also works in the Copilot CLI.

### Optional: read the manual checks in the browser

Many of the guide's checks have no API (SSPR, Entra Connect version, diagnostic settings, Restrict access to Microsoft Entra admin center). VS Code's browser tools let Copilot open those admin center pages and report what they're set to; the skill tells it to read only. Ask *"Also read the manual checks in the admin center."* Copilot opens the page in VS Code's integrated browser; sign in there yourself (with the group activated in PIM first). If Copilot has no browser tools, check that the VS Code setting **workbench.browser.enableChatTools** is on. To keep it to Microsoft sites, set **chat.agent.networkFilter** and list `entra.microsoft.com`, `portal.azure.com` and `admin.microsoft.com` in **chat.agent.allowedNetworkDomains**.

## Keep it read-only

- Approve each tool call yourself. Don't turn on auto-approve for this workspace.
- Copilot drafts notes to app owners but doesn't send them.
- The report changes nothing. Make the fixes yourself, with the right admin role activated in PIM.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `/entra-id-operations` doesn't show up | Run **Developer: Reload Window**. Check the folder is `~/.copilot/skills/entra-id-operations` (or `.github/skills/...` in the folder you opened) and has SKILL.md. Run **Chat: Open Customizations** to see the skills VS Code found |
| No `microsoft_graph_get` tool | Use Agent mode, not Ask. Run **MCP: List Servers** and start the server. Check the tools picker in Chat. On Copilot Business or Enterprise, ask your GitHub admin about the MCP servers policy |
| Sign-in says the app needs permission or admin approval | The tenant setup above hasn't been done |
| Many 403s | Activate Copilot Entra ID Operations Reader in PIM (My roles > Groups), sign out of the MCP server and back in, then try again |
| 403 "not authorized by the available scopes" on a few calls | Expected for Entra Connect feature settings, Microsoft Secure Score and hybrid agents: the Enterprise MCP has no scope for them (Secure Score needs `SecurityEvents.Read.All`; Entra Connect settings need `OnPremDirectorySynchronization.Read.All` and Global Administrator). They're on the manual checklist |
| 403 that mentions a license on sign-in logs or risky users | The tenant doesn't have Entra ID P1 or P2. The report skips those checks and says so |

## What's in this folder

| File | What it is |
| --- | --- |
| [Install-GitHubCopilotSkill.ps1](Install-GitHubCopilotSkill.ps1) | Installs the skill for GitHub Copilot, and writes `.vscode/mcp.json` for a workspace |
| [mcp.json](mcp.json) | The Enterprise MCP entry for `.vscode/mcp.json`, if you'd rather copy it by hand |

The skill itself lives in [../Cowork/plugin/skills/entra-id-operations](../Cowork/plugin/skills/entra-id-operations/SKILL.md), so Cowork and GitHub Copilot always use the same rules.

## Privacy

The report describes your tenant's weak spots. Keep the output folder out of source control (this repo's `.gitignore` already skips the report and CSV files) and share it only with the people who need it. GitHub Copilot sends what it reads to its model to answer you, so follow your organization's rules for GitHub Copilot and tenant data.

## Sources

- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [MCP configuration reference for VS Code](https://code.visualstudio.com/docs/agents/reference/mcp-configuration)
- [Extending GitHub Copilot Chat with MCP (the MCP servers policy)](https://docs.github.com/copilot/how-tos/context/model-context-protocol/extending-copilot-chat-with-mcp)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
- [Browser tools for GitHub Copilot in VS Code are generally available](https://github.blog/changelog/2026-07-01-browser-tools-for-github-copilot-in-vs-code-are-generally-available)
