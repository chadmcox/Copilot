---
name: supplier-risk-tracker
description: Use weekly to build a supplier risk tracker from supplier emails, meeting notes and shared files — late deliveries, quality issues, price changes, capacity warnings. Personas: Supply Chain/Procurement, Quality, Executive.
---

# Supplier risk tracker

## Inputs
- Supplier list (names or a shared file), lookback window (default 7 days)

## Steps
1. **Gather** emails, Teams messages and meeting transcripts mentioning each supplier in the window.
2. **Gather** shared files such as scorecards, corrective-action reports and delivery logs from SharePoint/OneDrive.
3. **Analyze**: classify signals as Delivery, Quality, Price/Cost, Capacity, Compliance or Financial. Score each supplier Red/Amber/Green with a one-line reason and the source.
4. **Produce** an Excel tracker: one row per supplier with status, signals, owner, next action and source links. Add a Summary tab with counts by status.
5. **Draft for approval** an email to the category lead listing the Red suppliers and the asks.

## Rules
- No status without a cited source. Mark "no signal" rather than guessing.
- If a system of record (ERP, supplier portal) isn't connected, say so and list it as a gap.
