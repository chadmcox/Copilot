# Behavioral test prompts

| # | Prompt | Should trigger | Expected behavior |
|---|---|---|---|
| 1 | "Can I require token protection for guests in CA?" | yes | Fetch token-protection Learn pages + conditionalAccessSessionControls v1.0 and beta (beta URL may redirect: use the graph-validation.md fallbacks); report v1.0/beta/not found; state guest support only as the page says; confidence line |
| 2 | "Map CMMC IA.L2-3.5.3 to Entra config" | yes | Fetch CMMC L2 IA Learn page; mapping table with Graph property; [DoD CMMC] control text; compliance disclaimer |
| 3 | "Design cross-tenant access for two subsidiaries sharing Teams" | yes | Topology decision (B2B collab / direct connect / sync / MTO) with citations; inbound trust settings; break-glass/report-only notes |
| 4 | "We are still on the legacy ID Protection user risk policy — what now?" | yes | Cite retirement date from the risk-policies page with last-updated date; migration steps to CA; Graph riskRemediation note |
| 5 | "Which MDI posture assessments cover AD CS?" | yes | Fetch the MDI Certificates assessments page (overview lists categories only); list only names shown there; Unverified if fetch fails |
| 6 | "Is there a Graph property to block device code flow?" | yes | conditionalAccessPolicy.conditions.authenticationFlows.transferMethods = deviceCodeFlow, v1.0, cited |
| 7 | "Where do I turn off SMS for MFA — MFA service settings?" | yes | Cite the Sep 30, 2025 legacy-policy change; answer from the Authentication methods policy; note a method must be disabled in all policies |
| 8 | "Is the author wiki's risk-based CA set still right?" | yes | Summarize from author-wiki-guidance.md labeled [Author repo]; lead with current Learn grant controls (risk remediation, authentication strength); flag the conflicts |
| 9 | "Give me a script to remove stale guests" | yes | Report first (Get-StaleGuests); DELETES OBJECTS label; backup + confirmation before Remove-StaleGuests with -WhatIf; never link `_Archive/` |
| 10 | "Write a Python function that parses a CSV file" | no | Not an identity question; skill stays quiet |
| 11 | "Draft a birthday message for a coworker" | no | Not an identity question; skill stays quiet |
