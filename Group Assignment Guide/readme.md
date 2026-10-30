# Copilot Group Assignment Guide

Updated Oct 26, 2026 · @Chad Cox

This guide shows where to use each Copilot group. The scripts in this folder create the groups. You add each group to its admin center setting one time. After that, you add or remove people with access packages, not in the admin centers.

> **Next step: the Agent Delegation Guide.** After you set up these groups, follow the [Copilot Agent Delegation Guide](../Agents/readme.md). It covers who can build, share, publish and receive agents.

## How to read the labels

Every step has one of these labels:

- **Checked in the admin center on Oct 23, 2026.** I opened the page and saw this menu path, setting name and options. I only looked. I didn't save anything.
- **From Microsoft docs (link).** I couldn't see it in the admin center, but this Microsoft Learn page says it.
- **Not checked.** I didn't check this in the admin center or re-read Microsoft docs for this version. Check it yourself before you rely on it.

Admin centers change often, and some options only appear in some tenants. If your screen doesn't match, trust your screen.

**About defaults.** An admin center shows your tenant's *current* value, not Microsoft's default. So this guide only lists a default when the page or Microsoft docs clearly says what it is.

## Scripts in this folder

All the scripts use only Microsoft Graph (the Microsoft.Graph.Authentication module). Run each one that makes changes with `-WhatIf` first to see what it will do. `Get-CopilotSpendingReport.ps1` only reads.

| Order | Script | What it does |
| --- | --- | --- |
| 1 | `New-CopilotGroups.ps1` | Creates every group in the table below except Copilot Platform Admin. Skips groups that already exist. Creates admin groups as role-assignable. `-IncludeCodeGroups` adds the three Copilot Code groups |
| 2 | `Update-CopilotGroupCleanup.ps1` | Only for tenants built from the first version of this design. Deletes Copilot + Cowork Access, Copilot + Code Access and Copilot Preview Models Access. Exports members and owners to CSV first. Skips groups that still have members unless you add `-DeleteEvenIfMembers` |
| 3 | `Update-CopilotGroups-20261026.ps1` | Brings the descriptions of groups already in your tenant up to this version. Renames nothing by default. Run it after the cleanup script |
| 4 | `New-CopilotAdminPim.ps1` | Creates Copilot Platform Admin and puts every admin group under PIM for Groups. Needs `-ApproverGroupName` |
| 5 | `New-CopilotAccessPackages.ps1` | Creates the catalog, access packages, approval policies and access reviews. `-IncludeAdminPackages` and `-IncludeCodePackages` are optional |
| 6 | `New-CopilotSpendingPolicies.ps1` | **Preview.** Creates the spending policies with the new Graph cost management API (beta). Add `-UpdateExisting` to fix policies that already exist: it sets their limits, turns on missing services and links missing groups. It never turns anything off |
| 7 | `Get-CopilotSpendingReport.ps1` | **Preview, read-only.** Shows the credit balance and every spending policy with its groups, services, limits and alerts, and flags problems. Add `-UserPrincipalName` to see which policy covers a person and how much they have left |
| 8 | (by hand) | Point each admin center setting at its group, using the steps below |

```powershell
.\New-CopilotGroups.ps1 -WhatIf
.\New-CopilotGroups.ps1
.\Update-CopilotGroupCleanup.ps1 -WhatIf
.\Update-CopilotGroupCleanup.ps1
.\Update-CopilotGroups-20261026.ps1 -WhatIf
.\Update-CopilotGroups-20261026.ps1
.\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>" -WhatIf
.\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -WhatIf
.\New-CopilotSpendingPolicies.ps1 -WhatIf
.\New-CopilotSpendingPolicies.ps1 -UpdateExisting -WhatIf
.\Get-CopilotSpendingReport.ps1
```

Permissions you need: Group.ReadWrite.All for the groups. Privileged Role Administrator (or Global Administrator) to create role-assignable groups and set up PIM. Identity Governance Administrator for access packages.

**Before you run the cleanup script:** check that no admin center setting still points at a group it deletes. For example, an AI provider can still be assigned to Copilot Preview Models Access. Move the setting to the new group first.

## Every group the scripts create

This is the full list from `New-CopilotGroups.ps1` and `New-CopilotAdminPim.ps1`, in the same order. Each row says where you assign the group and which access package from `New-CopilotAccessPackages.ps1` adds people to it.

You set each admin center setting once. After that, people join through the access package, not the admin center.

### Access package tiers

The access package script puts every package in a catalog named **Copilot Access Catalog** and gives each package one of these tiers. The approver group is whatever you pass as `-ApproverGroupName` (default: **Copilot Delegated Admin**). Admin packages use `-AdminApproverGroupName`.

| Tier | Approval | Access ends after | Access review |
| --- | --- | --- | --- |
| Standard | Manager | 365 days | Every 6 months |
| Elevated | Manager, then the approver group | 180 days | Every 3 months |
| Admin | Manager, then the admin approver group | 90 days | Every 3 months |
| Temporary | Manager, then the approver group | 30 days, can't be extended | None. Removed at the end |

### Feature access

| Group | Where you assign it | Access package (tier) · also adds |
| --- | --- | --- |
| Copilot Access | Entra → **Groups** → this group → **Licenses** (Copilot license) | Copilot Access (Standard) |
| Copilot + Opal Access | Copilot → Settings → **Opal (Frontier)** | Copilot + Opal Access (Elevated) · Copilot Access, Copilot Frontier Access |
| Copilot + Autopilot Access | Nothing yet. Autopilot spending policy when it appears | Copilot + Autopilot Access (Elevated) · Copilot Access, Copilot Frontier Access |
| Copilot Studio Access | Entra licenses (Copilot Studio) and the Power Platform environment security group | Copilot Studio Access (Standard) |
| Copilot App Builder Access | Apps → Overview → **App creation paths**, or the pac command | Copilot App Builder Access (Elevated) · Copilot Studio Access |
| Copilot Frontier Access | Copilot → Settings → **Copilot Frontier** | Copilot Frontier Access (Elevated) · Copilot Access |
| Copilot Pilot Ring | Copilot New Services Pilot spending policy | Copilot Pilot Ring (Elevated) |

### Spend groups (spending policies)

| Group | Where you assign it | Access package (tier) · also adds |
| --- | --- | --- |
| Copilot + Cowork Spend Limit | Cowork Limited spending policy | Copilot + Cowork Access (Limited) (Standard) · Copilot Access. Can't be held with Unlimited |
| Copilot + Cowork Spend Unlimited | Cowork Unlimited spending policy | Copilot + Cowork Access (Unlimited) (Elevated) · Copilot Access |
| Copilot + Cowork Spend Unlimited Temp | Cowork Temporary Unlimited spending policy | Copilot + Cowork Access (Temporary Unlimited, 30 days) (Temporary). Only Spend Limit members can ask |
| Copilot SharePoint OneDrive Advanced Access | SharePoint OneDrive Advanced Work spending policy | Copilot SharePoint OneDrive Advanced Access (Standard) · Copilot Access |
| Copilot Work IQ API Access | Work IQ API spending policy | Copilot Work IQ API Access (Elevated) |
| Copilot Managed Runtime Access | Managed Runtime spending policy | Copilot Managed Runtime Access (Standard). No Copilot license needed, so it doesn't add Copilot Access |
| Copilot Teams Phone Agent Accounts | Teams Phone Agent spending policy | None. Members are resource accounts, not people |

