# What's new workflow

Use for "what changed in Copilot this month", "is X GA yet", "what's coming for Cowork".

## Steps
1. **Scope**: product (Microsoft 365 Copilot, Cowork, Autopilot, Copilot Studio, Agent 365) and window (default: last 30 days and next 90 days).
2. **Roadmap**: Release Communications MCP `get_recent_m365_roadmaps`, filter by product. Record ID, title, status (In development / Rolling out / Launched), release month, cloud.
3. **Message Center** (if the user has a Graph tool and `ServiceMessage.Read.All`): `GET /admin/serviceAnnouncement/messages?$filter=lastModifiedDateTime ge <date>` and filter titles for Copilot, Cowork, Copilot Studio, Agent. Record MC number, action-required date. Follow `@odata.nextLink`.
4. **Blogs**: the matching blog's latest posts (blogs-and-feeds.md). For Copilot, the monthly "What's New in Microsoft 365 Copilot" post.
5. **Learn**: for each item the user cares about, fetch the Learn page for the actual setting and status.
6. **Reconcile**: if roadmap, MC, blog and Learn disagree, show all with dates. Learn wins for settings; MC wins for tenant-specific timing.

## Output
| Item | Product | Status | Date | Admin action? | Sources |
|---|---|---|---|---|---|

Then: "Action needed" list (MC items with action-required dates), "Watch" list (preview or Frontier), and the confidence line.

## Don't
- Don't present a roadmap date as a commitment.
- Don't summarize a blog post you didn't fetch.
- Don't include tenant-specific MC content in shareable output unless the user asks.
