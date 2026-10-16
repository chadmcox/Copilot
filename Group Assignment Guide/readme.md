# Copilot Group Assignment Guide

Oct 16, 2026 · @Chad Cox

This guide shows where to use each Copilot group. The groups come from New-CopilotGroups.ps1. You add each group to its admin center setting one time. After that, you add or remove people with the access packages from New-CopilotAccessPackages.ps1, not in the admin centers. *Unconfirmed* means Microsoft hasn't fully documented that path yet, so check it in your tenant.

> **Next step: the Agent Delegation Guide.**
> After you set up these groups, follow the [Copilot Agent Delegation Guide](../Agents/readme.md). It shows who can build, share, publish and receive agents, and how to limit each agent to the right group.

## Scripts in this folder

All four scripts use only Microsoft Graph (the Microsoft.Graph.Authentication module). Run each one with `-WhatIf` first to see what it will do.

| Order | Script | What it does |
| --- | --- | --- |
| 1 | `New-CopilotGroups.ps1` | Creates every group in this guide. Idempotent: groups that already exist are skipped. Admin groups are created role-assignable. `-IncludeCodeGroups` adds the Copilot Code groups once Code appears in your spending policy wizard |
| 2 | `Update-CopilotGroupCleanup.ps1` | One-off, only for tenants built from the first version of this design. Deletes Copilot + Cowork Access, Copilot + Code Access and Copilot Preview Models Access (exports members and owners to CSV first; skips groups that still have members unless `-DeleteEvenIfMembers`), and sets current descriptions |
| 3 | `New-CopilotAdminPim.ps1` | Puts the admin groups under PIM for Groups and creates Copilot Platform Admin. Requires `-ApproverGroupName` |
| 4 | `New-CopilotAccessPackages.ps1` | Creates the entitlement management catalog, access packages, approval policies and access reviews. `-IncludeAdminPackages` and `-IncludeCodePackages` are optional |
| 5 | (manual) | Point each admin center setting at its group, using the tables below |

```powershell
.\New-CopilotGroups.ps1 -WhatIf
.\New-CopilotGroups.ps1
.\Update-CopilotGroupCleanup.ps1 -WhatIf
.\Update-CopilotGroupCleanup.ps1
.\New-CopilotAdminPim.ps1 -ApproverGroupName "<approver group>" -WhatIf
.\New-CopilotAccessPackages.ps1 -ApproverGroupName "<approver group>" -WhatIf
```

Permissions: Group.ReadWrite.All for the groups; Privileged Role Administrator (or Global Administrator) to create role-assignable groups and configure PIM; Identity Governance Administrator for access packages.

## Do these first

| # | Where | What to do | By | Why |
| --- | --- | --- | --- | --- |
| 1 | M365 admin center → **Copilot → Settings → View all → Advanced package uploads** | Select **Specific users or groups**. Add **Copilot Advanced Package Upload Access**. Select **Save** | Oct 25, 2026 | If you do nothing, everyone can upload agents and plugins that run actions or MCP servers (MC1472007) |
| 2 | Entra admin center → **Entra ID → Users → User settings** | Set **Users can create agent blueprints** to **No**. Select **Save**. Add the people who build agents to **Copilot Agent ID Developers** | Early Nov 2026 | If you do nothing, every user can create agent blueprints (MC1506733) |
| 3 | M365 admin center → **Copilot → Cost Management → Configuration** | Open each spending policy. Turn off **Auto-apply new services**. Leave it on only for **Copilot New Services Pilot** | Now | It's on by default, so every new paid service gets added to every policy (MC1470425) |
| 4 | M365 admin center → **Copilot → Settings → All settings → Access to usage-based billing experiences** | Select **Specific users and groups**. Add **Copilot Access**. Select **Save**. You need Global Administrator | October (November for deferred tenants) | This decides who can ask for Cowork, Code and Autopilot. It replaces the old discovery setting (MC1479277) |
| 5 | SharePoint | If you used PowerShell to turn off Copilot in SharePoint, use the SharePoint & OneDrive spending policy and the site AI settings instead | Nov 1, 2026 | The PowerShell opt-out stops working (MC1479277) |

## Feature access groups

