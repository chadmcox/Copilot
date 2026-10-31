# Run the agent and tools health check in Copilot Cowork

Ask **Microsoft Copilot Cowork** to check your agents, tools, agent identities and blueprints, with no PowerShell needed after setup. Cowork reads Entra live through the **Microsoft MCP Server for Enterprise**, applies the same rules as `Get-AgentToolsHealth.ps1`, and gives you an interactive HTML report with a score per area.

**Read-only.** The Enterprise MCP server can only read; it can't change your tenant.

> Microsoft changes Cowork, plugins, Agent 365 and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## What you need to know first

The Enterprise MCP server **can't read the Agent 365 catalog**: no MCP scope covers it, so a request to `/copilot/admin/catalog/packages` returns 403. So you give Cowork the agents and tools as a file, **Packages.csv**, and Cowork reads everything else live. Tested against a live tenant on Oct 31, 2026:

| Data | Where Cowork gets it |
| --- | --- |
| Agents and tools: availability, install scope, groups, description, last used | **Packages.csv**, which you attach |
| Agent identities, sponsors, owners, permissions, sign-ins, agent users | Enterprise MCP, live |
| Blueprints: sponsors, owners, inheritable permissions, secrets, description | Enterprise MCP, live |
| Groups the agents are assigned to: owners, description | Enterprise MCP, live (group IDs come from Packages.csv) |
| Conditional Access policies for agents | Enterprise MCP, live |
| Attestation date, admin center settings (blueprint creation, inactivity policy, external publishers, sharing) | Not readable through the MCP. Manual checklist, or Cowork reads them in the browser if you turn that on |

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **A. Plugin with the Enterprise MCP** (recommended) | An admin does it once (below) | Runs the whole check live, then helps with follow-ups |
| **B. Skill only** | Each person, about 2 minutes | Explains and prioritizes the CSV files from `Get-AgentToolsHealth.ps1`, and drafts follow-ups |

## The prompt

Attach **Packages.csv** and paste this. It's also printed at the bottom of every `Report.html`.

```text
Run the agent and tools health check. Count anything unused for 90 days as stale.

Use the attached Packages.csv for agents and tools. Use the Microsoft MCP Server for Enterprise to read: every agent identity with its sponsors, owners, Microsoft Graph permissions and last sign-in; every agent identity blueprint with its sponsors, owners, inheritable permissions, credentials and description; agent user accounts; the groups listed in Packages.csv (owners and description); and the Conditional Access policies.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the agent-tools-health rules and give me:
1. A scorecard: one row per area (Agents, Tools, Agent identities, Blueprints, Tenant) with a score out of 100 and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the item, what's wrong and the fix.
3. The top 3 fixes to do first.
4. The well-governed funnel for agent identities: with an active sponsor, a clear name, least privilege, in use.
5. The Microsoft Graph calls you ran.
6. The HTML report from the skill's report template, named Agent and Tools Health.html.
```

No Packages.csv? Leave out that line. Cowork checks identities, blueprints and Conditional Access, and says agents and tools were skipped.

For **way B**, attach `Findings.csv` and `Scorecard.csv` instead and ask: *"Explain these agent and tools health results and give me the top 3 fixes."*

## What you get back

An example with made-up names:

**Scorecard**

| Area | Score | Rating | High | Medium | Low |
| --- | --- | --- | --- | --- | --- |
| Tenant | 65 | Amber | 1 | 1 | 0 |
| Agent identities | 74 | Amber | 2 | 3 | 1 |
| Agents | 81 | Green | 1 | 2 | 0 |
| Blueprints | 85 | Green | 0 | 2 | 0 |
| Tools | 93 | Green | 0 | 1 | 0 |

**Findings** (first rows)

