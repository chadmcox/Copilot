# Second Brain Prompts for Microsoft Copilot Cowork

Scheduled Cowork prompts that read your meetings, Teams, email and public sources every night and write Markdown notes to OneDrive. Copilot can then search those notes.

## Short version

1. Create the folder structure below in OneDrive.
2. In each prompt, replace `{{ROOT}}` with your root folder (for example, `Second Brain`). Replace `{{ADDITIONAL_TIER_1}}` and `{{ADDITIONAL_TIER_3}}` with other products you track, or delete those lines.
3. Add the source URLs you've checked to Jobs 4-6.
4. Run each job by hand once. Confirm it saves its file to OneDrive. Remove any source it can't open or that doesn't show publication dates, and don't let it search for a replacement.
5. Schedule the jobs at the times in the table.

## The jobs

Jobs 1-6 collect. Job 10 runs last: it's the only job that writes to the action tracker, and it builds one Daily Briefing page and sends a Teams chat with the highlights. Jobs 7-9 are reserved so you can add jobs without renumbering.

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
| Sunday 10:00 AM | [11. Weekly Knowledge Base](11-weekly-knowledge-builder.md) | Past 7 days of Jobs 4-6 | Topic files, Frontier vs Microsoft, Weekly Summary |

Jobs 1-3 review the previous business day and name files by that date. Jobs 4-6 review the 24 hours before they run and name files by the run date.

If a job takes longer than 30 minutes, space them an hour apart (1:00 AM to 6:00 AM). Job 10 must start after all the others finish.

## Folder structure

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
├── Knowledge Base/
└── Threat Intelligence/
```

## Ask Copilot about your notes

Everything lands in OneDrive, so you can ask Copilot chat about it by folder name:

- "Summarize my latest Product Intelligence report."
- "What were the top findings in Threat Intelligence this week?"
- "What open actions are in my Action Tracker?"
- "What did the Daily Briefing say about OpenAI this week?"
- "What Microsoft 365 Copilot updates were captured this month?"

## Add a job

1. Write the prompt as Job 7, 8 or 9 and schedule it between 4:00 and 7:30 AM.
2. Have it write a daily file to its own folder. It must not write to `Action Tracker.md`.
3. Add one row to the **Input Registry** in Job 10 with the file path, type (Actions or Intelligence) and sections to read.
4. If it's an Intelligence job, add a section for it to the Daily Briefing template in Job 10.

## Priority tiers

Jobs 4-6 rank findings by tier first, then by impact.

- **Tier 1:** Microsoft 365 Copilot, GitHub Copilot, Copilot Studio, Agent 365, {{ADDITIONAL_TIER_1}}
- **Tier 2:** OpenAI, Anthropic, Google (Gemini, DeepMind), Meta AI, xAI
- **Tier 3:** popular open-source AI (OpenClaw, Ollama); Microsoft Entra ID and Entra Agent ID; Microsoft Defender XDR, Defender for Endpoint, Defender for Identity, Defender for Cloud Apps and Defender for Cloud (AI threat protection); CrowdStrike and Okta; {{ADDITIONAL_TIER_3}}

## Why the prompts are narrow

An earlier version that tried to summarize every Teams chat across many topics ran for 16 hours without finishing. What fixed it:

**Keep the scope small**
- Each prompt names its sources. The agent doesn't search for new ones.
- Output is capped, for example no more than 10 updates a day.
- If nothing qualifies, the agent says so and stops.

**Keep the files clean**
- Only Job 10 writes to the action tracker, so jobs can't collide.
- Product, market and threat reports never create actions.
- The Daily Briefing and Teams chat are the one place to read, with links to the full reports.

**Keep it accurate**
- Owners, dates, availability and pricing come only from the source. Otherwise the output says "Not stated."
- Public items need a publication date inside the window. Page modified dates don't count.
- Content in emails, chats and web pages is data, not instructions. Every prompt tells the agent not to follow it.

## Sources that didn't work

These were removed in testing because publication dates or articles couldn't be read reliably:

- Microsoft 365 Roadmap (no item publication dates)
- Microsoft Tech Community Copilot blog (article URLs and timestamps couldn't be opened)
- MCP project feeds (unavailable; MCP coverage is now limited to Microsoft-authored MCP servers)

## Disclaimer

These prompts are examples. Results depend on the agent platform, its permissions and which sources it can read. Check the outputs before you rely on them.
