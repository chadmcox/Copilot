# Use the Copilot AI SME skill in Copilot Cowork

Ask **Microsoft Copilot Cowork** about Copilot, Cowork, Autopilot, Copilot Studio, agent governance, Copilot FinOps and AI security, and get answers checked against Microsoft Learn, the Copilot Roadmap and official blogs, with source tags, a status label and a confidence line.

Use GitHub Copilot in VS Code instead? The same skill works there. See [GitHub Copilot/readme.md](../GitHub%20Copilot/readme.md).

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## Short version

1. Pick a way. **B (skill only)** answers most questions. **A (plugin)** adds read-only tenant reads, such as Message Center posts and your licenses, through the Enterprise MCP.
2. Set it up: [Way B](#way-b-skill-only) (each person, about 2 minutes) or [Way A](#way-a-plugin-with-the-enterprise-mcp-admin-once-per-tenant).
3. Ask a question, for example: *"Our Autopilot users say it stopped answering. What do I check?"*

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **B. Skill only** (start here) | Each person, about 2 minutes | Answers and checks them against Microsoft Learn, the roadmap and blogs; credit estimates; framework mapping; threat models; scripts for you to run; explains files you attach (cost exports, policy screenshots) |
| **A. Plugin with the Enterprise MCP** | An admin does it once | Everything in B, plus read-only reads of your tenant, such as Message Center posts and subscribed licenses |

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **copilot-ai-sme.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task and ask a Copilot question. The skill loads on its own.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The skills box only takes the `-SkillOnly` zip.

## Way A: plugin with the Enterprise MCP (admin, once per tenant)

The setup is the same as the [Entra ID Security Review](../../Entra%20ID%20Security%20Review/Cowork/readme.md#way-a-admin-setup-once-per-tenant). **Already set up a plugin from this repo?** Reuse its app registration and OAuth client registration and go to step 2.

1. Do steps 1 to 4 of the [Entra ID Security Review admin setup](../../Entra%20ID%20Security%20Review/Cowork/readme.md#way-a-admin-setup-once-per-tenant). For Message Center reads, the app also needs the MCP scope that covers service messages; check the scope list in [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started) before granting.
2. Build the plugin:

   ```powershell
   .\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
   ```

   This writes **CopilotAiSme-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.
3. In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**, such as your Copilot admins. Don't pick all users.
4. Test: add **Copilot AI SME** under **+ > Customize > Plugins** and ask: *"List this month's Message Center posts about Copilot."* Sign in when asked.

The MCP server acts as the signed-in person, so it can't see more than their roles allow, and it can't change the tenant.

## Good questions to try

- *"How do I stop a group from using Cowork?"*
- *"Estimate monthly Copilot Credits for a Copilot Studio agent used by 500 unlicensed users."*
- *"Why doesn't the Azure invoice match Copilot Cost Management?"*
- *"Should this be a Cowork plugin or a Copilot Studio agent?"*
- *"What changed for Copilot Studio in the last 30 days?"*
- *"Map our Autopilot rollout to CISA's Careful Adoption of Agentic AI Services guidance."*
- *"Threat model our HR agent against the OWASP Agentic Top 10."*

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/copilot-ai-sme/SKILL.md](plugin/skills/copilot-ai-sme/SKILL.md) | The skill |
| [plugin/skills/copilot-ai-sme/references/](plugin/skills/copilot-ai-sme/references) | Area references, frameworks, threat model, gotchas, tests |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the plugin zip with your registration ID, or the skill-only zip |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The skill doesn't put tenant IDs, UPNs, contract prices or secrets in shareable output.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- The skill's source list: [sources.md](plugin/skills/copilot-ai-sme/references/sources.md)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development) and [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