| Area | Category | Severity | Item | Check | Fix |
| --- | --- | --- | --- | --- | --- |
| Tenant | Security | High | Conditional Access | No Conditional Access policy targets agent identities | Create agent policies, starting in report-only |
| Agents | Access | High | Contoso HR Agent | Available to all users | Make it available to specific groups |
| Agent identities | Ownership | High | Invoice Bot | No sponsor | Add a sponsor |
| Agent identities | Permissions | High | Mail Helper | High-privilege Graph permissions: Mail.Send | Replace with narrower permissions |
| Agents | Naming | Medium | Test agent 2 | Unclear name | Rename it |
| Tools | Usage | Medium | Old Jira Plugin | Not used in 90 days | Block it, or run Agent and Tools Cleanup |

You also get **Agent and Tools Health.html** in your OneDrive **Cowork** folder: one self-contained file that works offline, with a score dial, a card per area, the well-governed funnel, findings you can filter by severity, area or search, **Export CSV** and **Print** buttons, light and dark themes, and the manual checklist. Open [assets/report-template.html](plugin/skills/agent-tools-health/assets/report-template.html) in a browser to see it with sample data.

Good follow-ups:

- *"Draft a note to each sponsor listing what to fix on their agents."* Cowork drafts it and asks before sending.
- *"Which agents are stale?"* Then block or disable them with [Agent and Tools Cleanup](../../Agent%20and%20Tools%20Cleanup/README.md).
- *"Compare this with last month's Findings.csv."*
- *"Schedule this check for the first Monday of every month."* Attach a fresh Packages.csv each time.

## Get Packages.csv

Run `.\Get-AgentToolsHealth.ps1 -PackagesOnly` (a few minutes; one call per package). It needs the **AI Administrator** role and a **Microsoft Agent 365** license (included in Microsoft 365 E7).

Packages.csv has group IDs and agent names. Keep it private and out of source control.

## Way A: admin setup (once per tenant)

**Already set up the [Billing Health Check plugin](../../Billing%20Health%20Check/Cowork/readme.md) or the [Agent and Tools Cleanup plugin](../../Agent%20and%20Tools%20Cleanup/Cowork/readme.md)?** Reuse that app registration and OAuth client registration. Run step 3 with the same Application (client) ID to add the scopes below (the cmdlet adds them and keeps the old ones), then go to step 5 with the same registration ID.

