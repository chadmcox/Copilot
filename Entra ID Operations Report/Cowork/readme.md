# Run the Entra ID operations report in Copilot Cowork

Ask **Microsoft Copilot Cowork** to check your Microsoft Entra tenant against Microsoft's [Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro), with no PowerShell needed after setup. Cowork reads Entra live through the **Microsoft MCP Server for Enterprise**, applies the rules in the skill, and gives you an interactive HTML report with a score per area.

**Read-only.** The Enterprise MCP server can only read; it can't change your tenant.

Use GitHub Copilot in VS Code instead? The same skill works there, with a much shorter setup. See [GitHub Copilot/readme.md](../GitHub%20Copilot/readme.md).

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## What Cowork can read

Everything comes live from the Enterprise MCP. No files to attach. Tested against a live tenant on Nov 1, 2026:

| Data | Where Cowork gets it |
| --- | --- |
| Sync status, sync errors, license errors, direct license assignments, dynamic groups | Enterprise MCP, live |
| Security defaults, authentication methods policy, admins' MFA and passwordless registration, per-user MFA for admins, password protection, domains | Enterprise MCP, live |
| App registration and service principal secrets, delegated grants, Microsoft Graph application permissions, user consent, admin consent workflow, user settings | Enterprise MCP, live |
| Conditional Access policies and named locations, risky users (P2), legacy authentication sign-ins (P1) | Enterprise MCP, live |
| Role assignments, PIM eligibility and activation settings, access reviews, guests, access packages | Enterprise MCP, live |
| Microsoft Entra recommendations (the Identity Secure Score list) and Entra Health alerts | Enterprise MCP, live |
| Password hash sync (from the last password sync time on the organization) | Enterprise MCP, live |
| Entra Connect feature settings, Microsoft Secure Score, pass-through authentication agents, private network connectors | **Not readable**: the MCP has no scope for these and returns 403 (Entra Connect settings also need Global Administrator). Manual checklist, or recommendations cover them |
| Process checks: task owners, SIEM, staging server, Entra Connect version, AD FS, Tier 0 | No API. Manual checklist, or Cowork reads the admin center in the browser if you turn that on |

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **A. Plugin with the Enterprise MCP** (recommended) | An admin does it once (below) | Runs the whole report live, then helps with follow-ups |
| **B. Skill only** | Each person, about 2 minutes | Explains the findings you exported from an earlier report (the report's **Export CSV** button), and drafts follow-ups |

## The prompt

Activate **Copilot Entra ID Operations Reader** in PIM first, then paste this:

```text
Run the Entra ID operations report. Count anything unused for 90 days as inactive, and look back 30 days in the sign-in logs. My emergency access accounts are <first account UPN> and <second account UPN>.

Use the Microsoft MCP Server for Enterprise to read the tenant: sync and licensing, authentication methods and registration, password protection, app credentials and consent grants, user settings, Conditional Access and named locations, legacy authentication sign-ins, risky users, privileged roles and PIM settings, access reviews, guests, access packages, Entra recommendations and health alerts.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message. Don't list people's names or email addresses; counts are enough.

Apply the entra-id-operations rules and give me:
1. A scorecard: one row per area (Identity and access, Authentication, Governance, Operations) with a score out of 100 and Green 80+, Amber 50-79, Red under 50.
2. A findings table sorted High, Medium, Low, with the item, what's wrong, the fix and the section of the operations guide.
3. The top 3 fixes to do first.
4. The well-protected admins funnel: MFA registered, cloud-only, just in time, passwordless capable.
5. The manual checks, including who owns each key task.
6. The Microsoft Graph calls you ran, and the checks you skipped and why.
7. The HTML report from the skill's report template, named Entra ID Operations Report.html.
```

Leave out the emergency access sentence if you don't want to name them; Cowork then guesses from permanent cloud-only Global Administrators and says so. The prompt is also kept in the report, so you can run it again next month.

For **way B**, attach the findings CSV from an earlier report's **Export CSV** button and ask: *"Explain these Entra ID operations results and give me the top 3 fixes."*

## What you get back

An example with made-up names:

**Scorecard**

| Area | Score | Rating | High | Medium | Low |
| --- | --- | --- | --- | --- | --- |
| Authentication | 62 | Amber | 2 | 2 | 0 |
| Governance | 68 | Amber | 2 | 1 | 0 |
| Operations | 78 | Amber | 0 | 1 | 1 |
| Identity and access | 90 | Green | 0 | 1 | 0 |

**Findings** (first rows)

| Area | Topic | Severity | Item | Check | Fix |
| --- | --- | --- | --- | --- | --- |
| Authentication | Legacy authentication | High | Conditional Access | No enabled policy blocks legacy authentication | Block it with Conditional Access, starting in report-only |
| Authentication | Strong credentials | High | 2 admins | Not registered for MFA | Register them now |
| Governance | Privileged account usage | High | Global Administrator | 4 users hold it permanently | Make them eligible in PIM |
| Governance | Emergency access accounts | High | Global Administrator | Only one cloud-only account holds it permanently | Create two cloud-only emergency access accounts |
| Authentication | Consent grants | Medium | Admin consent workflow | Turned off | Turn it on |
| Authentication | Programmatic credentials | Medium | Contoso Payroll Sync | Uses a client secret | Use a certificate or managed identity |

You also get **Entra ID Operations Report.html** in your OneDrive **Cowork** folder: one self-contained file that works offline, with a score dial, a card per area, the well-protected admins funnel, findings you can filter by severity, area or search, **Export CSV** and **Print** buttons, light and dark themes, and the manual checklist. Open [assets/report-template.html](plugin/skills/entra-id-operations/assets/report-template.html) in a browser to see it with sample data.

Good follow-ups:

- *"Draft a note to the owners of the apps with client secrets."* Cowork drafts it and asks before sending.
- *"Which Conditional Access gaps should I close first?"*
- *"Turn the key tasks into a table with an Owner column."*
- *"Compare this with last month's findings CSV."*
- *"Schedule this report for the first Monday of every month."*

## Way A: admin setup (once per tenant)

**Already set up another plugin from this repo**, such as the [Agent and Tools Health Check](../../Agent%20and%20Tools%20Health%20Check/Cowork/readme.md)? Reuse that app registration and OAuth client registration. Run step 3 with the same Application (client) ID to add the scopes below (the cmdlet adds them and keeps the old ones), then go to step 5 with the same registration ID.

You need **Application Administrator** or **Cloud Application Administrator** for steps 1 to 3, and a Microsoft 365 admin for step 5. The people who run the report go in **Copilot Entra ID Operations Reader**: a role-assignable group under PIM that holds **Global Reader**. They also need a Microsoft 365 Copilot license and Cowork access. The MCP server acts as the signed-in person, so it can't see more than their activated roles allow. See [Who runs it](../README.md#who-runs-it-copilot-entra-id-operations-reader).

### 1. Turn on the Enterprise MCP server in your tenant

Run this once in PowerShell. It's Microsoft's own provisioning step and uses the Microsoft Entra PowerShell module (the one exception to this repo's Graph-only rule, because Microsoft only ships provisioning as a cmdlet).

```powershell
Install-Module Microsoft.Entra.Beta -Force -AllowClobber
Connect-Entra -Scopes 'Application.ReadWrite.All', 'Directory.Read.All', 'DelegatedPermissionGrant.ReadWrite.All'
Grant-EntraBetaMCPServerPermission -ApplicationName VisualStudioCode
```

This is the step in Microsoft's [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started). Without `-Scopes` it also grants **every** MCP scope to Visual Studio Code. If nobody uses VS Code with the MCP server, you can remove that grant later with `Revoke-EntraBetaMCPServerPermission`.

### 2. Register an app for Cowork

In the **Microsoft Entra admin center > App registrations > New registration**:

1. Name: **Entra ID Operations - Cowork**. Account type: **Single tenant**.
2. Redirect URI: platform **Web**, value `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`.
3. Copy the **Application (client) ID** and **Directory (tenant) ID**.
4. **Certificates & secrets > New client secret**. Copy the secret value, and note when it expires.

(Yes, the report flags app secrets. The Teams Developer Portal OAuth registration in step 4 needs one. Keep it short-lived and put a reminder on its expiry.)

### 3. Give the app read-only MCP permissions

```powershell
Grant-EntraBetaMCPServerPermission -ApplicationId "<Application (client) ID>" -Scopes `
    "MCP.Organization.Read.All", "MCP.User.Read.All", "MCP.Group.Read.All", "MCP.Domain.Read.All", `
    "MCP.Application.Read.All", "MCP.DelegatedPermissionGrant.Read.All", "MCP.Policy.Read.All", `
    "MCP.Policy.Read.ConditionalAccess", "MCP.GroupSettings.Read.All", "MCP.AuditLog.Read.All", `
    "MCP.Reports.Read.All", "MCP.UserAuthenticationMethod.Read.All", "MCP.IdentityRiskyUser.Read.All", `
    "MCP.RoleManagement.Read.Directory", "MCP.RoleAssignmentSchedule.Read.Directory", `
    "MCP.RoleEligibilitySchedule.Read.Directory", "MCP.AccessReview.Read.All", `
    "MCP.EntitlementManagement.Read.All", "MCP.DirectoryRecommendations.Read.All", `
    "MCP.HealthMonitoringAlert.Read.All", "MCP.LicenseAssignment.Read.All"
```

| Scope | Why |
| --- | --- |
| MCP.Organization.Read.All | Sync status, notification addresses, licenses (subscribed SKUs) |
| MCP.User.Read.All, MCP.LicenseAssignment.Read.All | Sync errors, direct license assignments, guests, privileged users' accounts |
| MCP.Group.Read.All | License errors, dynamic group rules |
| MCP.Domain.Read.All | Federated domains, password expiry |
| MCP.Application.Read.All | App registration and service principal credentials, Graph application permissions |
| MCP.DelegatedPermissionGrant.Read.All | Delegated consent grants |
| MCP.Policy.Read.All, MCP.Policy.Read.ConditionalAccess | Security defaults, authentication methods, authorization and consent policies, PIM policies, Conditional Access, named locations |
| MCP.GroupSettings.Read.All | Password protection and group creation settings |
| MCP.AuditLog.Read.All, MCP.Reports.Read.All | Sign-in logs, admins' registration details, guests' last sign-in |
| MCP.UserAuthenticationMethod.Read.All | Per-user MFA state for admins |
| MCP.IdentityRiskyUser.Read.All | Users at high risk |
| MCP.RoleManagement.Read.Directory, MCP.RoleAssignmentSchedule.Read.Directory, MCP.RoleEligibilitySchedule.Read.Directory | Privileged roles, permanent and eligible assignments |
| MCP.AccessReview.Read.All, MCP.EntitlementManagement.Read.All | Access reviews and access packages |
| MCP.DirectoryRecommendations.Read.All, MCP.HealthMonitoringAlert.Read.All | Entra recommendations and health alerts |

### 4. Register the OAuth client in the Teams Developer Portal

Open [Teams Developer Portal](https://dev.teams.microsoft.com/tools) > **Tools > OAuth client registration > Register client**:

| Field | Value |
| --- | --- |
| Registration name | Entra ID Operations - Enterprise MCP |
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

This writes **EntraIdOperations-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.

In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose **Copilot Entra ID Operations Reader** from the [Group Assignment Guide](../../Group%20Assignment%20Guide/readme.md#copilot-entra-id-operations-reader). Don't pick all users.

### 6. Test it

1. Activate **Copilot Entra ID Operations Reader** in PIM.
2. In Copilot Cowork, select **+ > Customize > Plugins** and add **Entra ID Operations**.
3. Start a task and ask: *"How many Global Administrators are in my tenant, and how many are permanent?"* Sign in when asked.
4. If that works, paste the prompt above.

If tool calls fail, check that the base URL, the "Any Teams app" setting and the registration ID all match. Microsoft's [plugin authentication troubleshooting](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-troubleshooting) lists the common causes.

### Optional: let Cowork read the manual checks in the browser

Many of the guide's checks have no API (SSPR, Entra Connect version, diagnostic settings, Restrict access to Microsoft Entra admin center). With browser access on, Cowork can open those admin center pages and report what they're set to; the skill tells it to read only. Turn it on in **Microsoft 365 admin center > Copilot > Settings > View all > Cowork settings > Allow browser access**, limited to the admins who run this report. The person needs Cowork in a browser, Edge 152 or later signed in with the same work account, and the group activated in PIM.

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **entra-id-operations.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task. The skill loads on its own when you ask about the Entra ID operations report.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The plugin zip goes under **Customize > Plugins > Upload plugin** (way A). The skills box only takes the `-SkillOnly` zip.

Without the Enterprise MCP connector, Cowork works only from the files you attach.

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/entra-id-operations/SKILL.md](plugin/skills/entra-id-operations/SKILL.md) | The steps Cowork follows, with the exact Graph calls |
| [plugin/skills/entra-id-operations/references/rules.md](plugin/skills/entra-id-operations/references/rules.md) | The rules, severities, scoring and manual checks, each tied to a section of Microsoft's guide |
| [plugin/skills/entra-id-operations/assets/report-template.html](plugin/skills/entra-id-operations/assets/report-template.html) | The HTML report template. Cowork fills in its data block |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the zip with your registration ID |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The report describes your tenant's weak spots, so share it only with the people who need it.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- [Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development) and [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started) (the list of MCP scopes)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-local-browser)
