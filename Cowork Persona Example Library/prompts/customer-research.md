# Customer research prompt

Fill in the brackets for a named company. Uses public job postings only.

```
Act as a Microsoft 365 Copilot Cowork adoption strategist preparing a customer workshop for [CUSTOMER NAME].
Optional context: Careers site URL: [CAREERS URL or "find it"]. Industry: [INDUSTRY or "infer it"].
STEP 1 – Research the customer (use web search).
- Find [CUSTOMER NAME]'s current open jobs on its careers site and LinkedIn.
- Map at least one real open role to each persona below. Read the full job description for at least 6 roles and use their duty language. If you only see a role's title, tag it "(title only)" and use typical job-posting language.
- From the postings, note any named systems (ERP, MES, HRIS, PLM, CRM, PMS, TMS, quality system, etc.). These are "seen in postings" connector signals.
- Flag postings from franchisees, partners or subsidiaries that are separate employers; treat their systems as signals to confirm, not proof.
- Identify the customer's business areas (brands, product lines, plants/properties, service, distribution, regions).
Personas (15): Finance, HR, Frontline Worker, Frontline Supervisor, Quality, Supply Chain/Procurement, Safety/EHS, Field Service/Repair, Sales/Marketing, Customer Service, Operations/Facilities, Engineering/R&D/Technology, Executive, plus TWO industry-specific personas you choose (suggested: [SUGGESTED PERSONAS or "you choose"]). Say why you chose them.
If no open role fits a persona, use the closest role whose posting covers those duties and say so in the Gaps note.
STEP 2 – Produce ONE table with 15 rows (one per persona) and exactly these columns:
1. Generalized Title / Persona: persona → generalized job title (add "(title only)" if you didn't read the full description)
2. Duty: key responsibilities from the job description (≤12 words)
3. Sources Cowork uses & Potential third-party connectors: Microsoft 365 sources (Outlook, Teams chats, meeting transcripts, SharePoint/OneDrive, calendar, Dynamics 365, Power BI) + 1–2 systems labeled *(seen)* or *(confirm)*
4. Example Ask & Expected result 1
5. Example Ask & Expected result 2
6. Example Ask & Expected result 3
7. Example Ask & Expected result 4
8. Example Ask & Expected result 5
9. Example Ask & Expected result 6
Format each ask cell as: "natural-language ask" → **deliverable** (Word doc, Excel tracker, PowerPoint deck, draft email for approval, Teams post drafted for approval, scheduled digest, meeting invite drafted for approval).
Rules:
- Every ask is multi-step: find/gather → analyze → produce a file or action. No simple Q&A.
- Six asks per persona: two daily/operational, two analytical, two leadership/communication.
- Use authentic industry terms and the customer's real brands, sites and product lines.
- Anything that sends, posts or schedules is a "draft for approval."
- Keep each cell to 1–2 short sentences.
- Don't invent product features, connectors, or customer data. Never claim the customer uses a system unless a posting or public source names it.
- Use only public information; make the asks illustrative, not real internal data.
After the table, add:
- Mapped by business area: personas grouped by the customer's business areas.
- Top 5 custom skills to build first: kebab-case name, personas served, and the repeatable steps it encodes (one line each).
- Top 5 connectors to demo: connector, personas it powers, one-line workshop story. "Seen in postings" connectors first.
- Sources: links to the job postings you used.
- Gaps: personas with no matching open role, franchise/partner caveats, expiring postings, and a reminder to re-check roles before the workshop.
```