You need **Application Administrator** or **Cloud Application Administrator** for steps 1 to 3, and a Microsoft 365 admin for step 5. The people who run the check need a Microsoft 365 Copilot license, Cowork access, and **Global Reader** (the MCP server acts as the signed-in person, so it can't see more than they can).

### 1. Turn on the Enterprise MCP server in your tenant

Run this once in PowerShell. It's Microsoft's own provisioning step and uses the Microsoft Entra PowerShell module (the one exception to this repo's Graph-only rule, because Microsoft only ships provisioning as a cmdlet).

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

### 2. Register an app for Cowork

In the **Microsoft Entra admin center > App registrations > New registration**:

1. Name: **Agent and Tools Health - Cowork**. Account type: **Single tenant**.
2. Redirect URI: platform **Web**, value `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`.
3. Copy the **Application (client) ID** and **Directory (tenant) ID**.
4. **Certificates & secrets > New client secret**. Copy the secret value, and note when it expires.

### 3. Give the app read-only MCP permissions

```powershell
Grant-EntraBetaMCPServerPermission -ApplicationId "<Application (client) ID>" -Scopes `
    "MCP.Application.Read.All", "MCP.AuditLog.Read.All", "MCP.User.Read.All", "MCP.Group.Read.All", `
    "MCP.GroupMember.Read.All", "MCP.DelegatedPermissionGrant.Read.All", "MCP.Policy.Read.All"
```

| Scope | Why |
| --- | --- |
| MCP.Application.Read.All | Agent identities, blueprints, principals, sponsors, owners, permissions, inheritable permissions |
| MCP.AuditLog.Read.All | Service principal sign-in activity |
| MCP.User.Read.All | Whether sponsors and owners are still active; agent user accounts |
| MCP.Group.Read.All, MCP.GroupMember.Read.All | Owners and descriptions of the groups agents are assigned to |
| MCP.DelegatedPermissionGrant.Read.All | Delegated grants to agents |
| MCP.Policy.Read.All | Conditional Access policies |

### 4. Register the OAuth client in the Teams Developer Portal

Open [Teams Developer Portal](https://dev.teams.microsoft.com/tools) > **Tools > OAuth client registration > Register client**:

| Field | Value |
| --- | --- |
| Registration name | Agent and Tools Health - Enterprise MCP |
| Base URL | `https://mcp.svc.cloud.microsoft/enterprise` |
| Restrict usage by org | Your organization |
| Restrict usage by app | **Any Teams app** (a specific app makes every tool call fail with 404) |
| Client ID and secret | From step 2 |
| Authorization endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/authorize`, with **TENANT-ID replaced by your Directory (tenant) ID** |
| Token endpoint and refresh endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/token`, with TENANT-ID replaced the same way |
| Scope | `api://e8c77dc2-69b3-43f4-bc51-3213c9d915b4/.default offline_access` |
| PKCE | On |

Save, then copy the **OAuth client registration ID**. (`e8c77dc2-...` is the Microsoft MCP Server for Enterprise app ID, the same in every tenant.)

> **AADSTS90013: Invalid input received from the user** when Cowork connects means an endpoint still has the placeholder in it. Edit the registration, put in your real tenant ID, and save. The registration ID stays the same.

### 5. Build and upload the plugin

```powershell
.\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
```

This writes **AgentToolsHealth-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.

In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose the admins who should run the check. Don't pick all users.

### 6. Test it

1. In Copilot Cowork, select **+ > Customize > Plugins** and add **Agent and Tools Health**.
2. Start a task and ask: *"How many agent identities are in my tenant, and how many have no sponsor?"* Sign in when asked.
3. If that works, attach Packages.csv and paste the prompt above.

If tool calls fail, check that the base URL, the "Any Teams app" setting and the registration ID all match. Microsoft's [plugin authentication troubleshooting](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-troubleshooting) lists the common causes.

### Optional: let Cowork read the manual checks in the browser

Some settings have no API (blueprint creation, the inactivity policy, external publishers, sharing). With browser access on, Cowork can open those admin center pages and report what they're set to; the skill tells it to read only. Turn it on in **Microsoft 365 admin center > Copilot > Settings > View all > Cowork settings > Allow browser access**, limited to the admins who run this check. The person needs Cowork in a browser, Edge 152 or later signed in with the same work account, and an admin role activated in PIM.

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **agent-tools-health.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task. The skill loads on its own when you ask about the agent and tools health check.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The plugin zip goes under **Customize > Plugins > Upload plugin** (way A). The skills box only takes the `-SkillOnly` zip.

Without the Enterprise MCP connector, Cowork works only from the files you attach.

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/agent-tools-health/SKILL.md](plugin/skills/agent-tools-health/SKILL.md) | The steps Cowork follows, with the exact Graph calls |
| [plugin/skills/agent-tools-health/references/rules.md](plugin/skills/agent-tools-health/references/rules.md) | The rules, severities, scoring and manual checks |
| [plugin/skills/agent-tools-health/assets/report-template.html](plugin/skills/agent-tools-health/assets/report-template.html) | The HTML report template. Cowork and the PowerShell script fill in its data block |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the zip with your registration ID |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The results name agents, groups and permissions, so share them only with the people who need them.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- [Best practices for Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/best-practices-agent-id)
- [Inheritable permissions in Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/concept-inheritable-permissions)
- [Conditional Access for agents](https://learn.microsoft.com/entra/identity/conditional-access/agent-id)
- [Understand agent details (availability and installation)](https://learn.microsoft.com/microsoft-agent-365/admin/agent-details)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development) and [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-local-browser)
