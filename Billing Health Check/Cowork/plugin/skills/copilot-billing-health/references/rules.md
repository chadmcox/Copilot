# Rules

Thresholds: per-user minimum 2,000 credits, inactive after 90 days. The user can change them in the prompt.

"Licensed services" are `cowork` and `code`. People without a Copilot license can't use them.

**Maester** is the matching test in the [Maester AI governance pack](https://github.com/chadmcox/maester-ai-governance-pack) (— means the pack has no matching test). The coverage workflow in `.github/workflows/maester-coverage.yml` fails when a pack test isn't listed here.

## Policy

| Check | Severity | Fix | Maester |
| --- | --- | --- | --- |
| Scope is All users | High | Limit it to a security group | MP.AIGOV.1025 |
| Status isn't `enabled` | High | Link the group, or recreate the policy | MP.AIGOV.1025 |
| Scope is Groups but no group is listed | High | Link the policy's group | MP.AIGOV.1025 |
| Per-user limit and monthly limit are both Unlimited | High | Set a monthly limit | MP.AIGOV.1013 |
| Per-user limit under 2,000 | Medium | Raise it to at least 2,000 credits | MP.AIGOV.1025 |
| Billing is `notSpecified` | Medium | Pick prepaid credits or pay-as-you-go | MP.AIGOV.1025 |
| AlertOn is false | Medium | Turn on an alert at 80% with two owners as recipients | MP.AIGOV.1026 |
| An alert recipient is disabled or not found | Medium | Replace the recipient | MP.AIGOV.1026 |
| Only one alert recipient | Low | Add a second recipient | MP.AIGOV.1026 |

## Group

| Check | Severity | Fix | Maester |
| --- | --- | --- | --- |
| Group not found | High | Link the right group | MP.AIGOV.1025 |
| Microsoft 365 group (`groupTypes` has `Unified`) or not security-enabled | Medium | Use a security group | MP.AIGOV.1027 |
| Has nested groups | Medium | Add people directly; Microsoft doesn't say whether spending policies count nested members | MP.AIGOV.1027 |
| Fewer than two owners | Medium | Add owners so there are at least two | MP.AIGOV.1014 |
| No access review (if you checked) | Medium | Add a quarterly access review | — |
| No members | Low | Retire the policy, or fill the group | MP.AIGOV.1027 |
| No description | Low | Describe the group and name its policy | MP.AIGOV.1014 |
| Dynamic group (`groupTypes` has `DynamicMembership`) | Info | Fine for broad audiences; spend tiers should use access packages | MP.AIGOV.1027 |

## Member

| Check | Severity | Fix | Maester |
| --- | --- | --- | --- |
| Account disabled | Medium | Remove them from the group | MP.AIGOV.1032 |
| Guest (`userType` is `Guest`) | Medium | Remove them, unless guests should spend credits | MP.AIGOV.1032 |
| No successful sign-in for 90 days | Medium | Remove them from the group | MP.AIGOV.1032 |
| No working Copilot license, and the policy covers a licensed service. Working means: a license with the Copilot service plan, that plan not in `disabledPlans`, and its `licenseAssignmentStates` entry not in `Error` or `Disabled` | Medium | Assign a working Copilot license, or remove them | MP.AIGOV.1032 |
| A person in a Teams Phone Agent policy group (it should hold resource accounts) | Medium | Keep resource accounts only | — |

## Across the Cowork tiers

Policy names come from the Copilot Access Governance Guide.

| Check | Severity | Fix | Maester |
| --- | --- | --- | --- |
| In both Cowork Limited and Cowork Unlimited | High | Remove one; the higher limit always wins | MP.AIGOV.1015 |
| In Cowork Temporary Unlimited but not in Cowork Limited | Medium | Check how they were added; Temp is only for Limited members | — |
| A service turned on in more than one enabled policy | Info | People in both groups get the higher per-user limit; make sure that's intended | MP.AIGOV.1015 |

## Across any policies

Microsoft applies the most permissive policy when more than one covers a person: the higher per-user
limit wins and limits aren't combined. Check every member of every enabled group policy. An enabled
all-users policy covers everyone. Compare per-user limits per service the policies share (Unlimited is
highest). Skip it when every policy involved is a Cowork tier policy (the tier checks above cover that),
and when the only lower policy is an all-users base policy (a group tier on top of it is normal).

| Check | Severity | Fix | Maester |
| --- | --- | --- | --- |
| A group policy's per-user limit is overridden by an Unlimited policy for the same person and service | High | Remove them from one policy; the most permissive limit always wins | MP.AIGOV.1015 |
| A group policy's per-user limit is overridden by a higher cap for the same person and service | Medium | Remove them from one policy; the most permissive limit always wins | MP.AIGOV.1015 |
| In two group policies with the same per-user limit for the same service | Low | Keep them in one policy | MP.AIGOV.1015 |

## Not available through the Enterprise MCP

Per-person credit balances (used, left, blocked) need the cost management API. If the user wants
them, tell them to run `Get-CopilotBillingHealth.ps1` without `-SkipBalances` and attach Findings.csv.
