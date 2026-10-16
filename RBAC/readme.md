# Copilot Group Assignment Guide

Oct 16, 2026 · @Chad Cox

Each group from New-CopilotGroups.ps1 is listed with the portal, path and setting where you select it. Membership is managed by the access packages from New-CopilotAccessPackages.ps1, so after this one-time setup you change who has access through packages, not these settings. Paths marked *unconfirmed* aren't fully documented by Microsoft yet; verify them in your tenant.

## Scripts in this folder

All four scripts use Microsoft Graph only (`Connect-MgGraph` + `Invoke-MgGraphRequest`, from the Microsoft.Graph.Authentication module) and support `-WhatIf`. Run each one with `-WhatIf` first.

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

## What Message Center adds (checked October 16, 2026)

I checked every Copilot post in Message Center from July 1 to today, the M365 roadmap and the current Learn pages. These items change the guide or need action, and several aren't on Learn yet.

**Act on these by the date shown**

| Change | Post | What to do | By |
| --- | --- | --- | --- |
| Advanced package uploads turn on for all users unless you pick a scope | MC1472007 | Copilot → Settings → Advanced package uploads → Specific users or groups → Copilot Advanced Package Upload Access | Oct 25, 2026 |
| Default users can create Entra agent blueprints | MC1506733 | Entra → Users → User settings → Users can create agent blueprints → No; put builders in the new Copilot Agent ID Developers group | Early Nov 2026 |
| Auto-apply new services is on by default for every spending policy, existing ones included | MC1470425 | Turn it off on every policy except Copilot New Services Pilot | Now |
| The UBB discovery setting is being removed and replaced by Access to usage-based billing experiences | MC1479277 | Copilot → Settings → All settings → Access to usage-based billing experiences → Specific users and groups → Copilot Access (Global Administrator only) | Oct (deferred: Nov) |
| SharePoint PowerShell opt-outs for Copilot in SharePoint stop being honored | MC1479277 | Control advanced SharePoint work with its spending policy and the site AI settings | Nov 1, 2026 |

**Changes that update the design**

| Change | Post | Effect on this guide |
| --- | --- | --- |
| Spending policies can apply a model profile (Cowork only) | MC1479276 | Each Cowork policy can limit models and what Auto picks; see Model profiles below |
| Custom request policies route credit requests to your own workflow | MC1470425 | Point Cowork requests at the Cowork (Limited) access package; see Credit requests below |
| Credits a user spent follow them when they move between policies | MC1470425 | Affects the 30-day temporary tier; see its notes |
| Code reaches Frontier tenants later in October and is billed through a spending policy | MC1479277 | Code groups stay on hold until Code appears in your wizard; deploy the unified Copilot app with TargetChannel beta first |
| Autopilot is the renamed Microsoft Scout, also billed through a spending policy; admin controls not published yet | MC1479277, MC1332811 | Autopilot group now has a target; package adds Frontier |
| App building in Copilot Studio is on by default and can be limited to security groups | MC1469329 | New Copilot App Builder Access group |
| Cowork browser use can be scoped to groups (GA) | MC1474461 | Confirms the Cowork Browser Access row |
| SpaceXAI subprocessor setting (Frontier, off by default, group scoping) | MC1474124 | Confirms the SpaceXAI row |
| GPT-6.1 Sol and Claude Sonnet 5.5 depend on the OpenAI and Anthropic subprocessor settings | MC1483844 | Model groups still decide access |
| Plugins replace the Agents, Agents & Skills and Customize buttons; plugin registry lives under Agents → Tools | MC1484008 | Plugin deployment path unchanged; update user training |
| The Microsoft Copilot with Graph-grounded chat service plan decides Premium vs Basic grounding | MC1405498 | Don't disable that plan in the Copilot Access license assignment |
| Copilot connectors follow Allowed agent types; the setFederatedConnectors toggle is retired | MC1454973 | Review Agents → Settings → Allowed agent types |
| Legal plugins in Word and Cowork; Legal Agent retiring | MC1509799 | Tenant-wide on/off only (Cowork for Legal plugin; Legal Skills in the Apps admin center); no group scoping documented |

## Feature access groups

