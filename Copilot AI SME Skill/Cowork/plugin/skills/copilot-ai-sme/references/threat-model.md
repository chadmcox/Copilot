# Threat model for Copilot agents (Mode 7)

Frameworks: OWASP Top 10 for Agentic Applications 2026 [OWASP] (published Dec 9, 2025) and the CISA-led *Careful Adoption of Agentic AI Services* risk categories [CISA] (May 2026). Risk names below were checked Nov 19, 2026; open the source for descriptions and mitigations and paraphrase them.

Microsoft controls in the right column are **candidates**: verify each on Learn for the specific product before recommending.

| OWASP | Risk | CISA category | Candidate Microsoft controls to check |
|---|---|---|---|
| ASI01 | Agent goal hijack (incl. indirect prompt injection via email, files, web) | Behaviour | Limit knowledge and web sources; approval before send/share/delete (Autopilot approval check); Defender and Purview protections for AI; content moderation in Copilot Studio |
| ASI02 | Tool misuse and exploitation | Design and configuration | Least tools per agent; data policies blocking connectors/channels; MCP server approval; plugin access policies |
| ASI03 | Identity and privilege abuse | Privilege | Entra Agent ID per agent; delegated vs own identity chosen deliberately; least-privilege scopes; Conditional Access for agents; sponsors (entra-id-sme) |
| ASI04 | Agentic supply chain vulnerabilities (plugins, MCP servers, skills, prompts) | Structural | Plugin publisher category controls; admin consent for MCP; scoped uploads; review third-party plugins |
| ASI05 | Unexpected code execution | Design and configuration | Use managed runtimes (Copilot Managed Runtime, Code) with governance defaults; block unneeded code tools |
| ASI06 | Memory and context poisoning | Behaviour | Users review/delete Autopilot memory; limit shared knowledge sources; monitor changes to agent instructions |
| ASI07 | Insecure inter-agent communication | Structural | Authenticated connectors only; no unauthenticated channels (data policies) |
| ASI08 | Cascading failures | Structural | Per-user and policy credit limits; agent monthly limits; start with low-risk tasks; staged rollout |
| ASI09 | Human-agent trust exploitation | Accountability | Approval cards for high-impact actions; user training; label agent output |
| ASI10 | Rogue agents | Accountability / Privilege | Agent 365 inventory; owners and lifecycle workflows; kill switch (remove from spending policy or activation scope, disable agent identity) |

CISA's guidance also lists **cyber security prerequisites before implementing AI agents** (see the PDF); check tenant hardening first (CISA SCuBA, entra-id-sme).

## Steps
1. Describe the agent: product, identity model, tools/connectors/MCP, knowledge sources, autonomy (user-triggered vs scheduled vs always-on), who uses it, data sensitivity.
2. Walk ASI01–ASI10; mark each **Applies / Partly / N/A** with a one-line reason.
3. For each that applies: current control, gap, recommended Microsoft control (verified), residual risk.
4. Map to the CISA category and, if asked, NIST AI RMF function (Govern/Map/Measure/Manage).
5. Output table + top 3 fixes + disclaimer (SKILL.md rule 10).

## Output
| ASI | Applies? | Scenario for this agent | Current control | Gap | Fix (Microsoft control, source) | Residual risk |
|---|---|---|---|---|---|---|
