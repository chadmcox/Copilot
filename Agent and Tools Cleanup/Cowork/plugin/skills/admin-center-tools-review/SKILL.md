---
name: admin-center-tools-review
description: Read-only review of the Microsoft 365 admin center Agents > Tools pages (standalone MCP servers, skills, plugins) and the Copilot agent usage report, using the browser, for the things no Graph API covers. Use when asked which MCP servers, skills or plugins nobody uses, or to check the Tools registry for cleanup.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Admin center tools review (browser)

Some of what needs cleaning up has no Graph API: standalone MCP servers and skills in the Tools registry, plugin status and user availability, and the agent usage report. This skill reads those pages in the Microsoft 365 admin center with the browser and recommends what to clean up.

## Rules

- **Read-only.** Only open pages, read them, filter, sort and export. Never select **Block**, **Unblock**, **Delete**, **Uninstall**, **Install**, **Remove**, **Approve**, **Reject**, **Save** or any button that changes a setting, even if the user asks in the same task. Tell them to make the change themselves, or to use `Invoke-AgentToolsCleanup.ps1` for packages.
- Use the browser only on `admin.microsoft.com` (and `admin.cloud.microsoft`, which it may redirect to). Don't sign in for the user; if a sign-in, MFA or PIM prompt appears, stop and ask them to complete it.
- If a page looks different from these steps (Microsoft moves things often), say what you see and ask before guessing.
- Don't copy user names from the usage report into the results. Counts are enough.

## Steps

1. **Tools registry.** Open `https://admin.microsoft.com` and go to **Agents > Tools > Registry**. For each tab or filter (Plugins, Skills, MCP servers, Connectors), read every row: name, type, publisher, status, who it's available to and the last updated date, plus any usage or last-used column. Scroll or page until the list ends. If the page has **Export**, use it and read the file instead.
2. **Plugins.** Go to **Agents > Tools > Plugins**. For each plugin, note status (blocked, installed, available), user availability (all users, specific users, none) and anything that shows use.
3. **Requests.** Go to **Agents > Tools > Requests** and note pending requests. A tool with a pending request is wanted, so it isn't a cleanup candidate.
4. **Agent usage.** Go to **Reports > Usage > Microsoft Copilot > Agents**, choose the 30-day period and read the agent details table (agent name, agent ID, active users, last activity date). Use **Export** if it's there.
5. **Combine with files.** If the user attached `Packages.csv` from `Get-AgentToolsReport.ps1`, match rows by name and use its status as well.

## Recommendations

| What you see | Recommendation |
| --- | --- |
| Microsoft-published | Keep |
| Blocked already | AlreadyBlocked |
| Pending request, or used in the last 30 days | Keep |
| Custom or external, available to users, no use shown, last updated more than 90 days ago | Block (the admin does it in the admin center, or with the script for packages) |
| Standalone MCP server with no plugin or agent using it | Review: ask the owner, then block it in **Agents > Tools** |
| Available to **All users** but used by very few | Narrow availability to a group |
| Can't tell whether it's used | Review |

## Report

Give one table: name, kind (plugin, skill, MCP server, connector, agent), publisher, status, availability, last used or last updated, and recommendation. Then:
- counts per recommendation;
- the pages you read, and anything you couldn't read;
- the manual steps for each Block or availability change: **Agents > Tools > Plugins** (or **Registry**) > select the item > **Block**, or **Users** to change availability;
- a reminder that packages (agents and plugins) can be blocked in bulk, with an undo file, by `Invoke-AgentToolsCleanup.ps1 -BlockPackages -WhatIf`.
