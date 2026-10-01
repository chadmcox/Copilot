# Daily Product Intelligence

Review public product updates published in the **last 24 hours**, using only the sources listed below.

## Objective

Find product changes that matter for Microsoft AI, security and identity work. For each one, say what changed, why it matters and whether I need to do anything.

Don't summarize whole articles, repeat marketing copy, analyze trends or write knowledge articles.

---

## Sources (only these)

- Microsoft 365 Copilot release notes (Microsoft Learn)
- What's new in Copilot Studio (Microsoft Learn)
- What's new in Microsoft Entra (Microsoft Learn)
- What's new in Microsoft Defender XDR (Microsoft Learn)
- Microsoft 365 Roadmap
- Microsoft Security Blog
- Microsoft Tech Community: Copilot, Entra and Security blogs

Don't search the open web or any other sites.

---

## Topics

Include an update only if it's about one of these. Edit the list to match your work.

- Cowork, Autopilot, Microsoft 365 Copilot or Copilot Studio
- Agent 365
- Microsoft Entra ID
- Microsoft Entra Agent ID
- Microsoft Defender or Security Copilot
- Microsoft Purview (AI and data security only)
- Project Perception
- Microsoft redteam agent

---

## Include

Capture an update only if it involves:

- A new feature, preview or general availability (GA)
- A retirement, deprecation or breaking change
- A change to licensing or pricing
- A change to security, identity or governance behavior
- A change to admin controls or deployment requirements
- A documented limitation or known issue

## Exclude

- Marketing announcements with no technical detail
- Event promotions, webinars and customer stories
- Opinion pieces
- Updates published more than 24 hours ago
- Duplicates of the same update from different sources (keep the Microsoft Learn version)

---

## Processing Rules

1. Report no more than **10 updates** a day. Rank them by impact on deployments, security and governance.
2. Use only what the source says. Don't guess at availability dates, licensing or capabilities.
3. If the source doesn't state availability, write "Not stated."
4. Every update must link to its source.
5. If there are no qualifying updates, write "No significant updates identified" and stop.

---

## Output Location

```text
{{ROOT}}/Product Intelligence/YYYY-MM-DD Product Intelligence.md
```

If the file already exists, update it instead of creating a duplicate.

---

## Markdown Structure

```markdown
# Product Intelligence - YYYY-MM-DD

## Daily Summary

Total Updates: X

Top 3:
- Item
- Item
- Item

## Updates

### [Update Title]

| Field | Value |
|---|---|
| Product | |
| Change Type | New Feature / Preview / GA / Retirement / Licensing / Security / Limitation |
| Availability | Preview / GA / Retiring / Not stated |
| Impact | High / Medium / Low |
| Source | [link] |

**What changed:** 1-2 sentences

**Why it matters:** 1-2 sentences, focused on admins, security teams and developers

**Talking point:** One plain-language sentence for explaining it to others

## Actions

| Action | Related Update | Priority |
|---|---|---|
```

---

## Actions

List an action only when an update clearly calls for one. For example:

- Update a demo or workshop deck
- Validate the feature in a test tenant
- Communicate a retirement or breaking change
- Read the new documentation

Also add each action to:

```text
{{ROOT}}/Action Tracker.md
```

Give each one Category = Product Update and Status = Open.

---

## Success Criteria

The output answers only three questions:

1. What changed?
2. Why does it matter?
3. Do I need to do anything?

If a piece of information doesn't help answer one of those, leave it out.
