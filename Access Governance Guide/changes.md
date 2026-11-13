# Access Governance Guide: change history

[Back to the guide](readme.md)

## What changed on Nov 13, 2026

I checked the admin centers again. These are the differences from the Nov 10 version:

| Guide said | What the admin center shows |
| --- | --- |
| Spending policy wizard has five steps | **Six** steps. **Model template** is new, between **Limits and alerts** and **Billing method** |
| Microsoft docs no longer mention model profiles | **Configuration** has a **Model templates (Preview)** tab, and the wizard has a **Model template** step |
| Code wasn't in the wizard | **Code** is under **Microsoft Copilot**, next to Cowork |
| Opal and Intelligent call delegation weren't in the wizard | Both are there. **Intelligent Call Delegation** is the only service not checked by default |
| — | New services in the wizard: **Sales Development Agent** and **Teams Interpreter** |
| SpaceXAI is only on the independent processors page | SpaceXAI is also on the **subprocessors** page, **Disabled by default** |
| **Choose which users can access Anthropic models** | **Choose who can use models operated by Anthropic** (same for OpenAI and SpaceXAI) |
| App creation paths: **Set up**, then limit Copilot Studio to a group | **Review settings**. Copilot Studio is only **On** or **Off**; use pac to limit it to a group |
| Code page lists **Add allowed domains for GitHub** | Not shown. The Code page is a getting-started page |
| Teams → Transcript API access → **WorkIQ access** | Only **Microsoft Graph access** was shown. Use `Set-CsTeamsMeetingConfiguration -EnableWorkIQTranscriptAccess` |
| — | New **Copilot Release preferences: General Availability** setting (Standard or Deferred) |

**Design change:** Cowork and Work IQ API spending now uses four tiers (Bronze, Silver, Gold, Platinum) instead of Limited, Unlimited and Temporary Unlimited. Use one set for the organization, or one set per line of business or cost center. `New-CopilotGroups.ps1`, `New-CopilotAccessPackages.ps1` and `New-CopilotSpendingPolicies.ps1` now build the tiers, rename the old Limited/Unlimited/Temp groups, packages and policies, and take `-BusinessUnits`. `Get-CopilotSpendingReport.ps1` recognizes tier names and flags policies with no policy limit.

**Admin center limit:** spending policies made with the Graph API can't be edited in the admin center ("cannot be modified through the legacy configuration-plan PATCH operation"). Use the Graph API.

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

**New on Nov 9, 2026:**

| Change | Post | What it means for you |
| --- | --- | --- |
| Opal needs usage-based billing and a spending policy, from Nov 9 | MC1540330 | See Do these first, step 15 |
| Intelligent call delegation moves to public preview and uses Copilot Credits, as early as Nov 17 | MC1537490 | See Do these first, step 16. New group: Copilot Intelligent Call Delegation Access |
| Power Platform connectors work in Cowork. Power Platform DLP doesn't apply to Cowork. Rollout done by mid-November | MC1542062 | See Do these first, step 17 and the Agent Delegation Guide |
| Standalone Word, Excel and PowerPoint agents go away, mid-November to late December. People ask Chat instead | MC1536062 | Tell users and the help desk. Copilot Anthropic Models Access is no longer tied to those agents |
| Workforce Insights custom data moves to the Microsoft 365 profile endpoint by Nov 18 | MC1542066 | Only if you send custom data. See the Agent Delegation Guide |
| Work IQ MCP can read a person's memory profile, early December. A new policy is on by default | MC1539004 | See the Agent Delegation Guide |
| Copilot connectors can be used through Work IQ APIs, late November to late December | MC1538999 | Existing connector controls still apply. No action |
| Planner plugin for Cowork, GA in November. Assign it like any other plugin | MC1540339 | See Cowork plugins |
| Accounting capabilities in Excel and Cowork. GA Nov 13, Frontier not required after that | MC1536053 | No group change. Tell finance teams |
| Notebooks are renamed Workspaces. Projects added to Home | MC1535647 | Check who is in a Cowork spending policy. Update training |
| Older models in prompts (including Anthropic and Grok) move to newer GPT models on Dec 2. Applies to Copilot Studio, Power Automate and Power Apps prompts | MC1536101 | Tell makers to test prompts before Dec 2. Your model groups don't change |
| Teams AI meeting policies moved later: Targeted Release in December, everyone in January 2027 | MC1532253 (updated Nov 3) | See Do these first, step 13 |
| Usage-based models in Chat and Office apps: everyone moved to early to mid-December | MC1519122 (updated Nov 4) | People still need a Copilot license, usage-based billing and credits |
| Copilot Studio replacement models changed for the Nov 12 retirement | MC1506318 (updated Nov 3) | Tell agent owners to test before Nov 12 |