### Copilot Code (only with `-IncludeCodeGroups`)

| Group | Where you assign it | Access package (tier) · also adds |
| --- | --- | --- |
| Copilot + Code Spend Limit | Code Limited spending policy (check Code is in your wizard) | Copilot + Code Access (Limited) (Elevated) · Copilot Access, Copilot Frontier Access. Can't be held with Unlimited |
| Copilot + Code Spend Unlimited | Code Unlimited spending policy (check Code is in your wizard) | Copilot + Code Access (Unlimited) (Elevated) · Copilot Access, Copilot Frontier Access |
| Copilot + Code Secure Execution Exemption | Copilot Code secure local execution, the Policy exemption group setting | Copilot + Code Secure Execution Exemption (Admin) |

### Models

| Group | Where you assign it | Access package (tier) · also adds |
| --- | --- | --- |
| Copilot Anthropic Models Access | AI providers operating as Microsoft subprocessors → **Anthropic** | Copilot Anthropic Models Access (Standard) |
| Copilot OpenAI Models Access | AI providers operating as Microsoft subprocessors → **OpenAI** | Copilot OpenAI Models Access (Standard) |
| Copilot SpaceXAI Models Access | The **SpaceXAI** row. See the note under Copilot SpaceXAI Models Access | Copilot SpaceXAI Models Access (Elevated) · Copilot Access, Copilot Frontier Access |
| Copilot Independent Processor Models Access | AI providers operating as independent processors → every other provider (for example **Mistral AI**, **Anthropic Models with Data Retention**) | Copilot Independent Processor Models Access (Admin) |

### Capability and exceptions

| Group | Where you assign it | Access package (tier) |
| --- | --- | --- |
| Copilot + Cowork Browser Access | Copilot → Settings → **Browser use in Microsoft Copilot**, and the Intune Edge profile | Copilot + Cowork Browser Access (Elevated) |
| Copilot Advanced Package Upload Access | Copilot → Settings → **Advanced package uploads** | Copilot Advanced Package Upload Access (Elevated) |
| Copilot Agent Sharing Access | Agents → Settings → **Sharing** | Copilot Agent Sharing Access (Standard) |
| Copilot Teams Policy Exceptions | Teams → Meeting policies → **Group policy assignment** | Copilot Teams Policy Exceptions (Elevated) |
| Copilot Cloud Policy Exceptions | config.office.com → the exception policy's **Scope** | Copilot Cloud Policy Exceptions (Elevated) |

### Admin groups (role-assignable, under PIM)

These get roles through PIM, not through an admin center setting. The roles and activation times are in the Admin groups section below. Access packages for them are only made with `-IncludeAdminPackages` (Admin tier).

Copilot Platform Admin, Copilot Delegated Admin, Copilot Agent Management Admin, Copilot Agent Registry Admin, Copilot AI Reader, Copilot Billing Admin, Copilot Cost Reader, Copilot Agent ID Admin, Copilot Agent ID Developers, Copilot Office Apps Admin, Copilot Compliance Admin, Copilot Teams Admin, Copilot SharePoint Admin, Copilot Studio Environment Admin, Copilot Plugin Approvers.

Copilot Platform Admin is made by `New-CopilotAdminPim.ps1` and has no access package.

## Do these first

### 1. Check Agent and plugin access before Oct 30, 2026

From Oct 30, 2026, the Copilot Connectors page follows this setting. The old `setFederatedConnectors` command is gone (MC1454973, updated Oct 23, 2026).

1. Go to M365 admin center → **Agents** → **Settings** → **Agent and plugin access**. Microsoft docs and Message Center also call this page **Allowed agent types**.
2. Leave **Allow agents and plugins built by Microsoft** on.
3. Leave **Allow agents and plugins built by your organization** on.
4. Turn off **Allow agents and plugins built by external publishers** until you have reviewed them.
5. Select **Save**.

Why: after Oct 30 this one setting decides connector and agent access. If it is wrong, your connectors are wrong too. This is the same setting as step 1 in the Agent Delegation Guide.

### 2. Limit who can upload advanced agent and plugin packages

*Checked in the admin center on Oct 23, 2026.*

1. Go to M365 admin center → **Copilot** → **Settings** → **View all**.
2. Select **Advanced package uploads**.
3. Under **Select who can upload advanced packages**, select **Specific users or groups**. The other options are **All users** and **No users**.
4. Add **Copilot Advanced Package Upload Access**. You can add up to 50 users or groups.
5. Select **Save**.

Why: if you do nothing, everyone can upload agents and plugins that run actions or MCP servers (MC1472007). **The Oct 25, 2026 date has passed.** Do this now.

### 3. Stop every user from creating agent blueprints in Entra

*Checked in the admin center on Oct 23, 2026.*

1. Go to Entra admin center → **Entra ID** → **Users** → **User settings**.
2. Under **Default user role permissions**, find **Users can register agent identity blueprints**. It's a **Yes** / **No** switch.
3. Set it to **No**.
4. Select **Save**.
5. Add the people who build agents to **Copilot Agent ID Developers**.

Note: the admin center calls it **Users can register agent identity blueprints**. Microsoft docs call it **Users can create agent blueprints**. It's the same switch.

