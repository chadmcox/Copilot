# Gotchas

Community-contributed. Empty until contributors add verified entries — do not invent entries.

## Contribution rules
- One row per gotcha, in the table for its area.
- Every row needs a **Source/verified link** (Microsoft Learn, Graph reference, or a public reproducible source). No link, no row.
- No tenant IDs, UPNs, customer names or secrets. Every entry must cite a public source.
- Date format: YYYY-MM-DD. Re-verify rows older than 12 months before relying on them.

## Format
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|

## Conditional Access
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Can't save a policy that has both "Require MFA" and "Require authentication strength" | Unsupported grant combination; built-in MFA strength equals Require MFA | Use one or the other; prefer authentication strength | https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths#limitations | Skill review (C. Cox) | 2026-11-19 |
| Directory-role-targeted policy doesn't apply to some admins | CA isn't enforced for administrative-unit-scoped or custom roles | Target a group of the admins, or the built-in roles they hold | https://learn.microsoft.com/entra/identity/conditional-access/policy-admin-phish-resistant-mfa#create-a-conditional-access-policy | Skill review (C. Cox) | 2026-11-19 |
| Guests using email one-time passcode fail an authentication-strength policy | Auth strength applies only to external users who authenticate with Entra ID | Use the MFA grant control for OTP, SAML/WS-Fed, Google, MSA guests | https://learn.microsoft.com/entra/identity/conditional-access/policy-guests-mfa-strength#overview | Skill review (C. Cox) | 2026-11-19 |

## ID Protection
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Tenant still relies on ID Protection user risk / sign-in risk policies | Legacy risk policies retired Oct 1, 2026 | Recreate as risk-based CA in report-only, then disable legacy policies | https://learn.microsoft.com/entra/id-protection/howto-identity-protection-configure-risk-policies#migrate-risk-policies-to-conditional-access | Skill review (C. Cox) | 2026-11-19 |

## Authentication methods and PIM
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| Changes in MFA "service settings" or SSPR authentication methods have no effect | Since Sep 30, 2025, methods can't be managed in the legacy MFA and SSPR policies | Manage methods in the Authentication methods policy; run the migration guide | https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage#migration-from-legacy-policies | Skill review (C. Cox) | 2026-11-19 |
| A method is "disabled" but users still register it | Enabled in another policy (legacy or Authentication methods); any policy enabling it wins | Disable the method in all policies | https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage#how-policies-work-together | Skill review (C. Cox) | 2026-11-19 |
| Nobody can activate Global Admin / Privileged Role Admin | All GA/PRA eligible, approval required, no approvers configured | Keep emergency access accounts; configure named approvers | https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-how-to-change-default-settings#require-approval-to-activate | Skill review (C. Cox) | 2026-11-19 |

## PowerShell and tooling
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
| `Connect-MsolService` / MSOnline cmdlets fail with access denied | MSOnline PowerShell retired (early Apr–late May 2025) | Use Microsoft Graph PowerShell SDK or Microsoft Entra PowerShell | https://learn.microsoft.com/entra/fundamentals/whats-new-archive#january-2025 | Skill review (C. Cox) | 2026-11-19 |
| AzureAD module scripts stop working | AzureAD PowerShell unsupported after Mar 30, 2025; retirement early July 2025 | Migrate to Graph PowerShell; cmdlet map: https://learn.microsoft.com/powershell/entra-powershell/azuread-powershell-to-entra-powershell-mapping | https://learn.microsoft.com/entra/fundamentals/whats-new-archive#january-2025 | Skill review (C. Cox) | 2026-11-19 |

## Hybrid identity
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|

## Defender for Identity
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|

## Multitenant and guest
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|

## Compliance mapping
| Symptom | Root cause | Fix | Source/verified link | Contributor | Date |
|---|---|---|---|---|---|
