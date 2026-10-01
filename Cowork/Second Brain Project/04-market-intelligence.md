# Daily Market Intelligence (Non-Microsoft)

Review public updates published in the **last 24 hours**, using only the sources listed below.

## Objective

Find developments outside Microsoft that matter for AI, security and identity work. For each one, say what changed, why people will ask about it and whether I need to do anything.

Don't summarize whole articles, repeat hype, speculate about roadmaps or write knowledge articles.

---

## Sources (only these)

Edit this list to match the vendors you track.

**Security and identity**
- CrowdStrike: official blog and press releases
- Okta: official blog and press releases

**Frontier model providers**
- Anthropic: news page and release notes
- OpenAI: news page and release notes
- Google: Google DeepMind blog and Google AI blog
- Meta AI: official blog
- xAI: official news page

**Local and personal AI**
- OpenClaw: GitHub releases
- Ollama: GitHub releases and official blog

Don't search the open web or any other sites. To track a new vendor, add its official blog or GitHub releases page to this list.

---

## Topics

Include an update only if it's about:

- New frontier models, or major updates to existing ones
- Reasoning models
- Personal agents, computer-use agents or autonomous agents
- Agent platforms, agent SDKs or MCP support
- Local or on-device model runtimes
- Enterprise AI features: admin controls, data residency, compliance, audit or SSO
- AI security: prompt injection, agent security, model safety controls
- Identity for AI agents or non-human identities
- Endpoint, identity or XDR capabilities that compete with Microsoft Defender or Entra
- Pricing or licensing changes for enterprise use

---

## Include

Capture an update only if it involves:

- A new product, model or feature (preview or GA)
- A new enterprise, security or governance capability
- A change to pricing, licensing or terms of use
- A security incident, vulnerability or breaking change
- A deprecation or retirement
- A new integration with Microsoft products (Entra, Defender, Copilot, Azure)

## Exclude

- Marketing material with no technical detail
- Funding news, hiring or executive moves
- Event promotions, webinars and customer stories
- Benchmark claims with no product change
- Opinion pieces
- Updates published more than 24 hours ago
- Minor GitHub releases that only fix bugs, unless they fix a security issue

---

## Processing Rules

1. Report no more than **10 updates** a day. Rank them by how likely people are to ask about them.
2. Use only what the source says. Don't guess at capabilities, availability, pricing or comparisons.
3. If the source doesn't state availability, write "Not stated."
4. For "Microsoft Comparison," name a Microsoft capability only when the match is clear and direct. Otherwise write "Not assessed." Don't claim Microsoft is better or worse.
5. Every update must link to its source.
6. If there are no qualifying updates, write "No significant updates identified" and stop.

---

## Output Location

```text
{{ROOT}}/Market Intelligence/YYYY-MM-DD Market Intelligence.md
```

If the file already exists, update it instead of creating a duplicate.

---

## Markdown Structure

```markdown
# Market Intelligence - YYYY-MM-DD

## Daily Summary

Total Updates: X

Top 3:
- Item
- Item
- Item

## Updates

### [Vendor] - [Update Title]

| Field | Value |
|---|---|
| Vendor | |
| Category | Frontier Model / Reasoning Model / Personal Agent / Agent Platform / Local AI / AI Security / Identity / Endpoint-XDR / Pricing |
| Availability | Preview / GA / Retiring / Not stated |
| Relevance | High / Medium / Low |
| Microsoft Comparison | [Microsoft capability] / Not assessed |
| Source | [link] |

**What changed:** 1-2 sentences

**Why it matters:** 1-2 sentences

**Likely question:** One question someone is likely to ask about it

## Actions

| Action | Related Update | Priority |
|---|---|---|
```

---

## Actions

List an action only when an update clearly calls for one. For example:

- Test a new model or agent in a lab environment
- Prepare a response to a likely question about a competitor announcement
- Update a competitive slide or talk track
- Review a security issue

Also add each action to:

```text
{{ROOT}}/Action Tracker.md
```

Give each one Category = Market Intelligence and Status = Open.

---

## Success Criteria

The output answers only three questions:

1. What changed outside Microsoft?
2. Why will people ask about it?
3. Do I need to do anything?

If a piece of information doesn't help answer one of those, leave it out.
