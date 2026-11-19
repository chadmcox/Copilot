# Use the Entra ID SME skill in Copilot Cowork

Ask **Microsoft Copilot Cowork** Entra ID questions and get answers checked against Microsoft Learn and the Microsoft Graph API reference, with source tags and a confidence line.

Use GitHub Copilot in VS Code instead? The same skill works there. See [GitHub Copilot/readme.md](../GitHub%20Copilot/readme.md).

> Microsoft changes Cowork, plugins and the Enterprise MCP server often, and parts are in preview. Test this in your own tenant first.

## Short version

1. Pick a way. **B (skill only)** is enough for most questions. **A (plugin)** adds live, read-only tenant reads through the Enterprise MCP.
2. Set it up: [Way B](#way-b-skill-only) (each person, about 2 minutes) or [Way A](#way-a-plugin-with-the-enterprise-mcp-admin-once-per-tenant).
3. Ask a question, for example: *"We're still on the legacy ID Protection user risk policy. What now?"*

## Pick a way

| Way | Setup | What Cowork can do |
| --- | --- | --- |
| **B. Skill only** (start here) | Each person, about 2 minutes | Answers and checks them against Microsoft Learn and Graph; writes KQL and Graph PowerShell for you to run; explains files you attach (CA policy JSON, sign-in exports) |
| **A. Plugin with the Enterprise MCP** | An admin does it once | Everything in B, plus read-only reads of your tenant, such as your CA policies or authentication methods policy |

## Way B: skill only

1. Build the skill zip: `.\New-CoworkPluginPackage.ps1 -SkillOnly`. It writes **entra-id-sme.zip**, which holds one folder with SKILL.md and its references.
2. In Copilot Cowork, open **Customize > Skills**, select the arrow next to **Add**, then **Upload skill**, and choose the zip.
3. Start a new Cowork task and ask an Entra ID question. The skill loads on its own.

> **"That archive has files outside the folder containing SKILL.md"** means you uploaded the plugin zip under Skills. The skills box only takes the `-SkillOnly` zip.

## Way A: plugin with the Enterprise MCP (admin, once per tenant)

The setup is the same as the [Entra ID Security Review](../../Entra%20ID%20Security%20Review/Cowork/readme.md#way-a-admin-setup-once-per-tenant). **Already set that up?** Reuse its app registration and OAuth client registration, and go straight to step 2 below.

1. Do steps 1 to 4 of the [Entra ID Security Review admin setup](../../Entra%20ID%20Security%20Review/Cowork/readme.md#way-a-admin-setup-once-per-tenant): turn on the Enterprise MCP server, register the app, grant the read-only MCP scopes, and register the OAuth client in the Teams Developer Portal. Name the app and registration **Entra ID SME - Cowork** if you're not reusing them.
2. Build the plugin:

   ```powershell
   .\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
   ```

   This writes **EntraIdSme-Cowork.zip**. If the `plugin` folder isn't next to the script, it downloads the plugin files from this repo on GitHub.
3. In the **Microsoft 365 admin center > Agents > Tools > Registry**, select **Upload**, choose the zip, and on **Scope users** pick **Specific users or groups**. Choose the admins who should use it, such as **Copilot Entra ID Operations Reader** from the [Access Governance Guide](../../Access%20Governance%20Guide/readme.md). Don't pick all users.
4. Test: activate your reader role in PIM, add **Entra ID SME** under **+ > Customize > Plugins**, and ask: *"List my Conditional Access policies that are in report-only."* Sign in when asked.

The MCP server acts as the signed-in person, so it can't see more than their activated roles allow, and it can't change the tenant.

## Good questions to try

- *"Can I require token protection for guests in Conditional Access?"*
- *"Review this CA policy JSON for gaps against CISA SCuBA."* (attach the export)
- *"Map CMMC IA.L2-3.5.3 to Entra configuration."*
- *"Design cross-tenant access for two subsidiaries sharing Teams."*
- *"Write a read-only KQL query that finds device code flow sign-ins."*
- *"Where do I turn off SMS for MFA?"*

## What's in this folder

| File | What it is |
| --- | --- |
| [plugin/manifest.json](plugin/manifest.json) | Plugin manifest: the skill plus the Enterprise MCP connector |
| [plugin/skills/entra-id-sme/SKILL.md](plugin/skills/entra-id-sme/SKILL.md) | The skill: anti-hallucination rules, verification workflow, modes, output format, change safety |
| [plugin/skills/entra-id-sme/references/](plugin/skills/entra-id-sme/references) | Per-area pointers, author wiki guidance, script and KQL index, gotchas, test prompts |
| [New-CoworkPluginPackage.ps1](New-CoworkPluginPackage.ps1) | Builds the plugin zip with your registration ID, or the skill-only zip |

## Privacy

The plugin collects nothing. Cowork calls Microsoft Graph as the signed-in person, and results stay in that person's Cowork session and OneDrive. The skill doesn't put tenant IDs, UPNs, object IDs or secrets in shareable output.

## Terms

Provided as is, with no warranty. Test in your own tenant before relying on it.

## Sources

- The skill's source list: [sources.md](plugin/skills/entra-id-sme/references/sources.md)
- [Build plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-plugin-development) and [Manage plugins for Copilot Cowork](https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins)
- [Get started with the Microsoft MCP Server for Enterprise](https://learn.microsoft.com/graph/mcp-server/get-started)
