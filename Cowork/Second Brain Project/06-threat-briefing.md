# Daily Threat Intelligence Briefing

Review public threat intelligence and AI safety publications from the **last 24 hours**, using only the sources listed below.

## Objective

Answer two questions each day:

1. What are frontier AI labs reporting about agents or models acting outside their intended boundaries?
2. What are Microsoft Security and other trusted sources seeing attackers do in the real world?

Don't speculate, repeat headlines, write opinion or expand the scope beyond these sources.

---

## Sources (only these)

Edit this list to match the sources you trust.

**Frontier AI labs and AI safety**
- Anthropic: news page, research page, system cards and threat intelligence reports
- OpenAI: news page, safety page, system cards and threat reports on malicious use of AI
- Google DeepMind: blog and safety research
- METR: research and evaluation reports
- UK AI Security Institute: blog and published evaluations

**Microsoft Security**
- Microsoft Security Blog (Microsoft Threat Intelligence posts)
- Microsoft Security Response Center (MSRC) blog
- Microsoft Security Update Guide (Patch Tuesday and out-of-band releases only)

**Industry and government**
- Google Threat Intelligence Group (GTIG) blog
- CISA: cybersecurity advisories and Known Exploited Vulnerabilities (KEV) catalog
- CrowdStrike: official blog (threat research posts only)

Don't search the open web or any other sites.

---

## Section 1: Frontier Lab Agent Containment

Capture an item only when a source reports a model or agent:

- Escaping, or trying to escape, a sandbox, container or test environment
- Getting around monitoring, permissions or tool restrictions
- Taking actions outside its assigned task or scope
- Gaining access to credentials, systems or data it wasn't given
- Deceiving evaluators, sabotaging tasks or hiding its behavior
- Being misused by threat actors for real-world attacks

For every item, label the evidence type:

- **Evaluation finding:** seen in a controlled test or red-team exercise
- **Real-world incident:** happened in production or in the wild
- **Threat actor misuse:** attackers used the model or agent

Never present an evaluation finding as a real-world incident. If the source doesn't make the setting clear, write "Setting not stated."

## Section 2: Threats in the Wild

Capture an item only when it involves:

- A new or active threat actor campaign
- A vulnerability that is being actively exploited
- An identity attack (token theft, phishing, MFA bypass, OAuth abuse, device code phishing)
- An attack on AI systems (prompt injection, agent hijacking, MCP or plugin abuse, model supply chain)
- A critical Microsoft vulnerability or out-of-band patch
- A new CISA KEV entry affecting common enterprise software

## Exclude

- Marketing, product announcements and webinars
- Funding, hiring and executive news
- Opinion pieces and predictions
- General AI safety commentary with no specific finding
- Items published more than 24 hours ago
- The same item from several sources (keep the original source)

---

## Processing Rules

1. Report no more than **5 items** in Section 1 and **10 items** in Section 2. Rank by severity and how widely they affect organizations.
2. Use only what the source says. Don't add threat actor names, CVE numbers, affected products or dates the source doesn't include.
3. Don't call something an "escape" or "breakout" unless the source describes it that way or describes the agent leaving its environment.
4. Every item must link to its source.
5. If a section has no qualifying items, write "Nothing reported in the last 24 hours" for that section. If both sections are empty, stop.

---

## Output Location

```text
{{ROOT}}/Threat Intelligence/YYYY-MM-DD Threat Briefing.md
```

If the file already exists, update it instead of creating a duplicate.

---

## Markdown Structure

```markdown
# Threat Briefing - YYYY-MM-DD

## Daily Summary

Frontier Lab Items: X
Threats in the Wild: X

Top 3:
- Item
- Item
- Item

## Section 1: Frontier Lab Agent Containment

### [Lab] - [Finding Title]

| Field | Value |
|---|---|
| Lab | |
| Model or Agent | [name] / Not stated |
| Evidence Type | Evaluation finding / Real-world incident / Threat actor misuse |
| Behavior | Sandbox escape / Permission bypass / Out-of-scope action / Credential access / Deception / Misuse |
| Mitigation Reported | [summary] / Not stated |
| Source | [link] |

**What happened:** 1-2 sentences

**Why it matters for organizations deploying agents:** 1-2 sentences on identity, permissions, monitoring or containment

## Section 2: Threats in the Wild

### [Threat Title]

| Field | Value |
|---|---|
| Reported By | |
| Category | Campaign / Exploited Vulnerability / Identity Attack / AI System Attack / Microsoft Patch / CISA KEV |
| Threat Actor | [name] / Not stated |
| Affected Products | [list] / Not stated |
| CVE | [ID] / None |
| Severity | Critical / High / Medium / Not stated |
| Source | [link] |

**What's happening:** 1-2 sentences

**Recommended mitigations:** Only what the source recommends. If it recommends none, write "Not stated."

## Patterns

Include only if two or more items today share a technique, target or threat actor. Otherwise leave this section out.

## Actions

| Action | Related Item | Priority |
|---|---|---|
```

---

## Actions

List an action only when an item clearly calls for one. For example:

- Check exposure to an actively exploited vulnerability
- Review agent permissions or containment controls against a new finding
- Share a critical advisory with stakeholders
- Update a security talk track or workshop deck

Also add each action to:

```text
{{ROOT}}/Action Tracker.md
```

Give each one Category = Threat Intel and Status = Open.

---

## Success Criteria

The output answers only three questions:

1. What are AI labs seeing their agents do outside their boundaries?
2. What are attackers doing in the real world right now?
3. Do I need to do anything?

If a piece of information doesn't help answer one of those, leave it out.

---

## Notes

- **Section 1 will often be empty, and that's expected.** Labs mostly report containment issues in system cards, safety evaluations and threat reports, which come out every few weeks rather than daily. The rule against speculating keeps the agent from filling the gap with guesses.
- **The evidence-type label is the most important control.** Most reported agent "breakout" findings come from controlled tests, not real incidents. Labeling each one keeps a test result from being repeated as a production incident.
- **Run it by hand once before scheduling.** Some lab pages may not show clear publication dates or may block automated reads. Remove any source the agent can't open rather than letting it search for a replacement.
