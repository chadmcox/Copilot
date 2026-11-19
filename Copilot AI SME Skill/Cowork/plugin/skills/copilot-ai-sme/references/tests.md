# Behavioral test prompts

| # | Prompt | Should trigger | Expected behavior |
|---|---|---|---|
| 1 | "How do I block a group from using Cowork?" | yes | Spending policy scope is the only access control; remove from every Cowork policy; low limit doesn't block; cite cowork-access; Verified |
| 2 | "Our Autopilot users say it stopped answering" | yes | Ordered checklist (Frontier, license, activation, spending policy coverage and credits, provider settings); note no message is shown |
| 3 | "Estimate monthly credits for a Copilot Studio agent with 500 unlicensed users" | yes | Ask the estimation questions; use billing-rates page (fetched); show math; say it's an estimate, not a quote; Copilot Credit Estimator link |
| 4 | "Why doesn't the Azure invoice match Copilot Cost Management?" | yes | Credits vs currency, non-billable usage, timing; one shared Copilot Studio meter; reconcile monthly |
| 5 | "Should this be a Cowork plugin or a Copilot Studio agent?" | yes | Recommendation first, ranked options, auth, data reach, cost driver, Before you deploy table |
| 6 | "What changed for Copilot Studio in the last 30 days?" | yes | Roadmap via Release Communications MCP + blogs (+ Message Center if available); table with IDs, dates, status |
| 7 | "Map our Autopilot rollout to the CISA agentic AI guidance" | yes | Five CISA categories + prerequisites; Microsoft control per row; verified links; disclaimer |
| 8 | "Threat model our HR agent" | yes | ASI01–ASI10 walk with Applies/N/A, gaps, fixes; disclaimer |
| 9 | "Paste the CIS benchmark text for recommendation 1.1.1" | yes | Decline to reproduce licensed text; give ID, paraphrase, link |
| 10 | "How do I reset Windows Autopilot for a laptop?" | no | Out of scope (Windows Autopilot); say so |
| 11 | "Write a birthday message for a coworker" | no | Not a Copilot/AI question; skill stays quiet |
| 12 | "Is SMS allowed as an MFA method in my tenant?" | hand off | Identity question → entra-id-sme |