| Group | Where | What to do | Notes |
| --- | --- | --- | --- |
| Copilot Access | Entra admin center → **Groups → Copilot Access → Licenses** | Assign the Microsoft Copilot license. Keep the **Microsoft Copilot with Graph-grounded chat** service plan turned on | **E7** includes Copilot: skip the license for E7 users but keep them in the group. **E5 doesn't include Copilot**. Groups inside this group don't get licenses |
| Copilot Frontier Access | M365 admin center → **Copilot → Settings → View all → Copilot Frontier** | Select **Specific users and groups**. Add this group. Select **Save**. It can take up to 3 hours | Add people directly. Don't put other groups inside it |
| Copilot + Opal Access | M365 admin center → **Copilot → Settings → Opal (Frontier)** | Add this group. Then finish setup in the Opal Admin Portal | The group owner must also be a member. Confirmed in your tenant |
| Copilot Studio Access | Entra admin center → **Groups → Licenses**; Power Platform admin center → **Environments → [environment] → Edit → Security group** | Assign the Copilot Studio license. Set this group as the environment's security group | |
| Copilot Pilot Ring | Any setting in this guide | Add it next to the main group when you test a new setting | It's also the only group in the New Services Pilot spending policy |

**Groups we removed.** Update-CopilotGroupCleanup.ps1 deletes these:

- **Copilot + Cowork Access.** Cowork access now comes only from the Cowork spend groups. To give people a Cowork plugin, go to **Agents → Tools → [plugin] → Installed for** and pick the Limited, Unlimited and Temp spend groups.
- **Copilot + Code Access.** Code access will come from a Code spending policy, the same way as Cowork.
- **Copilot Preview Models Access.** Use Copilot Independent Processor Models Access instead.

**Copilot Code: wait for it.** Code reaches Frontier tenants later in October 2026 (MC1479277), but it isn't in your tenant yet. When Code shows up in the spending policy wizard:

1. Deploy the unified Copilot app.
2. Set the app's update channel (TargetChannel) to beta.
3. Run `New-CopilotGroups.ps1 -IncludeCodeGroups` and `New-CopilotAccessPackages.ps1 -IncludeCodePackages`.
4. Create the Code spending policies in the policy table below.

## Spend groups and spending policies

A spending policy decides two things: who can use a paid Copilot service, such as Cowork, and how many credits they can spend. Anyone in a policy can use its services, even if the limit is tiny. To keep someone out of a service, take them out of every policy that includes it.

Create policies in M365 admin center → **Copilot → Cost Management → Configuration → + Add spending policy**.

- Make one policy for each group in the policy table below.
- Turn off **Auto-apply new services** on every policy except Copilot New Services Pilot. Older Microsoft pages call this setting **Allow new Agents and services as they become available**.
- **Check the default policy first.** If it covers all users and has services checked, everyone can use those services. Uncheck the services and turn off Auto-apply.

### What each service is

| Service in the wizard | Who uses the credits | Notes |
| --- | --- | --- |
| Microsoft Copilot (expand it) | Licensed Copilot users | Holds Cowork, Code, Advanced work in SharePoint and Advanced work in OneDrive. Expand it and check only what each policy needs |
| Work IQ API for custom apps and agents | People using custom agents or apps that read Microsoft 365 data through Work IQ | Copilot Chat and Microsoft's own agents don't use these credits. Work IQ used inside Cowork is billed to Cowork |
| Copilot Managed Runtime | People running apps built in Cowork, Copilot Studio or the command line | 0.1 credit per call. No Copilot license needed. Power Apps Premium users don't use credits until they pass their request limits |
| Teams Phone Agent | Teams Phone Agent resource accounts, not people | When credits run out, it acts like a plain auto attendant. All accounts in one group share one policy |

### Policy layout

| Policy name | Check these services | Group | Per-user limit | Owner |
| --- | --- | --- | --- | --- |
| Cowork – Limited | Cowork | Copilot + Cowork Spend Limit | On (at least 2,000 credits a month, per Microsoft) | Copilot program owner |
| Cowork – Unlimited | Cowork | Copilot + Cowork Spend Unlimited | Off | Copilot program owner |
| Cowork – Temporary Unlimited | Cowork | Copilot + Cowork Spend Unlimited Temp | Off. Set a policy limit and an alert | Copilot program owner |
| SharePoint & OneDrive advanced work | Advanced work in SharePoint, Advanced work in OneDrive | Copilot SharePoint OneDrive Advanced Access | On | Copilot program owner |
| Work IQ API | Work IQ API for custom apps and agents | Copilot Work IQ API Access | On | App platform / Power Platform team |
| Managed Runtime | Copilot Managed Runtime | Copilot Managed Runtime Access | On | App platform / Power Platform team |
| Teams Phone Agent | Teams Phone Agent | Copilot Teams Phone Agent Accounts (resource accounts only) | Optional | Teams voice admins |
| Copilot New Services Pilot | None. Auto-apply new services **on** | Copilot Pilot Ring | On | Copilot program owner |
| Code – Limited / Unlimited | *Wait for Code* | Copilot + Code Spend Limit / Unlimited | On / Off | Copilot program owner |