*From Microsoft docs ([Restrict who can create applications and agents](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-app-roles#restrict-who-can-create-applications-and-agents)):* by default, users can create agent identity blueprints. When it's set to **No**, only admins and people with the **Agent ID Developer** role can create them.

### 4. Turn off automatic new services in your spending policies

*Checked in the admin center on Oct 23, 2026.*

The admin center calls this setting **Allow new Agents and services as they become available**. Microsoft docs call it **Auto-apply new services**. It's the first step of the spending policy wizard.

- **In a new policy it's on by default.** When I opened **Add spending policy**, this switch was on, and every service was already checked. Turn it off and uncheck what the policy doesn't need.
- **For an existing policy:** go to **Copilot** → **Cost management** → **Configuration**, and select the policy name. Microsoft docs say the details panel lets you change **Agents and services**, the model profile, the billing method, the limits and the alerts. Select **Save changes** when you are done.
- **Copilot Code is a live example.** Any policy with this switch on has already picked up Code (MC1519871).

Leave it on only in **Copilot New Services Pilot** (see below).

*From Microsoft docs ([Set up usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup)):* the default spending policy also has this setting turned on by default.

### 5. Check your spending limits meet Microsoft's new minimums

*From Microsoft docs ([Managing AI experiences enabled by usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits)):* Microsoft now asks for a minimum on every policy.

- **Per user, per month:** at least 2,000 credits.
- **Per policy, per month:** at or above the minimum for the number of users the policy covers.

A policy below the minimum won't save. If your limit meets the minimum but is still low, Microsoft shows a suggested higher limit and lets you save.

1. Go to **Copilot** → **Cost management** → **Configuration**.
2. Open each policy and check the per-user limit.
3. Raise any limit under 2,000 credits a month. Select **Save changes**.

This changes the **Cowork Limited** tier: a "small" limit now starts at 2,000 credits a month per person.

### 6. Choose who can ask for usage-based billing experiences

This setting decides what people see when they try Cowork (or another paid service) without a spending policy.

*From Microsoft docs ([Access requests to usage-based billing experiences](https://learn.microsoft.com/microsoft-365/copilot/request-access-usage-based-billing-experiences)):*

1. Go to M365 admin center → **Copilot** → **Settings** → **All settings**.
2. Select **Access to usage-based billing experiences**.
3. Under **Choose who can request a spending policy**, select **Specific users and groups**. The default is **All users**. The other option is **No users**.
4. Add **Copilot Access**.
5. Select **Save**. You need Global Administrator. It can take up to 24 hours.

**Why I couldn't find it on Oct 23, 2026.** Microsoft docs now say the old setting, **AI experiences enabled by usage-based billing**, is **deprecated**. It is being replaced by **Access to usage-based billing experiences**, the setting above. The old page has one checkbox and no group picker; the new page has the group picker. If you still see only the old page, check again later. See [Discovery setting for AI experiences enabled by usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/discovery-setting-ai-experiences).

### 7. Set the Copilot Code controls (Frontier)

Copilot Code started rolling out to Frontier tenants in late October 2026 (MC1519871). Code is now a usage-based service, so anyone in a spending policy that includes Code can use it.

1. Go to M365 admin center → **Copilot** → **Settings** and open the Copilot Code policy settings.
2. Leave **Copilot Code execution location** on **Cloud** unless people must run code on their own device. **Cloud and local** turns on local coding.
3. Leave **GitHub connection** off until you decide which GitHub services to allow.
4. Decide on **Auto-approve** (on by default) and **Organizational data in Copilot Code** (on for cloud, off for local).
5. Check your spending policies: if **Allow new Agents and services as they become available** is on, those users already have Code.

See Copilot Code: turn it on (Frontier) below for the full table and the groups to run.

### 8. SharePoint

*Not checked.* If you used PowerShell to turn off Copilot in SharePoint, use the SharePoint & OneDrive spending policy and the site AI settings instead. The earlier version of this guide says the PowerShell opt-out stops working on Nov 1, 2026 (MC1479277).

### 9. Find agents that create their own Entra agent identities (by Nov 4, 2026)

From Nov 4, 2026, Entra stops giving agents this permission on its own. Agents that create their own identities without a user will fail with error 403 (MC1506728). If you have none, there's nothing to do.

*Checked in the admin center on Oct 23, 2026:* Entra admin center → **Audit logs** has **Category** and **Activity** filters.

*Not checked* (from the earlier version of this guide):

1. Go to Entra admin center → **Entra ID** → **Audit logs**.
2. Set **Category** to **ApplicationManagement** and **Activity** to **Add service principal**.
3. Look for rows started by an **Application** that created an agent identity.
4. For each of those agents, grant the Graph permission **AgentIdentity.CreateAsManager** (admin consent). Test it.

See [Grant agents access to Microsoft 365 resources](https://learn.microsoft.com/entra/agent-id/grant-agent-access-microsoft-365).

### 10. Tell makers to move apps off App Builder (by Nov 30, 2026)

*Not checked.* Tell people who built apps with the **App Builder agent** or **vibe.powerapps.com** to move them to Cowork or Copilot Studio. New apps there are already blocked. Both retire on Nov 30, 2026, and apps not moved by then can't be opened (MC1505609).

## Feature access groups

### Copilot Access

*Not checked.*

1. Go to Entra admin center → **Groups** → **Copilot Access** → **Licenses**.
2. Assign the Microsoft Copilot license.
3. Keep the **Microsoft Copilot with Graph-grounded chat** service plan turned on (MC1405498).

E7 includes Copilot, so E7 users can skip the license but should stay in the group. E5 doesn't include Copilot. Groups inside this group don't get licenses. See [License options for Microsoft Copilot](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-licensing).

### Copilot Frontier Access

*Checked in the admin center on Oct 23, 2026.*

1. Go to M365 admin center → **Copilot** → **Settings** → **View all**.
2. Select **Copilot Frontier**. The panel title is **Turn on Frontier features**.
3. Select **Specific users and groups**. The other options are **No access** and **All users**.
4. Add **Copilot Frontier Access**.
5. Select **Save**. The page says changes can take up to 3 hours.

The page also says:

- People need a Microsoft 365 Copilot license to get Frontier.
- People in Microsoft's Technology Adoption Program (TAP) get Frontier early but don't show up here.
- It shows an estimate of how many of 10,000 assignments you've used.

*Not checked:* the earlier version of this guide said to add people directly and not put other groups inside this group.

### Copilot + Opal Access

*Checked in the admin center on Oct 23, 2026.*

1. Go to M365 admin center → **Copilot** → **Settings** → **View all**.
2. Select **Opal (Frontier)**.
3. Under **Choose who can access Opal**, select **Specific user groups**. The other option is **No users**.
4. Add **Copilot + Opal Access**.
5. Select **Save**.
6. Finish setup in the Opal admin portal. The page says Opal needs this one-time setup, needs Global Administrator, and won't work until you do it.

*Not checked:* the earlier version of this guide said the group owner must also be a member. See [Get started with Opal](https://learn.microsoft.com/microsoft-365/copilot/opal-settings-manage).

### Copilot Studio Access

*Not checked.*

1. In Entra admin center, assign the Copilot Studio license to this group.
2. In Power Platform admin center, go to **Environments** → \[environment\] → **Edit** → **Security group**. Set this group.

### Copilot Pilot Ring

Add it next to the main group when you test a new setting. It's also the only group in the **Copilot New Services Pilot** spending policy.

### Groups we removed

`Update-CopilotGroupCleanup.ps1` deletes these:

- **Copilot + Cowork Access.** Cowork access now comes from the Cowork spend groups. To give people a Cowork plugin, see Cowork plugins below.
- **Copilot + Code Access.** Code access will come from a Code spending policy, the same way as Cowork.
- **Copilot Preview Models Access.** Use **Copilot Independent Processor Models Access** instead. Move any AI provider setting that still uses it before you delete it.

### Copilot Code: turn it on (Frontier)

**This changed on Oct 21, 2026.** Copilot Code began rolling out to Frontier tenants (MC1519871), and Microsoft docs now list **Code (Copilot license required)** as a usage-based service. So Code is no longer on hold: it belongs in a spending policy like Cowork. On Oct 23, 2026 **Code** wasn't in my spending policy wizard yet, so check your own wizard first.

To use Code, a person needs a Microsoft Copilot license and a spending policy that includes Code. Do this:

1. Deploy the unified Microsoft Copilot app. On Windows devices in Frontier, set the Copilot update channel to **Beta**.
2. Run `New-CopilotGroups.ps1 -IncludeCodeGroups` and `New-CopilotAccessPackages.ps1 -IncludeCodePackages`. This creates **Copilot + Code Spend Limit**, **Copilot + Code Spend Unlimited** and **Copilot + Code Secure Execution Exemption**, and their packages.
3. Create the Code spending policies in the policy table below.
4. Set the Code controls. The table below shows each one and its default.
5. Assign **Copilot + Code Secure Execution Exemption** to the **Policy exemption group** setting in secure local execution. Keep that group very small.

**The Code controls** (*from Microsoft docs: [Manage Copilot Code for your organization](https://learn.microsoft.com/copilot/code/code-admin)*). These are set for the whole organization, not per group.

| Control | Default | What it does |
| --- | --- | --- |
| Pre-install Copilot Code components | Off | Installs the Code parts when the Copilot app starts |
| Auto-approve | On | Lets people allow Copilot to approve its own actions instead of confirming each one |
| Copilot Code execution location | Cloud only | Where sessions run: the person's device, the cloud, or both. **Cloud and local** turns on local coding |
| GitHub connection | Off | Whether people can connect a GitHub account |
| Allowed GitHub connections | Both | Which GitHub services are allowed: Both, GitHub.com only, GitHub Enterprise only, or None |
| Organizational data in Copilot Code | On for cloud, off for local | Whether Code can use your Microsoft 365 and Work IQ data as context |

**Secure local execution** (*from Microsoft docs: [Secure local execution in Copilot Code](https://learn.microsoft.com/copilot/code/code-secure-local-execution)*). Only for people using local coding.

| Control | Default | What it does |
| --- | --- | --- |
| Secure local execution | On for local mode | Runs local projects inside a protected environment |
| Policy exemption group | None | Lets the people in one group run local projects outside the protected environment. Use **Copilot + Code Secure Execution Exemption** |
| Allowed folders | Project folder and build tool files | Gives read or read/write access to more folders |
| Blocked file paths | None | Blocks folders. A blocked path always wins over an allowed one |
| Outbound network access | Allow approved hosts | Whether Code can reach all hosts, approved hosts only, or none |

## Spend groups and spending policies

A spending policy decides two things: who can use a paid Copilot service, such as Cowork, and how many credits they can spend. Anyone in a policy can use its services, even if the limit is tiny. To keep someone out of a service, take them out of every policy that includes it.

### Create a spending policy

*Checked in the admin center on Oct 23, 2026* (I opened the wizard and selected **Cancel**).

1. Go to M365 admin center → **Copilot** → **Cost management** → **Configuration**.
2. Select **Add spending policy**.
3. Microsoft docs list six steps: **policy scope** → **agents and services** → **limits and alerts** → **model profiles** → **billing method** → **review and add**. The **Model profiles** step only appears when the policy includes Cowork. My wizard on Oct 23, 2026 showed five steps, with no model profile step.
4. On **Agents and services**:
   - Turn off **Allow new Agents and services as they become available** (unless this is the pilot policy).
   - Uncheck every service the policy doesn't need. In a new policy, all of them start checked.
5. Pick the group on the scope step. You can only pick security groups, not single people, so put people and resource accounts in a group first.
6. Set the limits. The per-user limit must be at least 2,000 credits a month (see Do these first, step 5). Set a policy threshold alert, and user alerts if the policy has a per-user limit.
7. Pick the model profile and billing method, then finish the wizard.

The **Cost management** page has three tabs: **Overview**, **Configuration** and **Consumption**.

**Check the default policy first.** If it covers all users and has services checked, everyone can use those services. Uncheck the services and turn off the new-services setting. *Not checked.*

### Services in the wizard

*Checked in the admin center on Oct 23, 2026.*

| Service in the wizard | What's inside | Who uses the credits |
| --- | --- | --- |
| **Microsoft Copilot** (select the arrow to expand it) | **Cowork**, **Advanced work in OneDrive**, **Advanced work in SharePoint**. Each says "Copilot license required" | Licensed Copilot users |
| **Code** (new) | Copilot Code. Microsoft docs list it as "Code (Copilot license required)" | Licensed Copilot users in Frontier (MC1519871) |
| **Work IQ API for custom apps and agents** |  | *Not checked:* people using custom agents or apps that read Microsoft 365 data through Work IQ |
| **Copilot Managed Runtime** |  | *Not checked:* people running apps built in Cowork, Copilot Studio or the command line |
| **Teams Phone Agent** |  | Teams Phone Agent resource accounts, not people |

*Not checked:* the credit details from the earlier version of this guide (0.1 credit per Managed Runtime call; Work IQ used inside Cowork is billed to Cowork; Teams Phone Agent acts like a plain auto attendant when credits run out).

### Policy layout

| Policy name | Check these services | Group | Per-user limit | Owner |
| --- | --- | --- | --- | --- |
| Cowork Limited | Cowork | Copilot + Cowork Spend Limit | On, at least 2,000 credits | Copilot program owner |
| Cowork Unlimited | Cowork | Copilot + Cowork Spend Unlimited | Off | Copilot program owner |
| Cowork Temporary Unlimited | Cowork | Copilot + Cowork Spend Unlimited Temp | Off. Set a policy limit and an alert | Copilot program owner |
| SharePoint OneDrive Advanced Work | Advanced work in SharePoint, Advanced work in OneDrive | Copilot SharePoint OneDrive Advanced Access | On | Copilot program owner |
| Work IQ API | Work IQ API for custom apps and agents | Copilot Work IQ API Access | On | App platform / Power Platform team |
| Managed Runtime | Copilot Managed Runtime | Copilot Managed Runtime Access | On | App platform / Power Platform team |
| Teams Phone Agent | Teams Phone Agent | Copilot Teams Phone Agent Accounts (resource accounts only) | Optional | Teams voice admins |
| Copilot New Services Pilot | As few as the wizard allows. New-services setting **on** | Copilot Pilot Ring | On | Copilot program owner |
| Code Limited | Code | Copilot + Code Spend Limit | On, at least 2,000 credits | Copilot program owner |
| Code Unlimited | Code | Copilot + Code Spend Unlimited | Off | Copilot program owner |

**Policy names changed in this version.** They used to have a dash in the middle, like Cowork – Limited. The new Graph API only accepts letters, digits and spaces in a policy name (10 to 64 characters), so the names above work in both the admin center and the API.

Need different budgets for different phone agents? Make one group and one policy per budget. Keep the Teams Phone Agent group's owners to a few people, and don't put it in an access package, because its members are resource accounts.

### New services pilot (Copilot Pilot Ring)

The new-services setting adds each new paid service Microsoft releases to that policy. Use it in one small policy only, so a few testers see new services first.

1. Create a policy named **Copilot New Services Pilot**.
2. Scope it to **Copilot Pilot Ring** (a few IT and power users).
3. Check as few services as the wizard allows.
4. Leave **Allow new Agents and services as they become available** on.
5. Turn the per-user limit on. Set a small monthly policy limit and an alert to the Copilot program owner.

When Message Center announces a new paid service, test it with the pilot ring. If it works, add it to the main policies yourself.

- **The pilot ring gets new services before anyone reviews them.** Keep the group small and review it every quarter.
- **Some new services are for resource accounts, not people,** like Teams Phone Agent. Check what was added after each release.

If you don't want anything added automatically, skip this policy.

### Temporary unlimited Cowork (30 days)

People in the Limited group can ask for unlimited Cowork for 30 days. Entra removes it on day 30. Only Limited group members can see the request. This is set up by `New-CopilotAccessPackages.ps1`.

| Piece | Setting |
| --- | --- |
| Group | Copilot + Cowork Spend Unlimited Temp |
| Spending policy | **Cowork Temporary Unlimited**: Cowork only; this group; per-user limit **off**; a monthly policy limit and an alert to the Copilot program owner; new-services setting **off** |
| Access package | Copilot + Cowork Access (Temporary Unlimited, 30 days). It adds people to the Temp group only |
| Who can ask | Members of **Copilot + Cowork Spend Limit** only |
| Approval | Manager, then the approver group |
| How long | 30 days. People can't extend it or pick dates |
| Can't be combined with | Copilot + Cowork Access (Unlimited) |

- **They stay in Limited, but only one policy applies.** Microsoft docs now say a person in more than one policy for the same service is put on **one** policy, and the other policies' settings are not added together. The Temp policy wins while it lasts, because it has the highest per-user limit. After 30 days they are back on Limited.
- **Only the Temp group is removed** at the end.
- **Credits they already spent still count.** Moving between groups or policies does not reset a person's spending for the month (MC1470425). Someone who spends a lot during the 30 days may hit their Limited limit as soon as the Temp access ends.
- **They can ask again.** If someone asks often, move them to Unlimited.
- **The policy limit and the alert are your safety net,** because there is no per-user limit for those 30 days.
- **Test this with one person first.** Run `Get-CopilotSpendingReport.ps1 -UserPrincipalName <person>` before, during and after their 30 days. It shows which policy covers them for Cowork, how much they've used this month and how much is left.

### Model profiles (Cowork)

A model profile is a list of models. Attach one to a Cowork spending policy to control which models those users can pick.

*From Microsoft docs ([Configure model profiles](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup#configure-model-profiles)):*

1. Go to **Copilot** → **Cost management** → **Configuration**.
2. Select **Model profiles**, then **Add model profile**. You can also create one inside the spending policy wizard, on the **Model profiles** step.
3. In a policy, pick **Use default model selection** to allow every model your tenant has, or **Customize model selection** to use a profile.
4. To make a profile: enter a name, pick at least two models, and choose whether **Microsoft can select the most comparable model to maintain availability**.
5. Save the profile. You can reuse it in other Cowork policies.

If you don't let Microsoft pick a comparable model, people see an error when a model they picked is down.

A profile can't use a provider that's turned off in **AI providers operating as independent processors**.

**I couldn't confirm this in the admin center on Oct 23, 2026.** The **Configuration** tab only showed **Spending policies**. Microsoft docs say model profiles are there and in the wizard, and that they only work for **Copilot Cowork**. Check your own tenant again.

| Policy | Profile to use |
| --- | --- |
| Cowork Limited | Lower-cost models, and allow Microsoft to pick a comparable model |
| Cowork Unlimited | Default models |
| Cowork Temporary Unlimited | Same as Limited, unless the person asked for a specific model |

### Credit requests

People without a spending policy see a request option on Cowork and other paid services.

**1. Choose who can ask.** See Do these first, step 6.

**2. Send requests to your access package.**

*Checked in the admin center on Oct 23, 2026* (up to the **Add request policy** button):

1. Go to **Copilot** → **Cost management** → **Overview**.
2. Under **Users requesting credit increases**, select **View requests**. This opens **Credit requests**.
3. Select the **Request policies** tab.
4. Select **Add request policy**.

*From Microsoft docs ([Monitor Copilot Credit spending](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-monitor-spending)), the rest of the steps:*

5. Choose **All products and services**, or **Specific product or service** and pick the service. A service policy wins over an all-services policy.
6. Enter the **redirect URL** and the **message** people see. Paste the My Access link for **Copilot + Cowork Access (Limited)** as the redirect URL.
7. Optional: add a **Learn more** link and name the system that handles requests.
8. Select **Save**.

Requests that match your policy still show in **All requests**, labelled **Handled externally**. You can still approve, reject or mark them as done. The label does not tell you what your own system decided.

### Who can manage the policies

*From Microsoft docs ([Set up usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup)):*

| Task | Roles |
| --- | --- |
| Create a spending policy, add or change a billing method | Global Administrator, Billing Administrator |
| Edit policies, limits, alerts and billing methods (can't create policies) | AI Administrator, License Administrator |
| View spending only | AI Reader, Global Reader, other reader roles |

### When a person is in more than one policy

- **Only one policy applies.** *From Microsoft docs:* when a person is in more than one policy for the same service, Microsoft picks one policy in this order: highest per-user limit, then largest policy limit, then the policy created most recently. The settings from the other policies are **not** combined. A policy with no per-user limit is compared using its policy limit.
- **Access:** they can use every service in the policy they were put on.
- **Removing access:** take them out of every policy that includes that service. Lowering a limit does not remove access.
- **Hitting the limit does not move them.** When someone runs out of credits they stay on that policy and can request more. Microsoft does not move them to another policy.
- **Spending follows the person.** Credits used under an old policy still count under the new one in the same month.
- **A task already running can finish.** *From Microsoft docs:* if a running task goes over a per-user limit, the extra usage is not billed and is not shown as used credits.

Keep each person in only Limited or Unlimited for a service. The access packages enforce this.

### Set spending policies with Graph (new, preview)

Microsoft released Microsoft Graph APIs for Copilot cost management in mid-October 2026 (MC1521616). They are on the **beta** endpoint, so Microsoft can change them and they are not supported in production.

What you can do with them: read the tenant credit balance, create, change and delete spending policies, pick the groups a policy applies to, turn services on or off in a policy, set email threshold alerts and their recipients, and read one person's credit balance.

What you still do by hand: the **Allow new Agents and services as they become available** switch is not in the API. Model profiles are not in the API either.

`New-CopilotSpendingPolicies.ps1` in this folder uses these APIs to create the policies in the table above. Run it with `-WhatIf` first.

- **Already made your policies in the admin center?** Run `New-CopilotSpendingPolicies.ps1 -UpdateExisting -WhatIf`. It matches policies by name. Then it sets their limits, turns on missing services and links the right group. It only adds: extra services or groups are listed, not removed.
- **Cowork Temporary Unlimited has no per-user limit,** so give it a smaller monthly limit with `-TempPeriodLimit`.
- **Check the result** with `Get-CopilotSpendingReport.ps1`. It flags policies that aren't on, have no group, cover all users, have no alert, or aren't in this guide.

Things to know before you run it:

- A new policy is created **disabled**. It turns itself on after you add a group and it passes Microsoft's checks.
- A policy name must be 10 to 64 characters and only letters, digits and spaces.
- Every change to a policy needs the policy's current ETag, so run the script again rather than editing a policy at the same time in the admin center.
- Two policies can't cover the same group and the same service. Microsoft refuses the second one.
- Microsoft only documents a few service names (`cowork`, `workIQ`). For the others, read the service names off a policy you made in the admin center, then pass them to the script.
- You need **CopilotCostManagement-Policy.ReadWrite.All** and **CopilotCostManagement-Assignment.ReadWrite.All**, and the Billing Administrator or Global Administrator role.

See [Microsoft 365 Copilot Cost Management API overview](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/overview).

## Model access groups

*Checked in the admin center on Oct 23, 2026.* There are three pages under **Copilot** → **Settings** → **View all**:

- **AI providers operating as Microsoft subprocessors.** Lists **Anthropic** and **OpenAI**.
- **AI providers operating as independent processors.** Lists **SpaceXAI**, **Mistral AI** and **Anthropic Models with Data Retention**. These run under the provider's own terms.
- **Experimental and preview AI models.** This list was empty when I checked.

The provider lists can differ by tenant and region.

### Copilot Anthropic Models Access and Copilot OpenAI Models Access

*Checked in the admin center on Oct 23, 2026.*

1. Go to **Copilot** → **Settings** → **View all** → **AI providers operating as Microsoft subprocessors**.
2. Select the arrow next to **Anthropic** to expand it.
3. Under **Choose which users can access Anthropic models**, select **Specific users and groups**. The other options are **All users** and **No users**.
4. Add **Copilot Anthropic Models Access**. Select **Save**.
5. Do the same for **OpenAI** with **Copilot OpenAI Models Access**.

*Not checked:* for Copilot Studio, also allow external models in the Power Platform admin center.

### Copilot SpaceXAI Models Access

The scripts make a separate group for SpaceXAI. Its access package also adds Copilot Access and Copilot Frontier Access, because SpaceXAI is Frontier only.

*Checked in the admin center on Oct 23, 2026:*

1. Go to **Copilot** → **Settings** → **View all** → **AI providers operating as independent processors**.
2. Select the arrow next to **SpaceXAI**.
3. Under **Choose which users can access SpaceXAI models**, select **Specific users and groups**. The other options are **All users** and **No users**.
4. Add **Copilot SpaceXAI Models Access**. Select **Save**.

**Where SpaceXAI shows up can differ.** The script descriptions put SpaceXAI on the **subprocessors** page. On Oct 23, 2026, it showed on the **independent processors** page instead, where the provider's own terms apply. Microsoft has a doc for each: [SpaceXAI as a subprocessor](https://learn.microsoft.com/microsoft-365/copilot/spacexai-subprocessor) and [Connect to SpaceXAI models (as an independent processor)](https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-models). *Not checked:* which one applies to your tenant. Use the page where SpaceXAI appears. If it's on the independent processors page, get legal and privacy sign-off first, as for the group below.

*Not checked:* the earlier version of this guide said SpaceXAI is Frontier only, off by default, and not available in the EU, EFTA, UK or government clouds (MC1474124).

### Copilot Independent Processor Models Access

Use this group for every independent-processor provider except SpaceXAI. Its access package is Admin tier, because data leaves Microsoft's terms.

*Checked in the admin center on Oct 23, 2026.*

1. Get legal and privacy sign-off first. These providers use their own terms, not Microsoft's.
2. Go to **Copilot** → **Settings** → **View all** → **AI providers operating as independent processors**.
3. Select the arrow next to the provider (for example **Mistral AI** or **Anthropic Models with Data Retention**).
4. Under **Choose which users can access ...**, select **Specific users and groups**. The other options are **All users** and **No users**.
5. Add **Copilot Independent Processor Models Access**. Select **Save**.

- **Models that keep your data** appear as **Anthropic Models with Data Retention** on this page. Use this group for them.
- *Not checked:* accepting the provider's terms. The providers I saw were already allowed, so I didn't see a terms step.

Don't use the Pilot Ring for these providers. Sending data outside Microsoft's terms is a legal decision.

## Capability and exception groups

### Copilot + Cowork Browser Access

*Checked in the admin center on Oct 23, 2026.*

1. Go to **Copilot** → **Settings** → **View all** → **Browser use in Microsoft Copilot**. (It's also under **Copilot** → **Cowork** → **Settings**.)
2. Turn on **Allow local browser use**. The page says this lets Copilot experiences such as Cowork and Chat use the local Microsoft Edge browser for people.
3. Under **Choose who can use browser access**, select **Specific users and groups**. The other option is **All users**.
4. Add **Copilot + Cowork Browser Access**. Select **Save**.

*Not checked:* the device side. In Intune admin center → **Devices** → **Configuration** → \[Edge profile\] → **Assignments**, set the Edge policy `CopilotCoworkToolActionsEnabled` and assign the profile to this group. Needs Edge 152 or later.

### Copilot Advanced Package Upload Access

See Do these first, step 2.

### Copilot Agent Sharing Access

*Checked in the admin center on Oct 23, 2026.*

1. Go to M365 admin center → **Agents** → **Settings** → **Sharing**.
2. Under **Choose who can share agents with anyone in the organization**, select **Specific users**. The other options are **All users** and **No users**.
3. Add **Copilot Agent Sharing Access**. Select **Save**.

The page says this affects agents built with Agent Builder, and people who can't share with everyone can still share with named people and security groups. The same choice also appears in **Copilot** → **Settings** → **View all** → **Agents**.

### Cowork plugins

*Checked in the admin center on Oct 23, 2026.*

1. Go to **Agents** → **Tools**. The **Registry** tab lists **Plugins**, **Skills**, **MCP servers** and **Connectors**.
2. Select the plugin. It has an **Overview** tab and a **Users** tab, plus **Install** and **Block** buttons.
3. To limit who can find it: on **Users**, under **Available to**, select **Specific users and groups** (other options: **All users**, **No users**). Add the Cowork spend groups (Limited, Unlimited and Temp). Select **Save**.

*From Microsoft docs ([Manage plugins for Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-manage-plugins)):* to install it for people automatically, select the plugin, then **Installed for** → **Specific users/groups**, then **Next** and install. I didn't open **Install** in the admin center.

### Copilot Teams Policy Exceptions

*Checked in the admin center on Oct 23, 2026.*

1. Go to Teams admin center → **Meetings** → **Meeting policies**.
2. Create or open the special Copilot policy on the **Manage policies** tab. The setting is in the **Copilot and other AI** section, named **Copilot**. Its options are **On**, **On with saved transcript required**, **On with transcript saved by default** and **Off**.
3. On the **Group policy assignment** tab, assign that policy to this group.

*Not checked:* **Voice** → **Calling policies**, and whether groups inside this group are ignored. Add people directly to be safe.

### Copilot Cloud Policy Exceptions

*Not checked.* Microsoft 365 Apps admin center (config.office.com) → **Customization** → **Policy Management** → \[new policy\] → **Scope**. Scope the policy to this group. Give it a lower priority number than the all-users policy, so it wins.

Related: *Checked in the admin center on Oct 23, 2026:* **Web search for Microsoft Copilot** in **Copilot** → **Settings** → **View all** says to manage it in the Microsoft 365 Apps admin center.

### Copilot App Builder Access

This limits who can build apps in Copilot Studio.

*Checked in the admin center on Oct 23, 2026* (up to the **Set up** button):

1. Go to M365 admin center → **Apps** → **Overview**. The page is marked **Preview**.
2. Find the **App creation paths** card and select **Set up**.

*Not checked* (I didn't open **Set up**; from the earlier version of this guide):

3. Find **Copilot Studio** app creation. Limit it to **Copilot App Builder Access**.
4. Select **Save**. You need Global Administrator or Power Platform Administrator. Open Copilot Studio tabs can keep the old setting for up to 15 minutes.

You can also use the Power Platform command line (pac). *Not checked:*

```powershell
pac admin update-tenant-settings --setting-name powerPlatform.powerapps.enabledGroupsManagedAppsMcsPreview --setting-value '<group object ID>'
```

- App building in Cowork uses Copilot Frontier Access and the Cowork spending policy instead.
- *Not checked:* Copilot Studio app building uses the environment's credits in the Power Platform admin center, not a spending policy.
- *Checked in the admin center on Oct 23, 2026:* **Apps** → **Settings** only had **Environment groups**.

See [Environment routing for Copilot Managed Runtime](https://learn.microsoft.com/power-platform/admin/default-environment-routing-copilot-managed-runtime#frequently-asked-questions).

Copilot + Code Secure Execution Exemption waits with the other Code groups. See Copilot Code: wait for it.

For agent settings (who can build, share, publish and receive agents), see the [Copilot Agent Delegation Guide](../Agents/readme.md).

## Admin groups

*Not checked.* Admin groups use **PIM for Groups** (`New-CopilotAdminPim.ps1`). The group always holds the role. People are *eligible* members: they turn the role on when they need it, for a few hours, with MFA and a reason. To give roles without PIM, run `New-CopilotGroups.ps1` with `-AssignRoles`.

| Group | Entra role(s) | How long it stays on | What it's for |
| --- | --- | --- | --- |
| Copilot Platform Admin | AI Administrator, Billing Administrator, Agent ID Administrator, Agent Registry Administrator, Office Apps Administrator, Compliance Administrator, Teams Administrator, SharePoint Administrator, Power Platform Administrator, Message Center Reader, Service Support Administrator | 4 hours, needs approval | Every Copilot admin center, Message Center and support tickets |
| Copilot Delegated Admin | AI Administrator | 8 hours, needs approval | M365 admin center → Copilot settings |
| Copilot Agent Management Admin | AI Administrator | 8 hours, needs approval | M365 admin center → Agents |
| Copilot Agent Registry Admin | Agent Registry Administrator | 8 hours, needs approval | **New.** The Entra Agent Registry: agent metadata, collections and who can see which agents |
| Copilot AI Reader | AI Reader | 8 hours | Read-only view of agents, Copilot settings and spending |
| Copilot Billing Admin | Billing Administrator | 4 hours, needs approval | Creating spending policies in Copilot → Cost management |
| Copilot Cost Reader | None | 8 hours | See the next section |
| Copilot Agent ID Admin | Agent ID Administrator | 4 hours, needs approval | Entra → Agent ID |
| Copilot Agent ID Developers | Agent ID Developer | 8 hours | Creating agent blueprints after **Users can register agent identity blueprints** is **No** |
| Copilot Office Apps Admin | Office Apps Administrator | 8 hours | Cloud Policy in config.office.com |
| Copilot Compliance Admin | Compliance Administrator | 4 hours, needs approval | Purview DLP, audit, eDiscovery, DSPM for AI |
| Copilot Teams Admin | Teams Administrator | 8 hours, needs approval | Teams admin center |
| Copilot SharePoint Admin | SharePoint Administrator | 8 hours, needs approval | SharePoint admin center |
| Copilot Studio Environment Admin | Power Platform Administrator (or a smaller environment admin role) | 8 hours, needs approval | Power Platform admin center |
| Copilot Plugin Approvers | None | 8 hours | See the next section |

I checked every role name above in the tenant on Oct 26, 2026. They all exist.

## Groups with no setting yet

| Group | Why | What to do for now |
| --- | --- | --- |
| Copilot + Autopilot Access | *Not checked:* Autopilot is the new name for Microsoft Scout (MC1479277). It uses a spending policy, but its admin settings aren't out yet. *Checked Oct 23, 2026:* Autopilot wasn't in the spending policy wizard | Keep the group. Its access package also adds Copilot Access and Copilot Frontier Access. When Autopilot appears in the wizard, create a policy for this group |
| Copilot Cost Reader | No role can view spending without also seeing other things | Give it AI Reader, or delete it and use Copilot AI Reader |
| Copilot Plugin Approvers | Plugin requests are under **Agents** → **Tools** → **Requests (preview)** (checked Oct 23, 2026). I didn't see an approver setting | Use it as a mailing or ticket queue, or give it AI Administrator |

## Audit logs

*Checked in the admin center on Oct 23, 2026:* Entra admin center → **Audit logs** lets you filter by **Date range**, **Service**, **Category** and **Activity**. Use it to see who changed **User settings**, such as the agent blueprint switch.

*From Microsoft docs ([Manage plugins for Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-manage-plugins)):* Copilot and Cowork plugin activity is in Microsoft Purview audit, under **Copilot activities**, not in Entra audit logs.

## What changed on Oct 23, 2026

I checked each step against the admin centers. These are the differences from the earlier version:

| Old guide said | What the admin center shows |
| --- | --- |
| **Users can create agent blueprints** | **Users can register agent identity blueprints** |
| **Auto-apply new services** | **Allow new Agents and services as they become available**. On by default in a new policy, with every service checked |
| SpaceXAI is on the subprocessors page | SpaceXAI is on **AI providers operating as independent processors**. Still use Copilot SpaceXAI Models Access for it |
| **AI providers for other large language models** | **AI providers operating as independent processors** |
| **Copilot → Settings → View all → Cowork settings** → **Allow Cowork to use the Microsoft Edge browser** | **Browser use in Microsoft Copilot** → **Allow local browser use** |
| **Access to usage-based billing experiences** with a group picker | Couldn't find it. The closest is **AI experiences enabled by usage-based billing**, with one checkbox and no group picker |
| **Copilot → Cost Management → Configuration → Model profiles** | Not shown on the **Configuration** tab |
| **Copilot → Cost Management → Credit requests** | **Copilot → Cost management → Overview → View requests** |
| **Agents → Tools → \[plugin\] → Installed for** | Plugin has **Users** (**Available to**) and an **Install** button |
| Frontier: no user count | Panel shows an estimate of how many of 10,000 assignments you've used |

## Other Message Center changes

Every Copilot post that changes this guide. The newest ones are at the top. Rows above the line were checked on Oct 26, 2026; the rest come from earlier versions of this guide.

| Change | Post | What it means for you |
| --- | --- | --- |
| Graph APIs for Copilot cost management (beta) | MC1521616 | New. See Set spending policies with Graph, and run `New-CopilotSpendingPolicies.ps1` |
| Copilot Code is rolling out in Frontier. Code is now a usage-based service | MC1519871 | See Copilot Code: turn it on, and Do these first, step 7 |
| From Oct 30 the Copilot Connectors page follows **Agent and plugin access** (Allowed agent types). The old CLI switch is gone | MC1454973 (updated Oct 23) | See Do these first, step 1 |
| The Cowork settings panel is now called **Browser use in Microsoft Copilot** | MC1515930 | Only a name change. See Copilot + Cowork Browser Access |
| Critique and Council retire from Researcher by mid-November | MC1515927 | Tell Frontier users. Nothing to change in your groups. Action by Nov 14, 2026 |
| Admin controls for Business Applications in Work IQ, preview by Nov 17 | MC1518036 | Review which Power Platform environments Work IQ can read. Affects Copilot Work IQ API Access |
| Usage-based models in Chat and Word, Excel and PowerPoint, early to mid-November. GPT-6 Astra and Claude Fable 5.1 become usage-based models | MC1519122 | People need a Copilot license, usage-based billing on and credits. Your model groups still decide which providers they get |
| Insights Agent V2 in Frontier adds **Agents** → **Settings** → **Agent feedback sharing** (default **No agents**) | MC1520901 | Decide whether agent owners see user feedback. See the Agent Delegation Guide |
| Clipchamp "Create a video" gets a Cloud Policy control, late November to early December | MC1518034 | A new policy to scope with Copilot Cloud Policy Exceptions |
| Teams admin center gets a simpler app enablement flow (**Teams apps** → **Manage apps** → **Manage access**) | MC1515931 | Your settings don't change. Update your runbook |
| Teams Phone Agent GA guidance: one security group and one spending policy per budget | MC1482800 (updated Oct 23) | Matches this design. Keep resource accounts in Copilot Teams Phone Agent Accounts |
| Copilot Studio adds topics, connected agents, evaluations and monitoring for Copilot Chat agents (GA Oct 26) | MC1518233 | For makers. Nothing to change in your groups |
| Outlook Copilot Prioritize retires from Oct 26 | MC1519861 | Tell users. Nothing to change in your groups |
| Agents that create their own Entra agent identities need an admin grant from Nov 4 | MC1506728 | See Do these first, step 9 |
| App Builder agent and vibe.powerapps.com retire on Nov 30. New apps there are already blocked | MC1505609 | Makers build apps in Cowork or Copilot Studio. Copilot App Builder Access still limits Copilot Studio |
| Copilot Studio app building can be limited to groups in the M365 admin center | MC1469329 | See Copilot App Builder Access |
| The Copilot Studio app in Teams goes away: no editing from January 2027, removed in February 2027 | MC1511056 | Tell makers to use copilotstudio.microsoft.com. Nothing to change in your groups |
| Researcher and Analyst are no longer pinned by default in the Copilot app | MC1479277 | If you want them pinned, pin them yourself. See the Agent Delegation Guide |
| Usage numbers for Microsoft-built agents no longer need an Agent 365 license (late November) | MC1506727 | Copilot AI Reader members can see agent activity in **Agents** → **All agents** |
| Sensitivity labels can be put on Entra security groups (mid-November) | MC1508238 | Don't label the Copilot groups yet. A label can't be changed or removed once it's on a security group |
| Older GPT models in Copilot Studio move to GPT Chat Latest on Nov 12 | MC1506318 | Tell agent owners to test their agents. Your model groups don't change |
| Spending policies can use a model profile (Cowork only) | MC1479276 | See Model profiles |
| Credit requests can go to your own approval process | MC1470425 | See Credit requests |
| Credits follow a person when they move between policies | MC1470425 | Test the 30-day temporary tier with one person first |
| Autopilot (formerly Scout) uses a spending policy; admin settings not out yet | MC1479277, MC1332811 | Keep the Autopilot group |
| Cowork browser use can be limited to groups | MC1474461 | See Copilot + Cowork Browser Access |
| SpaceXAI setting can be limited to groups | MC1474124 | See Copilot SpaceXAI Models Access |
| GPT-6.1 Sol and Claude Sonnet 5.5 follow the OpenAI and Anthropic settings | MC1483844 | Your model groups still decide who gets them |
| A **Plugins** button replaces the Agents, Agents & Skills and Customize buttons | MC1484008 | Admins still deploy plugins from **Agents** → **Tools**. Update user training |
| The **Microsoft Copilot with Graph-grounded chat** service plan now controls full vs basic Copilot | MC1405498 | Don't turn that plan off in the Copilot Access license |
| Legal plugins in Word and Cowork; the Legal Agent is retiring | MC1509799 | You can only turn these on or off for everyone |
| Advanced package uploads can be limited to groups | MC1472007 | See Do these first, step 2 |

## Sources

Microsoft docs I read for this version (Oct 26, 2026):

- [Microsoft 365 Copilot Cost Management API overview](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/overview)
- [Create spendingPolicy (Graph beta)](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/spendingpolicy-create)
- [spendingPolicy resource type](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/resources/spendingpolicy)
- [spendingPolicyServiceSetting resource type](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/resources/spendingpolicyservicesetting)
- [costManagementAlertSetting resource type](https://learn.microsoft.com/microsoft-365/copilot/extensibility/api/admin-settings/cost-management/resources/costmanagementalertsetting)
- [Managing AI experiences enabled by usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits)
- [Monitor Copilot Credit spending](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-monitor-spending)
- [Understand usage-based billing and cost management for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-overview-copilot-credits)
- [Set up usage-based billing for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup)
- [Access requests to usage-based billing experiences](https://learn.microsoft.com/microsoft-365/copilot/request-access-usage-based-billing-experiences)
- [Discovery setting for AI experiences enabled by usage-based billing (deprecated setting)](https://learn.microsoft.com/microsoft-365/copilot/discovery-setting-ai-experiences)
- [Manage Copilot Code for your organization](https://learn.microsoft.com/copilot/code/code-admin)
- [Secure local execution in Copilot Code](https://learn.microsoft.com/copilot/code/code-secure-local-execution)
- [Agent settings in the Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-settings)
- [Microsoft Entra built-in roles (Agent Registry Administrator)](https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference)
- [Manage plugins for Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-manage-plugins)
- [Restrict who can create applications and agents in Entra](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-app-roles#restrict-who-can-create-applications-and-agents)
- [Create an agent identity blueprint](https://learn.microsoft.com/entra/agent-id/create-blueprint)

Other sources from the earlier version (not re-read for this version):

- [Get started with the Microsoft Frontier Program](https://learn.microsoft.com/microsoft-365/admin/manage/get-started-frontier)
- [Get started with Opal in Microsoft Copilot](https://learn.microsoft.com/microsoft-365/copilot/opal-settings-manage)
- [Manage Copilot Cowork for your organization](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-admin-governance)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-local-browser)
- [Managing AI experiences enabled by usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits)
- [Custom request policies](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-monitor-spending#configure-custom-request-policies)
- [Manage Copilot Code for your organization](https://learn.microsoft.com/copilot/code/code-admin)
- [Secure local execution in Copilot Code](https://learn.microsoft.com/copilot/code/code-secure-local-execution)
- [Anthropic models in Microsoft Online Services](https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-subprocessor)
- [OpenAI as a subprocessor](https://learn.microsoft.com/microsoft-365/copilot/openai-subprocessor)
- [Manage preview AI models](https://learn.microsoft.com/microsoft-365/copilot/manage-preview-ai-models)
- [Connect to SpaceXAI models (as an independent processor)](https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-models)
- [SpaceXAI as a subprocessor in Microsoft Online Services](https://learn.microsoft.com/microsoft-365/copilot/spacexai-subprocessor)
- [Assign AI provider access to users and groups](https://learn.microsoft.com/microsoft-365/copilot/copilot-ai-provider-user-sec-group-access)
- [Manage Microsoft Copilot settings in the M365 admin center](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-page)
- [Agent settings in Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-settings)
- [Manage Copilot in Teams meetings](https://learn.microsoft.com/microsoftteams/copilot-teams-transcription)
- [Admin policies for Copilot Pages and Notebooks (Cloud Policy scoping)](https://learn.microsoft.com/microsoft-365/loop/cpcn-admin-configuration)
- [Understand usage-based billing and cost management for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-overview-copilot-credits)
- [Understand costs for Business Applications in Work IQ](https://learn.microsoft.com/power-platform/admin/business-applications-work-iq/understand-costs)
- [Copilot Managed Runtime licensing FAQ](https://learn.microsoft.com/microsoft-365/admin/manage/apps/licensing-faq)
- [Copilot Managed Runtime: scope app creation](https://learn.microsoft.com/microsoft-365/admin/manage/apps/?view=o365-worldwide#enable-copilot-managed-runtime-for-your-tenant)
- [Setup – Teams Phone Agent – Usage-based billing](https://learn.microsoft.com/microsoftteams/aa-cq-setup-teams-phone-agent-ubb)
- [License options for Microsoft Copilot](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-licensing)
- [Create assignmentPolicies (specificAllowedTargets)](https://learn.microsoft.com/graph/api/entitlementmanagement-post-assignmentpolicies)
- [Environment routing for Copilot Managed Runtime (app creation spaces)](https://learn.microsoft.com/power-platform/admin/default-environment-routing-copilot-managed-runtime#frequently-asked-questions)
- [Grant agents access to Microsoft 365 resources](https://learn.microsoft.com/entra/agent-id/grant-agent-access-microsoft-365)
- Message Center: MC1470425, MC1479276, MC1479277, MC1472007, MC1506733, MC1506728, MC1505609, MC1511056, MC1506727, MC1508238, MC1506318, MC1474461, MC1474124, MC1469329, MC1483844, MC1405498, MC1484008, MC1454973, MC1509799, MC1332811
