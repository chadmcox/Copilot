# Copilot Group Assignment Guide

Oct 16, 2026 · @Chad Cox

Each group from New-CopilotGroups.ps1 is listed with the portal, path and setting where you select it. Membership is managed by the access packages from New-CopilotAccessPackages.ps1, so after this one-time setup you change who has access through packages, not these settings. Paths marked *unconfirmed* aren't fully documented by Microsoft yet; verify them in your tenant.

## Feature access groups

| Group | Portal | Path | What to set |
| --- | --- | --- | --- |
| Copilot Access | Entra admin center | Groups → Copilot Access → Licenses → Assignments | Assign the Microsoft 365 Copilot license (group-based licensing) |
| Copilot Frontier Access | M365 admin center | Copilot → Settings → View all → Copilot Frontier | Specific users and groups → add this group. Takes up to 3 hours |
| Copilot + Opal Access | M365 admin center | Copilot → Settings → Opal (Frontier) | Select this group; then finish setup in the Opal Admin Portal. The group's owner must also be a member |
| Copilot + Cowork Access | M365 admin center | Agents → Tools (or All agents) → \[Cowork plugin\] → Installed for | Specific users/groups → this group, for plugins every Cowork user should get. Access itself comes from the spend groups (next section) |
| Copilot + Code Access | M365 admin center | Copilot → Settings → View all → search “Code” *(unconfirmed)* | Code's documented controls are org-wide; access comes from the Code spend groups plus Frontier. Use this group for reporting or nesting |
| Copilot Studio Access | Entra admin center; Power Platform admin center | Groups → Licenses; PPAC → Environments → \[environment\] → Edit → Security group | Assign the Copilot Studio user license; set as the environment's security group for makers |
| Copilot Pilot Ring | Several | Any group-scoped setting below | Add alongside the production group when piloting a new setting |

## Spend groups and spending policies

Every spending policy is created in **M365 admin center → Copilot → Cost Management → Configuration → + Add spending policy**. A policy is both a budget and an access grant: anyone in scope of a policy that checks a service can use it, however small the limit. Build one policy per audience, with its own group, and turn **Allow new Agents and services as they become available** off on every policy.

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
| Code – Limited | Code | Copilot + Code Spend Limit | On | Copilot program owner |
| Code – Unlimited | Code | Copilot + Code Spend Unlimited | Off | Copilot program owner |
| SharePoint & OneDrive advanced work | Advanced work in SharePoint, Advanced work in OneDrive | Copilot SharePoint OneDrive Advanced Access *(new group)* | On | Copilot program owner |
| Work IQ API | Work IQ API for custom apps and agents | Copilot Work IQ API Access *(new group)* | On | App platform / Power Platform team |
| Managed Runtime | Copilot Managed Runtime | Copilot Managed Runtime Access *(new group)* | On | App platform / Power Platform team |
| Teams Phone Agent | Teams Phone Agent only | Copilot Teams Phone Agent Accounts *(new group, resource accounts only)* | Optional, per resource account | Teams voice admins |

For different budgets per phone agent, create one group and policy per budget tier. Keep the number of owners on the Teams Phone Agent group small, per Microsoft's setup guide. Keep that group out of access packages, since its members are resource accounts.

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

| Group | Portal | Path | What to set |
| --- | --- | --- | --- |
| Copilot Anthropic Models Access | M365 admin center | Copilot → Settings → View all → AI providers operating as Microsoft subprocessors → Anthropic | Choose who can access → Specific users and groups → this group. For Copilot Studio, also allow external LLMs in PPAC |
| Copilot OpenAI Models Access | M365 admin center | Same page → OpenAI | Specific users and groups → this group |
| Copilot Preview Models Access | M365 admin center | Copilot → Settings → View all → search “preview” *(label unconfirmed)* | Restrict preview / data-retention models to this group |

## Capability and exception groups

| Group | Portal | Path | What to set |
| --- | --- | --- | --- |
| Copilot + Cowork Browser Access | M365 admin center | Copilot → Settings → View all → Cowork settings → Allow browser access | Allow Cowork to use Edge → scope to this group |
| Copilot + Cowork Browser Access (devices) | Intune admin center | Devices → Configuration → profile with Edge policy `CopilotCoworkToolActionsEnabled` → Assignments | Include this group (Edge 152+) |
| Copilot Advanced Package Upload Access | M365 admin center | Copilot → Settings → View all → Advanced package uploads | Specific users or groups → this group |
| Copilot Agent Sharing Access | M365 admin center | Agents → Settings → Sharing | Specific users → this group |
| Copilot + Code Secure Execution Exemption | M365 admin center | Copilot Code policy → Policy exemption group *(path unconfirmed)* | Set this group as the exemption group |
| Copilot Teams Policy Exceptions | Teams admin center | Meetings → Meeting policies (and Voice → Calling policies) → Group policy assignment | Assign the non-default Copilot policy to this group |
| Copilot Cloud Policy Exceptions | Microsoft 365 Apps admin center (config.office.com) | Customization → Policy Management → new policy → Choose the scope | Scope to this group at a lower priority number than the all-users policy |

## Admin groups

Assign each role in **Entra admin center → Roles & admins → \[role\] → Add assignments → select the group**, or as an eligible assignment in **Privileged Identity Management → Microsoft Entra roles**. Running New-CopilotGroups.ps1 with `-AssignRoles` does this for you (as active assignments).

| Group | Entra role | Where the role is used |
| --- | --- | --- |
| Copilot Delegated Admin | AI Administrator | M365 admin center → Copilot settings |
| Copilot Agent Management Admin | AI Administrator | M365 admin center → Agents |
| Copilot AI Reader | AI Reader | Agents registry and Copilot settings, read-only |
| Copilot Billing Admin | Billing Administrator | Copilot → Cost Management |
| Copilot Agent ID Admin | Agent ID Administrator | Entra → Agent ID |
| Copilot Office Apps Admin | Office Apps Administrator | config.office.com Cloud Policy |
| Copilot Compliance Admin | Compliance Administrator | Purview DLP, audit, eDiscovery, DSPM for AI |
| Copilot Teams Admin | Teams Administrator | Teams admin center |
| Copilot SharePoint Admin | SharePoint Administrator | SharePoint admin center |
| Copilot Studio Environment Admin | Power Platform Administrator (tenant-wide), or an environment admin security role in PPAC for narrower scope | Power Platform admin center |

## Groups with no direct setting yet

These four groups have no Microsoft 365 setting that takes them as a scope, as far as Microsoft's documentation shows today.

| Group | Why | Suggested use |
| --- | --- | --- |
| Copilot + Autopilot Access | No Microsoft 365 Copilot feature called Autopilot was found. GitHub Copilot CLI's Autopilot mode is governed in GitHub, which has no Entra-group setting. Windows Autopilot is device enrollment | Confirm the product. If it's GitHub, sync the group to a GitHub team (Enterprise Managed Users) and grant Copilot seats to that team |
| Copilot Cost Reader | Cost Management mentions reader roles for consumption views but doesn't name a specific Entra role | Check the “Roles and requirements” section of Microsoft's Copilot Credits setup article, then assign that role |
| Copilot Plugin Approvers | Org-wide publish requests are approved by tenant admins; no approver-group setting is documented | Use as the notification or ticket queue, or give it AI Administrator |
| Copilot Pilot Ring | Not a setting of its own | Add it next to the production group in any scoped setting above |

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