Need different budgets for different phone agents? Make one group and one policy per budget. Keep the Teams Phone Agent group's owners to a few people, and don't put it in an access package, because its members are resource accounts.

### New services pilot (Copilot Pilot Ring)

**Auto-apply new services** adds each new paid service Microsoft releases to that policy. Use it in one small policy only, so a few testers see new services first.

1. Create a policy named **Copilot New Services Pilot**.
2. Scope it to **Copilot Pilot Ring** (a few IT and power users).
3. Check no services. If the wizard needs one, pick a low-risk service the testers already have.
4. Turn **Auto-apply new services** on.
5. Turn the per-user limit on. Set a small monthly policy limit and an alert to the Copilot program owner.

When Message Center announces a new paid service, test it with the pilot ring. If it works for you, add it to the main policies yourself.

- **The pilot ring gets new services before anyone reviews them.** Keep the group small and review it every quarter.
- **Some new services are for resource accounts, not people,** like Teams Phone Agent. Check what was added after each release.

If you don't want anything added automatically, skip this policy.

### Temporary unlimited Cowork (30 days)

People in the Limited group can ask for unlimited Cowork for 30 days. Entra removes it on day 30. Only Limited group members can see the request.

| Piece | Setting |
| --- | --- |
| Group | Copilot + Cowork Spend Unlimited Temp |
| Spending policy | **Cowork – Temporary Unlimited**: Cowork only; this group; per-user limit **off**; a monthly policy limit and an alert to the Copilot program owner; Auto-apply new services **off** |
| Access package | Copilot + Cowork Access (Temporary Unlimited, 30 days). It adds people to the Temp group only |
| Who can ask | Members of **Copilot + Cowork Spend Limit** only. Nobody else sees it in My Access |
| Approval | Manager, then the approver group |
| How long | 30 days. People can't extend it or pick dates. Access ends on its own |
| Can't be combined with | Copilot + Cowork Access (Unlimited) |

- **They stay in Limited.** While someone is in both policies, the higher limit wins. After 30 days they're back on their Limited limit.
- **Only the Temp group is removed** at the end. Their other groups don't change.
- **They can ask again.** If someone asks often, move them to Unlimited.
- **There's no per-user limit for 30 days.** The policy limit and alert are your safety net.
- **Test this with one person first.** Credits now follow a person between policies (MC1470425). What they spend while unlimited might count against their Limited limit afterward and block them until next month.

### Model profiles (Cowork)

A model profile is a list of models. Attach one to a Cowork spending policy to control which models those users can pick and which models Auto can use.

1. Go to **Copilot → Cost Management → Configuration → Model profiles**.
2. Select **Add model profile**.
3. Pick at least two models. Select **Save**.
4. Open each Cowork policy and select the profile.

A profile can't turn on a provider that's turned off in the AI provider settings below.

| Policy | Profile to use |
| --- | --- |
| Cowork – Limited | Lower-cost models, and allow Microsoft to swap in a similar model |
| Cowork – Unlimited | Default models |
| Cowork – Temporary Unlimited | Same as Limited, unless the person asked for a specific model |

### Credit requests

People without a spending policy see a **Request access** button on Cowork, Code and Autopilot. Set up two things:

1. **Choose who can ask.** Go to **Copilot → Settings → All settings → Access to usage-based billing experiences**. Select **Specific users and groups**, add **Copilot Access**, and select **Save**. You need Global Administrator. It can take up to 24 hours.
2. **Send requests to your access package.** Go to **Copilot → Cost Management → Credit requests → Request policies → Add request policy**. Pick **Cowork**. For the redirect URL, paste the My Access link for **Copilot + Cowork Access (Limited)**. Select **Save**.

Requests then go through the access package approval. The admin center marks them **Handled externally**.

### Who can manage the policies

| Task | Roles |
| --- | --- |
| Create a spending policy or set a billing method | Global Administrator, Billing Administrator |
| Change policies, limits and alerts | AI Administrator, License Administrator |
| View spending only | AI Reader, Global Reader, other reader roles |

For the Teams Phone Agent policy, try Billing Administrator first. If that fails, use AI Administrator; Microsoft's guides disagree on this one.

### When a person is in more than one policy