| Group | Portal | Path | What to set | Notes |
| --- | --- | --- | --- | --- |
| Copilot Access | Entra admin center | Groups → Copilot Access → Licenses → Assignments | Assign the Microsoft Copilot license (group-based licensing) | If users get Copilot through Microsoft 365 **E7**, the license comes with E7: skip this assignment and keep the group as the base scope. **E5 doesn't include Copilot**, so E5 users still need the add-on license. Licensing ignores nested groups. Keep the Microsoft Copilot with Graph-grounded chat service plan on: it now decides Premium vs Basic grounding (MC1405498) |
| Copilot Frontier Access | M365 admin center | Copilot → Settings → View all → Copilot Frontier | Specific users and groups → this group. Takes up to 3 hours | Don't nest other groups in it: the Opal, SpaceXAI and Code access packages add people to it directly, and Microsoft doesn't document nested-group support for this setting |
| Copilot + Opal Access | M365 admin center | Copilot → Settings → Opal (Frontier) | Select this group; then finish setup in the Opal Admin Portal. The group's owner must also be a member | Confirmed in tenant |
| Copilot Studio Access | Entra admin center; Power Platform admin center | Groups → Licenses; PPAC → Environments → \[environment\] → Edit → Security group | Assign the Copilot Studio user license; set as the environment's security group for makers |  |
| Copilot Pilot Ring | Several | Any group-scoped setting below | Add alongside the production group when piloting a new setting. Also the only scope of the New Services Pilot spending policy, which auto-enrolls new credit-billed services |  |

**Removed groups.** *Copilot + Cowork Access* is gone: Cowork access comes only from the Cowork spend groups, so deploy Cowork plugins (Agents → Tools → plugin → Installed for) to the Limited, Unlimited and Temp spend groups instead. *Copilot + Code Access* is gone because Code access comes from a Code spending policy, the same way Cowork does.

**Copilot Code is on hold.** Learn now lists Code as a credit-billed service with a secure-execution exemption group, and MC1479277 says Code reaches Frontier tenants later in October. Neither shows in your tenant yet. Before you turn it on, deploy the unified Copilot app and set its update TargetChannel to beta. The Code spend and exemption groups and packages are only created with `-IncludeCodeGroups` and `-IncludeCodePackages`.

## Spend groups and spending policies

Every spending policy is created in **M365 admin center → Copilot → Cost Management → Configuration → + Add spending policy**. A policy is both a budget and an access grant: anyone in scope of a policy that checks a service can use it, however small the limit. Build one policy per audience, with its own group, and turn **Allow new Agents and services as they become available** (the wizard now calls it Auto-apply new services) off on every policy except the pilot policy below. It's on by default for every policy, including ones you already have (MC1470425).

**Check the default policy first.** If the all-users default policy has every service checked and “Allow new” on, everyone can use Cowork and Code, and future credit-billed services join automatically. Uncheck the services there and turn the toggle off.

### What each service in the policy wizard is

| Service (checkbox) | Who consumes credits | Notes |
| --- | --- | --- |
| Microsoft Copilot (expandable) | Licensed Copilot users | Contains Cowork, Code, Advanced work in SharePoint, Advanced work in OneDrive. Expand it and check only the child each policy should grant |
| Work IQ API for custom apps and agents | People using custom agents built in Copilot Studio, Foundry or third-party platforms grounded in M365 data; coding agents calling Work IQ directly | Not charged for Copilot Chat or Microsoft prebuilt agents; Work IQ used inside Cowork is billed to Cowork |
| Copilot Managed Runtime | People running internal apps built in Cowork, Copilot Studio or the CLI | 0.1 credit per API call; no Copilot license needed; Power Apps Premium users don't consume credits up to their request limits. Building apps is billed through the creator's Cowork policy or PPAC |
| Teams Phone Agent | Teams Phone Agent resource accounts, not people | Out of credits = falls back to a plain auto attendant. All accounts in one group share one policy |

### Policy layout

| Policy | Services checked | Scope group | Per-user limit | Owner |
| --- | --- | --- | --- | --- |
| Cowork – Limited | Cowork | Copilot + Cowork Spend Limit | On (≥ 2,000 credits/month per Microsoft guidance) | Copilot program owner |
| Cowork – Unlimited | Cowork | Copilot + Cowork Spend Unlimited | Off | Copilot program owner |
| Cowork – Temporary Unlimited | Cowork | Copilot + Cowork Spend Unlimited Temp (30-day access package) | Off; set a policy-level cap and alert | Copilot program owner |
| SharePoint & OneDrive advanced work | Advanced work in SharePoint, Advanced work in OneDrive | Copilot SharePoint OneDrive Advanced Access | On | Copilot program owner |
| Work IQ API | Work IQ API for custom apps and agents | Copilot Work IQ API Access | On | App platform / Power Platform team |
| Managed Runtime | Copilot Managed Runtime | Copilot Managed Runtime Access | On | App platform / Power Platform team |
| Teams Phone Agent | Teams Phone Agent only | Copilot Teams Phone Agent Accounts (resource accounts only) | Optional, per resource account | Teams voice admins |
| Copilot New Services Pilot | None; Allow new Agents and services **on** | Copilot Pilot Ring | On | Copilot program owner |
| Code – Limited / Unlimited | *On hold: Code isn't selectable in the wizard yet* | Copilot + Code Spend Limit / Unlimited (`-IncludeCodeGroups`) | On / Off | Copilot program owner |

