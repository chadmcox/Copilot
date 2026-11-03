# Cowork Industry Persona Library

Plain Markdown library for Microsoft 365 Copilot Cowork adoption workshops: **15 personas × 3 example asks** for 26 industries, plus example skills and reusable prompts. Nothing to install or deploy; read it on GitHub or in any Markdown viewer.

## How to use

1. Pick an industry below and open its page. *Top 3 demos* at the top is the quickest place to start a workshop.
2. Skim *Personas at a glance*, then jump to a persona for its three asks:
   - **Quick win:** a small, everyday job that pays off right away.
   - **Hand-off:** a multi-step job across several sources that would otherwise take an hour or more.
   - **Recurring:** something scheduled or ongoing that keeps working without the person.
3. To tailor to a specific company, paste [prompts/customer-research.md](prompts/customer-research.md) into Cowork.
4. To add an industry, paste [prompts/industry-template.md](prompts/industry-template.md) into Cowork and save the result as a new page in `industries/`.

Each ask uses the format: "natural-language ask" → deliverable. Every persona can use the standard Microsoft 365 sources (Outlook, Teams, meeting transcripts, SharePoint/OneDrive, calendar); each persona's **Systems** line lists only the industry systems beyond those, marked *(confirm)* because these are templates, not company data. Anything that sends, posts or schedules is a draft for approval.

## Industries

- [Aerospace & Defense](industries/aerospace-defense.md)
- [Agribusiness & Commodities](industries/agribusiness-commodities.md)
- [Airlines](industries/airlines.md)
- [Automotive OEM](industries/automotive-oem.md)
- [Automotive Suppliers & Aftermarket](industries/automotive-suppliers-aftermarket.md)
- [Building Products & Construction Materials](industries/building-products-construction-materials.md)
- [Car Rental, Leasing & Fleet](industries/car-rental-leasing-fleet.md)
- [Chemicals & Specialty Materials](industries/chemicals-specialty-materials.md)
- [Consumer Durables, Appliances & Tools](industries/consumer-durables-appliances-tools.md)
- [Consumer Packaged Goods](industries/consumer-packaged-goods.md)
- [Cruise Lines](industries/cruise-lines.md)
- [Food & Beverage Manufacturing](industries/food-beverage-manufacturing.md)
- [High Tech & Electronics Manufacturing](industries/high-tech-electronics-manufacturing.md)
- [Hotels & Hospitality](industries/hotels-hospitality.md)
- [Industrial Automation & Electrical Equipment](industries/industrial-automation-electrical-equipment.md)
- [Industrial Distribution & Wholesale](industries/industrial-distribution-wholesale.md)
- [Industrial Machinery & Heavy Equipment](industries/industrial-machinery-heavy-equipment.md)
- [Life Sciences, Pharma & Diagnostics](industries/life-sciences-pharma-diagnostics.md)
- [Medical Devices](industries/medical-devices.md)
- [Metals & Mining](industries/metals-mining.md)
- [Oil, Gas & Refining](industries/oil-gas-refining.md)
- [Paper, Packaging & Forest Products](industries/paper-packaging-forest-products.md)
- [Railroads](industries/railroads.md)
- [Semiconductors](industries/semiconductors.md)
- [Travel Management & Services](industries/travel-management-services.md)
- [Trucking, Freight & Logistics](industries/trucking-freight-logistics.md)

## Example skills

Each follows Inputs → Gather → Analyze → Produce → Draft for approval → Rules.

- [customer-escalation-pack](skills/customer-escalation-pack.md)
- [safety-incident-brief](skills/safety-incident-brief.md)
- [shift-handover-digest](skills/shift-handover-digest.md)
- [supplier-risk-tracker](skills/supplier-risk-tracker.md)
- [voyage-guest-recovery](skills/voyage-guest-recovery.md)

## Prompts

- [Customer research](prompts/customer-research.md): researches a named company's public job postings.
- [Industry template](prompts/industry-template.md): generates a new industry page.

## Caveats

- Templates from general industry knowledge; placeholders like [Company], [site], [ship] stand in for real names.
- Check current Cowork capabilities before a workshop; job postings change, so re-run research close to the date.