- **Access:** they get every service from every policy they're in.
- **Limits:** the highest per-user limit wins. If that's a tie, the biggest policy limit wins, then the newest policy.
- **Removing access:** take them out of every policy with that service. Lowering their limit doesn't remove access.

Keep each person in only Limited or Unlimited for a service. The access packages enforce this.

## Model access groups

The M365 admin center has two pages for AI providers:

- **AI providers operating as Microsoft subprocessors:** Microsoft's terms and data protection apply. AI Administrator can change it.
- **AI providers for other large language models:** the provider's own terms apply, not Microsoft's. You need Global Administrator and a legal sign-off.

Both pages accept groups inside groups, up to 999 per provider.

| Group | Where | What to do |
| --- | --- | --- |
| Copilot Anthropic Models Access | **Copilot → Settings → View all → AI providers operating as Microsoft subprocessors → Anthropic** | Select **Specific users and groups**. Add this group. Select **Save**. For Copilot Studio, also allow external models in the Power Platform admin center |
| Copilot OpenAI Models Access | Same page → **OpenAI** | Select **Specific users and groups**. Add this group. Select **Save** |
| Copilot SpaceXAI Models Access | Same page → **SpaceXAI** | Select **Specific users and groups**. Add this group. Select **Save**. It's off by default and Frontier only. It adds Grok to Word, Excel and PowerPoint. Not available in the EU, EFTA, UK or government clouds |
| Copilot Independent Processor Models Access | **Copilot → Settings → View all → AI providers for other large language models → [provider]** | Get legal and privacy sign-off. Accept the provider's terms. Add this group. Select **Save** |

**Models that keep your data.** Some models, like Claude Fable 5, keep your data at the provider. Use the Independent Processor group for them. They're off by default. Claude Fable 5.1 without data retention uses the normal Anthropic setting. *Unconfirmed:* Microsoft doesn't name the page for other preview models yet. Don't use the Pilot Ring for these models, because sending data outside Microsoft's terms is a legal decision.

New models, like GPT-6.1 Sol and Claude Sonnet 5.5, follow the OpenAI and Anthropic settings above.

## Capability and exception groups

| Group | Where | What to do |
| --- | --- | --- |
| Copilot + Cowork Browser Access | M365 admin center → **Copilot → Settings → View all → Cowork settings** (in your tenant: **Copilot → Cowork → Settings → Cowork**) | Turn on **Allow Cowork to use the Microsoft Edge browser**. Add this group. Select **Save** |
| Copilot + Cowork Browser Access (devices) | Intune admin center → **Devices → Configuration → [Edge profile] → Assignments** | Set the Edge policy `CopilotCoworkToolActionsEnabled`. Assign the profile to this group. Needs Edge 152 or later |
| Copilot Advanced Package Upload Access | M365 admin center → **Copilot → Settings → View all → Advanced package uploads** | Select **Specific users or groups**. Add this group. Select **Save**. Do this before Oct 25, 2026 |
| Copilot Agent Sharing Access | M365 admin center → **Agents → Settings → Sharing** | Select **Specific users**. Add this group. Select **Save** |
| Copilot Teams Policy Exceptions | Teams admin center → **Meetings → Meeting policies** (and **Voice → Calling policies**) **→ Group policy assignment** | Assign the special Copilot policy to this group. Add people directly; groups inside this group are ignored |
| Copilot Cloud Policy Exceptions | Microsoft 365 Apps admin center (config.office.com) → **Customization → Policy Management → [new policy] → Scope** | Scope the policy to this group. Give it a lower priority number than the all-users policy, so it wins |
| Copilot App Builder Access | Power Platform command line (pac) | Run `pac admin update-tenant-settings --setting-name powerPlatform.powerapps.enabledGroupsManagedAppsMcsPreview --setting-value '<group object ID>'`. This limits who can build apps in Copilot Studio. App building in Cowork uses Copilot Frontier Access instead |

The Copilot Code exemption group waits with the other Code groups.

For agent settings (who can build, share, publish and receive agents), see the [Copilot Agent Delegation Guide](../Agents/readme.md).

## Admin groups

Admin groups use **PIM for Groups** (New-CopilotAdminPim.ps1). The group always holds the role. People are *eligible* members: they turn the role on when they need it, for a few hours, with MFA and a reason. To give roles without PIM, run New-CopilotGroups.ps1 with `-AssignRoles`.