For different budgets per phone agent, create one group and policy per budget tier. Keep the number of owners on the Teams Phone Agent group small, per Microsoft's setup guide. Keep that group out of access packages, since its members are resource accounts.

### New services pilot policy (Copilot Pilot Ring)

**Allow new Agents and services as they become available** is a per-policy toggle, not a group setting: everyone in that policy's scope gets each new credit-billed service Microsoft adds. Use it on purpose in one small policy only.

| Setting | Value |
| --- | --- |
| Policy name | Copilot New Services Pilot |
| Allow new Agents and services | **On** |
| Services checked | None, so it collects only newly released services. If the wizard requires one, pick a low-risk service the pilot users already have |
| Scope | Copilot Pilot Ring (a handful of IT and power users) |
| Per-user limit | On |
| Policy limit and alert | Modest monthly cap; alert to the Copilot program owner |

Every other policy, including the default all-users policy, keeps the toggle **off**. When Microsoft releases a new service, only the pilot ring gets it; after evaluation, add it to production policies on purpose and create a group for it if it needs its own audience.

- **It grants access, not only spend.** The pilot ring can use a new service before anyone has reviewed it. Keep the group small and include it in a quarterly access review.
- **Some new services won't fit users.** Services like Teams Phone Agent are scoped to resource accounts; check what joined the policy after each release.
- **Watch Message Center.** New credit-billed services are announced there; whoever holds Message Center Reader (the Copilot Platform Admin group) reviews the pilot policy when one is announced.

To avoid auto-enrollment entirely, skip this policy and turn the toggle off everywhere.

### Temporary unlimited Cowork (30 days)

People on the Limited tier can request unlimited Cowork spend for 30 days, and Entra removes it automatically. Nobody has to remember to take it away, and nobody outside the Limited tier sees the option.

| Piece | Setting |
| --- | --- |
| Group | Copilot + Cowork Spend Unlimited Temp |
| Spending policy | **Cowork – Temporary Unlimited**: Cowork only; scope = this group; per-user limit **off**; policy-level monthly cap and an alert to the Copilot program owner; Allow new Agents and services **off** |
| Access package | Copilot + Cowork Access (Temporary Unlimited, 30 days): grants only the Temp group |
| Who can see and request it | Members of **Copilot + Cowork Spend Limit** only (policy scope: specific users → members of that group). Nobody else sees it in My Access |
| Approval | Manager, then the approver group |
| Duration | Fixed 30 days; users can't extend or pick custom dates; access is removed at expiry (no access review needed) |
| Incompatible with | Copilot + Cowork Access (Unlimited) |

- **Limited stays in place.** When someone is in both the Limited and Temp policies, the highest per-user limit applies, so they're unlimited for 30 days and fall back to their Limited cap automatically at expiry.
- **Expiry removes nothing else.** The package grants only the Temp group, so Copilot Access and the Limited spend group are untouched.
- **Re-requesting is allowed** after expiry, with approval again. Track repeat requesters; they may belong in the permanent Unlimited package.
- **Spend risk:** for 30 days these users have no per-user cap, so the policy-level cap and alert are the safety net.
- **Usage carries over.** Credits a user spends follow them between policies (MC1470425). Microsoft doesn't say whether the Limited cap counts what they spent while unlimited. If it does, someone who goes past their Limited cap during the 30 days is blocked until the monthly reset. Test with one user first.

### Model profiles (Cowork)

A model profile is a reusable list of providers and models, at least two, attached to a spending policy. It limits which models Cowork users in that policy can pick and which ones Auto can choose. Create one in **Copilot → Cost Management → Configuration → Model profiles**, or in the policy wizard's Model profiles step, which only appears when Cowork is checked. A profile can't turn on a provider that the AI provider settings below have turned off.

