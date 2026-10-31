# Run the agent and tools review in Copilot Cowork

Ask **Microsoft Copilot Cowork** which agents, tools (plugins, skills, MCP servers), agent identities and blueprints nobody uses, and get tables with a recommendation for each. You don't need PowerShell after setup.

The plugin has two skills:

| Skill | Reads | How |
| --- | --- | --- |
| **agent-tools-review** | Agent identities, sponsors, blueprints, sign-ins, plus an attached `Packages.csv` | **Microsoft MCP Server for Enterprise**, live |
| **admin-center-tools-review** | Admin center pages with no API: standalone MCP servers and skills, plugin status and availability, pending requests, the agent usage report | Cowork's **browser** (Microsoft Edge), as you |

**Read-only.** The Enterprise MCP server can only read, and the browser skill is told never to select Block, Delete or any button that changes a setting. To block or disable anything, use `Invoke-AgentToolsCleanup.ps1` (see the [main README](../README.md)).

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## What Cowork can read through the Enterprise MCP

Tested against a live tenant on Oct 31, 2026:

| Data | Graph call | Works through the MCP? |
| --- | --- | --- |
| Agent identities and their sponsors | `/beta/servicePrincipals/graph.agentIdentity?$expand=sponsors` | Yes |
| Blueprint principals | `/beta/servicePrincipals/microsoft.graph.agentIdentityBlueprintPrincipal` | Yes |
| Blueprints registered in your tenant | `/beta/applications/microsoft.graph.agentIdentityBlueprint` | Yes |
| Last sign-in per identity or blueprint | `/beta/reports/servicePrincipalSignInActivities?$filter=appId eq '...'` | Yes |
| Agents and tools in the Agent 365 catalog | `/beta/copilot/admin/catalog/packages` | **No: 403.** No MCP scope covers it |
| Copilot audit records | `/beta/security/auditLog/queries` | No. No MCP scope covers it |

So for agents and plugins, either attach **Packages.csv** from `Get-AgentToolsReport.ps1` (the full catalog with usage, status and recommendation), or let the browser skill read the admin center pages. Standalone MCP servers and skills have no API at all, so only the browser skill covers them.

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **A. Plugin with the Enterprise MCP** (recommended) | An admin, once per tenant (below) | Both skills: reads identities, blueprints and sign-ins live, reads the admin center in the browser, and combines them with any CSV you attach |
| **B. Skills only** | Each person, about 2 minutes | Explains the CSVs from `Get-AgentToolsReport.ps1`, and reads the admin center in the browser |

## The prompt

```text
Run the agent and tools review. Count anything unused for 90 days as stale.

Use the Microsoft MCP Server for Enterprise to read every agent identity (with sponsors), every agent identity blueprint principal, the blueprints registered in this tenant, and the last sign-in of each identity and blueprint principal. Use the attached Packages.csv for agents and plugins. Then use the browser to read the Microsoft 365 admin center Agents > Tools pages (Registry, Plugins, Requests) for standalone MCP servers and skills.

This is read-only. Don't change anything in the tenant, don't select any button that changes a setting, and don't send any email or Teams message.

Give me:
1. Tables of agents, tools (plugins, skills, MCP servers), agent identities and blueprints, each with name, status, days since last use and recommendation.
2. Counts per recommendation.
3. The identities with no sponsor.
4. The manual admin center steps for anything to block, and the Graph calls and pages you used.
```

For **way B**, attach `Packages.csv`, `AgentIdentities.csv` and `Blueprints.csv` and ask: *"Explain these agent and tools results and tell me what to clean up first."*

Browser only (either way): *"Check the admin center Tools registry and tell me which MCP servers, skills and plugins look unused."*

Good follow-ups:
- *"Draft a note to the sponsor of each stale agent identity asking if it's still needed."* Cowork drafts it and asks before sending.
- *"Run this review on the first Monday of every month."* Cowork can run prompts on a schedule.

## Turn on browser access (for admin-center-tools-review)

The browser skill drives the person's own Microsoft Edge, with their sign-in and your Conditional Access and DLP policies. It can't reach anything they can't.

1. Microsoft 365 admin center > **Copilot > Settings > View all > Cowork settings > Allow browser access**: select **Allow Cowork to use the Microsoft Edge browser to perform tasks on behalf of users**, and limit it to the admins who run this review (for example the *Copilot + Cowork Browser Access* group from the [Group Assignment Guide](../../Group%20Assignment%20Guide/readme.md)). It's off by default.
2. The person runs Cowork **in a browser** (not the desktop app or mobile), has **Edge 152 or later**, and is signed in to Edge with the same work account. InPrivate and guest profiles don't work.
3. They need read access to **Agents > Tools** and the Copilot reports: activate **Copilot Health Check Users** (AI Reader, Security Reader, Reports Reader) in PIM before they start. Cowork stops and asks if a sign-in, MFA or PIM prompt appears.
4. The first browser task shows a consent notice. Select **I understand**.

Optional: the Edge policy `CopilotCoworkToolActionsEnabled` controls which Edge installs Cowork may drive.

## Way A: admin setup (once per tenant)

**Already set up the [Billing Health Check plugin](../../Billing%20Health%20Check/Cowork/readme.md)?** Reuse its app registration and OAuth client registration. Run step 3 with the same Application (client) ID to add the scopes below (the cmdlet adds them and keeps the old ones), then go to step 5 with the same registration ID.

