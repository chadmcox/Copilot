# Copilot Cowork — pointers

Read on Microsoft Learn on Nov 19, 2026. Re-fetch before citing.

## Access [MS Learn]
- Cowork is generally available. Access is granted **only** by a spending policy whose scope includes the user and that selects **Cowork**. The old **Agents > All agents > Cowork** entry no longer controls access. https://learn.microsoft.com/copilot/cowork/cowork-admin-governance
- To remove access, remove the user from every spending policy that selects Cowork. A low credit limit doesn't block access. https://learn.microsoft.com/copilot/cowork/cowork-access
- The **AI experiences enabled by usage-based billing** discovery setting controls visibility, not access.
- **Model templates** (Cowork only) on a spending policy control which model providers and models Cowork can use; at least two models per template. https://learn.microsoft.com/copilot/implement/usage-based-billing-manage-copilot-credits
- GCC: available with a Microsoft 365 GCC Copilot license; prepaid credits without Azure, or Azure pay-as-you-go/pre-purchase. https://learn.microsoft.com/copilot/cowork/cowork-government

## Plugins [MS Learn]
Source: https://learn.microsoft.com/copilot/cowork/cowork-plugin-development
- A plugin is a Microsoft 365 app package (`manifest.json` with `agentSkills` and/or `agentConnectors`, `color.png`, `outline.png`, `skills/<name>/SKILL.md`). Skills follow the Agent Skills open standard.
- Patterns: skills only; skills + remote MCP connector; connector only; imported Claude Code or Cursor plugin.
- Tooling: **wiqd CLI** (preview) scaffolds, validates (`wiqd plugin validate --mode deep`), provisions, packages and shares; Microsoft 365 Agents Toolkit (`atk`) also packages.
- Manifest 1.29: connector entries are URL-only and `mcpToolDescription` is optional. Manifest 1.28: `mcpToolDescription` required and its file must be in the zip.
- Connector auth: `OAuthPluginVault` / `ApiKeyPluginVault` with `referenceId` (secrets stay in the Enterprise Token Store). If the MCP server supports Dynamic Client Registration, Cowork can omit auth (Cowork only, not Copilot Chat).
- Companion files per skill: max 20 files, 5 MB each, 10 MB total; relative paths; no hidden files, `..`, backslashes or Windows reserved names.
- Publish: direct share (`wiqd plugin share`), org upload (**Microsoft 365 admin center > Agents > Tools > Registry > Upload**), Microsoft Marketplace.
- Prerequisites: Microsoft 365 Copilot license per user; AI Administrator or Global Administrator for MCP approval and tenant consent; admin consent for server-linked plugins.
- Governance: plugins under **Tools** in the Microsoft 365 admin center and Agent 365; policies under **Agents > Settings > Agent and plugin access**. Manage plugins: https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins

## Build checklist (Mode 8)
1. Decide pattern (skills only vs connector). 2. Manifest version (1.29 unless a channel needs 1.28). 3. Auth for each connector. 4. Validate deep. 5. Least-privilege scopes on the connector app. 6. Scope the upload to a group, not all users. 7. Zip with forward slashes (Windows PowerShell 5.1 `Compress-Archive` writes backslashes).

## Author examples [Author repo – community, not official Microsoft guidance]
Plugin packaging scripts and manifests in https://github.com/chadmcox/Copilot (each solution's `Cowork/` folder).
