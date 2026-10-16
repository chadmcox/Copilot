# Copilot Agent Delegation Guide

Oct 16, 2026 · @Chad Cox

> **Start here: do the Group Assignment Guide first.**
> This guide is step 2. It uses groups and admin roles that the [Copilot Group Assignment Guide](../Group%20Assignment%20Guide/readme.md) sets up.
> 1. Follow the [Group Assignment Guide](../Group%20Assignment%20Guide/readme.md). Run its scripts to create the Copilot groups, access packages and PIM admin groups.
> 2. Then come back here to control who can build, share, publish and receive agents.

This guide explains who can **build** Copilot agents, who can **share and publish** them, and how to **give agents to people** in Microsoft 365.

Microsoft changes these settings often. Check each path in your own tenant before you rely on it.

## The big idea

**You can't fully stop people from building agents.** Anyone with a Microsoft Copilot license can open Agent Builder and Copilot Studio. What you *can* control is where an agent goes after it's built:

1. **Build.** Who can create agents, and with which tools.
2. **Share.** Who can share an agent with other people.
3. **Publish.** Which agents an admin approves for the whole organization.
4. **Assign.** Who sees each agent, who has it installed and who has it pinned.

Lock down steps 2 to 4, and a badly built agent stays with the one person who built it.

## Do these first

