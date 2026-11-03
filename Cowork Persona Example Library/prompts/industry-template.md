# Industry template prompt

Generates one industry page for `industries/`. Replace `[INDUSTRY]` and `[PRACTICE]`. [Airlines](../industries/airlines.md) is the reference page for this format.

```
Industry: [INDUSTRY]  Practice: [PRACTICE]

Act as a Microsoft 365 Copilot Cowork adoption strategist building a REUSABLE INDUSTRY persona library (not for one customer).

PERSONAS
Produce 15 personas: Finance, HR, Frontline Worker, Frontline Supervisor, Quality, Supply Chain/Procurement, Safety/EHS, Field Service/Repair, Sales/Marketing, Customer Service, Operations/Facilities, Engineering/R&D/Technology, Executive, plus TWO industry-specific personas you choose (say why in one sentence). Map each persona to the industry-typical job title (e.g., for cruise lines Frontline Worker = Stateroom Attendant; Field Service = Marine Engineer). Make the generic functions specific to this industry: an airline Finance persona talks about RASM and interline billing, not generic month-end close.

Per persona:
- Title.
- Duty: 12 words or fewer, in typical job-posting language.
- Systems: only the 1-3 industry systems this persona uses BEYOND the standard Microsoft 365 sources (Outlook, Teams, meeting transcripts, SharePoint/OneDrive, calendar). Do not repeat the standard sources. Add Dynamics 365 or Power BI only if this role would really use them. Label every industry system "(confirm)"; use categories like "ERP (confirm)" or well-known vendors as "e.g." examples.
- THREE asks, one of each:
  - Quick win: a small, everyday job that pays off right away. One step is fine. Phrase it the way the person would actually type it, often as a question.
  - Hand-off: a multi-step job that pulls from 2 or more named sources, analyzes them, and produces something the person would otherwise spend an hour or more on. Name the sources in the ask.
  - Recurring: something scheduled or triggered ("every Monday", "before each trip", "at the end of each shift") that keeps working without the person.
  Each ask must fit the role. Frontline roles get asks about their own work (their trip, their shift, their aircraft), not leadership communications.

ASK FORMAT
- **Quick win:** "natural-language ask" → deliverable
Deliverable is one of: Word doc, Word doc (one page), Excel workbook, PowerPoint deck, email draft(s), Teams post draft, meeting invite draft, scheduled digest. Combine two with " + " only when the ask really produces both. Use placeholders like [Company], [ship], [plant], [site], [tail number] instead of real names. Vary the opening verbs; don't start most asks with Draft, Analyze, Compare or Summarize. Don't invent Copilot features or connectors.

OTHER SECTIONS
- Top 3 demos: the three asks from different personas that best show Cowork in this industry (at least one Hand-off and one Recurring), each one line with a link to the persona.
- Top 5 custom skills: kebab-case name, personas, steps as "gather → analyze → produce". Where one of the library's example skills fits (customer-escalation-pack, safety-incident-brief, shift-handover-digest, supplier-risk-tracker, voyage-guest-recovery), say "Start from" and link it.
- Top 5 connectors to demo: connector category, personas, one-line workshop story.
- Business areas: typical business areas with their personas.
- Confirm with each customer: things that vary by company.

OUTPUT
Markdown in this order: title; "Back to index" link; Top 3 demos; How to read this page (the three ask types, the standard Microsoft 365 sources stated once, systems marked (confirm), anything that sends/posts/schedules is a draft for approval); Why the two industry personas; Personas at a glance table (#, Persona, Title, Duty); one ### section per persona (Title, Duty, Systems, three bulleted asks, and "Related example skill:" link where one fits); Top 5 custom skills; Top 5 connectors; Business areas; Confirm with each customer.
Exactly 15 personas. No web research required. Final reply: one line, no tool names.
```
