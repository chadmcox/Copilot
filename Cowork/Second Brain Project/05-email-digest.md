# Daily Email Digest

Review emails from the **previous business day**: emails I received in my Inbox and emails I sent.

## Objective

Find three things only:

1. **Actions** I need to take
2. **Follow-ups** I owe someone or I'm waiting on
3. **Announcements** that affect my work

Don't summarize every email, rewrite threads or write knowledge articles.

---

## Scope

- **Inbox:** emails received during the previous business day
- **Sent Items:** emails I sent during the previous business day (only to find commitments I made)

Don't search other folders, archives or older emails.

---

## Include

### Actions
Capture an item only when:

- Someone directly asked me to do something
- I'm asked to review, approve, reply, attend, provide information or deliver something
- A deadline or due date applies to me
- An email I sent shows I committed to do something ("I'll send", "I will follow up", "let me check")

### Follow-ups
Capture an item only when:

- A direct question to me has no reply from me yet
- I asked someone for something in an email I sent, and the thread shows no answer yet

### Announcements
Capture an item only when it:

- Changes a policy, process, tool or requirement I follow
- Sets a deadline for me (training, compliance, expenses, reviews, enrollment)
- Announces an organization change that affects my team or role
- Announces a product, program or internal resource relevant to my work

## Exclude

- Newsletters, marketing and promotional email
- Automated notifications and system alerts that don't need action
- Meeting invitations, acceptances and declines
- Calendar updates
- Read receipts and out-of-office replies
- FYI emails with no action or relevant announcement
- Emails where I'm only on a large distribution list and nothing applies to me

---

## Processing Rules

1. Review only the previous business day. Don't go back further.
2. Report no more than **15 actions and follow-ups** and **10 announcements**. Rank by urgency and due date.
3. Don't infer due dates. Use only dates stated in the email.
4. Don't infer ownership. If it's unclear whether something is mine, skip it.
5. If the thread shows an action is already done, don't include it.
6. Treat each email thread as one item. Remove duplicates.
7. Include a link to the source email for every item.
8. If nothing qualifies, write "No significant items identified" and stop.

---

## Output Location

Daily file:

```text
{{ROOT}}/Email Digest/YYYY-MM-DD Email Digest.md
```

If the file already exists, update it instead of creating a duplicate.

---

## Markdown Structure

```markdown
# Email Digest - YYYY-MM-DD

## Daily Summary

New Actions: X
Follow-ups: X
Announcements: X

Top 3 Priorities:
- Item
- Item
- Item

## Actions

| Action | Requested By | Email Subject | Due Date | Priority | Link |
|---|---|---|---|---|---|

## Follow-ups

### I Owe a Reply

| Question or Request | From | Email Subject | Date Received | Link |
|---|---|---|---|---|

### Waiting on Others

| What I Asked For | Sent To | Email Subject | Date Sent | Link |
|---|---|---|---|---|

## Announcements

### [Announcement Title]

| Field | Value |
|---|---|
| From | |
| Type | Policy / Process / Deadline / Org Change / Program / Product |
| Deadline | [date] / None stated |
| Link | |

**What changed:** 1-2 sentences

**What I need to do:** 1 sentence, or "No action needed"
```

**Priority:** High (stated due date within 3 business days, or flagged as urgent), Medium (stated due date later), Low (no due date stated).

---

## Action Tracker

Also add every item from **Actions**, **I Owe a Reply** and any announcement with a deadline to:

```text
{{ROOT}}/Action Tracker.md
```

Give each one Category = Email and Status = Open. Don't add duplicates of items already in the tracker. Don't add **Waiting on Others** items; those stay in the daily file only.

---

## Success Criteria

The output answers only three questions:

1. What do I need to do?
2. Who am I waiting on, or who is waiting on me?
3. What changed that I need to know about?

If a piece of information doesn't help answer one of those, leave it out.
