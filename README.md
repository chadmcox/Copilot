# Copilot

Guides and scripts for Microsoft 365 Copilot administration.

## Start here: setting up Copilot access

Follow these guides in order:

1. **[Copilot Group Assignment Guide](Group%20Assignment%20Guide/readme.md):** create the Copilot groups, access packages and PIM admin groups, and add each group to its admin center setting.
2. **[Copilot Agent Delegation Guide](Agents/readme.md):** control who can build, share, publish and receive agents, using the groups from step 1.
3. **[Copilot Billing Health Check](Billing%20Health%20Check/README.md):** once spending policies are in place, check them, their groups and their members, and get a scored HTML report. Run it from PowerShell or in Copilot Cowork.
4. **[Agent and Tools Health Check](Agent%20and%20Tools%20Health%20Check/README.md):** check agents, tools, agent identities and blueprints against best practices (groups, sponsors, least privilege, clear names, stale items), and get a scored HTML report. Run it in Copilot Cowork or from PowerShell.

## Ongoing cleanup

- **[Agent and Tools Cleanup](Agent%20and%20Tools%20Cleanup/README.md):** find Copilot agents and tools (plugins, skills, MCP servers) nobody uses, stale Entra agent identities and stale agent identity blueprints, then block or disable them with an undo file. Also runs read-only in Copilot Cowork.

## Copilot Cowork prompts

- **[Daily Summary](Daily%20Summary/readme.md):** separate Cowork prompts scheduled to run daily and email you the results, a few minutes apart so they arrive in order.
- **[Second Brain Project](Second%20Brain%20Project/readme.md):** scheduled Cowork prompts that build a personal work "second brain" in OneDrive from your Microsoft 365 data and public sources.
