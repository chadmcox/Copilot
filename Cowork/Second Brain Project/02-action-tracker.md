# Daily Action Tracker

Review Microsoft Teams chats, group chats and channel conversations from the **previous business day**.

## Objective

Find work items that require action from me.

Don't summarize conversations, analyze trends or write knowledge articles. Focus only on work I need to complete.

---

## Include

Capture an item only when:

- Someone directly asked me to do something
- I volunteered or committed to do something
- I agreed to follow up, investigate, send information or schedule a meeting
- I agreed to create, update, review, build, validate, test, research or deliver something
- An external or internal request needs my action

## Exclude

- General discussion and FYI messages
- Notifications, bot messages and workflow messages
- Meeting scheduling messages
- Reactions, greetings and small talk
- Status updates that don't require action

---

## Processing Rules

1. Review only conversations from the previous business day.
2. Remove duplicate action items.
3. Don't create an action unless the conversation supports it.
4. Don't infer due dates.
5. Don't infer ownership. If ownership is unclear, skip the item.
6. If the conversation shows the action is already done, don't include it.
7. If nothing qualifies, write "No new actions identified" and stop.

---

## Output Location

Create or update:

```text
{{ROOT}}/Action Tracker.md
```

This file is cumulative. Add new items. Don't remove or overwrite existing ones.

---

## Markdown Structure

```markdown
# Action Tracker

## Daily Summary - YYYY-MM-DD

Total New Actions: X

Highest Priority Items:
- Item
- Item
- Item

## Open Actions

| Date Added | Action | Requested By | Source | Due Date | Category | Status |
|---|---|---|---|---|---|---|

## Actions Older Than 14 Days

List every open action that was added more than 14 days ago.

## Completed Actions

| Date Added | Date Completed | Action | Source |
|---|---|---|---|
```

**Status:** Open, unless the conversation shows it's complete.

**Categories:** Use one category per item. Replace these with your own:

- External Request
- Internal Request
- Follow Up
- {{TOPICS}}

When a conversation shows that an open action is complete, move it from **Open Actions** to **Completed Actions**. Keep the original date added and add the completion date.

---

## Success Criteria

The output answers only three questions:

1. What do I need to do?
2. Who asked me to do it?
3. Where did it come from?

If a piece of information doesn't help answer one of those, leave it out.
