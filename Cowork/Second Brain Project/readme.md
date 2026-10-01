# Second Brain Prompts

Prompts for scheduled AI agents that build a personal work "second brain" from Microsoft 365 data and public sources. Each prompt runs as a daily scheduled task and writes Markdown files to OneDrive.

## Why Markdown

- AI tools can create and update it easily.
- It works in OneDrive, SharePoint, GitHub, Obsidian, VS Code and most AI tools.
- AI tools search and summarize it better than Word or OneNote files.
- It supports headings, tables, links and checklists, and it's easy to version.

## The prompts

| # | Prompt | Source | Output |
|---|---|---|---|
| 1 | [Meeting Notes](01-meeting-notes.md) | Meeting transcripts and recaps | One file per meeting, plus a daily summary |
| 2 | [Action Tracker](02-action-tracker.md) | Teams chats | Rolling `Action Tracker.md` |
| 3 | [Product Intelligence](03-product-intelligence.md) | Public Microsoft release notes and blogs | One file per day |
| 4 | [Market Intelligence](04-market-intelligence.md) | Public non-Microsoft vendor updates | One file per day |

## Folder structure

```text
Second Brain/
├── Action Tracker.md
├── Meeting Notes/
│   ├── Meetings/
│   └── Daily Summaries/
├── Product Intelligence/
└── Market Intelligence/
```

## Design principles

These prompts are deliberately narrow. An earlier version that tried to summarize every Teams chat across many topics ran for 16 hours without finishing. What fixed it:

- **Fixed sources.** Each prompt names its sources. The agent doesn't search for new ones.
- **A cap on output.** For example, no more than 10 updates a day.
- **One job, one question set.** Each prompt answers only three questions and drops everything else.
- **No guessing.** Owners, due dates, availability and pricing come only from the source. If the source doesn't say, the output says "Not stated."
- **Explicit stop condition.** If nothing qualifies, the agent writes that and stops.

## Setup

1. Create the folder structure above in OneDrive.
2. Replace the placeholders in each prompt:
   - `{{ROOT}}`: your root folder (for example, `Second Brain`)
   - `{{TOPICS}}`: the products and technologies you care about
3. Run each prompt by hand once before scheduling it. Remove any source the agent can't open rather than letting it search for a replacement.
4. Schedule the jobs at different times. Several of them write to `Action Tracker.md`, and running them apart keeps them from writing to the file at the same moment.

Suggested order: Meeting Notes → Action Tracker → Product Intelligence → Market Intelligence.

## Next steps (not included yet)

- A weekly job that merges the daily product and market files into a topic-organized knowledge base.
- A morning digest that combines the outputs of all four jobs.

Add these only after the daily jobs run reliably. Merging and correlating across files is the same scope problem that broke the original Teams job.

## Disclaimer

These prompts are examples. Results depend on the agent platform, its permissions and which sources it can read. Check the outputs before relying on them.

