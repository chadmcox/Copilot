# Run the health check in Copilot Cowork

Run the Copilot billing health check by asking **Microsoft Copilot Cowork**, with no PowerShell needed after setup. Cowork reads your groups, members, licenses and sign-ins live through the **Microsoft MCP Server for Enterprise**, applies the same rules as `Get-CopilotBillingHealth.ps1`, and gives you an interactive HTML report.

**Read-only.** The Enterprise MCP server can only read; it can't change your tenant.

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## What you need to know first

The Enterprise MCP server **can't read spending policies**: it has no Copilot cost management permission, so a request to `/copilot/costManagement/spendingPolicies` returns 403. So you give Cowork the policy list as a file, **Policies.csv**, and Cowork reads everything else live.

| Data | Where Cowork gets it |
| --- | --- |
| Spending policies: limits, services, groups, alerts | **Policies.csv**, which you attach |
| Groups, owners, nested groups, members | Enterprise MCP, live |
| Account state, guest, last sign-in, Copilot license | Enterprise MCP, live |
| Each person's credits used and left | Not available through the MCP. Run the script without `-SkipBalances` |

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **A. Plugin with the Enterprise MCP** (recommended) | An admin does it once (below) | Runs the whole check live, then helps with follow-ups |
| **B. Skill only** | Each person, about 2 minutes | Explains and prioritizes the CSV files from `Get-CopilotBillingHealth.ps1`, and drafts follow-ups |

## The prompt

Attach **Policies.csv** and paste this. It's also printed at the bottom of every `Report.html`.

```text
Run the Copilot billing health check.

Use the attached Policies.csv for the spending policies. Use the Microsoft MCP Server for Enterprise to read, for every group in that file: the group type, owners, description, nested groups, and every member (including members of nested groups). For each member, read whether the account is enabled, the user type, the last successful sign-in, and their licenses. Use subscribedSkus to find which licenses include the Copilot service plan 3f30311c-6b1e-48a4-ab79-725b469da960.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message.

Apply the copilot-billing-health rules and give me:
1. A scorecard: one row per policy with a score out of 100 (High -25, Medium -10, Low -3) and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the person or group, what's wrong, and the fix.
3. The top 3 fixes to do first.
4. The Cowork readiness funnel: Copilot license assigned, Copilot turned on, active in Copilot in the last 28 days, covered by a Cowork policy, billing set, and the % of active Copilot users who are ready.
5. The Microsoft Graph calls you ran.
6. The HTML report from the skill's report template, named Copilot Billing Health.html.
```

For **way B**, attach `Findings.csv` and `Scorecard.csv` instead and ask: *"Explain these Copilot billing health results and give me the top 3 fixes."*

## What you get back

An example with made-up names:

**Scorecard**

| Policy | Score | Rating | High | Medium | Low |
| --- | --- | --- | --- | --- | --- |
| Cowork Unlimited | 55 | Amber | 1 | 2 | 0 |
| Cowork Limited | 77 | Amber | 0 | 2 | 1 |
| Cowork Temporary Unlimited | 100 | Green | 0 | 0 | 0 |

**Findings** (first rows)

| Policy | Severity | Target | Check | Fix |
| --- | --- | --- | --- | --- |
| Cowork Unlimited | High | user1@contoso.com | In both Cowork Limited and Cowork Unlimited | Remove one; the higher limit always wins |
| Cowork Unlimited | Medium | Copilot + Cowork Spend Unlimited | Has 1 owner | Add a second owner |
| Cowork Limited | Medium | user2@contoso.com | No Copilot license, but cowork needs one | License them, or remove them |
| Cowork Limited | Medium | user3@contoso.com | No sign-in for 90 days | Remove them from the group |

**Fix these first**

1. Take user1 out of Cowork Limited.
2. Add a second owner to *Copilot + Cowork Spend Unlimited*.
3. Remove user3, who hasn't signed in for 90 days.

You also get **Copilot Billing Health.html** in your OneDrive **Cowork** folder. It's one self-contained file that works offline:

- An average score dial, severity counts, a card for each policy with its own score, and the Cowork readiness funnel with the % of active Copilot users who are ready.
- Findings you can filter by severity, by policy (select a card) or by searching.
- **Export CSV** and **Print** buttons, light and dark themes, and a checklist for the checks no API covers.
- The Graph calls Cowork ran.

The template is [assets/report-template.html](plugin/skills/copilot-billing-health/assets/report-template.html). Open it in a browser to see it with sample data. `Get-CopilotBillingHealth.ps1` fills the same template, so both ways give the same report. Ask Cowork for a spreadsheet if you want one as well.

Good follow-ups:

- *"Draft a note to each group owner listing the people to remove."* Cowork drafts it and asks before sending.
- *"Compare this with last month's Findings.csv."*
- *"Schedule this check for the first Monday of every month."* Cowork can run prompts on a schedule; attach a fresh Policies.csv when your policies change.

## Get Policies.csv

Pick one:

- **Run the script** (quickest, about 1 minute): `.\Get-CopilotBillingHealth.ps1 -PoliciesOnly`. It writes only Policies.csv. Run it as a member of **Copilot Health Check Users** with the group activated. If the policy calls return 403, AI Reader isn't enough in your tenant: Microsoft documents Global Reader and Billing Administrator for these reads.
- **Type it by hand**: copy [Policies-template.csv](Policies-template.csv) and fill it from **Microsoft 365 admin center > Copilot > Cost management > Configuration**. You can leave **GroupIds** blank; Cowork then finds each group by its exact name.