**New on Nov 2, 2026:**

| Change | Post | What it means for you |
| --- | --- | --- |
| Frontier now gives public previews in Teams, new Outlook, OneDrive and SharePoint. A Copilot license isn't needed to enroll. Targeted release retires in January 2027 | MC1529472, MC1490899 | See Do these first, step 11 |
| **MeetingAI** and **TranscriptionWithMeetingAI** replace the Copilot meeting policy, Targeted Release in December, everyone in January 2027 | MC1532253 | See Do these first, step 13. Keep using Copilot Teams Policy Exceptions |
| Copilot Studio spending can move to Cost management, by agent or environment. GA by Nov 20 | MC1530368 | See Do these first, step 14 |
| Grok 4.6 comes to Chat as a usage-based model in early November, for Frontier tenants with the SpaceXAI subprocessor setting on | MC1474124 (updated Oct 28) | Copilot SpaceXAI Models Access decides who gets it. People also need credits |
| Copilot Code post updated. Cloud sessions are on, local sessions are off, and policies with the new-services setting already include Code | MC1519871 (updated Oct 28) | Matches this guide. See Do these first, step 7 |
| Engage plugin for Cowork and Autopilot, GA Nov 16, off by default | MC1530609 | See Cowork plugins |
| AI Builder credits are retiring. New or renewed licenses have none from Nov 1. Usage then falls back to Copilot Credits, and runs stop if neither is left | MC1526652 | Check your contracts in the Power Platform admin center. Buy Copilot Credits before yours run out |
| The taskbar pin setting adds a paid Copilot license option, early to mid-December | MC1530612 | It makes its own license group, so the admin needs rights to create groups. Or use **Pin for selected groups** with Copilot Access |
| Office in the Copilot app, mid-November | MC1530611 | No admin action. Tell users |
| DSPM classic and DSPM for AI classic retire in March 2027 | MC1481315 (updated Oct 30) | Move to Purview → **Solutions** → **DSPM**. Affects Copilot Compliance Admin |
| Authoritative sources for Copilot Search, up to 100 SharePoint sites | MC1526676 | Only Global Administrator and Global Reader see it. Nothing to change in your groups |
| Teams meeting memory files move to January 2027. On by default, kept 5 years | MC1429018 (updated Oct 30) | Review **Meeting Memory** in Teams meeting policies when it appears |
| People can see which memories shaped a Copilot answer | MC1530959 | No new setting. You can still turn memory off by group with Enhanced Personalization |
| Scheduled prompts in Agent Builder, connected agents, and the Evaluation Viewer role | MC1302906, MC1478975, MC1532073 | See the Agent Delegation Guide |

**Earlier:**

| Change | Post | What it means for you |
| --- | --- | --- |
| Graph APIs for Copilot cost management (beta) | MC1521616 | New. See Set spending policies with Graph, and run `New-CopilotSpendingPolicies.ps1` |
| Copilot Code is rolling out in Frontier. Code is now a usage-based service | MC1519871 | See Copilot Code: turn it on, and Do these first, step 7 |
| From Oct 30 the Copilot Connectors page follows **Agent and plugin access** (Allowed agent types). The old CLI switch is gone | MC1454973 (updated Oct 23) | See Do these first, step 1 |
| The Cowork settings panel is now called **Browser use in Microsoft Copilot** | MC1515930 | Only a name change. See Copilot + Cowork Browser Access |
| Critique and Council retire from Researcher by mid-November | MC1515927 | Tell Frontier users. Nothing to change in your groups. Action by Nov 14, 2026 |
| Admin controls for Business Applications in Work IQ, preview by Nov 17 | MC1518036 | Review which Power Platform environments Work IQ can read. Affects Copilot Work IQ API Access |
| Usage-based models in Chat and Word, Excel and PowerPoint, Frontier early to mid-November, everyone early to mid-December (updated Nov 4). GPT-6 Astra and Claude Fable 5.1 become usage-based models | MC1519122 | People need a Copilot license, usage-based billing on and credits. Your model groups still decide which providers they get |
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
