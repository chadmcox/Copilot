# Run the Entra ID security review in Copilot Cowork

Ask **Microsoft Copilot Cowork** to review your Microsoft Entra tenant against the CISA SCuBA Entra ID baseline, the CIS Microsoft 365 Foundations Benchmark, the Attack and Defense Playbook for Microsoft Entra, and Microsoft, NSA and Mandiant incident guidance, with no PowerShell needed after setup. Cowork reads Entra live through the **Microsoft MCP Server for Enterprise**, applies the rules in the skill, and gives you an interactive HTML report with a score per area and the attack each finding helps stop.

**Read-only.** The Enterprise MCP server can only read; it can't change your tenant.

Use GitHub Copilot in VS Code instead? The same skill works there, with a much shorter setup. See [GitHub Copilot/readme.md](../GitHub%20Copilot/readme.md).

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## Short version

1. Pick a way. **A:** an admin sets up the plugin once and Cowork runs the whole review live. **B:** skill only, about 2 minutes per person; Cowork explains findings you exported from an earlier report.
2. Set it up: [Way A](#way-a-admin-setup-once-per-tenant) (admin, once per tenant) or [Way B](#way-b-skill-only).
3. Paste [the prompt](#the-prompt) into Cowork.
4. Open the HTML report. Fix the BOD 25-01 items first; every finding names the attack it helps stop.

## What Cowork can read

Everything comes live from the Enterprise MCP. No files to attach. Tested against a live tenant on Nov 2, 2026:

| Data | Where Cowork gets it |
| --- | --- |
| Domains, security defaults, the authorization policy (user, consent and guest settings), directory settings (password rules, group creation) | Enterprise MCP, live |
| Authentication methods policy, Authenticator, FIDO2 and TAP settings, authentication strengths, admins' and members' registration, per-user MFA for admins | Enterprise MCP, live |
| Conditional Access with session controls, named locations, risky users and risky service principals (P2), legacy authentication sign-ins (P1) | Enterprise MCP, live |
| Role assignments with on-premises IDs, PIM eligibility, approval, MFA and notification settings, role-assignable groups and their owners | Enterprise MCP, live |
| App registrations, service principals, their owners, credentials and app instance lock, delegated grants, Graph and Exchange application permissions, app management policies, admin consent workflow | Enterprise MCP, live |
| Device registration policy, cross-tenant access default and partners, guests, access reviews | Enterprise MCP, live |
| Audit log for the last 30 days (federation changes, direct role assignments, new credentials, owners and permissions, sync feature changes, TAPs) | Enterprise MCP, live |
| Federation settings, Entra Connect sync features, partner (GDAP) relationships, risky agents | **Not readable**: the MCP returns 403 for these. Manual checklist |
| Process checks: privileged access workstations, offline break-glass credentials, help desk, Tier 0, SIEM, alerts, recovery plan | No API. Manual checklist, or Cowork reads the admin center in the browser if you turn that on |

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **A. Plugin with the Enterprise MCP** (recommended) | An admin does it once (below) | Runs the whole review live, then helps with follow-ups |
| **B. Skill only** | Each person, about 2 minutes | Explains the findings you exported from an earlier review (the report's **Export CSV** button), and drafts follow-ups |

## The prompt

Activate **Copilot Entra ID Operations Reader** in PIM first, then paste this:

```text
Run the Entra ID security review. Count anything unused for 90 days as inactive, and look back 30 days in the sign-in and audit logs. My emergency access accounts are <first account UPN> and <second account UPN>. Planned changes in the last 30 days: <none, or what you changed>.

Use the Microsoft MCP Server for Enterprise to read the tenant: privileged roles, PIM settings and owners, authentication methods and registration, password rules, Conditional Access, risky users and service principals, apps, service principals, credentials, consent grants and application permissions, app management and consent policies, domains and sync accounts, guests and cross-tenant settings, device registration settings, and the audit log.

This is read-only. Don't change anything in the tenant, and don't send any email or Teams message. Don't list people's names or email addresses; counts are enough.

Apply the entra-id-security-review rules and give me:
1. A scorecard: one row per area with a score out of 100 and Green 80+, Amber 50-79, Red under 50, and how many CISA BOD 25-01 policies the tenant meets.
2. A findings table sorted High, Medium, Low, with the item, what's wrong, the attack it helps stop, the fix and the sources (CISA, CIS, Playbook chapter or article).
3. The top 3 fixes to do first.
4. The phishing-resistant admins funnel: cloud-only, just in time, phishing-resistant method registered, phishing-resistant MFA required.
5. The manual checks.
6. The Microsoft Graph calls you ran, and the checks you skipped and why.
7. The HTML report from the skill's report template, named Entra ID Security Review.html.
```

Leave out the emergency access sentence if you don't want to name them; Cowork then guesses from permanent cloud-only Global Administrators and says so. Telling it about planned changes keeps them out of the Recent changes findings. The prompt is also kept in the report, so you can run it again next month.

For **way B**, attach the findings CSV from an earlier report's **Export CSV** button and ask: *"Explain these Entra ID security review results and give me the top 3 fixes."*

## What you get back

An example with made-up names:

**Scorecard** (CISA BOD 25-01: 15 of 22 met)

| Area | Score | Rating | High | Medium | Low |
| --- | --- | --- | --- | --- | --- |
| Privileged access | 50 | Amber | 2 | 0 | 0 |
| Applications and consent | 58 | Amber | 3 | 0 | 0 |
| Conditional Access and risk | 65 | Amber | 1 | 1 | 0 |
| Authentication | 75 | Amber | 1 | 0 | 0 |
| Hybrid and federation | 75 | Amber | 1 | 0 | 0 |

**Findings** (first rows)

| Area | Attack | Severity | Item | Check | Fix |
| --- | --- | --- | --- | --- | --- |
| Applications and consent | Consent phishing | High | User consent | Users can consent to any app | Allow only verified publishers and low-impact permissions [CISA MS.AAD.5.2v1 · CIS 5.1.5.1 · Playbook: Consent grant] |
| Applications and consent | Privilege escalation | High | Contoso Reporting | Has the Graph permission RoleManagement.ReadWrite.Directory | Replace it with a narrower permission [IR recovery · Solorigate IOCs] |
| Applications and consent | App credential abuse | High | Fabrikam Sync | The service principal has its own client secret | Find out who added it; remove it if unknown [Solorigate IOCs · NSA] |
| Privileged access | Lateral movement from on-premises | High | 3 admins | Highly privileged role on a synced account | Use cloud-only admin accounts [CISA MS.AAD.7.3v1 · CIS 1.1.1] |
| Authentication | MFA fatigue and phone fraud | High | SMS | SMS is enabled | Turn off SMS and voice [CISA MS.AAD.3.5v2 · CIS 5.2.3.5 · DEV-0537] |
| Hybrid and federation | Federation trust abuse | High | contoso.com | The domain is federated | Move to cloud authentication [Protect M365 from on-premises · NSA] |

You also get **Entra ID Security Review.html** in your OneDrive **Cowork** folder: one self-contained file that works offline, with a score dial, the BOD 25-01 count, a card per area, the phishing-resistant admins funnel, findings you can filter by severity, area or search (try an attack name, "MS.AAD.7" or "5.2.2"), **Export CSV** and **Print** buttons, light and dark themes, and the manual checklist. Open [assets/report-template.html](plugin/skills/entra-id-security-review/assets/report-template.html) in a browser to see it with sample data.

Good follow-ups:

- *"Which attacks am I most exposed to?"*
- *"Show only what CISA BOD 25-01 requires."*
- *"What would an attacker do first in this tenant, and what breaks that path?"*
- *"Draft a note to the owners of the apps with high-privilege permissions."* Cowork drafts it and asks before sending.
- *"Compare this with last month's findings CSV."*
- *"Schedule this review for the first Monday of every month."*

## Way A: admin setup (once per tenant)

**Already set up another plugin from this repo**, such as the [Entra ID Operations Report](../../Entra%20ID%20Operations%20Report/Cowork/readme.md)? Reuse that app registration and OAuth client registration. Run step 3 with the same Application (client) ID to add the scopes below (the cmdlet adds them and keeps the old ones), then go to step 5 with the same registration ID.

You need **Application Administrator** or **Cloud Application Administrator** for steps 1 to 3, and a Microsoft 365 admin for step 5. The people who run the review go in **Copilot Entra ID Operations Reader**: a role-assignable group under PIM that holds **Global Reader**. They also need a Microsoft 365 Copilot license and Cowork access. The MCP server acts as the signed-in person, so it can't see more than their activated roles allow. See [Who runs it](../README.md#who-runs-it-copilot-entra-id-operations-reader).

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

1. Name: **Entra ID Security Review - Cowork**. Account type: **Single tenant**.
2. Redirect URI: platform **Web**, value `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`.
3. Copy the **Application (client) ID** and **Directory (tenant) ID**.
4. **Certificates & secrets > New client secret**. Copy the secret value, and note when it expires.

(Yes, the review flags app secrets. The Teams Developer Portal OAuth registration in step 4 needs one. Keep it short-lived, put a reminder on its expiry, and give the app no owners. The review will list it; that's expected.)

### 3. Give the app read-only MCP permissions

```powershell
Grant-EntraBetaMCPServerPermission -ApplicationId "<Application (client) ID>" -Scopes `
    "MCP.Organization.Read.All", "MCP.User.Read.All", "MCP.Group.Read.All", "MCP.Domain.Read.All", `
    "MCP.Application.Read.All", "MCP.DelegatedPermissionGrant.Read.All", "MCP.Policy.Read.All", `
    "MCP.Policy.Read.ConditionalAccess", "MCP.AuditLog.Read.All", "MCP.Reports.Read.All", `
    "MCP.UserAuthenticationMethod.Read.All", "MCP.IdentityRiskyUser.Read.All", `
    "MCP.IdentityRiskyServicePrincipal.Read.All", "MCP.RoleManagement.Read.Directory", `
    "MCP.RoleAssignmentSchedule.Read.Directory", "MCP.RoleEligibilitySchedule.Read.Directory", `
    "MCP.AccessReview.Read.All", "MCP.LicenseAssignment.Read.All"
```

| Scope | Why |
| --- | --- |
| MCP.Organization.Read.All | Sync status, licenses (subscribed SKUs) |
| MCP.User.Read.All, MCP.LicenseAssignment.Read.All | Admins' accounts and licenses, guests, on-premises IDs |
| MCP.Group.Read.All | Role-assignable groups and their owners, dynamic group rules |
| MCP.Domain.Read.All | Federated domains, password expiry |
| MCP.Application.Read.All | App registrations and service principals, owners, credentials, app instance lock, Graph and Exchange application permissions |
| MCP.DelegatedPermissionGrant.Read.All | Delegated consent grants |
| MCP.Policy.Read.All, MCP.Policy.Read.ConditionalAccess | Security defaults, authorization, consent, app management, authentication methods and strengths, device registration, cross-tenant access and PIM policies, directory settings, Conditional Access, named locations |
| MCP.AuditLog.Read.All, MCP.Reports.Read.All | Sign-in and audit logs, registration details, guests' last sign-in |
| MCP.UserAuthenticationMethod.Read.All | Per-user MFA state for admins |
| MCP.IdentityRiskyUser.Read.All, MCP.IdentityRiskyServicePrincipal.Read.All | Users and service principals at risk |
| MCP.RoleManagement.Read.Directory, MCP.RoleAssignmentSchedule.Read.Directory, MCP.RoleEligibilitySchedule.Read.Directory | Privileged roles, permanent and eligible assignments |
| MCP.AccessReview.Read.All | Access reviews for guests and roles |

### 4. Register the OAuth client in the Teams Developer Portal

Open [Teams Developer Portal](https://dev.teams.microsoft.com/tools) > **Tools > OAuth client registration > Register client**:

| Field | Value |
| --- | --- |
| Registration name | Entra ID Security Review - Enterprise MCP |
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

This writes **EntraIdSecurityReview-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.

In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose **Copilot Entra ID Operations Reader** from the [Access Governance Guide](../../Access%20Governance%20Guide/readme.md#copilot-entra-id-operations-reader). Don't pick all users.

### 6. Test it

1. Activate **Copilot Entra ID Operations Reader** in PIM.
2. In Copilot Cowork, select **+ > Customize > Plugins** and add **Entra ID Security Review**.
3. Start a task and ask: *"Is SMS turned on as an authentication method in my tenant?"* Sign in when asked.
4. If that works, paste the prompt above.

If tool calls fail, check that the base URL, the "Any Teams app" setting and the registration ID all match. Microsoft's [plugin authentication troubleshooting](https://learn.microsoft.com/microsoft-365/copilot/extensibility/plugin-authentication-troubleshooting) lists the common causes.

### Optional: let Cowork read the manual checks in the browser

Several checks have no API through the MCP (federation settings, Entra Connect sync features, legacy MFA settings, SSPR, Restrict access to Microsoft Entra admin center, partner relationships). With browser access on, Cowork can open those admin center pages and report what they're set to; the skill tells it to read only. Turn it on in **Microsoft 365 admin center > Copilot > Settings > View all > Cowork settings > Allow browser access**, limited to the admins who run this review. The person needs Cowork in a browser, Edge 152 or later signed in with the same work account, and the group activated in PIM.

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **entra-id-security-review.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task. The skill loads on its own when you ask about the Entra ID security review.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The plugin zip goes under **Customize > Plugins > Upload plugin** (way A). The skills box only takes the `-SkillOnly` zip.

Without the Enterprise MCP connector, Cowork works only from the files you attach.

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/entra-id-security-review/SKILL.md](plugin/skills/entra-id-security-review/SKILL.md) | The steps Cowork follows, with the exact Graph calls |
| [plugin/skills/entra-id-security-review/references/rules.md](plugin/skills/entra-id-security-review/references/rules.md) | The rules, severities, scoring and manual checks, each tied to its attack and sources |
| [plugin/skills/entra-id-security-review/references/guidance.md](plugin/skills/entra-id-security-review/references/guidance.md) | Every source with its link, and the CISA and CIS coverage tables |
| [plugin/skills/entra-id-security-review/assets/report-template.html](plugin/skills/entra-id-security-review/assets/report-template.html) | The HTML report template. Cowork fills in its data block |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the zip with your registration ID |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The report describes your tenant's weak spots, so share it only with the people who need it.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- The baselines, Playbook chapters and articles behind the checks: [guidance.md](plugin/skills/entra-id-security-review/references/guidance.md)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development) and [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started) (the list of MCP scopes)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-local-browser)