| Policy | Suggested profile |
| --- | --- |
| Cowork – Limited | Lower-cost models, with Microsoft allowed to substitute a comparable model |
| Cowork – Unlimited | Default model selection |
| Cowork – Temporary Unlimited | Same as Limited, unless the request is for a specific model |

### Credit requests

Users without a spending policy now see Cowork, Code and Autopilot with a Request access button. Two settings control what happens next:

- **Who can request:** Copilot → Settings → All settings → Access to usage-based billing experiences → Specific users and groups → Copilot Access, so only licensed users can ask. Global Administrator only; up to 24 hours to apply. This replaces the deprecated discovery setting.
- **Where requests go:** Copilot → Cost Management → Credit requests → Request policies → Add request policy → Cowork → redirect URL = the My Access link for Copilot + Cowork Access (Limited). Requests then go through the package's approval, and the admin center marks them Handled externally.

### Who can manage the policies

| Action | Roles |
| --- | --- |
| Create a spending policy, set billing methods | Global Administrator, Billing Administrator |
| Edit policies, limits and alerts | AI Administrator, License Administrator |
| View consumption only | AI Reader, Global Reader, other supported reader roles |

Microsoft's Teams Phone Agent guide says creating its policy needs AI Administrator, which conflicts with the general setup article; test with Billing Administrator first.

### How overlapping policies behave

- **Access:** if any policy a user is in checks a service, they get it. A stricter policy doesn't override a looser one.
- **Limits:** when policies overlap, the highest per-user limit applies, then the largest policy limit, then the newest policy.
- **Removing access:** take the user out of every policy that checks the service; lowering a limit doesn't remove access.

Keep the Limited and Unlimited groups mutually exclusive per service; the incompatible-package setting in New-CopilotAccessPackages.ps1 enforces this for Cowork and Code.

## Model access groups

The admin center has two provider pages. **AI providers operating as Microsoft subprocessors** covers providers working under Microsoft's Product Terms and DPA (AI Administrator can configure). **AI providers for other large language models** covers *independent processors*: data is processed under the provider's own terms, and Microsoft's DPA, data residency, audit commitments and SLAs don't apply (Global Administrator configures). Both accept nested groups, up to 999 user and group assignments per provider.

| Group | Portal | Path | What to set |
| --- | --- | --- | --- |
| Copilot Anthropic Models Access | M365 admin center | Copilot → Settings → View all → AI providers operating as Microsoft subprocessors → Anthropic | Specific users and groups → this group. For Copilot Studio, also allow external LLMs in PPAC |
| Copilot OpenAI Models Access | M365 admin center | Same page → OpenAI | Specific users and groups → this group |
| Copilot SpaceXAI Models Access *(new)* | M365 admin center | Same page → SpaceXAI | Specific users and groups → this group. Off by default; Frontier-only; Grok in the Word, Excel and PowerPoint model selector; not offered in the EU, EFTA, UK or government clouds |
| Copilot Independent Processor Models Access *(replaces Preview Models)* | M365 admin center | Copilot → Settings → View all → AI providers for other large language models → \[provider, e.g. SpaceXAI\] | Accept the provider's terms, then choose users → this group. Covers SpaceXAI for Cowork and Copilot Studio. Needs legal/privacy sign-off |

**Preview models.** Anthropic models with Data Retention, such as Claude Fable 5, run with Anthropic as an independent processor. They're off by default and can be scoped to specific users or groups. Fable 5.1 without retention comes under the normal Anthropic subprocessor setting. Learn still doesn't name the page for other preview models *(unconfirmed)*. Use the Independent Processor group for any data-retention model. Don't reuse the Copilot Pilot Ring for data-retention models: it already auto-enrolls new services, and sending data outside Microsoft's terms is a legal decision that needs its own audience.

## Capability and exception groups

