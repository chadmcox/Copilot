# Daily Meeting Notes

Review all meetings from the **previous business day** that have a transcript, a recording transcript or AI-generated meeting notes.

## Objective

Create one Markdown file per meeting that records what was decided, who owns follow-up work and what was committed, so I don't need to reopen the transcript later.

Don't write a transcript-style recap.

---

## Processing Rules

1. Retrieve all meetings from the previous business day.
2. Process only meetings that have a transcript, a recording transcript or AI-generated notes. Skip the others.
3. Create one Markdown file per meeting.
4. Use the transcript as the main source.
5. Assign an owner only when the transcript states one. Capture a due date only when it's mentioned. Otherwise leave it blank.
6. Include a link to the original meeting, and to the recording and transcript when they're available.
7. If a file for the meeting already exists, update it instead of creating a duplicate.
8. If no meetings qualify, write "No qualifying meetings" in the daily summary and stop.

---

## Output Location

Meeting files:

```text
{{ROOT}}/Meeting Notes/Meetings/YYYY-MM-DD - Meeting Title.md
```

Daily summary:

```text
{{ROOT}}/Meeting Notes/Daily Summaries/YYYY-MM-DD Daily Summary.md
```

---

## Meeting File Template

```markdown
# Meeting Title

## Meeting Information

| Field | Value |
|---|---|
| Date | |
| Time | |
| Duration | |
| Organizer | |
| Meeting Link | |
| Recording | Yes / No |
| Transcript | Yes / No |

## Attendees

### Attended
- Name

### Invited, Attendance Not Confirmed
- Name

## Executive Summary

3-5 bullets covering the purpose, key decisions and outcomes. Readable in under 30 seconds.

## Detailed Summary

### Topic 1
Summary of the discussion.

### Topic 2
Summary of the discussion.

## Decisions Made
- Decision

## Action Items

| Task | Owner | Due Date | Status |
|---|---|---|---|
| | | | Open |

## Commitments
- Commitments made to external stakeholders

## Risks and Blockers
- Item

## Follow-Up Items
- Open questions
- Pending decisions
- Topics deferred to a future meeting

## References
- Original meeting link
- Recording link
- Transcript link
```

Separate attendees into "Attended" and "Invited" only when the transcript or attendance report shows who joined. Otherwise list everyone under "Invited, Attendance Not Confirmed."

---

## Daily Summary Template

After all meeting files are created, create the daily summary:

```markdown
# Daily Meeting Summary - YYYY-MM-DD

## Meetings Reviewed
- [Meeting 1](../Meetings/YYYY-MM-DD - Meeting 1.md)
- [Meeting 2](../Meetings/YYYY-MM-DD - Meeting 2.md)

## Key Decisions
- Decision

## My Action Items

| Task | Meeting | Due Date |
|---|---|---|

## Commitments

## Risks and Escalations
```

---

## Quality Requirements

- Focus on decisions, action items, commitments and risks.
- Remove filler and repeated discussion.
- Keep summaries concise and professional.
- Capture information that will still be useful 30, 60 or 90 days later.
