# Industrial Automation & Electrical Equipment

[Back to index](../README.md)

## Top 3 demos

Start a workshop with these. Each shows something different Cowork does well.

1. **Field Service Engineer, hand-off:** a commissioning job pack for tomorrow's site built from emails, drawings and service history. → [jump](#8-field-servicerepair)
2. **Product Compliance Engineer, recurring:** every Monday, certification expirations, upcoming audits and certifier correspondence in one watch list. → [jump](#15-industry-specific-product-compliance--certification)
3. **Electrical Assembler, quick win:** "What drawing revisions hit my panel cell since last shift?" → [jump](#3-frontline-worker)

## How to read this page

Each persona has three asks:

- **Quick win:** a small, everyday job that pays off right away.
- **Hand-off:** a multi-step job across several sources that would otherwise take an hour or more.
- **Recurring:** something scheduled or ongoing that keeps working without the person.

Every persona can use the standard Microsoft 365 sources (Outlook, Teams, meeting transcripts, SharePoint/OneDrive, calendar). **Systems** lists only the industry-specific systems that persona uses beyond those, marked *(confirm)* because they vary by company. Anything that sends, posts or schedules is a draft for the person's approval.

**Why the two industry personas:** Applications Engineer chosen because engineered-to-order configuration drives quotes and wins; Product Compliance Engineer chosen because UL/CE/IEC certification gates every product shipment.

## Personas at a glance

| # | Persona | Title | Duty |
|---|---|---|---|
| 1 | [Finance](#1-finance) | Plant Controller | Manage plant cost accounting, standard costs, and monthly close variances. |
| 2 | [HR](#2-hr) | HR Business Partner – Manufacturing | Support plant staffing, labor relations, and skilled-trades workforce planning. |
| 3 | [Frontline Worker](#3-frontline-worker) | Electrical Assembler | Assemble and wire control panels per drawings and work instructions. |
| 4 | [Frontline Supervisor](#4-frontline-supervisor) | Production Supervisor | Lead assembly shift to meet safety, quality, delivery, and cost targets. |
| 5 | [Quality](#5-quality) | Quality Engineer | Drive CAPA, NCR disposition, and UL/CE compliance for products. |
| 6 | [Supply Chain/Procurement](#6-supply-chainprocurement) | Commodity Buyer – Electronics | Source semiconductors, PCBs, and components; manage supplier performance. |
| 7 | [Safety/EHS](#7-safetyehs) | EHS Manager | Lead plant safety programs, arc-flash compliance, and environmental permits. |
| 8 | [Field Service/Repair](#8-field-servicerepair) | Field Service Engineer | Commission, troubleshoot, and repair drives, PLCs, and switchgear on-site. |
| 9 | [Sales/Marketing](#9-salesmarketing) | Regional Sales Manager – Automation | Grow OEM, systems integrator, and distributor revenue in territory. |
| 10 | [Customer Service](#10-customer-service) | Customer Service Representative – Order Management | Manage orders, expedites, RMAs, and delivery commitments for customers. |
| 11 | [Operations/Facilities](#11-operationsfacilities) | Plant Manager | Run plant operations, capacity, budget, and continuous improvement. |
| 12 | [Engineering/R&D/Technology](#12-engineeringrdtechnology) | Controls / Product Design Engineer | Design control products and firmware; manage ECNs and certifications. |
| 13 | [Executive](#13-executive) | VP Operations / Business Unit GM | Own BU P&L, plant network performance, and growth strategy. |
| 14 | [Industry-Specific: Applications/Solutions Engineer](#14-industry-specific-applicationssolutions-engineer) | Applications Engineer | Configure drive, PLC, and switchgear solutions to customer specs. |
| 15 | [Industry-Specific: Product Compliance & Certification](#15-industry-specific-product-compliance--certification) | Product Compliance Engineer | Maintain UL, CE, IEC certifications and regulatory documentation. |

## Personas and example asks

### 1. Finance

**Title:** Plant Controller  
**Duty:** Manage plant cost accounting, standard costs, and monthly close variances.  
**Systems:** ERP (confirm; e.g., SAP S/4HANA)

- **Quick win:** "What PPV and labor variance items are still open for [plant]'s close?" → Excel workbook
- **Hand-off:** "Compare standard vs. actual cost on the top 20 drive and switchgear SKUs, explain the drivers, and draft the month-end margin bridge" → Word doc + Excel workbook
- **Recurring:** "Before each close, reconcile variance emails against the close checklist and list open items" → scheduled digest

### 2. HR

**Title:** HR Business Partner – Manufacturing  
**Duty:** Support plant staffing, labor relations, and skilled-trades workforce planning.  
**Systems:** HCM (confirm; e.g., Workday)

- **Quick win:** "Which electrician and assembler reqs at [plant] are aging?" → Excel workbook
- **Hand-off:** "Analyze overtime and turnover by shift with exit-interview notes, and prepare the skilled-trades pipeline update for plant leadership" → Word doc
- **Recurring:** "Every Friday, summarize open employee-relations items" → scheduled digest

### 3. Frontline Worker

**Title:** Electrical Assembler  
**Duty:** Assemble and wire control panels per drawings and work instructions.  
**Systems:** MES (confirm), PLM (confirm; e.g., Siemens Teamcenter)

- **Quick win:** "What drawing revisions hit my panel cell since last shift?" → Word doc (one page)
- **Hand-off:** "Compare the last three NCRs on my panel type, list the common wiring errors, and put them into a checklist for my next build" → Word doc (one page)
- **Recurring:** "At the end of each shift, draft my handoff with orders in progress and missing parts" → Word doc (one page)

Related example skill: [shift-handover-digest](../skills/shift-handover-digest.md)

### 4. Frontline Supervisor

**Title:** Production Supervisor  
**Duty:** Lead assembly shift to meet safety, quality, delivery, and cost targets.  
**Systems:** MES (confirm), ERP (confirm; e.g., SAP S/4HANA)

- **Quick win:** "Who's absent and which work orders are open for tomorrow?" → Excel workbook
- **Hand-off:** "Analyze two weeks of downtime reasons on [line], rank the top losses, and summarize the week's SQDC performance for the plant manager" → Word doc
- **Recurring:** "Every morning, build my shift huddle sheet from yesterday's OEE, scrap and safety notes" → Word doc (one page)

Related example skill: [shift-handover-digest](../skills/shift-handover-digest.md)

### 5. Quality

**Title:** Quality Engineer  
**Duty:** Drive CAPA, NCR disposition, and UL/CE compliance for products.  
**Systems:** QMS (confirm), PLM (confirm; e.g., Siemens Teamcenter)

- **Quick win:** "Summarize today's MRB meeting into decisions and owners" → Word doc (one page)
- **Hand-off:** "Analyze field returns on [product] with a Pareto of failure modes, and prepare the 8D summary for the customer escalation" → Word doc
- **Recurring:** "Every Monday, rebuild the NCR disposition tracker from email and Teams" → Excel workbook

Related example skill: [customer-escalation-pack](../skills/customer-escalation-pack.md)

### 6. Supply Chain/Procurement

**Title:** Commodity Buyer – Electronics  
**Duty:** Source semiconductors, PCBs, and components; manage supplier performance.  
**Systems:** ERP (confirm; e.g., SAP S/4HANA), supplier portal (confirm)

- **Quick win:** "Which parts are at shortage risk from supplier emails and today's MRP exceptions?" → Excel workbook
- **Hand-off:** "Analyze lead-time and price trends for MCUs and power semis across suppliers, and draft the escalation to [supplier] on past-due deliveries" → Word doc + email draft
- **Recurring:** "Every Friday, summarize planners' expedite requests" → scheduled digest

Related example skill: [supplier-risk-tracker](../skills/supplier-risk-tracker.md)

### 7. Safety/EHS

**Title:** EHS Manager  
**Duty:** Lead plant safety programs, arc-flash compliance, and environmental permits.  
**Systems:** EHS system (confirm)

- **Quick win:** "Which audit corrective actions are open and when are they due?" → Excel workbook
- **Hand-off:** "Analyze recordables and lockout/tagout findings across sites for root causes, and draft the arc-flash PPE safety alert for all shifts" → Word doc + Teams post draft
- **Recurring:** "Every Friday, update the near-miss trend tracker by area" → Excel workbook

Related example skill: [safety-incident-brief](../skills/safety-incident-brief.md)

### 8. Field Service/Repair

**Title:** Field Service Engineer  
**Duty:** Commission, troubleshoot, and repair drives, PLCs, and switchgear on-site.  
**Systems:** Field service mgmt (confirm), PLM (confirm; e.g., Siemens Teamcenter)

- **Quick win:** "Which service cases are open in my territory?" → Excel workbook
- **Hand-off:** "For tomorrow's commissioning at [site], gather emails, drawings and service history into a job pack" → Word doc
- **Recurring:** "After each startup visit, draft the service report to the customer" → email draft

### 9. Sales/Marketing

**Title:** Regional Sales Manager – Automation  
**Duty:** Grow OEM, systems integrator, and distributor revenue in territory.  
**Systems:** Dynamics 365 Sales, distributor POS data (confirm)

- **Quick win:** "Prep me for today's meeting with [customer]: emails, quotes and opportunities" → Word doc (one page)
- **Hand-off:** "Analyze distributor POS by product line, find declining accounts, and build the territory review" → PowerPoint deck
- **Recurring:** "Every Monday, list quotes expiring this week and draft follow-ups" → email drafts

### 10. Customer Service

**Title:** Customer Service Representative – Order Management  
**Duty:** Manage orders, expedites, RMAs, and delivery commitments for customers.  
**Systems:** Dynamics 365, ERP (confirm; e.g., SAP S/4HANA)

- **Quick win:** "Which expedites are open and what dates did we promise?" → Excel workbook
- **Hand-off:** "Analyze RMA reasons by product family and on-time delivery by customer, and draft notifications for delayed orders" → Word doc + email drafts
- **Recurring:** "Every morning, summarize order-status inquiries and draft replies with ship dates" → email drafts

Related example skill: [customer-escalation-pack](../skills/customer-escalation-pack.md)

### 11. Operations/Facilities

**Title:** Plant Manager  
**Duty:** Run plant operations, capacity, budget, and continuous improvement.  
**Systems:** MES (confirm), CMMS (confirm)

- **Quick win:** "Give me the morning brief from overnight production, safety and quality" → Word doc (one page)
- **Hand-off:** "Analyze capacity vs. backlog by line for next quarter, compare lean project savings to plan, and prepare the tier-3 review deck" → PowerPoint deck
- **Recurring:** "Every Monday, list overdue preventive maintenance and critical spares" → scheduled digest

### 12. Engineering/R&D/Technology

**Title:** Controls / Product Design Engineer  
**Duty:** Design control products and firmware; manage ECNs and certifications.  
**Systems:** PLM (confirm; e.g., Siemens Teamcenter)

- **Quick win:** "Which ECNs on my products are waiting for review?" → Excel workbook
- **Hand-off:** "Group test failures from validation reports on [product], add customer feature requests from Teams and email, and draft the design review agenda and invite" → Word doc + meeting invite draft
- **Recurring:** "Every Friday, summarize customer feature requests for my products" → scheduled digest

### 13. Executive

**Title:** VP Operations / Business Unit GM  
**Duty:** Own BU P&L, plant network performance, and growth strategy.  
**Systems:** ERP (confirm; e.g., SAP S/4HANA)

- **Quick win:** "What are today's top issues across plants?" → Word doc (one page)
- **Hand-off:** "Analyze BU margin and backlog vs. plan and plant KPIs (OEE, OTD, safety) across the network, and prepare the quarterly business review deck" → PowerPoint deck
- **Recurring:** "Every Monday, list customer escalations and commitments due this week" → scheduled digest

### 14. Industry-Specific: Applications/Solutions Engineer

**Title:** Applications Engineer  
**Duty:** Configure drive, PLC, and switchgear solutions to customer specs.  
**Systems:** PLM (confirm; e.g., Siemens Teamcenter), CPQ (confirm)

- **Quick win:** "Which technical clarifications with customers are still open?" → Excel workbook
- **Hand-off:** "Turn the customer spec and RFQ emails for [project] into a requirements list, compare BOM options for cost and lead time, and draft the technical proposal summary" → Word doc + Excel workbook
- **Recurring:** "Every Friday, list open clarifications by project and who owes the answer" → scheduled digest

### 15. Industry-Specific: Product Compliance & Certification

**Title:** Product Compliance Engineer  
**Duty:** Maintain UL, CE, IEC certifications and regulatory documentation.  
**Systems:** PLM (confirm; e.g., Siemens Teamcenter), QMS (confirm)

- **Quick win:** "Does the design change on [product] affect its certification?" → Word doc (one page)
- **Hand-off:** "Gather new IEC standard changes and our affected products, check certification status, and draft the notice to engineering" → Word doc + email draft
- **Recurring:** "Every Monday, update certification expirations, upcoming audits and certifier correspondence" → Excel workbook

## Top 5 custom skills to build first

- **shift-huddle-brief** (Production Supervisor; Plant Manager): Gather overnight production, quality, safety notes; Analyze SQDC vs. targets; Produce huddle Word sheet. Start from [shift-handover-digest](../skills/shift-handover-digest.md).
- **ncr-disposition-tracker** (Quality Engineer): Collect NCRs from email/Teams; Age and classify; Produce Excel workbook
- **shortage-risk-scan** (Commodity Buyer – Electronics; Production Supervisor): Gather supplier notices and MRP exceptions; Rank risk; Produce tracker and draft escalation. Start from [supplier-risk-tracker](../skills/supplier-risk-tracker.md).
- **commissioning-job-pack** (Field Service Engineer): Pull drawings, emails, service history; Summarize risks; Produce Word job pack
- **certification-watch** (Product Compliance Engineer; Controls / Product Design Engineer): Gather certs and ECNs; Assess impact; Produce tracker and briefing

## Top 5 connectors to demo

- **ERP (confirm)** (Plant Controller; Commodity Buyer – Electronics): Buyer pulls MRP exceptions alongside supplier emails to flag shortages before the line stops.
- **MES (confirm)** (Production Supervisor; Plant Manager): Supervisor gets an OEE-backed huddle sheet in minutes.
- **PLM (confirm)** (Controls / Product Design Engineer; Applications Engineer): Engineer sees ECN status and drawings next to customer requests.
- **QMS (confirm)** (Quality Engineer): NCRs and CAPAs roll into a single disposition tracker.
- **Field service mgmt (confirm)** (Field Service Engineer): Technician gets job pack with service history before arriving on-site.

## Business areas

- **Manufacturing Operations:** Production Supervisor; Electrical Assembler; Plant Manager
- **Quality & Compliance:** Quality Engineer; Product Compliance Engineer
- **Supply Chain:** Commodity Buyer – Electronics
- **Commercial:** Regional Sales Manager – Automation; Applications Engineer; Customer Service Representative – Order Management
- **Service:** Field Service Engineer
- **Engineering:** Controls / Product Design Engineer
- **Corporate:** Plant Controller; HR Business Partner – Manufacturing; EHS Manager; VP Operations / Business Unit GM

## Confirm with each customer

- Which ERP, MES, PLM, QMS systems are in use
- Connector availability and licensing
- Data access permissions per plant
- Union/works council considerations for frontline data
- Export control (ITAR/EAR) restrictions on technical data
- Frontline device access (shared kiosks vs. mobile)
