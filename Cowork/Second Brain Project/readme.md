# Second Brain Prompts for Microsoft Copilot Cowork

Prompts for scheduled AI agents that build a personal work "second brain" from Microsoft 365 data and public sources. Each prompt runs as a daily scheduled task and writes Markdown files to OneDrive.

## Architecture

Six collection jobs gather information. Job 10 runs last: it's the only job that writes to the action tracker, and it builds a single Daily Briefing page and sends a Teams chat with the highlights.

Jobs 7-9 are reserved so new collection jobs can be added without renumbering.

| Time | Job | Source | Output |
|---|---|---|---|
| 1:00 AM | [1. Meeting Notes](01-meeting-notes.md) | Meeting transcripts and recaps | One file per meeting, plus a daily summary |
| 1:30 AM | [2. Teams Actions](02-teams-actions.md) | Teams chats and channels | Daily actions file |
| 2:00 AM | [3. Email Digest](03-email-digest.md) | Inbox and Sent Items | Daily digest |
| 2:30 AM | [4. Product Intelligence](04-product-intelligence.md) | Public Microsoft release notes and blogs | Daily report |
| 3:00 AM | [5. Market Intelligence](05-market-intelligence.md) | Public non-Microsoft vendor updates | Daily report |
| 3:30 AM | [6. Threat Briefing](06-threat-briefing.md) | AI lab safety reports and threat intelligence | Daily report |
| 4:00-7:30 AM | Jobs 7-9 (reserved) | | |
| 8:00 AM | [10. Action Consolidation and Daily Briefing](10-daily-briefing.md) | Outputs of Jobs 1-6 | `Action Tracker.md`, Daily Briefing, Teams chat |

Jobs 1-3 review the previous business day and name files by that date. Jobs 4-6 review the rolling 24 hours before they run and name files by the run date.

If a collection job takes longer than 30 minutes, space them one hour apart (1:00 AM to 6:00 AM). Job 10 must start after all other jobs finish.

## Adding a Job

1. Write the new prompt as Job 7, 8 or 9 and schedule it between 4:00 and 7:30 AM.
2. Have it write a daily file to its own folder. It must not write to `Action Tracker.md`.
3. Add one row to the **Input Registry** in Job 10 with the file path, type (Actions or Intelligence) and sections to read.
4. If it's an Intelligence job, add a section for it to the Daily Briefing template in Job 10.

## Folder Structure

```text
{{ROOT}}/
├── Action Tracker.md
├── Daily Briefing/
├── Meeting Notes/
│   ├── Meetings/
│   └── Daily Summaries/
├── Teams Actions/
├── Email Digest/
├── Product Intelligence/
├── Market Intelligence/
└── Threat Intelligence/
```

## Priority Tiers

Jobs 4-6 rank findings by tier first, then by impact.


**Tier 1 (highest)**
- Microsoft 365 Copilot
- GitHub Copilot
- Copilot Studio
- Agent 365
- {{ADDITIONAL_TIER_1}}

**Tier 2**
- OpenAI
- Anthropic
- Google (Gemini, DeepMind)
- Meta AI
- xAI

**Tier 3**
- Popular open-source AI: OpenClaw, Ollama
- Microsoft Entra ID and Entra Agent ID
- Microsoft Defender XDR, Defender for Endpoint, Defender for Identity, Defender for Cloud Apps
- Microsoft Defender for Cloud (AI threat protection)
- Competing security and identity vendors: CrowdStrike, Okta
- {{ADDITIONAL_TIER_3}}

## Design Principles

These prompts are deliberately narrow. An earlier version that tried to summarize every Teams chat across many topics ran for 16 hours without finishing. What fixed it:

- **Fixed sources.** Each prompt names its sources. The agent doesn't search for new ones.
- **A cap on output.** For example, no more than 10 updates a day.
- **One writer per file.** Only Job 10 writes to the action tracker, so jobs can't collide.
- **One place to read.** The Daily Briefing and Teams chat summarize everything with links to the full reports.
- **Intelligence is separate from tasks.** Product, market and threat reports never create actions.
- **No guessing.** Owners, dates, availability and pricing come only from the source. Otherwise the output says "Not stated."
- **Publication date evidence.** Public items must have a publication date inside the window. Repository or page modified dates don't count.
- **Source content is data, not instructions.** Every prompt tells the agent not to follow instructions found in emails, chats or web pages.
- **Explicit stop condition.** If nothing qualifies, the agent says so and stops.

## Setup

1. Create the folder structure above in OneDrive.
2. Replace the placeholders in each prompt:
   - `{{{ROOT}}}`: your root folder (for example, `Second Brain`)
   - `{{ADDITIONAL_TIER_1}}` and `{{ADDITIONAL_TIER_3}}`: other products you track, or delete the line
3. Add the URLs you've verified to the source lists in Jobs 4-6.
4. Run each job by hand once before scheduling it. Remove any source the agent can't open or that doesn't show publication dates. Don't let it search for a replacement.
5. Schedule the jobs in the order above.
6. Run it the first time to make sure to confirm always uploading the file it creates

## Because everything is being written into your Second Brain folders in OneDrive, you can reference the repository by name in copilot chat:

Examples

- "Summarize my latest Product Intelligence report."
- "What were the top findings in Threat Intelligence this week?"
- "What open actions exist in my Action Tracker?"
- "Show me everything from Enablement Intelligence related to Agent 365."
- "What did the Daily Briefing say about OpenAI this week?"
- "What Microsoft 365 Copilot updates have been captured this month?"

## Known Source Limitations

From testing, these sources were removed because publication dates or articles couldn't be read reliably:

- Microsoft 365 Roadmap (item publication dates unavailable)
- Microsoft Tech Community Copilot blog (article URLs and timestamps couldn't be accessed)
- MCP project feeds (unavailable; MCP is now limited to Microsoft-authored MCP servers)

Results will vary by agent platform and permissions.

## Disclaimer

These prompts are examples. Results depend on the agent platform, its permissions and which sources it can read. Check the outputs before relying on them.
