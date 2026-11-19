# Copilot Studio — pointers

Read on Microsoft Learn on Nov 19, 2026. Re-fetch before citing.

## Billing (see finops.md for rates)
- Rates: https://learn.microsoft.com/microsoft-copilot-studio/requirements-messages-management
- Capacity in the Power Platform admin center (prepaid, pay-as-you-go billing plans, per-environment allocation, agent monthly limits): https://learn.microsoft.com/power-platform/admin/manage-copilot-studio-copilot-credits-capacity
- The agent's **Monitor** page shows billed credits only; admin reports also show non-billed credits.
- Agents on the **Microsoft Copilot harness** bill differently from the standard harness: https://learn.microsoft.com/microsoft-copilot-studio/agents-experience/billing-credit-overview
- Who can author: Power Platform admin center **Settings > Copilot Author**, assign a security group.

## Data policies (DLP) [MS Learn]
Source: https://learn.microsoft.com/microsoft-copilot-studio/admin-data-loss-prevention
- Data policies govern Copilot Studio connectors, channels, knowledge sources, unauthenticated use, Azure Bot Service skills and Application Insights. Scope: environment, environment group or tenant.
- Enforcement is on for all tenants since early 2025 (MC973179); exemptions are no longer supported.
- Connectors introduced after 2019 (e.g. chat without Entra ID authentication, Direct Line channels) usually land in the default **Non-business** group, often blocked.
- Data policies and sharing rules still apply when an agent is packaged in a plugin.
- Advanced connector policies (ACP) interact with classic data policies per environment group; see https://learn.microsoft.com/microsoft-365/admin/manage/apps/governance

## Sharing limits [MS Learn]
Source: https://learn.microsoft.com/microsoft-copilot-studio/admin-sharing-controls-limits
- Managed Environments control; apply per environment or at scale with environment groups and rules.
- Enforced at share time; existing access isn't removed. Up to an hour to take effect. Only for agents that require authentication.

## Environment strategy [MS Learn]
Source: https://learn.microsoft.com/microsoft-copilot-studio/guidance/sec-gov-phase3
- Personal dev: strict data policies and managed-environment rules. Dedicated dev: relaxed data policies, strict rules. Test/prod: relaxed after review.
- Critical use cases: VNet for connectors, IP firewall, continuous access evaluation, Direct Line secrets, data residency and cross-geo data movement setting.
- Govern credit consumption by environment purpose, layer tenant/environment/agent limits: https://learn.microsoft.com/microsoft-copilot-studio/guidance/govern-credit-consumption

## Identity
- Migrate Copilot Studio agents to Entra Agent ID: https://learn.microsoft.com/entra/agent-id/migrate-copilot-studio-agents-to-agent-id (identity depth: entra-id-sme)

## Status sources
What's new: https://learn.microsoft.com/microsoft-copilot-studio/whats-new ; release plans: https://learn.microsoft.com/power-platform/release-plan/ ; blogs: blogs-and-feeds.md.
