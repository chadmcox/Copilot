# Agent governance — pointers

Read on Microsoft Learn on Nov 19, 2026. Re-fetch before citing. Identity depth (Conditional Access for agents, ID Protection, access packages) → entra-id-sme.

## Who does what [MS Learn]
| Control plane | Use for | Source |
|---|---|---|
| **Agent 365** (Microsoft 365 admin center) | Unified registry and control plane: discover all agents (Microsoft and non-Microsoft), govern access to systems, data and tools, monitor | https://learn.microsoft.com/entra/agent-id/agent-registry-convergence |
| **Entra Agent ID** (Entra admin center) | Agent identities and blueprints, permissions, Conditional Access, ID Governance (sponsors, lifecycle workflows, access packages), ID Protection for agents | https://learn.microsoft.com/entra/agent-id/identity-professional/microsoft-entra-agent-identities-for-ai-agents |
| **Power Platform admin center** | Copilot Studio environments, data policies, sharing limits, capacity | copilot-studio.md |
| **Microsoft 365 admin center > Copilot** | Spending policies (access + cost), Copilot settings, plugin and agent access, Frontier | finops.md, cowork.md |

Roles: **AI Reader** to see all agents in Agent 365 and Agent ID; **Agent ID Administrator** to change agent identities (same source).

## Lifecycle checklist (Copilot controls)
Source: https://learn.microsoft.com/copilot/implement/copilot-controls-management
1. Enable/block Copilot connectors; review connector access permissions; delegate connector management to AI Administrators.
2. Limit agent sharing (Editor/Viewer, managed-environment rules).
3. Block publishing channels with data policies.
4. Approval process to move agents to production.
5. Owners/sponsors on every agent identity; lifecycle workflows so access doesn't outlive need.
6. Inventory and retire unused agents.

## Governance questions to answer for any agent
| Question | Where to check |
|---|---|
| Whose identity does it act as (user delegated, own agent ID, agent user)? | Agent ID / product docs |
| What data can it reach (Graph, connectors, MCP, web)? | Data policies, connector permissions, plugin scopes |
| Who can use it, share it, publish it? | Sharing limits, agent and plugin access, spending policy scope |
| Who owns it and reviews it? | Sponsors, lifecycle workflows |
| How is cost capped? | Spending policy limits, agent monthly limits |
| How is it logged and stopped? | Audit, Defender, removal from scope/activation |

## Author tools [Author repo – community, not official Microsoft guidance]
- Agent and Tools Health Check, Agent and Tools Cleanup, Agents delegation guide, Access Governance Guide: https://github.com/chadmcox/Copilot