Policies.csv has group IDs and alert recipients. Keep it private and out of source control.

## Way A: admin setup (once per tenant)

You need **Application Administrator** or **Cloud Application Administrator** for steps 1 to 3, and a Microsoft 365 admin for step 5. The people who run the check go in **Copilot Health Check Users**: a role-assignable group under PIM that holds **AI Reader** and **Reports Reader** (plus Security Reader for the Agent and Tools Health Check). They also need a Microsoft 365 Copilot license and Cowork access. The MCP server acts as the signed-in person, so it can't see more than their activated roles allow. See [Who runs it](../README.md#who-runs-it-copilot-health-check-users).

### 1. Turn on the Enterprise MCP server in your tenant

Run this once in PowerShell. It's Microsoft's own provisioning step and uses the Microsoft Entra PowerShell module.

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

### 2. Register an app for Cowork

In the **Microsoft Entra admin center > App registrations > New registration**:

1. Name: **Copilot Billing Health - Cowork**. Account type: **Single tenant**.
2. Redirect URI: platform **Web**, value `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`.
3. Copy the **Application (client) ID** and **Directory (tenant) ID**.
4. **Certificates & secrets > New client secret**. Copy the secret value.

### 3. Give the app read-only MCP permissions

```powershell
Grant-EntraBetaMCPServerPermission -ApplicationId "<Application (client) ID>" -Scopes `
    "MCP.Group.Read.All", "MCP.GroupMember.Read.All", "MCP.User.Read.All", "MCP.AuditLog.Read.All", `
    "MCP.Organization.Read.All", "MCP.LicenseAssignment.Read.All", "MCP.AccessReview.Read.All", "MCP.Reports.Read.All"
```

### 4. Register the OAuth client in the Teams Developer Portal

Open [Teams Developer Portal](https://dev.teams.microsoft.com/tools) > **Tools > OAuth client registration > Register client**:

| Field | Value |
| --- | --- |
| Registration name | Copilot Billing Health - Enterprise MCP |
| Base URL | `https://mcp.svc.cloud.microsoft/enterprise` |
| Restrict usage by org | Your organization |
| Restrict usage by app | **Any Teams app** (a specific app makes every tool call fail with 404) |
| Client ID and secret | From step 2 |
| Authorization endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/authorize`, with **TENANT-ID replaced by your Directory (tenant) ID** from step 2 |
| Token endpoint and refresh endpoint | `https://login.microsoftonline.com/TENANT-ID/oauth2/v2.0/token`, with TENANT-ID replaced the same way |
| Scope | `api://e8c77dc2-69b3-43f4-bc51-3213c9d915b4/.default offline_access` |
| PKCE | On |

Save, then copy the **OAuth client registration ID**.

> **AADSTS90013: Invalid input received from the user** when Cowork connects means an endpoint still has the placeholder in it (the sign-in address shows `<tenant ID>` or `TENANT-ID`). Edit the registration, put in your real tenant ID, and save. The registration ID stays the same, so you don't need to rebuild the plugin.

### 5. Build and upload the plugin

```powershell
.\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
```

This writes **CopilotBillingHealth-Cowork.zip**. You can download just the script: if the `plugin` folder isn't next to it, the script downloads the plugin files from this repo on GitHub.

In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose **Copilot Health Check Users** from the [Group Assignment Guide](../../Group%20Assignment%20Guide/readme.md#copilot-health-check-users). Don't pick all users.

### 6. Test it

1. In Copilot Cowork, select **+ > Customize > Plugins** and add **Copilot Billing Health**.
2. Start a task and ask: *"How many members are in the group Copilot + Cowork Spend Limit?"* Sign in when asked.
3. If that works, attach Policies.csv and paste the prompt above.

If tool calls fail, check that the base URL, the "Any Teams app" setting and the registration ID all match. Microsoft's [plugin authentication troubleshooting](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-troubleshooting) lists the common causes.

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **copilot-billing-health.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task. The skill loads on its own when you ask about the billing health check.

Or copy the files by hand: create `Documents/Cowork/skills/copilot-billing-health/` in your OneDrive, put [SKILL.md](plugin/skills/copilot-billing-health/SKILL.md) in it, and put `rules.md` in a `references` subfolder.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The plugin zip goes under **Customize > Plugins > Upload plugin** (way A). The skills box only takes the `-SkillOnly` zip.

Without the Enterprise MCP connector, Cowork works only from the files you attach.

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/copilot-billing-health/SKILL.md](plugin/skills/copilot-billing-health/SKILL.md) | The steps Cowork follows, with the exact Graph calls |
| [plugin/skills/copilot-billing-health/references/rules.md](plugin/skills/copilot-billing-health/references/rules.md) | The rules and severities |
| [plugin/skills/copilot-billing-health/assets/report-template.html](plugin/skills/copilot-billing-health/assets/report-template.html) | The HTML report template. Cowork and the PowerShell script fill in its data block |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the zip with your registration ID |
| [Policies-template.csv](Policies-template.csv) | Template for typing policies in by hand |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The results name people and show who should lose access, so share them only with the people who need them.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- [Use Copilot Cowork: attach files, custom skills, scheduled prompts](https://learn.microsoft.com/copilot/cowork/use-cowork)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development)
- [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Manage plugins, skills, and MCP servers (Tools registry)](https://learn.microsoft.com/microsoft-agent-365/admin/manage-plugins-skills-mcp-servers)
- [Configure OAuth 2.0 authentication for MCP plugins](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-oauth)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
- [Overview of the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/overview)
