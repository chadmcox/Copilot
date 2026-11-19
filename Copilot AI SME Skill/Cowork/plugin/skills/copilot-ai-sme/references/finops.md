# FinOps for Copilot and agents

All facts below were read on Microsoft Learn on Nov 19, 2026. Re-fetch before citing; billing changes often.

## The three ways Copilot usage is paid for

| Meter | What it covers | Where it's managed | Source |
|---|---|---|---|
| **Per-user licenses** | Microsoft 365 Copilot (includes Copilot Chat, Copilot in apps, SharePoint agents, Copilot Studio agent use in Copilot/Teams/SharePoint under the user's identity, Copilot Analytics) | Microsoft 365 admin center licenses | [MS Learn] https://learn.microsoft.com/microsoft-copilot-studio/billing-licensing |
| **Usage-based billing (Copilot Credits) with spending policies** | Cowork, Autopilot, Code, Work IQ API, Copilot Managed Runtime, advanced work in SharePoint/OneDrive, Teams Phone Agent and more | Microsoft 365 admin center > **Copilot > Cost Management** | [MS Learn] https://learn.microsoft.com/copilot/plan/usage-based-billing-overview-copilot-credits |
| **Copilot Studio credits** (prepaid capacity packs, P3, pay-as-you-go billing plans/policies) | Copilot Studio agents, Copilot Chat agents for unlicensed users, SharePoint agents | Power Platform admin center (environments, capacity) and Microsoft 365 admin center (Copilot Chat billing policies) | [MS Learn] https://learn.microsoft.com/power-platform/admin/manage-copilot-studio-copilot-credits-capacity |

## Key facts (cite each)
Source column uses the page name; full URLs are in sources.md.


| Fact | Source |
|---|---|
| Cowork, Copilot Studio and Work IQ usage is billed through one common Copilot Credits service labeled **Microsoft Copilot Studio** on the Azure bill. To attribute cost, separate by subscription or resource group. | usage-based-billing-compare-dashboard-views |
| The Microsoft 365 admin center shows **credits, not currency**, includes non-billable usage, and is daily; the Azure bill is finalized monthly. Reconcile with the monthly bill, not dashboards. | same |
| Credit cost per task varies with models, retrieved context, runtime and tools; it isn't fixed per request. | same |
| Billing order when several methods exist: **Prepaid capacity packs → Copilot Credit Pre-purchase plan (P3) → pay-as-you-go**. | usage-based-billing-copilot-credits-setup |
| Prepaid capacity credits allocated to environments in the Power Platform admin center reduce what's available in the Microsoft 365 admin center. | same |
| A capacity pack gives **25,000 credits per month**, replenished monthly. | copilot-capacity-packs |
| Up to **10 Copilot credit policies** per tenant; a credit policy without pay-as-you-go makes Copilot Chat unavailable for covered users when credits run out. | copilot-capacity-packs |
| Up to **50 billing policies** per tenant (pay-as-you-go). Budgets send alerts but **don't stop spending**. | setup-pay-as-you-go |
| Copilot Studio enforces purchased capacity monthly; unused credits don't carry over; overage can lead to service denial. | billing-licensing |
| A **spending policy is an access control**, not only a budget: users in scope of a policy that selects Cowork can use Cowork. A low limit doesn't block access. | cowork-admin-governance, cowork-access |
| If a user is in several policies, precedence picks which **limits** apply (highest per-user limit, then largest policy limit, then newest); it doesn't decide access. | cowork-access |
| **Auto-apply new services** is on by default for spending policies; turn it off where new services should be reviewed first. | usage-based-billing-overview-copilot-credits |
| Autopilot isn't included in the Copilot license; a user not covered by an Autopilot spending policy, or whose policy runs out, can't use it and sees no explanation. | autopilot/admin-configure |

## Copilot Studio credit rates (from the billing-rates page; re-fetch, rates change)
Classic answer 1 · Generative answer 2 · Agent action 5 · Tenant graph grounding 10 · Agent flow actions 13 per 100 · Premium text/generative AI tools (reasoning models) 10 per 1,000 tokens · Content processing 8 per page. Microsoft 365 Copilot licensed users aren't charged for most agent features when the agent runs under their identity (footnotes apply; computer-using agents aren't included).
Source: [MS Learn] https://learn.microsoft.com/microsoft-copilot-studio/requirements-messages-management

Reasoning models are billed per token (feature rate + premium tokens). One message can cost hundreds of credits; see the page's worked example before estimating.

## FinOps workflow (Mode 1)

1. **Inform (visibility)**: which meters are in use? Microsoft 365 admin center Cost Management, Power Platform admin center Licensing > Copilot Studio, Azure Cost Management for the subscription(s) on the billing method.
2. **Allocate (showback/chargeback)**: one Azure subscription or resource group per business unit or service for pay-as-you-go; spending policies scoped to groups; tag where supported. Map to FOCUS columns if exporting.
3. **Optimize**: per-user limits in every policy; P3 for predictable usage; capacity packs for Copilot Chat; agent-level monthly limits in the Power Platform admin center; avoid reasoning models where a standard model works; turn off tenant graph grounding where not needed.
4. **Operate**: alerts at 50/80/100%; monthly reconciliation of admin-center credits to Azure invoice; review **Auto-apply new services**; remove access by removing users from policy scope, not by lowering limits.

## Questions to ask before estimating
- Licensed or unlicensed users? Which experience (Cowork, Autopilot, Copilot Studio agent, Copilot Chat agent)?
- Model choice (reasoning vs standard)? Tenant graph grounding on?
- Expected runs per user per day; autonomous triggers?
Then use the Copilot Credit Estimator (https://aka.ms/CopilotCreditPlanningModel) and the billing-rates page. State that estimates aren't quotes.

## Author tools [Author repo – community, not official Microsoft guidance]
- Billing Health Check (read-only check of spending policies, groups, members): https://github.com/chadmcox/Copilot/tree/main/Billing%20Health%20Check
