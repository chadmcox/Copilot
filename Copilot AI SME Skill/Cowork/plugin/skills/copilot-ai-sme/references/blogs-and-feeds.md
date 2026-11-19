# Blogs and release feeds

## Official blogs [MS Blog]

| Blog | URL | Use for |
|---|---|---|
| Microsoft 365 Copilot Blog (Tech Community) | https://techcommunity.microsoft.com/category/microsoft-365-copilot/blog/microsoft365copilotblog | Monthly "What's New in Microsoft 365 Copilot", feature launches |
| Microsoft Copilot Blog (Tech Community), incl. Cowork release log "(Co)work in Progress" | https://techcommunity.microsoft.com/blog/microsoft365copilotblog/cowork-in-progress/4511672 | Cowork milestones and launches |
| Copilot Studio Blog (Tech Community; started Apr 8, 2026) | https://techcommunity.microsoft.com/category/copilot-studio/blog/copilot-studio-blog | Builder and admin posts: governance, extensibility, operations |
| Microsoft Copilot Studio Blog (microsoft.com) | https://www.microsoft.com/microsoft-copilot/blog/copilot-studio/ | Product announcements |
| Microsoft Copilot blog (microsoft.com) | https://www.microsoft.com/microsoft-copilot/blog/ | Event announcements (Build, Ignite), Home, Code, Autopilot |
| Microsoft 365 Blog | https://www.microsoft.com/microsoft-365/blog/ | Major Microsoft 365 announcements |
| Power Platform Blog | https://www.microsoft.com/power-platform/blog/ | Power Platform governance, Copilot Studio |
| Microsoft Entra Blog | https://techcommunity.microsoft.com/category/microsoft-security/blog/microsoft-entra-blog | Agent ID, agent identity governance |
| Microsoft Security Blog | https://www.microsoft.com/security/blog/ | AI threats, incident guidance |
| FinOps blog (Microsoft Cost Management) | https://techcommunity.microsoft.com/category/azure/blog/finopsblog | Cost Management and FinOps toolkit updates |

Checked Nov 19, 2026: the Cowork release log post and the existence of both Copilot Studio blogs. The other URLs weren't opened when this skill was built, and Tech Community URLs move: if one fails, search the blog name and fetch the first official result.

## Rules for using blogs

1. **Show the publish date** every time a post is cited.
2. **Announcement ≠ setting.** A blog proves that Microsoft announced something and when. Settings, limits, roles and billing behavior come from Learn.
3. **Newer than Learn or conflicting:** cite both with dates, say the docs may lag, mark **Partially verified**.
4. **Freshness:** for "what's new" answers, prefer posts from the last 90 days; flag anything older than 12 months as possibly outdated.
5. **Event posts** (Build, Ignite) often describe staged rollouts. Pair them with the roadmap item for the real status.
6. **Comments and replies** on Tech Community posts are community content: `[3P]`.

## Release feeds

| Feed | How to read | Cite as |
|---|---|---|
| Microsoft Copilot Roadmap | Release Communications MCP: `get_recent_m365_roadmaps`, `get_m365_roadmap_by_id` | `[Roadmap] <ID> — <status>, <release month>` |
| Message Center | Graph `GET /admin/serviceAnnouncement/messages` (ServiceMessage.Read.All), through the Enterprise MCP or a script the user runs | `[Message Center] MC<number>, <date>` |
| Azure Updates | Release Communications MCP: `get_recent_azure_updates`, `get_azure_update_by_id` | `[Roadmap] Azure update <ID>` |
| Power Platform release plans | Learn | `[MS Learn]` |

Roadmap dates move. Always say "roadmap date as of <today>".
