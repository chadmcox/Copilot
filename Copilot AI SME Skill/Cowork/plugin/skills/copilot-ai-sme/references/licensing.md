# Licensing — pointers

Never state a price from memory. Rates and inclusions below were read on Microsoft Learn on Nov 19, 2026; prices come only from the dated licensing guide or price list.

## What a Microsoft 365 Copilot license includes [MS Learn]
Per https://learn.microsoft.com/microsoft-copilot-studio/billing-licensing :
- Microsoft Copilot Chat (incl. Pages), Copilot in Microsoft 365 apps (incl. Teams), SharePoint agents
- Copilot Studio agent capabilities when used in Microsoft Copilot, Teams or SharePoint under the user's authenticated identity (classic answers, generative answers, tenant graph grounding aren't charged; footnotes apply to agent flows)
- Copilot Analytics (Copilot Dashboard, business impact reports, Viva Insights advanced analytics)
- SharePoint Advanced Management

## Not included in the license (usage-based) [MS Learn]
Cowork, Autopilot, Code, Work IQ API, Copilot Managed Runtime, and other services listed at https://learn.microsoft.com/copilot/plan/usage-based-billing-overview-copilot-credits . Cowork and Autopilot also require the Copilot license on the user.

## Unlicensed users
Copilot Chat (Basic) users using agents that read shared tenant data (SharePoint, Graph connectors) are billed on metered consumption through Copilot Studio credits: https://learn.microsoft.com/copilot/manage/manage-agents-copilot-chat

## Agent governance licensing [MS Learn]
Entra ID Governance for agent identities needs **Microsoft 365 E7** (includes Agent 365 and Microsoft Entra Suite) or **Microsoft Agent 365** paired with at least Entra P1 or Microsoft 365 E3: https://learn.microsoft.com/entra/id-governance/agent-id-governance-overview

## Copilot Studio
- Trial license can build and test, not publish: https://learn.microsoft.com/microsoft-copilot-studio/billing-licensing
- Licensing Guide (PDF, dated): https://go.microsoft.com/fwlink/?linkid=2320995

## Detecting Copilot licenses in a tenant
Detect by service plan, not SKU name (bundles like Microsoft 365 E7 include Copilot without "Copilot" in the name). Read `GET /subscribedSkus` and look for the Copilot service plan; verify the plan ID at runtime on the Microsoft 365 licensing service plan reference: https://learn.microsoft.com/entra/identity/users/licensing-service-plan-reference

## Government clouds
Cowork is available in GCC with a Microsoft 365 GCC Copilot license; billing is usage-based: https://learn.microsoft.com/copilot/cowork/cowork-government . Check each feature's cloud availability at runtime.