Roles: **Application Administrator** or **Cloud Application Administrator** for steps 1 to 3, and a Microsoft 365 admin (AI Administrator or Global Administrator) for step 5. The people who run the review go in **Copilot Health Check Users** (role-assignable, under PIM, with AI Reader, Security Reader and Reports Reader; see the [Group Assignment Guide](../../Group%20Assignment%20Guide/readme.md#copilot-health-check-users)), and need a Microsoft 365 Copilot license and Cowork access. Scope the plugin to that group when you upload it. Blocking and disabling with the scripts needs **Copilot Agent Management Admin** and **Copilot Agent ID Admin** instead. The MCP server acts as the signed-in person, so it can't see more than they can.

### 1. Turn on the Enterprise MCP server in your tenant

Run this once in PowerShell. It's Microsoft's own provisioning step and uses the Microsoft Entra PowerShell module (this one step is the exception to the Graph-only rule in this repo, because Microsoft only ships provisioning as a cmdlet).

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

### 2. Register an app for Cowork

In the **Microsoft Entra admin center > App registrations > New registration**:

1. Name: **Agent and Tools Review - Cowork**. Account type: **Single tenant**.
2. Redirect URI: platform **Web**, value `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`.
3. Copy the **Application (client) ID** and **Directory (tenant) ID**.
4. **Certificates & secrets > New client secret**. Copy the secret value, and note when it expires.

### 3. Give the app read-only MCP permissions

```powershell
Grant-EntraBetaMCPServerPermission -ApplicationId "<Application (client) ID>" -Scopes `
    "MCP.Application.Read.All", "MCP.AuditLog.Read.All"
```

| Scope | Why |
| --- | --- |
| MCP.Application.Read.All | Agent identities, blueprints, blueprint principals, sponsors |
| MCP.AuditLog.Read.All | Service principal sign-in activity |

Nothing else is needed. There's no MCP scope for the Agent 365 registry yet.

### 4. Register the OAuth client in the Teams Developer Portal

Open [Teams Developer Portal](https://dev.teams.microsoft.com/tools) > **Tools > OAuth client registration > Register client**:

| Field | Value |
| --- | --- |
| Registration name | Agent and Tools Review - Enterprise MCP |
| Base URL | `https://mcp.svc.cloud.microsoft/enterprise` |
| Restrict usage by org | Your organization |
| Restrict usage by app | **Any Teams app** (a specific app makes every tool call fail with 404) |
| Client ID and secret | From step 2 |
| Authorization endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/authorize`, with **TENANT-ID replaced by your Directory (tenant) ID** |
| Token endpoint and refresh endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/token`, with TENANT-ID replaced the same way |
| Scope | `api://e8c77dc2-69b3-43f4-bc51-3213c9d915b4/.default offline_access` |
| PKCE | On |

Save, then copy the **OAuth client registration ID**. (`e8c77dc2-...` is the Microsoft MCP Server for Enterprise app ID, the same in every tenant.)

> **AADSTS90013: Invalid input received from the user** when Cowork connects means an endpoint still has the placeholder in it. Edit the registration, put in your real tenant ID, and save. The registration ID stays the same, so you don't need to rebuild the plugin.

### 5. Build and upload the plugin

```powershell
.\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
```

This writes **AgentToolsReview-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.

In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose the admins who should run the review (for example your Agent ID or AI admin group). Don't pick all users.

### 6. Test it

1. In Copilot Cowork, select **+ > Customize > Plugins** and add **Agent and Tools Review**.
2. Start a task and ask: *"How many agent identities are in my tenant?"* Sign in when asked.
3. If that works, attach Packages.csv (optional) and paste the prompt above.

If tool calls fail, check that the base URL, the "Any Teams app" setting and the registration ID all match. Microsoft's [plugin authentication troubleshooting](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-troubleshooting) lists the common causes.

## Way B: skills only

1. Build the skill zips: `.\New-CoworkPluginPackage.ps1 -SkillOnly` writes **agent-tools-review.zip**, and `.\New-CoworkPluginPackage.ps1 -SkillOnly -Skill admin-center-tools-review` writes **admin-center-tools-review.zip**.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose each zip.
3. Start a new Cowork task. Attach the CSVs, or ask for the admin center check. The skills load on their own.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The plugin zip goes under **Customize > Plugins > Upload plugin**. The skills box only takes the `-SkillOnly` zip.

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/agent-tools-review/SKILL.md](plugin/skills/agent-tools-review/SKILL.md) | MCP skill: the steps Cowork follows, with the exact Graph calls |
| [plugin/skills/admin-center-tools-review/SKILL.md](plugin/skills/admin-center-tools-review/SKILL.md) | Browser skill: the admin center pages to read, and the read-only rules |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the plugin zip with your registration ID, or a skill-only zip |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The browser skill runs in the person's own Edge with their own sign-in, and the browser tasks are recorded in the unified audit log. Results name agents and their sponsors, so share them only with the people who need them.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started) (provisioning and the list of MCP scopes)
- [Manage Microsoft MCP Server for Enterprise permissions](https://learn.microsoft.com/powershell/entra-powershell/how-to-manage-mcp-server-permissions)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development)
- [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Manage plugins, skills, and MCP servers](https://learn.microsoft.com/microsoft-agent-365/admin/manage-plugins-skills-mcp-servers)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-local-browser)
- [Overview of the Tools page](https://learn.microsoft.com/microsoft-agent-365/admin/agent-tools-overview)
- [Microsoft Copilot Agents usage report](https://learn.microsoft.com/microsoft-365/admin/activity-reports/microsoft-365-copilot-agents-new)
