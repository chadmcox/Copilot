# Admin settings: what to read and the rules

None of these settings is in Microsoft Graph (checked against Microsoft Learn, November 2026), so
they're read in the browser. Paths are the ones Microsoft's docs use; the admin centers move pages
from time to time, so use the admin center's search box when a path doesn't match.

References use the same mapping as the agent and tools health check (guidance.md): **this repo's
judgment** of the CIS Controls v8.1 safeguard and the CISA risk category, not something CIS or CISA
published.

## Pages, in order

| # | Admin center | Path | What to read |
| --- | --- | --- | --- |
| 1 | Microsoft 365 (admin.microsoft.com) | Agents > Settings > **Agent and plugin access** | Whether each box is selected: **Allow agents and plugins built by Microsoft**, **... by your organization**, **... by external publishers** |
| 2 | Microsoft 365 | Agents > Settings > **User access** | **All users**, **Specific users or groups** (record the group names), or **No users** |
| 3 | Microsoft 365 | Agents > Settings > **Sharing** | **All users**, **Specific users**, or **No users** |
| 4 | Microsoft 365 | Copilot > Connectors > **Your connections** | Every connector: name, type (federated, synced, self-serve sync), publisher (Microsoft, your organization, or a partner), status (enabled or disabled), **Staged rollout** (Everyone, the groups or users it's staged to, or No users) |
| 5 | Microsoft 365 | Agents > Tools > **Registry**, filtered to MCP servers with status Available | For each server: publisher, and if it has a **Tools** tab, the tools that are **Enabled**. Note tools whose names or descriptions say they write, update, delete, send, post or pay. Close the pane without saving |
| 6 | Microsoft 365 | Copilot > Settings > View all > **Cowork settings** > Allow browser access | Off, on for all users, or on for specific groups |
| 7 | Microsoft Entra (entra.microsoft.com) | Entra ID > Users > **User settings** | **Users can register agent identity blueprints** (Microsoft docs also call it *Users can create agent blueprints*): Yes or No |
| 8 | Microsoft Entra | ID Governance > Lifecycle workflows > Lifecycle policies > **Agent ID** (preview) | Whether the **default inactivity policy** is on |

## What the settings do (from Microsoft's docs)

- **Agent and plugin access** decides which publisher types are available, including connectors and
  MCP servers. Clearing a type sets the staged rollout of that type's existing connectors to **No
  users** and applies to connectors released later; an admin can still turn individual connectors
  on. Microsoft-built federated connectors are available by default while **Allow agents and plugins
  built by Microsoft** is selected.
- **User access** is the ceiling for every agent and plugin, connectors included. Connector staging
  can narrow it but never widen it.
- A user sees a federated connector only when its publisher type is allowed (or it was turned on
  individually), it's enabled, the user is in User access and in its staged rollout, and the user
  has a Microsoft 365 Copilot license.
- Microsoft's connectors can't be deleted; disable them, stage them to No users, or clear the
  Microsoft publisher type.
- Per-tool control on an MCP server is rolling out and only works on some MCP servers. Blocking a
  whole server blocks every tool on it.
- **Sharing** only applies to agents built with Agent Builder.

## Rules

| Setting | Finding when | Severity | Category | Fix | Reference |
| --- | --- | --- | --- | --- | --- |
| Agent and plugin access | **External publishers** is selected | Medium | Access | Clear it, then turn on the partner agents and connectors you've reviewed one at a time | CIS 2.5, 15.1 \| CISA: design and configuration |
| Agent and plugin access | **Microsoft** is selected (this is the default) | Info | Access | A decision, not a fault: Microsoft-built connectors, including ones that reach outside services, reach everyone in User access. Keep it if you want them, and stage the ones that reach outside Microsoft 365 | CIS 2.5, 6.1 \| CISA: design and configuration |
| User access | **All users** | Medium | Access | Set it to Specific users or groups: your Copilot users. It's the ceiling for every agent, plugin and connector | CIS 6.1, 6.8 \| CISA: privilege |
| Sharing | **All users** | Low | Access | Set it to Specific users, so only people you choose can share Agent Builder agents widely | CIS 6.1, 6.8 \| CISA: privilege |
| Your connections | A **federated** or **self-serve sync** connector to a service outside Microsoft 365 (for example HubSpot, Confluence, Jira) is **enabled** and its staged rollout is **Everyone** | Medium | Access | Stage it to the groups that need it, or disable it if no one does | CIS 6.1, 15.1 \| CISA: privilege |
| Your connections | An **enabled** connector from a **partner** publisher | Low | Access | Confirm you reviewed the vendor and what it can read and write, and stage it to the groups that need it | CIS 2.5, 15.1 \| CISA: design and configuration (third-party components) |
| Your connections | A **synced** connector staged to **Everyone** | Low | Access | Confirm everyone should search it; item permissions still apply, but check the connection's access settings aren't set so everyone sees all content | CIS 3.3, 6.1 \| CISA: privilege |
| Tools > Registry | An Available MCP server with a Tools tab has **write, update, delete, send, post or payment tools enabled** | Medium | Tools | Turn those tools off unless someone needs them, and keep the read tools on | CIS 3.3, 6.1 \| CISA: privilege, behavioral |
| Cowork settings | Browser access is **on for all users** | Low | Access | Limit it to the people who need Cowork to work in websites for them | CIS 6.1, 6.8 \| CISA: privilege |
| Entra user settings | **Users can register agent identity blueprints** is **Yes** (the default) | Medium | Identity | Set it to No, so blueprints are created by admins through a process | CIS 5.6, 6.1 \| CISA: design and configuration |
| Lifecycle policies | The **Agent ID default inactivity policy** is off | Low | Usage | Turn it on (preview): it notifies at 60 days, disables at 90 and deletes at 455 | CIS 5.3, 6.2 \| CISA: accountability |

Don't report a finding for a setting that's already as recommended. Don't guess a connector's type
or publisher: if the page doesn't show it, write "not shown".

## Checklist for reading by hand

When there's no browser, give the user this list and ask for each value:

1. Agents > Settings > Agent and plugin access: which of the three boxes are selected?
2. Agents > Settings > User access: All users, specific users or groups (which), or no users?
3. Agents > Settings > Sharing: All users, specific users, or no users?
4. Copilot > Connectors > Your connections: for each connector, its type, publisher, status and
   staged rollout.
5. Agents > Tools > Registry: for each available MCP server with a Tools tab, which write, delete,
   send or payment tools are enabled?
6. Copilot > Settings > View all > Cowork settings: is browser access off, on for all, or on for
   groups?
7. Entra > Users > User settings: can users register agent identity blueprints?
8. Entra > Lifecycle policies > Agent ID: is the default inactivity policy on?

## Sources

- Agent settings in the Microsoft 365 admin center: https://learn.microsoft.com/microsoft-agent-365/admin/agent-settings
- Manage federated connector availability: https://learn.microsoft.com/microsoft-365/copilot/connectors/manage-federated-connectors
- Federated connectors overview: https://learn.microsoft.com/microsoft-365/copilot/connectors/federated-connectors-overview
- Set up custom federated connectors (FAQ): https://learn.microsoft.com/microsoft-365/copilot/connectors/set-up-custom-federated-connectors
- Manage self-serve sync connector availability: https://learn.microsoft.com/microsoft-365/copilot/connectors/manage-personal-sync-connectors
- Manage plugins, skills, and MCP servers: https://learn.microsoft.com/microsoft-agent-365/admin/manage-plugins-skills-mcp-servers
- Use the local browser with Copilot Cowork: https://learn.microsoft.com/copilot/cowork/cowork-local-browser
