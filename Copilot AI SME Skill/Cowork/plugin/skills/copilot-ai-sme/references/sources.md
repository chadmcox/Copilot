# Source hierarchy

Priority: **1)** Microsoft Learn + Microsoft Graph reference → **1b)** Copilot Roadmap, Message Center, Power Platform release plans → **1c)** official Microsoft blogs → **2)** licensing guides (dated) → **3)** CISA / NIST / CIS / OWASP / MITRE / ISO / industry → **4)** author repos `[Author repo – community, not official Microsoft guidance]` → **5)** `[3P – third party, not Microsoft guidance]`.

Links are pointers. Fetch the page in the session before relying on it. "Checked Nov 19, 2026" means the page was read when this skill was built; re-fetch before citing.

## 1. Microsoft Learn [MS Learn]

### Copilot (Microsoft 365 Copilot, Chat, usage-based billing)
- Usage-based billing overview (services that use Copilot Credits): https://learn.microsoft.com/copilot/plan/usage-based-billing-overview-copilot-credits (checked Nov 19, 2026)
- Set up usage-based billing for Copilot Credits: https://learn.microsoft.com/copilot/implement/usage-based-billing-copilot-credits-setup (checked)
- Manage spending policies: https://learn.microsoft.com/copilot/implement/usage-based-billing-manage-copilot-credits
- Admin center view vs Azure bill: https://learn.microsoft.com/copilot/implement/usage-based-billing-compare-dashboard-views (checked)
- Capacity packs for Copilot Chat and SharePoint agents: https://learn.microsoft.com/copilot/implement/copilot-capacity-packs (checked)
- Pay-as-you-go setup (billing policies): https://learn.microsoft.com/copilot/implement/setup-pay-as-you-go (checked)
- Copilot controls for management: https://learn.microsoft.com/copilot/implement/copilot-controls-management (checked)
- Agents in Copilot Chat: https://learn.microsoft.com/copilot/manage/manage-agents-copilot-chat (checked)

### Cowork
- Overview: https://learn.microsoft.com/copilot/cowork/
- Manage Cowork for your organization: https://learn.microsoft.com/copilot/cowork/cowork-admin-governance (checked)
- How access is determined: https://learn.microsoft.com/copilot/cowork/cowork-access (checked)
- Build plugins: https://learn.microsoft.com/copilot/cowork/cowork-plugin-development (checked)
- Manage plugins: https://learn.microsoft.com/copilot/cowork/cowork-manage-plugins
- Cowork in GCC: https://learn.microsoft.com/copilot/cowork/cowork-government (checked)

### Autopilot
- Overview, requirements, get started, use, FAQ, admin configure, application card: https://learn.microsoft.com/copilot/autopilot/overview (all checked Nov 19, 2026; see autopilot.md)

### Copilot Studio
- Billing rates and management: https://learn.microsoft.com/microsoft-copilot-studio/requirements-messages-management (checked)
- Licensing and billed credits: https://learn.microsoft.com/microsoft-copilot-studio/billing-licensing (checked)
- Copilot Credits capacity (Power Platform admin center): https://learn.microsoft.com/power-platform/admin/manage-copilot-studio-copilot-credits-capacity (checked)
- Data policies for agents: https://learn.microsoft.com/microsoft-copilot-studio/admin-data-loss-prevention (checked)
- Sharing limits: https://learn.microsoft.com/microsoft-copilot-studio/admin-sharing-controls-limits (checked)
- Security and governance guidance: https://learn.microsoft.com/microsoft-copilot-studio/guidance/sec-gov-phase3 (checked)
- Govern Copilot Credit consumption: https://learn.microsoft.com/microsoft-copilot-studio/guidance/govern-credit-consumption (checked)

### Agent governance
- Agent 365 overview: https://learn.microsoft.com/microsoft-agent-365/overview
- Agent registry convergence (Agent 365 + Entra Agent ID): https://learn.microsoft.com/entra/agent-id/agent-registry-convergence (checked)
- Entra Agent ID: https://learn.microsoft.com/entra/agent-id/identity-professional/microsoft-entra-agent-identities-for-ai-agents (checked)
- Governing agent identities (licensing): https://learn.microsoft.com/entra/id-governance/agent-id-governance-overview (checked)
- Copilot Managed Runtime default governance: https://learn.microsoft.com/microsoft-365/admin/manage/apps/governance (checked)

### FinOps (Azure)
- Microsoft Cost Management: https://learn.microsoft.com/azure/cost-management-billing/costs/overview-cost-management (checked)
- Copilot Credit pre-purchase plan (P3): https://learn.microsoft.com/azure/cost-management-billing/reservations/copilot-credit-p3
- FinOps Framework and toolkit: https://learn.microsoft.com/cloud-computing/finops/implementing-finops-guide ; https://learn.microsoft.com/cloud-computing/finops/toolkit/finops-toolkit-overview (checked)
- FOCUS: https://learn.microsoft.com/cloud-computing/finops/focus/what-is-focus

## 1b. Release feeds
- Microsoft Copilot Roadmap (formerly Microsoft 365 Roadmap) [Roadmap]: https://www.microsoft.com/microsoft-365/roadmap — query through the Release Communications MCP `https://www.microsoft.com/releasecommunications/mcp` (checked: no auth, free) https://learn.microsoft.com/microsoft-365/admin/manage/mrc-mcp
- Message Center [Message Center]: Graph `GET /admin/serviceAnnouncement/messages`, least-privileged permission `ServiceMessage.Read.All` (checked) https://learn.microsoft.com/graph/api/serviceannouncement-list-messages
- Power Platform and Copilot Studio release plans: https://learn.microsoft.com/power-platform/release-plan/
- What's new in Copilot Studio: https://learn.microsoft.com/microsoft-copilot-studio/whats-new

## 1c. Official blogs [MS Blog]
See blogs-and-feeds.md.

## 2. Licensing guides [Licensing guide]
- Microsoft Copilot Studio Licensing Guide: https://go.microsoft.com/fwlink/?linkid=2320995 (linked from Learn)
- Copilot Credit Guide: https://go.microsoft.com/fwlink/p/?linkid=2368800 (linked from Learn)
- Copilot Credit Estimator: https://aka.ms/CopilotCreditPlanningModel (linked from Learn)
Guides are PDFs that change. Always name the version or date you read.

## 3. Frameworks
See security-frameworks.md.

## 4. Author repos [Author repo – community, not official Microsoft guidance]
- Copilot repo (Billing Health Check, Agent and Tools Health Check, Agent and Tools Cleanup, Access Governance Guide, Agents delegation guide): https://github.com/chadmcox/Copilot
- Entra ID SME skill (identity questions): https://github.com/chadmcox/Copilot/tree/main/Entra%20ID%20SME%20Skill

## 5. Third party [3P – third party, not Microsoft guidance]
- Agent resources hub (Microsoft-employee curated GitHub Pages, not product docs): https://microsoft.github.io/agent-resources/
- MVP and partner blogs: use only to find leads, then verify on Learn.