| Group | Entra role(s) | How long it stays on | What it's for |
| --- | --- | --- | --- |
| Copilot Platform Admin | AI Administrator, Billing Administrator, Agent ID Administrator, Office Apps Administrator, Compliance Administrator, Teams Administrator, SharePoint Administrator, Power Platform Administrator, Message Center Reader, Service Support Administrator | 4 hours, needs approval | Every Copilot admin center, Message Center and support tickets |
| Copilot Delegated Admin | AI Administrator | 8 hours, needs approval | M365 admin center → Copilot settings |
| Copilot Agent Management Admin | AI Administrator | 8 hours, needs approval | M365 admin center → Agents |
| Copilot AI Reader | AI Reader | 8 hours | Read-only view of agents, Copilot settings and spending |
| Copilot Billing Admin | Billing Administrator | 4 hours, needs approval | Creating spending policies in Copilot → Cost Management |
| Copilot Cost Reader | None | 8 hours | See the next section |
| Copilot Agent ID Admin | Agent ID Administrator | 4 hours, needs approval | Entra → Agent ID |
| Copilot Agent ID Developers | Agent ID Developer | 8 hours | Creating agent blueprints after **Users can create agent blueprints** is set to **No** |
| Copilot Office Apps Admin | Office Apps Administrator | 8 hours | Cloud Policy in config.office.com |
| Copilot Compliance Admin | Compliance Administrator | 4 hours, needs approval | Purview DLP, audit, eDiscovery, DSPM for AI |
| Copilot Teams Admin | Teams Administrator | 8 hours, needs approval | Teams admin center |
| Copilot SharePoint Admin | SharePoint Administrator | 8 hours, needs approval | SharePoint admin center |
| Copilot Studio Environment Admin | Power Platform Administrator (or a smaller environment admin role) | 8 hours, needs approval | Power Platform admin center |
| Copilot Plugin Approvers | None | 8 hours | See the next section |

## Groups with no setting yet

Microsoft doesn't have a setting for these groups yet.

| Group | Why | What to do for now |
| --- | --- | --- |
| Copilot + Autopilot Access | Autopilot is the new name for Microsoft Scout (MC1479277). It's Frontier only and uses a spending policy, but Microsoft hasn't released its admin settings yet. The Scout preview needed Intune policies and an admin sign-off (MC1332811) | Keep the group. Its access package also adds Copilot Access and Copilot Frontier Access. When Autopilot appears in the spending policy wizard, create a policy for this group |
| Copilot Cost Reader | No role can view spending without also seeing other things | Give it AI Reader, or delete it and use Copilot AI Reader |
| Copilot Plugin Approvers | Tenant admins approve plugin requests. The new plugin registry under **Agents → Tools** (MC1484008) has no approver setting | Use it as a mailing or ticket queue, or give it AI Administrator |

## Other Message Center changes (checked Oct 16, 2026)

I checked every Copilot post in Message Center from July 1 to Oct 16, 2026, plus the M365 roadmap and Learn. These changes are already worked into the sections above.

| Change | Post | What it means for you |
| --- | --- | --- |
| Spending policies can use a model profile (Cowork only) | MC1479276 | You can limit which models each Cowork policy uses. See Model profiles |
| Credit requests can go to your own approval process | MC1470425 | Send Cowork requests to the Cowork (Limited) access package. See Credit requests |
| Credits follow a person when they move between policies | MC1470425 | Test the 30-day temporary tier with one person first |
| Code comes to Frontier tenants later in October | MC1479277 | Wait for Code to appear in the wizard. Deploy the unified Copilot app with the beta channel first |
| Autopilot (formerly Scout) uses a spending policy; admin settings not out yet | MC1479277, MC1332811 | Keep the Autopilot group. Its package adds Frontier |
| App building in Copilot Studio is on by default and can be limited to groups | MC1469329 | Use the new Copilot App Builder Access group |
| Cowork browser use can be limited to groups | MC1474461 | Confirms the Cowork Browser Access row |
| SpaceXAI setting: Frontier only, off by default, can be limited to groups | MC1474124 | Confirms the SpaceXAI row |
| GPT-6.1 Sol and Claude Sonnet 5.5 follow the OpenAI and Anthropic settings | MC1483844 | Your model groups still decide who gets them |
| A **Plugins** button replaces the Agents, Agents & Skills and Customize buttons | MC1484008 | Admins still deploy plugins from Agents → Tools. Update user training |
| The **Microsoft Copilot with Graph-grounded chat** service plan now controls full vs basic Copilot | MC1405498 | Don't turn that plan off in the Copilot Access license |
| Copilot connectors follow **Allowed agent types**; the old setFederatedConnectors switch is gone | MC1454973 | Check **Agents → Settings → Allowed agent types** |
| Legal plugins in Word and Cowork; the Legal Agent is retiring | MC1509799 | You can only turn these on or off for everyone: the Cowork for Legal plugin in the M365 admin center, and Legal Skills in the Apps admin center |

