# Copilot Billing Health Check

Oct 30, 2026 · @Chad Cox

A plan for a health check that reviews Microsoft 365 Copilot **billing policies** and **spending policies**, the groups they use and the people in those groups. It reports problems and tells you how each policy should be set up.

**Status: proof of concept.** [Get-CopilotBillingHealth.ps1](Get-CopilotBillingHealth.ps1) runs the spending policy, group and member checks. Billing policies are still design only. See [Build order](#build-order).

## Two ways to run it

| Way | Best for | How |
| --- | --- | --- |
| **PowerShell** | The full check, including each person's credit balance and Cowork readiness | `.\Get-CopilotBillingHealth.ps1`. It writes Findings.csv, Scorecard.csv, Readiness.csv, Policies.csv and an interactive Report.html |
| **Copilot Cowork** | Asking in plain language, follow-ups, and drafting notes to group owners | Attach Policies.csv and paste the prompt. Cowork reads groups and members live through the Microsoft MCP Server for Enterprise. See [Cowork/readme.md](Cowork/readme.md) |

The script uses only `Connect-MgGraph` and `Invoke-MgGraphRequest` (module Microsoft.Graph.Authentication) and changes nothing. Every Report.html ends with the Cowork prompt, so people can see it and rerun the check in Cowork.

```powershell
.\Get-CopilotBillingHealth.ps1                 # full check
.\Get-CopilotBillingHealth.ps1 -SkipBalances   # faster: no per-person credit balances
.\Get-CopilotBillingHealth.ps1 -PoliciesOnly   # only Policies.csv, for Copilot Cowork
.\Get-CopilotBillingHealth.ps1 -Environment USGov  # GCC High, without the cloud question
```

The script asks which Microsoft cloud to sign in to: **Global** (also GCC), **USGov** (GCC High), **USGovDoD** or **China**. Press Enter for Global, or pass `-Environment` to skip the question. Not every Copilot or agent API exists in every national cloud, so check Microsoft's docs for yours. The Enterprise MCP server that the Cowork setup uses is [global cloud only](https://learn.microsoft.com/graph/mcp-server/overview), so in GCC High, DoD and China use the scripts.

## How many active Copilot users are ready for Cowork?

The health check answers this too, as a funnel at the top of the report:

| Step | Counts people who… |
| --- | --- |
| Copilot license assigned | have a license that includes the Copilot service plan |
| Copilot turned on | have that plan enabled, no license assignment error, and an enabled account |
| Active in Copilot | used Copilot in the period (`-Period`, 28 days by default) |
| Covered by a Cowork policy | are in an enabled spending policy that selects Cowork |
| Billing set | are in such a policy with a billing method (not "not specified") |
| Can use Cowork now | Microsoft says can use Cowork right now (skipped with `-SkipBalances`) |

The funnel heading gives the headline: "% of active Copilot users ready for Cowork". Readiness.csv has one row per person. The findings add:

- **High:** looks ready, but Microsoft says they can't use Cowork.
- **Medium:** Copilot turned off in the license, or a license assignment error.
- **Info:** active Copilot users without Cowork (candidates), and Cowork users with no Copilot activity in the period.

Missing licenses and missing billing for Cowork users are already reported by the member and policy checks, so they aren't repeated.

```powershell
.\Get-CopilotBillingHealth.ps1 -Period D90   # readiness over 90 days
```

> If the Copilot usage report hides names (Microsoft 365 admin center > **Settings > Org settings > Reports** > *Display concealed user, group, and site names in all reports*), "Active in Copilot" is a count only and can't be matched to people. The script tells you; it doesn't change the setting.

## Microsoft has two kinds of Copilot policy

A health check has to cover both. They work differently.

| | **Billing policies** (classic pay-as-you-go) | **Spending policies** (Copilot Credits) |
| --- | --- | --- |
| Where | **Billing → Pay-as-you-go**, or **Copilot → Cost management → Classic Billing & usage** | **Copilot → Cost management → Configuration** |
| Pays for | Copilot Chat agents and SharePoint agents for people **without** a Copilot license | Cowork, Code, advanced SharePoint and OneDrive work, Work IQ API, Managed Runtime, Teams Phone Agent |
| Who it covers | All users, or **one** group per policy (up to 50 policies) | One or more security groups, or all users |
| How it's paid | An Azure subscription and resource group | Prepaid credits, pay-as-you-go, or both |
| Budget | **Only sends alerts. It doesn't stop spending** | Per-user and monthly limits **stop spending** |
| API | None found | Microsoft Graph beta, **signed-in admin only** |

Two checks work in opposite directions because of this:

- **Billing policies:** someone who already has a Copilot license doesn't need the policy. Remove them.
- **Cowork and Code spending policies:** someone *without* a Copilot license can't use the service. License them or remove them. The license doesn't include Cowork or Code usage, so licensed users still use credits.

## Who runs it: Copilot Health Check Users

Put the people who run the health checks in one group: **Copilot Health Check Users**. The same group runs both the [Billing](../Billing%20Health%20Check/README.md) and [Agent and Tools](../Agent%20and%20Tools%20Health%20Check/README.md) health checks.

1. **Create it as a role-assignable security group, and put it under PIM.** `New-CopilotGroups.ps1` and `New-CopilotAdminPim.ps1` in the [Group Assignment Guide](../Group%20Assignment%20Guide/readme.md#copilot-health-check-users) do both. The roles sit on the group, so Groups Administrators and User Administrators can't change its members (only Global Administrators, Privileged Role Administrators and the group's owners can; give it no owners). People activate it for 8 hours with MFA, a reason and approval instead of holding reader roles all the time. Microsoft recommends approval for groups used to activate Entra roles.
2. **Give the group reader roles only** (table below). Prefer these to Global Reader, which reads the whole tenant.
3. **Scope the Cowork plugin to the group** when you upload it: Agents > Tools > Registry > Upload > Scope users > Specific users or groups > Copilot Health Check Users.
4. Members also need a Microsoft 365 Copilot license and Cowork access to run the check in Copilot Cowork. The Enterprise MCP server acts as the signed-in person, so they see only what their activated roles allow.

| Entra role | What this check reads with it |
| --- | --- |
| **AI Reader** | Groups, owners, members; users, licenses and subscribed SKUs (all in the Entra roles reference). Spending policies and credit balances: *not confirmed*, see below |
| **Reports Reader** | The Microsoft 365 Copilot usage report (Cowork readiness funnel), and sign-in activity (inactive members) |
| **Security Reader** | Not needed for this check (the Agent and Tools Health Check uses it) |

**Spending policies and credits: test AI Reader.** Microsoft's [cost management overview](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/overview) names Global Reader and Billing Administrator for reads, and the API pages list no role. AI Reader is documented for viewing consumption in the admin center, not for this API. If the policy calls return 403 with the group active, use **Global Reader** for the run. If per-person credit balances return 403, run with `-SkipBalances`. Creating or changing spending policies isn't part of the check; that stays with **Copilot Billing Admin**.

## 1. Collect the data (read-only)

The cost management API only works when an admin signs in. So the check runs in two parts.

### Part A: unattended, weekly

Runs as a managed identity in Azure Automation or an Azure Function, with app-only permissions.

| Data | Source | Permission |
| --- | --- | --- |
| Billing policies: group, service, subscription, resource group, budget | A config file (there's no API) | — |
| Group details: type, dynamic rule, owners, created date, description | `/groups/{id}`, `/groups/{id}/owners` | Group.Read.All |
| Everyone in the group, including nested groups | `/groups/{id}/transitiveMembers/microsoft.graph.user` | GroupMember.Read.All |
| User state: enabled, guest, department, last sign-in, licenses | `/users?$select=accountEnabled,userType,department,signInActivity,assignedLicenses` | User.Read.All, AuditLog.Read.All (needs Entra ID P1) |
| Access packages and access reviews on each group | Entitlement management and access review APIs | EntitlementManagement.Read.All, AccessReview.Read.All |
| Copilot usage for licensed users | `/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail` | Reports.Read.All |
| Tenant credit balance | `/beta/copilot/costManagement/getTenantCreditBalance` | CopilotCostManagement.Read.All (app-only works) |
| Azure spend against budget | Azure Cost Management on each linked subscription (Azure Resource Manager, not Graph) | Cost Management Reader |

Unlicensed Copilot Chat usage isn't in the Graph usage report. Get it from the admin center's Copilot Chat usage report or the Purview audit log.

### Part B: an admin signs in, monthly or when needed

| Data | Source | Permission |
| --- | --- | --- |
| Spending policies: status, limits, billing method, services, groups, alerts and recipients | `/beta/copilot/costManagement/spendingPolicies` and its child endpoints | CopilotCostManagement-Policy.Read.All, CopilotCostManagement-Assignment.Read.All |
| Each person's credits used, what's left, whether they can use the service, and which policy covers them | `/beta/copilot/costManagement/userBalances/{id}/serviceBalances` | CopilotCostManagement-UserData.Read.All |

Part B saves a snapshot file. Part A reads the newest snapshot, so the weekly report still covers spending policies, and shows how old the snapshot is.

## 2. Rules

Each finding has a severity, a reason and a fix. Thresholds (2,000 credits, 80%, 90 days and so on) live in one table at the top of the script, so you can change them.

### Policy design

| Check | Applies to | Severity | Fix |
| --- | --- | --- | --- |
| The policy covers all users | Both | High | Limit it to a group |
| No budget, or no one gets the alerts | Billing | High | Add a budget with alerts at 50%, 80% and 100%. It warns but doesn't stop spending |
| No per-user limit **and** no monthly limit | Spending | High | Set a monthly limit |
| Status is `disabled` or `provisioningFailed`, or no group linked | Spending | High | Link the group, or recreate the policy |
| No email alert, or alert recipients who are disabled or gone | Spending | Medium | Add two active owners |
| Per-user limit under 2,000 credits | Spending | Medium | Raise it to Microsoft's minimum |
| A service doesn't match the policy name | Spending | Medium | Split it, so each budget has one purpose |
| Billing method is `notSpecified` | Spending | Medium | Pick prepaid or pay-as-you-go |
| Several services share one resource group | Billing | Low | Split them, so each team's costs are separate |
| Resource group has no cost owner or business unit tags | Billing | Low | Tag it |
| Policy isn't in the [Group Assignment Guide](../Group%20Assignment%20Guide/readme.md) | Spending | Low | Document it, or retire it |

### Group hygiene

| Check | Severity | Fix |
| --- | --- | --- |
| No owner, or only one | Medium | Add a second owner |
| Microsoft 365 group, or not a security group | Medium | Use a security group |
| Groups inside the group (nesting) | Medium | The real audience is hidden, and Microsoft doesn't say whether spending policies count nested members. Add people directly |
| Large group with people added by hand and no access package | Medium | Use an access package for spend tiers, or a dynamic rule for broad audiences. Access packages can't manage dynamic groups, so pick one |
| Empty group | Low | The policy does nothing. Retire it |
| No description that names its policy | Low | Add one |

### Member hygiene

| Check | Applies to | Severity | Fix |
| --- | --- | --- | --- |
| Disabled, guest, or no sign-in for 90 days | Both | Medium | Remove them |
| In both **Cowork Limited** and **Cowork Unlimited** | Spending | High | The higher limit always wins, so Limited does nothing. Remove one. (Being in Temp and Limited together is expected) |
| In the Temp group but not in Limited | Spending | Medium | Find out how they were added |
| **Has** a Copilot license | Billing | Medium | They don't need this policy. Remove them |
| **No** working Copilot license (none, Copilot turned off in the license, or a license assignment error), in a Cowork or Code policy | Spending | Medium | They can't use it. Assign a working license or remove them |
| People in a Teams Phone Agent group | Spending | Medium | Keep resource accounts only |
| No metered usage for 30 to 60 days | Both | Info | Candidate to remove |
| Heavy metered usage | Billing | Info | Candidate for a Copilot license. Show the break-even cost |
| At 80% or more of their limit, or blocked (`limitExhausted`) | Spending | Info | Candidate for the Temp or Unlimited tier |

### Governance

| Check | Severity | Fix |
| --- | --- | --- |
| No access review on the group | Medium | Add an Entra ID Governance access review every quarter |
| No named cost owner (tag or group owner) | Low | Name one |

### Checked by hand

No API shows these, so the report lists them as a checklist:

- **Allow new Agents and services as they become available** is off on every spending policy except the pilot one.
- Each Cowork spending policy has the right model profile.
- Credit request policies send requests to your access packages.

## 3. Outputs

- **Score for each policy** from 0 to 100, shown red, amber or green. Each High finding takes off 25, each Medium 10 and each Low 3.
- **Interactive HTML report** (score dial, policy cards, filters, search, CSV export, print) **and CSV files**, with each fix linked to the right part of the Group Assignment Guide. A Power BI report can read the same CSV files later.
- **The same check in Copilot Cowork.** The report ends with a ready-to-paste prompt and what it returns. See [Cowork/readme.md](Cowork/readme.md).
- **Weekly change list** compared with last week: new problems, fixed problems, and changes in group size and spend.
- **Fix mode, off by default.** It uses the tools you already have:
  - Policy settings: `New-CopilotSpendingPolicies.ps1 -UpdateExisting` in the [Group Assignment Guide folder](../Group%20Assignment%20Guide).
  - Stale members: removed through their access package, not straight from the group, so access reviews stay accurate.
  - Missing owners: a small new script with `-WhatIf` and an approval switch.
- **Privacy.** The reports show what each person spends. Save them outside this repo and treat them as sensitive.

## 4. What good looks like

The checks enforce this baseline:

1. One policy per service per audience. Each billing policy has its own tagged Azure resource group.
2. Every policy uses a security group with at least two owners.
3. Spend tiers (like Cowork Limited, Unlimited and Temp) are managed by access packages. Broad audiences can use dynamic rules.
4. Alerts at 50%, 80% and 100% go to a named cost owner. Billing-policy budgets only warn; spending-policy limits actually stop spending.
5. A person is in Cowork Limited **or** Unlimited, never both. Temp sits on top of Limited and has its own monthly limit.
6. **Allow new Agents and services** is off everywhere except the pilot policy.
7. Quarterly access reviews on every policy group.
8. A monthly cost review:
   - **Billing policies:** a Copilot license vs pay-as-you-go.
   - **Spending policies:** prepaid credits vs pay-as-you-go.

## Build order

1. **Proof of concept (done).** A PowerShell script you run signed in. It covers spending policies from the API, plus the group and member checks. A Copilot Cowork plugin runs the same group and member checks through the Enterprise MCP.
2. Add billing policies from the config file, the Copilot usage report and Azure Cost Management.
3. Add the HTML scorecard and the weekly change list.
4. Split it into the unattended weekly part and the monthly signed-in snapshot.
5. Add fix mode.

## What still needs testing

Microsoft doesn't document these, so test them in a tenant before relying on them:

- Whether spending policies count members of nested groups.
- What the linked-groups call returns: full group details or only IDs.
- How the per-person balance calls slow down (throttle) on large groups.
- Whether the Cowork plugin package uploads as written. It uses app manifest 1.29, so Cowork reads the tool list from the MCP server and no tool description file is needed. The OAuth setup for the Enterprise MCP in Cowork isn't fully documented yet.
- The real service names for SharePoint, OneDrive, Code, Managed Runtime and Teams Phone Agent. Microsoft only documents `cowork` and `workIQ`. `New-CopilotSpendingPolicies.ps1 -ShowServiceIds` reads them from your own policies.

## Sources

- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development)
- [Overview of the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/overview)
- [Microsoft Copilot pay-as-you-go overview (billing policies)](https://learn.microsoft.com/microsoft-365/copilot/pay-as-you-go/pay-as-you-go-overview)
- [Set up Copilot pay-as-you-go: budgets only send alerts](https://learn.microsoft.com/microsoft-365/copilot/pay-as-you-go/setup-pay-as-you-go)
- [Pay-as-you-go setup in the Copilot node (one group per policy)](https://learn.microsoft.com/microsoft-365/commerce/services/pay-as-you-go-setup-copilot)
- [Microsoft 365 Copilot Cost Management API overview](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/overview)
- [Get Copilot usage user detail (v1.0)](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/reports/copilotreportroot-getmicrosoft365copilotusageuserdetail)
- [Cost considerations for agents](https://learn.microsoft.com/microsoft-365/copilot/extensibility/cost-considerations)
- [Understand usage-based billing for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-overview-copilot-credits)