| # | Where | What to do | By | Why |
| --- | --- | --- | --- | --- |
| 1 | M365 admin center → **Copilot → Settings → View all → Advanced package uploads** | Select **Specific users or groups**. Add **Copilot Advanced Package Upload Access**. Select **Save** | Oct 25, 2026 | If you do nothing, everyone can upload agents and plugins that run actions or MCP servers (MC1472007) |
| 2 | Entra admin center → **Entra ID → Users → User settings** | Set **Users can create agent blueprints** to **No**. Select **Save**. Put agent developers in **Copilot Agent ID Developers** | Early Nov 2026 | If you do nothing, every user can create agent identities in Entra (MC1506733) |
| 3 | M365 admin center → **Agents → Settings → Sharing** | Select **Specific users**. Add **Copilot Agent Sharing Access**. Select **Save** | Now | Stops everyone from sharing Agent Builder agents with the whole organization |
| 4 | M365 admin center → **Agents → Settings → Agent and plugin access** | Leave **Built by Microsoft** and **Built by your organization** on. Turn off **Built by external publishers** until you've reviewed them | Now | Outside agents process your data under their own terms |
| 5 | SharePoint | Tell site owners that new SharePoint agents use Agent Builder from mid-November, and that `.agent` files stop working in April 2027 | Mid-Nov 2026 | See [SharePoint agents are changing](#sharepoint-agents-are-changing) (MC1511052) |

## 1. Who can build agents

| Tool | Who can use it by default | How to control it | Group to use |
| --- | --- | --- | --- |
| **Agent Builder** (in the Copilot app) | Everyone with a Microsoft Copilot license | You can't turn off building for some people. Control sharing (step 2) and who can use agents at all (**Agents → Settings → User access**) | Copilot Agent Sharing Access (for sharing) |
| **Copilot Studio** | Everyone with a Copilot license, a Copilot Studio license or a trial | 1. Assign the Copilot Studio user license to a group. 2. In the Power Platform admin center, go to **Manage → Tenant settings → Copilot Studio authors** and add the group. 3. Turn off self-service trials. 4. Limit each environment to a security group. 5. Use data policies to block channels and connectors | Copilot Studio Access |
| **Apps in Copilot Studio and Cowork** | On by default in Copilot Studio. Cowork app building needs Frontier | Copilot Studio: run `pac admin update-tenant-settings --setting-name powerPlatform.powerapps.enabledGroupsManagedAppsMcsPreview --setting-value '<group object ID>'`. Cowork: Frontier access | Copilot App Builder Access; Copilot Frontier Access |
| **SharePoint agents** | Anyone who can edit a site and has a Copilot license | Turn off agents on sensitive sites with **Restricted content discovery**. Turn off the **Microsoft Copilot for SharePoint** service plan for people who shouldn't use them | None (site-level setting) |
| **Agents with actions or MCP servers** (uploaded packages) | Everyone, from Oct 25, 2026, unless you limit it | **Copilot → Settings → Advanced package uploads** | Copilot Advanced Package Upload Access |
| **Teams custom apps** (sideloading) | Depends on your Teams app setup policy | Teams admin center → **Teams apps → Setup policies → Upload custom apps**. Turn it on only in a policy for developers | Your developer group |
| **Entra agent identities** (blueprints) | Every user, from early Nov 2026 | Set **Users can create agent blueprints** to **No**. Give the **Agent ID Developer** role to people who need it | Copilot Agent ID Developers |
| **MCP servers and tools** | Developers register them, then an admin approves | M365 admin center → **Agents → Tools → Requests**. Needs AI Administrator | Copilot Agent Management Admin |

**Copilot Studio can't be turned off.** Microsoft says to use data policies so nobody can chat with agents you haven't approved. Even with **Copilot Studio authors** set, people with a Copilot license can still open Copilot Studio.

## 2. Who can share agents

How far an agent can go depends on the tool that built it.

| Built with | How far it can be shared | Setting |
| --- | --- | --- |
| Agent Builder | With specific people, or with the whole organization | **Agents → Settings → Sharing**. With **Specific users**, only Copilot Agent Sharing Access members can share broadly. Everyone can still share with named people |
| Copilot Studio | A small group, for testing only. Reaching everyone needs admin approval | Publish request (see step 3) |
| SharePoint | People who already have access to the `.agent` file, in Teams | SharePoint file permissions |
| Agents Toolkit (developers) | Through a Teams app package | Teams setup policies and admin approval |

**Sharing never gives access to data.** An agent only shows each person what that person can already open.

## 3. Publishing to the whole organization

When a maker publishes an agent to the organization, it goes to a request queue. An admin must approve it before anyone else can find it.

1. Go to M365 admin center → **Agents → All agents → Requests**.
2. Open the request. Check the owner, what data it reads and what actions it can take.
3. Select **Publish to store**.
4. Pick who can install it. **Start with a small group**, like Copilot Pilot Ring.
5. Optional: pick who gets it installed for them.
6. Pick a policy template. Review the permissions. Grant consent only if they make sense.
7. Select **Publish**.

To reject it, select **Reject submission**. To clear out old requests, go to **Agents → Settings → Agent management rules** and add a rule that rejects requests older than a set number of days.

**Who approves:** people in **Copilot Agent Management Admin** (AI Administrator, turned on through PIM). **Copilot Plugin Approvers** can be your review queue, because there's no separate approver setting.

## 4. Giving agents to people

Every agent has three separate settings. They're under M365 admin center → **Agents → All agents → [agent] → Users**.

| Setting | What it does | When to use it |
| --- | --- | --- |
| **Available to** | Who can find the agent and install it themselves | Most agents. People add it when they need it |
| **Installed for** | Who has it installed for them automatically | Agents a team needs every day |
| **Pinned** | Who sees it at the top of their agent list. Admins get 3 pin slots | The one or two agents everyone should notice |

Rules of thumb:

- **Use groups, never single people.** Pick a group you already have for that audience, like a department group, instead of making a new one.
- **Start small.** Make a new agent available to Copilot Pilot Ring first. Then widen it.
- **Install only what people need.** If you install an agent for the entire organization, everyone gets it, whatever **Available to** says.
- **Pin sparingly.** Pin only agents that are deployed. Pins can take up to 6 hours to show up.
- **Need a group just for one agent?** Name it `Copilot <Agent name> Agent Access`, like the other groups in this repo. Give it through an access package so it gets reviewed.

**Cowork plugins are assigned elsewhere:** go to **Agents → Tools → [plugin] → Installed for**. Pick the Cowork spend groups (Limited, Unlimited and Temp), because those groups are the people who can use Cowork.

**Plugins replace the Agents button.** From late October to late November 2026, users see a **Plugins** button instead of **Agents**, **Agents & Skills** or **Customize** (MC1484008). You still manage agents in the same admin pages.

## 5. Examples: setting up Microsoft's own agents

**Not every agent should go to every user.** Before you assign an agent, ask four questions:

1. **What data can it see?** People data, HR data and customer data need a smaller audience.
2. **What can it do?** Agents that send email, change records or call other systems need a smaller audience.
3. **Who actually needs it?** If only one team uses it, only that team gets it.
4. **Does it cost extra?** Some agents use Copilot Credits or need another license.

Here's how Microsoft's own agents should look in **Agents → All agents → [agent] → Users**:

| Agent | Who should get it | Available to | Installed for | Pinned | Why |
| --- | --- | --- | --- | --- | --- |
| **Researcher** and **Analyst** | Everyone with a Copilot license | Can't be changed | Everyone (Microsoft installs them) | By Microsoft | You can't limit these to a group. Your only choice is to leave them on or block them for everyone |
| **Workforce Insights** (Frontier) | Leaders, managers and their delegates | **Copilot Workforce Insights Agent Access** | Same group | Same group | It shows people data about a leader's organization. Microsoft says to pilot it with specific groups. Members also need Copilot Frontier Access |
| **Sales** | Sellers who use Dynamics 365 Sales or Salesforce | **Copilot Sales Agent Access** | Same group | Optional | It only works for people connected to a CRM. Also add a Teams app setup policy for the same group |
| **Employee Self-Service** (HR and IT) | Everyone, after a pilot | Pilot group first (about 5 to 10% of staff), then **Entire organization** | Same as Available to | Everyone, once it's live | Your team builds it from Microsoft's template in Copilot Studio, so it arrives as a publish request. Microsoft suggests a pilot of 5 to 10% |
| **Legal** (Cowork for Legal plugin, Legal Skills in Word) | Your legal team | Can't be limited to a group today | Can't be limited to a group today | n/a | You can only turn these on or off for everyone. Turn them off if most people shouldn't use them (MC1509799) |

### How to limit an agent to a group

This example uses the Workforce Insights agent and a group called **Copilot Workforce Insights Agent Access**.

1. **Create the group.** Name it `Copilot <Agent name> Agent Access`. Give it through an access package with manager approval, so it's reviewed.
2. **Check the baseline.** Go to **Agents → Settings → User access**. Make sure the group's members can use agents at all, for example with **All users** or a group that includes them.
3. **Open the agent.** Go to **Agents → All agents** and select the agent. Select the **Users** tab.
4. **Set Available to.** Select **Specific users or groups can install**. Add the group. Don't pick **All users in the organization can install**.
5. **Set Installed for.** Select **Specific users or groups**. Add the same group. Never pick **Entire organization** here: it installs the agent for everyone, whatever **Available to** says.
6. Select **Update**.
7. **Pin it (optional).** Go to **Agents → All agents → ... → Manage pinned agents → Pin agent**. Pick the agent, choose **Specific users or groups the agent is deployed to**, and add the group. Select **Save**. Pins can take up to 6 hours to appear.
8. **Test it.** Sign in as someone who isn't in the group. They shouldn't be able to find or open the agent.
9. **Review it.** Add the group to your quarterly access review.

**For agents your own team builds** (Copilot Studio or Agents Toolkit), the maker picks an audience when they submit the agent. You set the final audience when you approve it under **Agents → All agents → Requests → Publish to store**. Use the same rules: start with a group, never the whole organization, until the pilot has worked.

## 6. Keeping agents tidy

Do these every month:

1. **Find agents with no owner.** Go to **Agents → All agents** and filter on **Missing an owner**. Add a rule under **Agents → Settings → Agent management rules** to:
   - give Agent Builder agents to the old owner's manager
   - block ownerless agents nobody uses
2. **Block risky agents.** Open the agent and select **Block**. This removes it from everyone who installed it. Blocking a SharePoint or Foundry agent only removes it from Copilot Chat.
3. **Review who can share and publish.** Include the Copilot Agent Sharing Access, Copilot Advanced Package Upload Access and Copilot Agent ID Developers groups in your access reviews.
4. **Check the logs.** Copilot Studio and agent admin actions are logged in Microsoft Purview audit.
5. **For Entra agent identities:** every blueprint and agent needs a sponsor, which is the person accountable for it. Turning off a blueprint stops every agent made from it.

## SharePoint agents are changing

From mid-November 2026, **Create an agent** in SharePoint and OneDrive opens Agent Builder, and the agent shows up in the Plugin store (MC1511052). `.agent` files stop working in SharePoint, Teams and the Copilot app in April 2027.

1. Find the teams that own `.agent` agents. Tell them about the April 2027 deadline.
2. For each agent, pick one:
   - **Simple questions about one site:** use Copilot in SharePoint instead.
   - **One task for one site:** turn the `.agent` file into a site skill.
   - **A chat agent used across Microsoft 365:** select **Upgrade to M365 Agent** in the SharePoint builder.
3. Upgraded agents must be added to Teams chats and channels again.

## Admin roles for agents

| Task | Role | Group |
| --- | --- | --- |
| Approve, publish, deploy, pin, block and set agent settings | AI Administrator | Copilot Agent Management Admin |
| View agents and settings only | AI Reader | Copilot AI Reader |
| Manage Entra agent identities and blueprints | Agent ID Administrator | Copilot Agent ID Admin |
| Create agent blueprints | Agent ID Developer | Copilot Agent ID Developers |
| Copilot Studio environments, data policies, **Copilot Studio authors** | Power Platform Administrator | Copilot Studio Environment Admin |
| Teams app setup and permission policies | Teams Administrator | Copilot Teams Admin |
| Restricted content discovery for SharePoint sites | SharePoint Administrator | Copilot SharePoint Admin |

All of these groups use PIM, so people turn the role on only when they need it. See `New-CopilotAdminPim.ps1` in the Group Assignment Guide folder.

## Sources

- [Agent settings in the Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-settings)
- [Understand agent details: availability and installation](https://learn.microsoft.com/microsoft-365/admin/manage/agent-details)
- [Manage the agent registry and pinned agents](https://learn.microsoft.com/microsoft-365/admin/manage/agent-registry)
- [Manage agent requests](https://learn.microsoft.com/microsoft-365/admin/manage/agent-requests)
- [Governance and lifecycle actions for agents](https://learn.microsoft.com/microsoft-365/admin/manage/agent-actions)
- [Agents admin guide for Microsoft 365](https://learn.microsoft.com/microsoft-365/copilot/agent-essentials/m365-agents-admin-guide)
- [Manage plugins, skills and MCP servers](https://learn.microsoft.com/microsoft-365/admin/manage/manage-plugins-skills-mcp-servers)
- [Copilot Studio security FAQ (agent creation can't be turned off)](https://learn.microsoft.com/microsoft-copilot-studio/security-faq)
- [Users outside the Copilot Studio authors group can still use Copilot Studio](https://learn.microsoft.com/troubleshoot/power-platform/copilot-studio/licensing/authors-access)
- [Secure your Copilot Studio projects](https://learn.microsoft.com/microsoft-copilot-studio/guidance/sec-gov-phase3)
- [Manage access to agents in SharePoint](https://learn.microsoft.com/sharepoint/manage-access-agents-in-sharepoint)
- [Restrict who can create applications and agents in Entra](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-app-roles#restrict-who-can-create-applications-and-agents)
- [Best practices for Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/best-practices-agent-id)
- [Copilot Managed Runtime: scope app creation](https://learn.microsoft.com/microsoft-365/admin/manage/apps/)
- [Set availability of agents (Available to)](https://learn.microsoft.com/microsoft-365/copilot/agent-essentials/agent-lifecycle/agent-availability)
- [Agent installation in Microsoft Copilot (Researcher and Analyst)](https://learn.microsoft.com/microsoft-365/copilot/copilot-agent-install)
- [Workforce Insights agent: admin controls](https://learn.microsoft.com/microsoft-365/copilot/workforce-insights-agent)
- [Install the Sales agent](https://learn.microsoft.com/microsoft-sales-copilot/install-sales-as-an-integrated-app)
- [Publish the Employee Self-Service agent](https://learn.microsoft.com/microsoft-365/copilot/employee-self-service/declarative-agent-publish)
- [Manage Copilot for legal](https://learn.microsoft.com/microsoft-365/admin/manage/manage-copilot-for-legal)
- Message Center: MC1472007 (advanced package uploads), MC1506733 (agent blueprints), MC1484008 (plugin registry), MC1511052 (SharePoint agents), MC1469329 (app building), MC1509799 (legal plugins)