| Group | Portal | Path | What to set |
| --- | --- | --- | --- |
| Copilot + Cowork Browser Access | M365 admin center | Copilot → Cowork → Settings → Cowork *(confirmed in tenant; MC1474461 and Learn list it as Copilot → Settings → View all → Cowork settings; group scoping is GA)* | Allow Cowork to use Edge → scope to this group |
| Copilot + Cowork Browser Access (devices) | Intune admin center | Devices → Configuration → profile with Edge policy `CopilotCoworkToolActionsEnabled` → Assignments | Include this group (Edge 152+) |
| Copilot Advanced Package Upload Access | M365 admin center | Copilot → Settings → View all → Advanced package uploads | Specific users or groups → this group before Oct 25, 2026, or uploads open to all users (MC1472007) |
| Copilot Agent Sharing Access | M365 admin center | Agents → Settings → Sharing | Specific users → this group |
| Copilot Teams Policy Exceptions | Teams admin center | Meetings → Meeting policies (and Voice → Calling policies) → Group policy assignment | Assign the non-default Copilot policy to this group (direct members only; nesting is ignored) |
| Copilot Cloud Policy Exceptions | Microsoft 365 Apps admin center (config.office.com) | Customization → Policy Management → new policy → Choose the scope | Scope to this group at a lower priority number than the all-users policy |
| Copilot App Builder Access (new) | Power Platform CLI | pac admin update-tenant-settings --setting-name powerPlatform.powerapps.enabledGroupsManagedAppsMcsPreview | This group's object ID (comma-separate several). Limits app building in Copilot Studio. App building in Cowork follows Copilot Frontier Access instead |

The Copilot Code secure-execution exemption group is on hold with the other Code groups; the setting isn't exposed in the tenant yet.

## Admin groups

Admin groups use **PIM for Groups** (New-CopilotAdminPim.ps1): each group holds its role permanently, and people are *eligible* members who activate for a few hours with MFA and a justification. To assign roles without PIM, run New-CopilotGroups.ps1 with `-AssignRoles`.

| Group | Entra role(s) | Activation | Where the role is used |
| --- | --- | --- | --- |
| Copilot Platform Admin | AI Administrator, Billing Administrator, Agent ID Administrator, Office Apps Administrator, Compliance Administrator, Teams Administrator, SharePoint Administrator, Power Platform Administrator, Message Center Reader, Service Support Administrator | 4 hours, approval | Every Copilot portal, Message Center, support tickets |
| Copilot Delegated Admin | AI Administrator | 8 hours, approval | M365 admin center → Copilot settings |
| Copilot Agent Management Admin | AI Administrator | 8 hours, approval | M365 admin center → Agents |
| Copilot AI Reader | AI Reader | 8 hours | Agent registry, Copilot settings and consumption, read-only |
| Copilot Billing Admin | Billing Administrator | 4 hours, approval | Copilot → Cost Management (creating spending policies) |
| Copilot Cost Reader | None assigned by the scripts | 8 hours | See below |
| Copilot Agent ID Admin | Agent ID Administrator | 4 hours, approval | Entra → Agent ID |
| Copilot Agent ID Developers (new) | Agent ID Developer | 8 hours | Entra → create agent blueprints once Users can create agent blueprints is set to No (MC1506733) |
| Copilot Office Apps Admin | Office Apps Administrator | 8 hours | config.office.com Cloud Policy |
| Copilot Compliance Admin | Compliance Administrator | 4 hours, approval | Purview DLP, audit, eDiscovery, DSPM for AI |
| Copilot Teams Admin | Teams Administrator | 8 hours, approval | Teams admin center |
| Copilot SharePoint Admin | SharePoint Administrator | 8 hours, approval | SharePoint admin center |
| Copilot Studio Environment Admin | Power Platform Administrator (or a narrower environment admin role in PPAC) | 8 hours, approval | Power Platform admin center |
| Copilot Plugin Approvers | None | 8 hours | See below |

## Groups with no direct setting yet

These three groups have no Microsoft 365 setting that takes them as a scope, as far as Microsoft's documentation shows today.

| Group | Why | Suggested use |
| --- | --- | --- |
| Copilot + Autopilot Access | Autopilot is the renamed Microsoft Scout (MC1479277): Frontier-only and billed by Copilot Credits through a spending policy. Microsoft hasn't published its admin controls yet. The Scout preview needed Intune policies and an admin attestation (MC1332811) | The package now adds Copilot Access, Frontier and this group. Use the group as the policy scope when Autopilot appears in the spending policy wizard |
| Copilot Cost Reader | Microsoft lists AI Reader, Global Reader and License Administrator as able to view consumption; none of them is limited to Cost Management | Assign AI Reader (least privilege), or drop this group and use Copilot AI Reader |
| Copilot Plugin Approvers | Org-wide publish requests are approved by tenant admins. The new plugin registry under Agents → Tools (MC1484008) has no approver-group setting either | Use as the notification or ticket queue, or give it AI Administrator |

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
