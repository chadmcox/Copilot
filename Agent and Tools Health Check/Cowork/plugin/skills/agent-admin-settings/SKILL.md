---
name: agent-admin-settings
description: |
  Read-only check of the agent, plugin and connector settings Microsoft Graph doesn't expose, done
  in the browser: Agent and plugin access (including Microsoft-built connectors), User access,
  Sharing, each connector's status and staged rollout, per-tool control on MCP servers, Cowork
  browser access, blueprint registration and the Agent ID inactivity policy. Reads the Microsoft 365
  and Entra admin centers in the browser, never changes anything, and writes AdminSettings.csv in the
  same columns as Findings.csv. Use when the user asks to "check the admin center settings", "check
  the settings Graph can't read", "check Microsoft connectors", "check agent and plugin access" or
  "do the manual checks" for the agent and tools health check.
license: MIT
metadata:
  author: Chad Cox
  version: "1.0"
---

# Agent and connector admin settings check

Some of the settings that decide which agents, plugins and connectors people can use have no
Microsoft Graph API. This skill reads them from the admin centers in the browser, applies
**references/settings.md**, and reports what's set and what to change.

**Read-only.** You only open pages and read them. Never select Save, Apply, Block, Unblock,
Enable, Disable, Deploy, Delete, Edit, Add staging or any toggle, checkbox or option button. If a
page or pane opens in edit mode, close it with Cancel or the X. Type only into search or filter
boxes. Never send an email or Teams message.

## Before you start

1. **You need the browser.** In Copilot Cowork, that's Cowork on the web in Microsoft Edge, with
   browser access turned on for this user (Microsoft 365 admin center > Copilot > Settings > View
   all > Cowork settings > Allow browser access). If no browser tool is available, say so, then give
   the user the checklist in references/settings.md to read by hand, and stop.
2. **The user needs a reader role, activated.** Global Reader can view both admin centers. AI Reader
   covers most Microsoft 365 admin center agent pages. Ask the user to activate the role in PIM
   first if they use it. Don't ask for an admin role that can change settings.
3. **Sign-in is the user's.** If a page asks for a password, MFA or a PIM activation, hand the
   browser back to the user, and carry on after they finish. If they can't, record the page as
   "couldn't read" and move on.

## Step 1: Read each setting

Open each page in references/settings.md in order, read the value it describes, and write down:
the page, the setting, the value you saw, and the time. Use the admin center's own navigation; the
paths in settings.md are how Microsoft's docs describe them. If a page has moved or been renamed,
use the admin center's search box to find it. If you still can't find it, record "couldn't find"
rather than guessing a value.

- Read lists to the end: scroll, and open each page of results.
- For connectors and MCP servers, open each item's details pane only to read it, then close it.
- Don't copy people's names into the results. For group-scoped settings, record the group names and
  how many there are; for a single person, write "1 person".

## Step 2: Apply the rules

Apply the rules in references/settings.md to what you read. Each finding has the same columns as the
agent and tools health check's Findings.csv: **Area** ("Admin settings"), **Item** (the setting,
connector or MCP server), **Category**, **Severity** (High, Medium, Low, Info), **Check** (what's
wrong), **Fix** and **Reference**. A setting you couldn't read isn't a finding; list it under
"Couldn't read".

## Step 3: Report

Give the user, in this order:

1. **Fix first:** up to three changes, in plain words.
2. **Findings:** a table sorted High, Medium, Low, Info.
3. **What I saw:** one row per setting: page, setting, value, read at. For connectors, one row per
   connector: name, type (federated, synced or self-serve sync), publisher (Microsoft, your
   organization, or a partner), status, staged rollout.
4. **Couldn't read:** pages you couldn't open or find, and why.

Save the findings as **AdminSettings.csv** (Area, Item, Category, Severity, Check, Fix, Reference)
in the user's output folder (OneDrive **Cowork** in Copilot Cowork), so it can be added to
Findings.csv from Get-AgentToolsHealth.ps1. If the agent and tools health check report is in this
conversation, add these findings to it as an area named "Admin settings", and put what you saw next
to each manual check.

## If you're running in GitHub Copilot (VS Code or Copilot CLI)

This skill needs a browser that can open the admin centers as the signed-in user. VS Code's browser
tools can stand in for the Cowork browser if they're available and signed in; if not, give the user
the checklist in references/settings.md to read by hand, then apply the rules to the values they
tell you. The Copilot CLI has no browser, so it always uses the checklist.
