# Car Rental, Leasing & Fleet

[Back to index](../README.md)

## Top 3 demos

Start a workshop with these.

1. **Fleet Safety & Compliance Manager, recurring:** every morning, open recall vehicles still available or on rent, by branch, with a hold reminder drafted for each branch manager. → [jump](#7-safetyehs)
2. **Customer Care Specialist, hand-off:** a damage-claim case file built from rental agreement, check-in photos, emails and repair invoice. → [jump](#10-customer-service)
3. **Branch Manager / Station Manager, quick win:** "Give me today's fleet status: ready, dirty, in shop, on rent vs. reservations." → [jump](#4-frontline-supervisor)

## How to read this page

Each persona has a **quick win**, a **hand-off** and a **recurring** ask. Systems marked *(confirm)* vary by company. Anything that sends, posts or schedules is a draft. Details: [How to use](../README.md#how-to-use).

**Why the two industry personas:** Revenue Management/Pricing drives daily rate decisions that make or break rental margin; Fleet Lease Account Manager owns the long-term B2B leasing relationship distinct from daily rental.

## Personas at a glance

| # | Persona | Title |
|---|---|---|
| 1 | [Finance](#1-finance) | Fleet Finance Manager |
| 2 | [HR](#2-hr) | HR Business Partner, Branch Operations |
| 3 | [Frontline Worker](#3-frontline-worker) | Rental Sales Agent / Counter Representative |
| 4 | [Frontline Supervisor](#4-frontline-supervisor) | Branch Manager / Station Manager |
| 5 | [Quality](#5-quality) | Vehicle Quality & Damage Control Lead |
| 6 | [Supply Chain/Procurement](#6-supply-chainprocurement) | Fleet Acquisition & Remarketing Manager |
| 7 | [Safety/EHS](#7-safetyehs) | Fleet Safety & Compliance Manager |
| 8 | [Field Service/Repair](#8-field-servicerepair) | Fleet Maintenance Technician / Shop Lead |
| 9 | [Sales/Marketing](#9-salesmarketing) | Commercial Fleet & Leasing Sales Manager |
| 10 | [Customer Service](#10-customer-service) | Customer Care Specialist |
| 11 | [Operations/Facilities](#11-operationsfacilities) | Regional Fleet Operations Manager |
| 12 | [Engineering/R&D/Technology](#12-engineeringrdtechnology) | Telematics & Connected Fleet Product Manager |
| 13 | [Executive](#13-executive) | Regional Vice President / General Manager |
| 14 | [Fleet Planning & Pricing Analyst](#14-fleet-planning--pricing-analyst) | Revenue Management / Pricing Analyst |
| 15 | [Lease & Fleet Account Manager](#15-lease--fleet-account-manager) | Fleet Lease Account Manager |

## Personas and example asks

### 1. Finance

**Title:** Fleet Finance Manager  
**Duty:** Manage fleet depreciation, residual values, and branch P&L.  
**Systems:** Power BI, ERP (confirm), fleet management system (confirm)

- **Quick win:** "Which damage recoveries and unbilled agreements by [branch] are over 30 days?" → Excel workbook
- **Hand-off:** "Compare residual vs. book value on vehicles due to de-fleet next quarter, add recent auction results, and draft the CFO memo on depreciation and remarketing impact" → Word doc
- **Recurring:** "Every Monday, list open lease invoice disputes from email with owner and due date" → scheduled digest

### 2. HR

**Title:** HR Business Partner, Branch Operations  
**Duty:** Recruit and retain rental agents, porters, and technicians.  
**Systems:** HRIS (confirm), workforce scheduling (confirm)

- **Quick win:** "List open rental agent and shuttle driver reqs by [site]" → Excel workbook
- **Hand-off:** "Gather turnover by location and tenure, training completion by branch and last summer's staffing gaps, and prepare the summer-peak staffing plan for regional leaders" → Word doc
- **Recurring:** "On the 1st of each month, list driver license and MVR renewals due and draft reminders" → email drafts

### 3. Frontline Worker

**Title:** Rental Sales Agent / Counter Representative  
**Duty:** Process rentals, returns, and upgrades at the counter.  
**Systems:** Rental reservation/counter system (confirm), telematics (confirm)

- **Quick win:** "Which of today's arriving reservations will I need to upgrade or substitute?" → Excel workbook
- **Hand-off:** "Gather the timeline, photos and notes on a customer's damage dispute and put them into a summary for my manager" → Word doc (one page)
- **Recurring:** "At the start of each shift, list one-way and cross-border rule changes since my last shift" → scheduled digest

### 4. Frontline Supervisor

**Title:** Branch Manager / Station Manager  
**Duty:** Run branch fleet availability, staff, and customer satisfaction.  
**Systems:** Rental reservation system (confirm), fleet management system (confirm)

- **Quick win:** "Give me today's fleet status: ready, dirty, in shop, on rent vs. reservations" → Word doc (one page)
- **Hand-off:** "Pull last week's NPS comments, wait times by shift, utilization and damage, and prepare my weekly branch review" → PowerPoint deck
- **Recurring:** "Every Thursday, list vehicles to shuttle in from other branches to cover the weekend" → Excel workbook

### 5. Quality

**Title:** Vehicle Quality & Damage Control Lead  
**Duty:** Ensure vehicle readiness, inspection accuracy, and damage claim quality.  
**Systems:** Damage inspection app (confirm), fleet management system (confirm)

- **Quick win:** "Which of yesterday's check-in inspections are missing photos or damage codes?" → Excel workbook
- **Hand-off:** "Analyze six months of damage write-offs by cause and branch, compare detection rates by inspector, and write the quarterly vehicle readiness report" → Word doc
- **Recurring:** "Every Monday, log last week's cleanliness complaints by branch" → scheduled digest

### 6. Supply Chain/Procurement

**Title:** Fleet Acquisition & Remarketing Manager  
**Duty:** Buy vehicles from OEMs and remarket de-fleeted units.  
**Systems:** Fleet management system (confirm), auction/remarketing platform (confirm)

- **Quick win:** "Which OEM deliveries are late this week, by [site]?" → Excel workbook
- **Hand-off:** "Compare auction prices to residual estimates by model and buyback vs. risk economics for next model year, and prepare the review deck for [OEM]" → PowerPoint deck
- **Recurring:** "Every week, list vehicles reaching de-fleet mileage and propose auction lots" → Excel workbook

Related example skill: [supplier-risk-tracker](../skills/supplier-risk-tracker.md)

### 7. Safety/EHS

**Title:** Fleet Safety & Compliance Manager  
**Duty:** Manage recalls, driver safety, and environmental compliance.  
**Systems:** Telematics (confirm), recall data feed (confirm)

- **Quick win:** "Which recall vehicles are on rent or available right now?" → Excel workbook
- **Hand-off:** "Pull shuttle driver incidents, telematics harsh-driving events and this quarter's incident reports, find the patterns, and draft the safety briefing for branch managers" → Word doc
- **Recurring:** "Every morning, list open recall vehicles by branch and draft a hold reminder to each branch manager" → scheduled digest + email drafts

Related example skill: [safety-incident-brief](../skills/safety-incident-brief.md)

### 8. Field Service/Repair

**Title:** Fleet Maintenance Technician / Shop Lead  
**Duty:** Perform preventive maintenance, repairs, and vehicle prep.  
**Systems:** Maintenance management system (confirm), telematics (confirm)

- **Quick win:** "Which vehicles are due for PM or showing fault codes today?" → Excel workbook
- **Hand-off:** "Analyze repeat repairs by model and component for the quarter, add parts on back-order with ETAs, and summarize shop backlog for my manager" → Word doc
- **Recurring:** "At the end of each shift, draft my handover of vehicles in progress and parts waiting" → Word doc (one page)

Related example skill: [shift-handover-digest](../skills/shift-handover-digest.md)

### 9. Sales/Marketing

**Title:** Commercial Fleet & Leasing Sales Manager  
**Duty:** Win corporate rental and fleet leasing accounts.  
**Systems:** Dynamics 365, quoting tool (confirm)

- **Quick win:** "What's the status of this week's lease proposals in Dynamics 365?" → Excel workbook
- **Hand-off:** "Compare our TCO quote with competitor scenarios, pull win/loss on similar deals, and draft the proposal executive summary for [Prospect]" → Word doc
- **Recurring:** "Every month, list corporate accounts due for renewal in the next 90 days with rental volumes" → scheduled digest

### 10. Customer Service

**Title:** Customer Care Specialist  
**Duty:** Resolve billing, damage, and reservation issues for renters.  
**Systems:** Dynamics 365, Contact center platform (confirm), rental reservation system (confirm)

- **Quick win:** "Which toll and fuel charge disputes are open and how old are they?" → Excel workbook
- **Hand-off:** "For a disputed damage charge, gather the rental agreement, check-in photos, emails and repair invoice into a case file, and draft the customer reply" → Word doc + email draft
- **Recurring:** "On the 1st of each month, summarize top complaint drivers by channel and branch for leadership" → scheduled digest

Related example skill: [customer-escalation-pack](../skills/customer-escalation-pack.md)

### 11. Operations/Facilities

**Title:** Regional Fleet Operations Manager  
**Duty:** Balance fleet, manage lots, and run airport facilities.  
**Systems:** Fleet management system (confirm), yield/revenue management (confirm)

- **Quick win:** "What's today's regional utilization and shortage forecast by branch?" → Word doc (one page)
- **Hand-off:** "Analyze fleet balancing moves vs. demand, cost per transaction by site and airport lot issues, and prepare the peak-season fleet plan" → PowerPoint deck
- **Recurring:** "Every Thursday, draft the weekend fleet move plan for branch managers" → email draft

### 12. Engineering/R&D/Technology

**Title:** Telematics & Connected Fleet Product Manager  
**Duty:** Manage telematics, keyless, and EV charging technology.  
**Systems:** Telematics platform (confirm), EV charging management (confirm)

- **Quick win:** "Which telematics devices and keyless units failed this week?" → Excel workbook
- **Hand-off:** "Analyze EV charging utilization and range-related complaints by site, add open branch integration requests, and write the connected fleet roadmap update" → Word doc
- **Recurring:** "Before each keyless or telematics release, draft the release note for branches" → Teams post draft

### 13. Executive

**Title:** Regional Vice President / General Manager  
**Duty:** Lead P&L, fleet strategy, and customer growth.  
**Systems:** Power BI, ERP (confirm), fleet management system (confirm)

- **Quick win:** "Give me a morning brief on utilization, revenue and top escalations" → Word doc (one page)
- **Hand-off:** "Analyze fleet cost per unit and RPD year over year, compare regions, and draft the fleet reallocation recommendation for leadership" → PowerPoint deck
- **Recurring:** "Every Friday, summarize decisions from this week's leadership meetings" → scheduled digest

### 14. Fleet Planning & Pricing Analyst

**Title:** Revenue Management / Pricing Analyst  
**Duty:** Set rental rates and forecast demand by location and class.  
**Systems:** Yield/revenue management system (confirm), competitor rate shopping tool (confirm)

- **Quick win:** "Where are we out of band on today's competitor rate shop for [airport]?" → Excel workbook
- **Hand-off:** "Compare forecast vs. actual demand by location, analyze price elasticity by class over holidays, and prepare the pricing review deck for the regional VP" → PowerPoint deck
- **Recurring:** "Every day, log branch rate-override requests and decisions" → Excel workbook

### 15. Lease & Fleet Account Manager

**Title:** Fleet Lease Account Manager  
**Duty:** Manage corporate lease portfolios, renewals, and end-of-term.  
**Systems:** Lease administration system (confirm), fuel card platform (confirm)

- **Quick win:** "Which of [Client]'s leases end in the next 90 days and what's the replacement status?" → Excel workbook
- **Hand-off:** "Analyze [Client]'s fuel card spend, excess mileage and EV vs. ICE replacement costs, and prepare the client fleet review deck" → PowerPoint deck
- **Recurring:** "Every Monday, gather open driver issues and vehicle orders for my accounts from email" → scheduled digest

## Top 5 custom skills to build first

- **daily-fleet-status** (Frontline Supervisor; Operations/Facilities): Gather fleet and reservation data → compute shortages → produce branch tracker and huddle post.
- **recall-hold-check** (Safety/EHS; Field Service/Repair): Pull recall list → match vehicles on rent/available → produce hold tracker and reminder. Start from [safety-incident-brief](../skills/safety-incident-brief.md).
- **damage-claim-pack** (Customer Service; Quality): Collect inspection photos and emails → build timeline → produce claim file and reply draft. Start from [customer-escalation-pack](../skills/customer-escalation-pack.md).
- **defleet-remarketing-plan** (Supply Chain/Procurement; Finance): Find units at de-fleet thresholds → compare residuals → propose auction lots.
- **fleet-client-review** (Lease & Fleet Account Manager): Gather lease, fuel, and mileage data → analyze TCO → build review deck.

## Top 5 connectors to demo

- **Rental reservation/counter system (confirm)** (Frontline Worker; Frontline Supervisor): Branch managers see on-rent vs. ready fleet in one morning ask.
- **Fleet management system (confirm)** (Operations/Facilities; Supply Chain/Procurement): Remarketing picks de-fleet units without exporting spreadsheets.
- **Telematics (confirm, e.g., OEM connected-car data)** (Field Service/Repair; Safety/EHS): Technicians get fault-code lists before the shift starts.
- **Revenue management system (confirm)** (Fleet Planning & Pricing Analyst): Analysts get out-of-band rate alerts summarized daily.
- **Lease administration / fuel card (confirm)** (Lease & Fleet Account Manager; Finance): Account managers build client reviews from lease and fuel data in minutes.

## Business areas

- **Rental counter & branch operations:** Frontline Worker; Frontline Supervisor; Operations/Facilities
- **Fleet acquisition, maintenance & remarketing:** Supply Chain/Procurement; Field Service/Repair; Quality
- **Pricing & revenue management:** Fleet Planning & Pricing Analyst; Finance
- **Leasing & fleet services:** Lease & Fleet Account Manager; Sales/Marketing
- **Customer experience:** Customer Service; Frontline Worker
- **Safety, compliance & connected fleet:** Safety/EHS; Engineering/R&D/Technology
- **Leadership & people:** Executive; HR

## Confirm with each customer

- Rental reservation and fleet management systems in use
- Telematics vendor and data access
- Revenue management tool and data refresh cadence
- Lease administration and fuel card platforms
- Damage inspection app and photo storage
- Customer PII and driver license data restrictions
- Approval rules for customer and client communications
