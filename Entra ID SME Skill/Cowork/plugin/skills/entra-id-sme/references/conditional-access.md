# Conditional Access — pointers

Verify every property in graph-validation.md before stating it.

## Baseline policy set (verify each page at runtime) [MS Learn]
| Topic | Page |
|---|---|
| Block legacy authentication | https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication |
| Block authentication flows (device code, authentication transfer) | https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-authentication-flows |
| MFA for all users | https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength (old howto-…-all-users-mfa URL redirects here) |
| Token protection | https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection ; external-user limits: https://learn.microsoft.com/en-us/entra/identity/conditional-access/deployment-guide-token-protection-windows |
| Microsoft admin portals target | https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-cloud-apps#microsoft-admin-portals |
| Windows VM sign-in with MFA | https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-windows#mfa-sign-in-method-required |
| Resilient / contingency policies | https://learn.microsoft.com/entra/identity/authentication/concept-resilient-controls |
| Emergency access accounts | https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access |

## Fetched at authoring (re-fetch before citing)
- Device code flow can be targeted in CA via `conditions.authenticationFlows.transferMethods = deviceCodeFlow` (v1.0) [Graph API] https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessauthenticationflows?view=graph-rest-1.0

## Review checklist (structure — fill each with a verified citation)
1. Emergency access (break-glass) exclusions — two levels:
   - **Required [MS Learn]:** excluded from every policy that blocks or restricts sign-in (block, MFA, compliant device or other grant controls). Learn wording: "Exclude emergency access accounts from Conditional Access policies that block or restrict sign-in." / "Report-only policies don't block access and don't need to exclude emergency accounts." https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access (last updated 06/05/2026). Missing → **High severity finding**.
   - **Recommended [Author repo – community, not official Microsoft guidance] (author practice):** excluded from all CA policies, including report-only. Missing → recommendation only.
   - Learn also recommends a dedicated security group for these accounts (e.g. EmergencyAccess) and testing sign-in regularly (e.g. quarterly) — re-fetch before citing.
2. Legacy auth blocked?
3. MFA / authentication strength for all users; phishing-resistant for admins?
4. Device code / authentication transfer restricted?
5. Risk-based user and sign-in policies in CA (see id-protection.md)?
6. Guest / external user policies (see multitenant-and-guest.md)?
7. Workload identity policies where licensed?
8. New policies start in report-only even where a Learn walkthrough says to set the policy straight to On (state the conflict) (`state = enabledForReportingButNotEnforced`, verified v1.0 at authoring: https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0).
9. Compare to CISA SCuBA MS.AAD policies (compliance-cisa-nist-cmmc.md).

## Author tools [Author repo – community, not official Microsoft guidance]
https://github.com/chadmcox/Azure_Active_Directory/tree/master/Conditional%20Access%20Policy — Backup-CAPolicies, Import-RecommendedCAPolicies, Add-BreakGlassExclusions, Get-StaleCAObjects, New-TorNamedLocations. Review before running. Backup-CAPolicies is the backup step before any CA change. Import-RecommendedCAPolicies, Add-BreakGlassExclusions and New-TorNamedLocations change the tenant: follow **Change safety** in SKILL.md (change list, backup, explicit confirmation, `-WhatIf`/`-Confirm`, user runs it).

Author policy catalog and design principles (older, up to 12/1/2022 — ideas, not exact settings): **author-wiki-guidance.md** §2. Read-only CA reports: Compare-CABaseline, Export-CAPoliciesToCsv, Get-CAExclusions, Get-CAPolicyReport (kql-and-scripts.md).

## Grant-control gotchas [MS Learn] (fetched Nov 19, 2026 — re-fetch before citing)
- Require MFA and Require authentication strength can't be combined in one policy: https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths#limitations
- Directory-role targeting doesn't enforce for administrative-unit-scoped or custom roles: https://learn.microsoft.com/entra/identity/conditional-access/policy-admin-phish-resistant-mfa#create-a-conditional-access-policy
- More in gotchas.md and auth-methods-and-pim.md.

## Third party [3P – third party, not Microsoft guidance]
https://github.com/AlexFilipin/ConditionalAccess — last commit Feb 28, 2025 (checked Nov 19, 2026); its README says it uses Graph **beta** endpoints. Say both when citing.
