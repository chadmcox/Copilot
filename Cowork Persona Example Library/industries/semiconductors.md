# Semiconductors

[Back to index](../README.md)

## Top 3 demos

Start a workshop with these.

1. **Yield / Quality Engineer, hand-off:** an 8D update for a customer excursion built from lot dispositions, SPC data and yield by layer. → [jump](#5-quality)
2. **Materials & Commodity Buyer, recurring:** every Monday, days of supply for photoresist, gases and critical consumables against forecasted wafer starts. → [jump](#6-supply-chainprocurement)
3. **Manufacturing Technician (Wafer Fab), quick win:** "What's on today's PM and qualification list for my bay?" → [jump](#3-frontline-worker)

## How to read this page

Each persona has a **quick win**, a **hand-off** and a **recurring** ask. Systems marked *(confirm)* vary by company. Anything that sends, posts or schedules is a draft. Details: [How to use](../README.md#how-to-use).

**Why the two industry personas:** Lithography Equipment Engineer chosen because patterning is the fab's typical bottleneck and costliest tool set; Test & Product Engineer chosen because sort/final test yield links fab output to customer quality and revenue.

## Personas at a glance

| # | Persona | Title |
|---|---|---|
| 1 | [Finance](#1-finance) | Fab Cost Accountant |
| 2 | [HR](#2-hr) | Fab Talent Acquisition Partner |
| 3 | [Frontline Worker](#3-frontline-worker) | Manufacturing Technician (Wafer Fab) |
| 4 | [Frontline Supervisor](#4-frontline-supervisor) | Fab Area Shift Supervisor |
| 5 | [Quality](#5-quality) | Yield / Quality Engineer |
| 6 | [Supply Chain/Procurement](#6-supply-chainprocurement) | Materials & Commodity Buyer |
| 7 | [Safety/EHS](#7-safetyehs) | EHS Engineer (Fab) |
| 8 | [Field Service/Repair](#8-field-servicerepair) | Customer Field Applications / Equipment Service Engineer |
| 9 | [Sales/Marketing](#9-salesmarketing) | Account Manager (Design Win) |
| 10 | [Customer Service](#10-customer-service) | Customer Order Fulfillment Specialist |
| 11 | [Operations/Facilities](#11-operationsfacilities) | Fab Facilities Manager |
| 12 | [Engineering/R&D/Technology](#12-engineeringrdtechnology) | Process Integration Engineer |
| 13 | [Executive](#13-executive) | VP / General Manager, Fab Operations |
| 14 | [Industry-Specific: Lithography](#14-industry-specific-lithography) | Lithography Equipment Engineer |
| 15 | [Industry-Specific: Product/Test](#15-industry-specific-producttest) | Test & Product Engineer |

## Personas and example asks

### 1. Finance

**Title:** Fab Cost Accountant  
**Duty:** Manage wafer standard costs, variances, and month-end close.  
**Systems:** Power BI, ERP (confirm; e.g., SAP S/4HANA)

- **Quick win:** "What wafer-start and scrap cost variances came in yesterday for [fab]?" → Excel workbook
- **Hand-off:** "Compare cost per wafer by node this quarter vs. last, flag yield-driven swings, and draft the month-end variance narrative" → Word doc
- **Recurring:** "Before each close, list open variance questions from email and the close folder" → scheduled digest

### 2. HR

**Title:** Fab Talent Acquisition Partner  
**Duty:** Recruit and onboard technicians and engineers for cleanroom operations.  
**Systems:** HRIS (confirm; e.g., Workday)

- **Quick win:** "What interview feedback is pending on open technician reqs?" → Excel workbook
- **Hand-off:** "Analyze two quarters of time-to-fill for process and equipment engineers, and draft the hiring update for fab leadership on the [fab] ramp" → Word doc
- **Recurring:** "Each month, build the onboarding plan for the new technician class" → Word doc

### 3. Frontline Worker

**Title:** Manufacturing Technician (Wafer Fab)  
**Duty:** Operate and monitor fab tools per specs in cleanroom.  
**Systems:** MES (confirm; e.g., Applied SmartFactory)

- **Quick win:** "What's on today's PM and qualification list for my bay?" → Excel workbook
- **Hand-off:** "Pull shift pass-down notes, open tool issues and lots on hold by reason code into one page for the start of shift" → Word doc (one page)
- **Recurring:** "At the end of each shift, draft my pass-down with tool issues and holds" → Word doc (one page)

Related example skill: [shift-handover-digest](../skills/shift-handover-digest.md)

### 4. Frontline Supervisor

**Title:** Fab Area Shift Supervisor  
**Duty:** Lead shift technicians to hit moves, cycle time, and safety.  
**Systems:** MES (confirm)

- **Quick win:** "Which technicians have certification gaps?" → Excel workbook
- **Hand-off:** "Analyze last week's moves vs. target and WIP bubbles by area, and prepare my area review" → PowerPoint deck
- **Recurring:** "At the start of each shift, build my brief from pass-downs, holds and tool-down emails" → Word doc (one page)

Related example skill: [shift-handover-digest](../skills/shift-handover-digest.md)

### 5. Quality

**Title:** Yield / Quality Engineer  
**Duty:** Drive yield improvement, excursion response, and 8D corrective actions.  
**Systems:** YMS/SPC (confirm; e.g., KLA Klarity)

- **Quick win:** "Which SPC charts are out of control right now?" → Excel workbook
- **Hand-off:** "Pull open excursions, lot dispositions and die yield by layer for four weeks, and draft the 8D update for the customer on the [product] excursion" → Word doc + email draft
- **Recurring:** "Every morning, summarize open excursions and lot dispositions from the last 24 hours" → scheduled digest

Related example skill: [customer-escalation-pack](../skills/customer-escalation-pack.md)

### 6. Supply Chain/Procurement

**Title:** Materials & Commodity Buyer  
**Duty:** Source wafers, chemicals, gases, and spares; manage supplier risk.  
**Systems:** ERP (confirm)

- **Quick win:** "Which POs need expediting?" → Excel workbook
- **Hand-off:** "Analyze days of supply for critical consumables against forecasted wafer starts, and draft the escalation on late [material] shipments" → Word doc + email draft
- **Recurring:** "Every Monday, compare days of supply for photoresist, gases and consumables with forecasted starts" → scheduled digest

Related example skill: [supplier-risk-tracker](../skills/supplier-risk-tracker.md)

### 7. Safety/EHS

**Title:** EHS Engineer (Fab)  
**Duty:** Manage chemical, gas, and cleanroom safety and environmental compliance.  
**Systems:** EHS system (confirm; e.g., Enablon)

- **Quick win:** "Which safety trainings are overdue?" → Excel workbook
- **Hand-off:** "Analyze near-miss trends by area and hazard type for the quarter, and draft the chemical handling safety alert after the [area] near miss" → Word doc + Teams post draft
- **Recurring:** "Every morning, summarize yesterday's gas alarms, near misses and incidents" → scheduled digest

Related example skill: [safety-incident-brief](../skills/safety-incident-brief.md)

### 8. Field Service/Repair

**Title:** Customer Field Applications / Equipment Service Engineer  
**Duty:** Support customer and fab tools; resolve failures, install, qualify.  
**Systems:** CMMS (confirm)

- **Quick win:** "Which spare parts do I need for next week's jobs?" → Excel workbook
- **Hand-off:** "Analyze MTTR and repeat failures by tool model with open tickets at [site], and draft the service visit summary for the customer" → Word doc + email draft
- **Recurring:** "Every morning, summarize open service tickets and tool-down events at [site]" → scheduled digest

### 9. Sales/Marketing

**Title:** Account Manager (Design Win)  
**Duty:** Win sockets and grow revenue across assigned OEM accounts.  
**Systems:** Dynamics 365, PLM/design-win tracker (confirm)

- **Quick win:** "What open sample, quote and lead-time requests do I have?" → Excel workbook
- **Hand-off:** "Analyze the design-win pipeline by stage and expected production ramp, and prepare the account review for [customer]" → PowerPoint deck
- **Recurring:** "After each sample review, draft the follow-up to the customer" → email draft

### 10. Customer Service

**Title:** Customer Order Fulfillment Specialist  
**Duty:** Manage orders, allocations, lead times, and customer delivery commitments.  
**Systems:** Dynamics 365, ERP (confirm)

- **Quick win:** "Which RMA and shipping inquiries are open?" → Excel workbook
- **Hand-off:** "Analyze on-time delivery and backlog aging by product, and draft lead-time updates for customers affected by [product] allocation" → Word doc + email drafts
- **Recurring:** "Every morning, summarize customer expedite and allocation requests" → scheduled digest

Related example skill: [customer-escalation-pack](../skills/customer-escalation-pack.md)

### 11. Operations/Facilities

**Title:** Fab Facilities Manager  
**Duty:** Run cleanroom, UPW, gases, power, and HVAC for uptime.  
**Systems:** BMS/FMCS (confirm)

- **Quick win:** "What facilities alarms and work orders came in overnight?" → Word doc (one page)
- **Hand-off:** "Analyze power, UPW and nitrogen use per wafer out, and prepare the facilities cost review" → PowerPoint deck
- **Recurring:** "Before a planned utility shutdown, draft the notice to the affected area" → email draft

### 12. Engineering/R&D/Technology

**Title:** Process Integration Engineer  
**Duty:** Develop and integrate process flows for new technology nodes.  
**Systems:** PLM (confirm), YMS (confirm)

- **Quick win:** "What action items came out of the last process review?" → Excel workbook
- **Hand-off:** "Analyze electrical test and yield results across process splits, and draft the technology readiness update for the [node] program" → Word doc
- **Recurring:** "Every Friday, summarize split-lot results and open experiments" → scheduled digest

### 13. Executive

**Title:** VP / General Manager, Fab Operations  
**Duty:** Lead fab output, yield, cost, and capacity strategy.  
**Systems:** Power BI, ERP (confirm)

- **Quick win:** "Give me a morning brief on outs, yield, holds and escalations" → Word doc (one page)
- **Hand-off:** "Analyze capacity use vs. demand by node for the next two quarters, and draft my all-hands message on [fab] ramp milestones" → Word doc
- **Recurring:** "Every Friday, list top customer escalations and status" → scheduled digest

### 14. Industry-Specific: Lithography

**Title:** Lithography Equipment Engineer  
**Duty:** Maintain scanners, overlay, and CD performance for patterning.  
**Systems:** SPC/APC (confirm)

- **Quick win:** "Which reticle qualifications and PMs are due this week?" → Excel workbook
- **Hand-off:** "Analyze overlay and CD trends by scanner and reticle, and draft the escalation to the scanner vendor on repeated [error]" → Word doc + email draft
- **Recurring:** "At the start of each shift, summarize scanner downtime and overlay excursions from the last shift" → scheduled digest

### 15. Industry-Specific: Product/Test

**Title:** Test & Product Engineer  
**Duty:** Own wafer sort and final test programs, bins, and yields.  
**Systems:** Test data system (confirm)

- **Quick win:** "Which test-time reduction actions are open?" → Excel workbook
- **Hand-off:** "Analyze bin Pareto changes after the new test program release and final test yield, and draft the test program change notice for the customer" → Word doc
- **Recurring:** "Every morning, summarize sort yield and bin issues from yesterday's lots" → scheduled digest

## Top 5 custom skills to build first

- **shift-pass-down-brief** (Frontline Worker; Frontline Supervisor): Gather pass-down emails and chats → identify holds and tool issues → produce Word shift brief. Start from [shift-handover-digest](../skills/shift-handover-digest.md).
- **excursion-8d-update** (Quality; Industry-Specific: Product/Test): Gather excursion notes → summarize containment and root cause → draft 8D Word doc and email for approval. Start from [customer-escalation-pack](../skills/customer-escalation-pack.md).
- **supply-risk-scan** (Supply Chain/Procurement; Executive): Gather supplier emails → rank material risks → produce Excel workbook and deck. Start from [supplier-risk-tracker](../skills/supplier-risk-tracker.md).
- **design-win-account-brief** (Sales/Marketing; Customer Service): Gather CRM and meeting notes → summarize program status → produce Word brief and follow-up draft.
- **fab-ops-weekly-review** (Executive; Frontline Supervisor; Finance): Gather Power BI and email updates → analyze vs. plan → produce PowerPoint deck.

## Top 5 connectors to demo

- **MES (confirm)** (Frontline Worker; Frontline Supervisor): Supervisor gets a shift brief combining lot holds with pass-down chats.
- **YMS/SPC (confirm)** (Quality; Industry-Specific: Lithography): Yield engineer turns excursion data and emails into an 8D draft.
- **ERP (confirm)** (Finance; Supply Chain/Procurement): Buyer ranks consumable shortages against wafer starts.
- **Dynamics 365** (Sales/Marketing; Customer Service; Field Service/Repair): Account manager preps a QBR from design-win records and emails.
- **EHS system (confirm)** (Safety/EHS): EHS engineer drafts a safety alert from near-miss trends.

## Business areas

- **Wafer Fab Operations:** Frontline Worker; Frontline Supervisor; Industry-Specific: Lithography; Executive
- **Yield, Quality & Test:** Quality; Industry-Specific: Product/Test; Engineering/R&D/Technology
- **Supply Chain & Materials:** Supply Chain/Procurement; Customer Service
- **Facilities & EHS:** Operations/Facilities; Safety/EHS
- **Commercial & Service:** Sales/Marketing; Field Service/Repair; Customer Service
- **Corporate Functions:** Finance; HR

## Confirm with each customer

- Which MES, YMS, and ERP the customer runs
- Data access and export controls for process IP
- Whether Dynamics 365 is used for design-win/CRM
- Cleanroom device policies for frontline access to Teams
- Customer-specific job titles and shift structures