## Sources

- [Get started with the Microsoft Frontier Program](https://learn.microsoft.com/microsoft-365/admin/manage/get-started-frontier)
- [Get started with Opal in Microsoft Copilot](https://learn.microsoft.com/microsoft-365/copilot/opal-settings-manage)
- [Manage Copilot Cowork for your organization](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-admin-governance)
- [Manage plugins for Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-manage-plugins)
- [Use the local browser with Copilot Cowork](https://learn.microsoft.com/microsoft-365/copilot/cowork/cowork-local-browser)
- [Managing AI experiences enabled by usage-based billing](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-manage-copilot-credits)
- [Set up usage-based billing for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup)
- [Manage Copilot Code for your organization](https://learn.microsoft.com/copilot/code/code-admin)
- [Secure local execution in Copilot Code](https://learn.microsoft.com/copilot/code/code-secure-local-execution)
- [Anthropic models in Microsoft Online Services](https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-subprocessor)
- [OpenAI as a subprocessor](https://learn.microsoft.com/microsoft-365/copilot/openai-subprocessor)
- [Manage preview AI models](https://learn.microsoft.com/microsoft-365/copilot/manage-preview-ai-models)
- [Manage Microsoft Copilot settings in the M365 admin center](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-page)
- [Agent settings in Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-settings)
- [Manage Copilot in Teams meetings](https://learn.microsoft.com/microsoftteams/copilot-teams-transcription)
- [Admin policies for Copilot Pages and Notebooks (Cloud Policy scoping)](https://learn.microsoft.com/microsoft-365/loop/cpcn-admin-configuration)
- [Understand usage-based billing and cost management for Copilot Credits](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-overview-copilot-credits)
- [Understand costs for Business Applications in Work IQ](https://learn.microsoft.com/power-platform/admin/business-applications-work-iq/understand-costs)
- [Copilot Managed Runtime licensing FAQ](https://learn.microsoft.com/microsoft-365/admin/manage/apps/licensing-faq)
- [Setup – Teams Phone Agent – Usage-based billing](https://learn.microsoft.com/microsoftteams/aa-cq-setup-teams-phone-agent-ubb)
- [Connect to SpaceXAI models (as an independent processor)](https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-models)
- [SpaceXAI as a subprocessor in Microsoft Online Services](https://learn.microsoft.com/microsoft-365/copilot/spacexai-subprocessor)
- [Assign AI provider access to users and groups](https://learn.microsoft.com/microsoft-365/copilot/copilot-ai-provider-user-sec-group-access)
- [License options for Microsoft Copilot (E7 includes Copilot)](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-licensing)
- [Create assignmentPolicies (specificAllowedTargets)](https://learn.microsoft.com/graph/api/entitlementmanagement-post-assignmentpolicies)
- [MC1470425 Cost Management September updates](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1470425)
- [MC1479276 Copilot pricing model and FinOps](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1479276)
- [MC1479277 Home, Code, Autopilot, request access](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1479277)
- [MC1472007 Advanced package uploads](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1472007)
- [MC1506733 Who can create agents in Entra](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1506733)
- [MC1474461 Cowork browser use admin control](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1474461)
- [MC1474124 SpaceXAI subprocessor setting](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1474124)
- [MC1469329 Build apps in Copilot Studio and Cowork](https://admin.microsoft.com/?ref=MessageCenter/:/messages/MC1469329)
- [Access requests to usage-based billing experiences](https://learn.microsoft.com/microsoft-365/copilot/request-access-usage-based-billing-experiences)
- [Configure model profiles](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-setup#configure-model-profiles)
- [Custom request policies](https://learn.microsoft.com/microsoft-365/copilot/usage-based-billing-copilot-credits-monitor-spending#configure-custom-request-policies)
- [Manage Copilot Code for your organization](https://learn.microsoft.com/copilot/code/code-admin)
- [Copilot Managed Runtime: scope app creation](https://learn.microsoft.com/microsoft-365/admin/manage/apps/?view=o365-worldwide#enable-copilot-managed-runtime-for-your-tenant)
- [Manage preview AI models](https://learn.microsoft.com/microsoft-365/copilot/manage-preview-ai-models)
