# Rules

Thresholds: per-user minimum 2,000 credits, inactive after 90 days. The user can change them in the prompt.

"Licensed services" are `cowork` and `code`. People without a Copilot license can't use them.

## Policy

| Check | Severity | Fix |
| --- | --- | --- |
| Scope is All users | High | Limit it to a security group |
| Status isn't `enabled` | High | Link the group, or recreate the policy |
| Scope is Groups but no group is listed | High | Link the policy's group |
| Per-user limit and monthly limit are both Unlimited | High | Set a monthly limit |
| Per-user limit under 2,000 | Medium | Raise it to at least 2,000 credits |
| Billing is `notSpecified` | Medium | Pick prepaid credits or pay-as-you-go |
| AlertOn is false | Medium | Turn on an alert at 80% with two owners as recipients |
| An alert recipient is disabled or not found | Medium | Replace the recipient |
| Only one alert recipient | Low | Add a second recipient |

## Group

| Check | Severity | Fix |
| --- | --- | --- |
| Group not found | High | Link the right group |
| Microsoft 365 group (`groupTypes` has `Unified`) or not security-enabled | Medium | Use a security group |
| Has nested groups | Medium | Add people directly; Microsoft doesn't say whether spending policies count nested members |
| Fewer than two owners | Medium | Add owners so there are at least two |
| No access review (if you checked) | Medium | Add a quarterly access review |
| No members | Low | Retire the policy, or fill the group |
| No description | Low | Describe the group and name its policy |
| Dynamic group (`groupTypes` has `DynamicMembership`) | Info | Fine for broad audiences; spend tiers should use access packages |

## Member

| Check | Severity | Fix |
| --- | --- | --- |
| Account disabled | Medium | Remove them from the group |
| Guest (`userType` is `Guest`) | Medium | Remove them, unless guests should spend credits |
| No successful sign-in for 90 days | Medium | Remove them from the group |
| No Copilot license, and the policy covers a licensed service | Medium | License them, or remove them |
| A person in a Teams Phone Agent policy group (it should hold resource accounts) | Medium | Keep resource accounts only |

## Across the Cowork tiers

Policy names come from the Copilot Group Assignment Guide.

| Check | Severity | Fix |
| --- | --- | --- |
| In both Cowork Limited and Cowork Unlimited | High | Remove one; the higher limit always wins |
| In Cowork Temporary Unlimited but not in Cowork Limited | Medium | Check how they were added; Temp is only for Limited members |
| A service turned on in more than one enabled policy | Info | People in both groups get the higher per-user limit; make sure that's intended |

## Not available through the Enterprise MCP

Per-person credit balances (used, left, blocked) need the cost management API. If the user wants
them, tell them to run `Get-CopilotBillingHealth.ps1` without `-SkipBalances` and attach Findings.csv.
