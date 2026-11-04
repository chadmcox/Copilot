# Entra ID Operations Report

Updated Nov 1, 2026

A read-only check of your Microsoft Entra tenant against Microsoft's [Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro), with a score per area and a fix for every finding. A skill reads the tenant live through the **Microsoft MCP Server for Enterprise**, so there's no script to run: ask **Copilot Cowork** or **GitHub Copilot** in VS Code.

## Run it

| Way | How |
| --- | --- |
| **Copilot Cowork** (recommended) | Set up the plugin once, activate the reader group in PIM, paste the prompt. See **[Cowork/readme.md](Cowork/readme.md)** |
| **GitHub Copilot** (VS Code) | Install the skill with one script, add the Enterprise MCP server, then ask. See **[GitHub Copilot/readme.md](GitHub%20Copilot/readme.md)** |

Both use the same skill and give the same HTML report from the same template: a score dial, a card per area, the well-protected admins funnel, filterable findings, CSV export, print, and the manual checklist.

The Enterprise MCP server is [global cloud only](https://learn.microsoft.com/graph/mcp-server/overview), so this report doesn't run in GCC High or DoD.

## What it checks

Microsoft's guide has four sections. The report has one area for each, and every finding names the guide section it comes from. The full rule list is in [rules.md](Cowork/plugin/skills/entra-id-operations/references/rules.md).

| Area | Checks |
| --- | --- |
| **Identity and access** ([guide](https://learn.microsoft.com/entra/architecture/ops-guide-iam)) | Sync has stopped or runs slower than the 30-minute delta cycle. Sync errors older than 100 days. Groups with license errors, licenses assigned directly instead of through groups. "All users" dynamic groups that include guests |
| **Authentication** ([guide](https://learn.microsoft.com/entra/architecture/ops-guide-auth)) | No MFA for everyone, admins without MFA (High), per-user MFA. Passwordless methods, phone methods, legacy MFA and SSPR policy migration. Password protection, password expiry, federated domains. App secrets and expiring credentials. Named locations, risk policies and high-risk users (P2), device and app protection grants. Legacy authentication: no block policy (High) and recent legacy sign-ins. Conditional Access hygiene: All apps plus block with no exclusions, policies assigned to people instead of groups. Consent: user consent, admin consent workflow, risky delegated grants and Graph application permissions. User settings: app registration, group creation, guest invitations |
| **Governance** ([guide](https://learn.microsoft.com/entra/architecture/ops-guide-govern)) | Fewer than two emergency access accounts (High). Five or more Global Administrators. Permanent privileged role assignments instead of PIM, synced or mailbox-enabled admin accounts, apps holding privileged roles. PIM activation without MFA or approval. Access reviews for apps, privileged roles, guests and Conditional Access exclusion groups. Inactive guests. Entitlement management |
| **Operations** ([guide](https://learn.microsoft.com/entra/architecture/ops-guide-ops)) | Active Microsoft Entra recommendations (the Identity Secure Score list), active Entra Health alerts, fewer than two technical notification contacts |

**Scores:** each check is an item. A passing check scores 100; a failing one loses 25 for each High, 10 for each Medium and 3 for each Low finding. An area's score is the average of its checks. Green 80+, Amber 50–79, Red under 50. Checks that need a license the tenant doesn't have (Entra ID P1, P2 or ID Governance) are skipped and listed in the notes.

**Severities, scores and thresholds are this repo's choices.** Microsoft's guide says what to do but doesn't rank it. Where the guide gives a number (100 days, six months, 30 minutes, two emergency accounts), the rule uses it.

**People aren't named.** The report gives counts for users, guests and admins ("2 admins aren't registered for MFA"). Apps, policies, groups and roles are named.

## Not readable through the Enterprise MCP (manual checklist in the report)

Much of the guide is process or on-premises, and some Graph data has no MCP scope. The report lists these as a checklist, and Cowork or VS Code can read the admin center pages in the browser if you turn that on.

- **Assign owners to key tasks**: every section of the guide starts with a table of tasks and owners. The report lists them so you can fill in names.
- **Entra Connect**: version (no more than six months behind), staging server, source anchor, custom rules, sync scope, password hash sync. The MCP returns 403 for `/directory/onPremisesSynchronization`.
- **Hybrid agents**: at least two pass-through authentication agents and two private network connectors per group, Connect Health, agent logs. The MCP returns 403 for `/onPremisesPublishingProfiles`.
- **Secure Score** itself (403); the report uses Entra recommendations, which is the Identity Secure Score list.
- SSPR on for all users, Seamless SSO, smart lockout, SSO and AD FS app migration, **Restrict access to Microsoft Entra admin center**, logs sent to a SIEM, a change testing approach, the Azure EA portal, AD FS lockdown, and Tier 0 protection for identity servers.

## Who runs it: Copilot Entra ID Operations Reader

Put the people who run the report in one group: **Copilot Entra ID Operations Reader**.

1. **Create it as a role-assignable security group, and put it under PIM.** `New-CopilotGroups.ps1` and `New-CopilotAdminPim.ps1` in the [Access Governance Guide](../Access%20Governance%20Guide/readme.md#copilot-entra-id-operations-reader) do both. The role sits on the group, so Groups Administrators and User Administrators can't change its members (only Global Administrators, Privileged Role Administrators and the group's owners can; give it no owners). People activate it for 8 hours with MFA, a reason and approval instead of holding the role all the time.
2. **Give the group Global Reader** (table below), and nothing that can make changes.
3. **Scope the Cowork plugin to the group** when you upload it: Agents > Tools > Registry > Upload > Scope users > Specific users or groups > Copilot Entra ID Operations Reader.
4. Members also need a Microsoft 365 Copilot license and Cowork access, or a GitHub Copilot plan for VS Code. The Enterprise MCP server acts as the signed-in person, so they see only what their activated role allows.

| Entra role | What the report reads with it |
| --- | --- |
| **Global Reader** | Everything the report reads: users, groups, domains, licenses, apps and their credentials, consent grants, authentication methods policy, guest invite settings, Conditional Access and named locations, sign-in logs, MFA registration, risky users, role assignments and PIM settings, access reviews, entitlement management, recommendations and health alerts |

**Why Global Reader and not a narrower set.** Microsoft documents Global Reader as the reader for the authentication methods policy and external collaboration settings, and it covers every other read too. Microsoft labels it a privileged role because it reads everything a Global Administrator can, which is why the group needs PIM with approval. Security Reader plus Reports Reader covers most of the report if you'd rather not use Global Reader; the authentication methods and guest invite checks may then be skipped. See the [Access Governance Guide](../Access%20Governance%20Guide/readme.md#copilot-entra-id-operations-reader) for the full comparison.

**Making the fixes** isn't part of the report. Use the matching admin role through its own PIM group, for the change only.

## What's in this folder

| File | What it is |
| --- | --- |
| [Cowork/](Cowork/readme.md) | Cowork setup guide, plugin, skill, rules and report template |
| [GitHub Copilot/](GitHub%20Copilot/readme.md) | GitHub Copilot setup guide (VS Code), and the script that installs the skill |

The report describes your tenant's weak spots. Keep it private; the `.gitignore` here excludes the report and CSV files.

## References

- [Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro): [identity and access management](https://learn.microsoft.com/entra/architecture/ops-guide-iam), [authentication management](https://learn.microsoft.com/entra/architecture/ops-guide-auth), [governance](https://learn.microsoft.com/entra/architecture/ops-guide-govern), [operations](https://learn.microsoft.com/entra/architecture/ops-guide-ops)
- [Overview](https://learn.microsoft.com/graph/mcp-server/overview) and [Get started](https://learn.microsoft.com/graph/mcp-server/get-started) with the Microsoft MCP Server for Enterprise
- [Microsoft Entra built-in roles: Global Reader](https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference#global-reader)
- [Least privileged roles by task in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-by-task)
- [Manage emergency access accounts](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)
- [Microsoft Entra recommendations](https://learn.microsoft.com/entra/identity/monitoring-health/overview-recommendations)

## What's verified and what isn't

Checked against Microsoft Learn and a live tenant on Nov 1, 2026.

**Tested through the Enterprise MCP:** every Graph call in the skill returned data or an empty list (not an error), including role assignment schedules, PIM policies, access reviews, recommendations, health alerts, sign-in log filters and the authentication methods policy. The calls that return 403 are listed above.

**Confirmed in Microsoft docs:** the guide's recommendations and numbers, the MCP scope list, Global Reader's reach and privileged label, and the least-privileged readers for each area.

**This repo's own choices, not Microsoft's:** severities and scores, the 90-day inactivity threshold, the "more than 30 policies" and "five or more Global Administrators" lines, the high-privilege permission list, the guess at emergency access accounts when you don't name them, and the mailbox heuristic for day-to-day admin accounts.

**Not confirmed:** whether Global Reader alone reads every call in every tenant (test it with the group activated), and whether the narrower Security Reader plus Reports Reader pair skips more than the two checks named above.
