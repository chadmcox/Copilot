# Industry template prompt

Generates one industry page for `industries/`. Replace `[INDUSTRY]` and `[PRACTICE]`.

```
Industry: [INDUSTRY]  Practice: [PRACTICE]

Act as a Microsoft 365 Copilot Cowork adoption strategist building a REUSABLE INDUSTRY persona library (not for one customer).
For the industry given, produce 15 personas: Finance, HR, Frontline Worker, Frontline Supervisor, Quality, Supply Chain/Procurement, Safety/EHS, Field Service/Repair, Sales/Marketing, Customer Service, Operations/Facilities, Engineering/R&D/Technology, Executive, plus TWO industry-specific personas you choose (say why). Map each persona to the industry-typical job title (e.g., for cruise lines Frontline Worker = Stateroom Attendant; Field Service = Marine Engineer).
Per persona: title; duty (<=12 words, typical posting language); sources = Microsoft 365 sources (Outlook, Teams chats, meeting transcripts, SharePoint/OneDrive, calendar, Dynamics 365, Power BI) + 1-2 systems COMMON in this industry, always labeled "(confirm)" since no specific customer is named (use system categories like "ERP (confirm)", "PMS (confirm)", or widely known vendors as "e.g." examples); and SIX asks: ask1 & ask4 daily/operational, ask2 & ask5 analytical, ask3 & ask6 leadership/communication.
Ask format: "natural-language ask" → deliverable (Word doc, Excel tracker, PowerPoint deck, draft email for approval, Teams post drafted for approval, scheduled digest, meeting invite drafted for approval). Every ask multi-step (gather → analyze → produce). Authentic industry terms; use placeholders like [Company], [ship], [plant], [site] instead of real customer names. Anything that sends/posts/schedules is "drafted for approval". 1–2 short sentences per cell. Don't invent Copilot features or connectors.
Also: business_areas (typical business areas in this industry with personas), skills (5: kebab-case name, personas, steps), connectors (5: connector category, personas, one-line workshop story), gaps (things to confirm per customer).
Output Markdown with sections: title, why personas, personas-at-a-glance table, one section per persona (title, duty, sources, 6 numbered asks), top 5 skills, top 5 connectors, business areas, confirm-with-customer. (Field list for reference: {"industry","practice","why_personas","rows":[{persona,title,duty,sources,ask1..ask6}],"business_areas":[{area,personas}],"skills":[{name,personas,steps}],"connectors":[{connector,personas,story}],"gaps":[...]} ) Exactly 15 rows. No web research required. Final reply: one line, no tool names.
```
