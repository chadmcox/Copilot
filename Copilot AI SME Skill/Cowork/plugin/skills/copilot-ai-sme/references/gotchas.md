# Gotchas

## Contribution rules
- One row per gotcha, in the table for its area.
- Every row needs a **Source/verified link** (Microsoft Learn, Graph reference, or a public reproducible source). No link, no row.
- No tenant IDs, UPNs, customer names, contract prices or secrets.
- Date format: YYYY-MM-DD. Re-verify rows older than 6 months before relying on them (Copilot changes fast).

## Format
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|

## FinOps and billing
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Azure bill doesn't match credits in the Microsoft 365 admin center | Admin center shows daily credits incl. non-billable usage; Azure shows finalized monthly billable cost | Reconcile against the monthly bill, not dashboards | https://learn.microsoft.com/copilot/implement/usage-based-billing-compare-dashboard-views | Skill author | 2026-11-19 |
| Can't see Cowork as its own line on the Azure bill | Cowork, Copilot Studio and Work IQ share one Copilot Credits service labeled Microsoft Copilot Studio | Separate by subscription or resource group | same | Skill author | 2026-11-19 |
| Spending continued past the budget | Billing-policy budgets only send alerts | Use spending limits; set alerts early | https://learn.microsoft.com/copilot/implement/setup-pay-as-you-go | Skill author | 2026-11-19 |
| Copilot Chat stopped for a group mid-month | Copilot credit policy with no pay-as-you-go ran out of capacity-pack credits | Pair with pay-as-you-go or add packs | https://learn.microsoft.com/copilot/implement/copilot-capacity-packs | Skill author | 2026-11-19 |
| Fewer credits available in Microsoft 365 admin center than purchased | Credits allocated to environments in the Power Platform admin center | Review allocations in both admin centers | https://learn.microsoft.com/copilot/implement/usage-based-billing-copilot-credits-setup | Skill author | 2026-11-19 |
| New service started consuming credits without review | **Auto-apply new services** is on by default | Turn it off on policies that need review | https://learn.microsoft.com/copilot/plan/usage-based-billing-overview-copilot-credits | Skill author | 2026-11-19 |
| One reasoning-model message cost hundreds of credits | Reasoning models bill per token (premium) plus feature rate | Use a standard model where possible; set agent limits | https://learn.microsoft.com/microsoft-copilot-studio/requirements-messages-management | Skill author | 2026-11-19 |

## Cowork
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Blocked a user in **All agents > Cowork** but they still use Cowork | Since GA, access is only via spending policies that select Cowork | Remove the user from every Cowork spending policy | https://learn.microsoft.com/copilot/cowork/cowork-admin-governance | Skill author | 2026-11-19 |
| Set a tiny limit to "turn off" Cowork for a group; they still open it | A low limit doesn't block access | Remove from policy scope | https://learn.microsoft.com/copilot/cowork/cowork-access | Skill author | 2026-11-19 |
| Plugin upload fails on connector | Manifest 1.28 requires `mcpToolDescription` and the file in the zip | Use 1.29 or include the file | https://learn.microsoft.com/copilot/cowork/cowork-plugin-development | Skill author | 2026-11-19 |

## Autopilot
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Autopilot silently stops responding | User not covered by an Autopilot spending policy, or policy out of credits; no message is shown | Check coverage and remaining credits | https://learn.microsoft.com/copilot/autopilot/admin-configure | Skill author | 2026-11-19 |
| Frontier enabled but no Autopilot | Also needs activation, spending policy and Copilot license | Complete all prerequisites | https://learn.microsoft.com/copilot/autopilot/requirements | Skill author | 2026-11-19 |

## Copilot Studio
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Previously exempt agent now blocked by data policy | Exemptions no longer supported; enforcement for all tenants since early 2025 | Fix connector grouping or policy scope | https://learn.microsoft.com/microsoft-copilot-studio/admin-data-loss-prevention | Skill author | 2026-11-19 |
| Sharing rule set but users already shared still have access | Rules enforce at share time only; take up to an hour | Remove existing shares manually | https://learn.microsoft.com/microsoft-copilot-studio/admin-sharing-controls-limits | Skill author | 2026-11-19 |
| Agent's Monitor page shows fewer credits than admin reports | Monitor shows billed credits only | Use Power Platform admin center reports for totals | https://learn.microsoft.com/power-platform/admin/manage-copilot-studio-copilot-credits-capacity | Skill author | 2026-11-19 |

## Governance
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Reader can't see all agents | Needs AI Reader role | Assign AI Reader | https://learn.microsoft.com/entra/agent-id/agent-registry-convergence | Skill author | 2026-11-19 |
