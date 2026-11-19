# Source hierarchy

Priority: **1)** Microsoft Learn + Microsoft Graph API reference → **1b)** Microsoft Entra Blog `[MS Entra Blog]` → **2)** CISA / NIST / DoD official → **3)** Author repos `[Author repo – community, not official Microsoft guidance]` → **4)** `[3P – third party, not Microsoft guidance]`.

Links are pointers. Fetch the page in the session before relying on it. Status column: "Fetched at authoring" = page was retrieved when this skill was built (Nov 2026); everything else = verify at runtime.

## Microsoft Graph API reference [Graph API]
- conditionalAccessPolicy v1.0: https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0
- conditionalAccessPolicy beta: https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-beta
- More resource types: see graph-validation.md

## Microsoft Entra Blog [MS Entra Blog] — priority 1b (official Microsoft)
- https://techcommunity.microsoft.com/category/microsoft-security/blog/microsoft-entra-blog
- Use for: announcements, new features, GA vs preview, retirements/deprecations, "what's new". Always show the post's publication date.
- Not proof of a setting, property or enum value: confirm those in Learn / Graph. Blog newer than or contradicting Learn → docs may lag; cite both with dates; Partially verified.
- Reachability: fetched at authoring (Nov 19, 2026); the index page returned a list of dated posts. Individual posts were not read or summarized — fetch the specific post at runtime.

## Standards and baselines [CISA] [NIST] [MS Learn]
- CISA SCuBA Entra ID baseline [CISA]: https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md (flags BOD 25-01 Requirement / Automated Check / Manual; assumes E3/G3 licensing; defines resource vs home tenant for guests; lists CISA highly-privileged roles)
- NIST NCP checklist, Entra ID SCuBA 2.0 [NIST]: https://ncp.nist.gov/checklist/1082
- NIST SP 800-207 Zero Trust Architecture [NIST]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
- Entra for CMMC [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-for-cmmc-compliance
- CMMC Level 1 [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-1-controls
- CMMC Level 2 Access Control [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-access-control
- CMMC Level 2 Identification and Authentication [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-identification-and-authentication
- CMMC Level 2 additional controls [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-additional-controls
- Entra standards docs source (also NIST AAL, FedRAMP, M-22-09 pages; resolve the matching Learn URLs at runtime): https://github.com/MicrosoftDocs/entra-docs/tree/main/docs/standards

## Defender for Identity [MS Learn]
- Docs hub: https://learn.microsoft.com/en-us/defender-for-identity/
- Security posture assessments: https://learn.microsoft.com/en-us/defender-for-identity/security-assessment
- Account assessments: https://learn.microsoft.com/en-us/defender-for-identity/security-posture-assessments/accounts
- Certificates (AD CS) assessments: https://learn.microsoft.com/en-us/defender-for-identity/security-posture-assessments/certificates

## Multitenant [MS Learn]
- Cross-tenant sync overview: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview
- Configure cross-tenant sync (incl. cross-cloud): https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure
- Governance and cross-tenant sync: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-governance
- Multitenant capabilities overview: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview
- Multitenant organization (MTO) overview: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview

## 1. Operating model [MS Learn]
- https://learn.microsoft.com/entra/architecture/security-operations-introduction (monitoring/alerting backbone)
- https://learn.microsoft.com/entra/architecture/ops-guide-intro (day-2 / tenant health)
- https://learn.microsoft.com/entra/identity/authentication/concept-resilient-controls (contingency CA, EMnnn naming)
- https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access (break-glass)
- https://learn.microsoft.com/security/zero-trust/deploy/identity

## 2. Conditional Access [MS Learn]
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-authentication-flows
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-all-users-mfa (now redirects to https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength)
- Token protection: https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection
- Token protection deployment (Windows; includes external-user limits): https://learn.microsoft.com/en-us/entra/identity/conditional-access/deployment-guide-token-protection-windows
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-cloud-apps#microsoft-admin-portals
- https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-windows#mfa-sign-in-method-required

## 2b. Authentication methods, strengths, PIM [MS Learn]
See auth-methods-and-pim.md (fetched Nov 19, 2026).

## 3. ID Protection [MS Learn]
- https://learn.microsoft.com/entra/id-protection/howto-identity-protection-configure-risk-policies#migrate-risk-policies-to-conditional-access (fetched at authoring — see id-protection.md)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-risk-user (now redirects to https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-risk-based-user)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-risk
- https://learn.microsoft.com/entra/id-protection/workbook-risk-based-policy-impact
- https://learn.microsoft.com/en-us/entra/id-protection/how-to-deploy-identity-protection
- https://learn.microsoft.com/en-us/entra/id-protection/
- https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-migrate-mfa-server-to-mfa-with-federation#set-federatedidpmfabehavior-to-enforcemfabyfederatedidp

## 4. Attack response [MS Learn] / Microsoft Security blog
- https://learn.microsoft.com/en-us/security/operations/incident-response-playbook-password-spray
- https://learn.microsoft.com/en-us/defender-xdr/alert-classification-password-spray-attack
- https://www.microsoft.com/en-us/security/blog/2022/11/16/token-tactics-how-to-prevent-detect-and-respond-to-cloud-token-theft/
- https://www.microsoft.com/en-us/security/blog/2020/12/21/advice-for-incident-responders-on-recovery-from-systemic-identity-compromises/
- https://www.microsoft.com/en-us/security/blog/2024/01/25/midnight-blizzard-guidance-for-responders-on-nation-state-attack/
- https://learn.microsoft.com/entra/architecture/protect-m365-from-on-premises-attacks
- https://learn.microsoft.com/defender-office-365/detect-and-remediate-illicit-consent-grants

Blog posts are dated; check for a newer Learn page before relying on product specifics.

## 5. Hybrid, devices, B2B, passwords [MS Learn]
- https://learn.microsoft.com/entra/identity/devices/concept-primary-refresh-token
- https://learn.microsoft.com/entra/external-id/cross-tenant-access-overview#cross-tenant-sign-in-activity-powershell-script
- https://learn.microsoft.com/en-us/entra/identity/authentication/howto-password-ban-bad-on-premises-deploy
- https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization#password-expiration-policy

## 6. Author repos [Author repo – community, not official Microsoft guidance]
Author: Chad Cox. Useful queries and scripts; never cite as Microsoft guidance. Review any script before running it.
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Log%20Analytics/Identity%20Protection%20Queries
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Log%20Analytics/RBCA%20Impact
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Conditional%20Access%20Policy (Backup-CAPolicies, Import-RecommendedCAPolicies, Add-BreakGlassExclusions, Get-StaleCAObjects, New-TorNamedLocations)
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Guest (Get-GuestReport, Get-StaleGuests, Remove-StaleGuests, Get-ViralGuests)
- https://github.com/chadmcox/Sentinel-and-Defender-Queries/tree/main/Defender

- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Authentication%20Methods , /Roles%20and%20PIM , /Identity%20Protection , /Agent%20ID (indexed in kql-and-scripts.md)

Wiki pages (Azure_Active_Directory GitHub wiki) — **ingested Nov 19, 2026; summarized in author-wiki-guidance.md** (wiki last edited May 21, 2025):
- Entra-ID-Protection
- Azure-AD-Conditional-Access-Policies
- Entra-ID-Find-Bad-Authentications-Types
- Entra-ID-Reduce-the-chance-of-successful-password-sprays
- Entra-ID-Protection-stop-false-positive-risk-caused-by-Zscaler
Base URL: https://github.com/chadmcox/Azure_Active_Directory/wiki/<page-name>
Known wiki issues: 5 script links 404 after the repo reorg (old names such as create-aadmgguestreport.ps1); the `Conditional Access Policy/ReadMe.md` also still lists old script names. Use the folder index in kql-and-scripts.md, not wiki script links.

## 7. Third party [3P – third party, not Microsoft guidance]
- https://github.com/Cloud-Architekt/AzureAD-Attack-Defense (primary attack/defense playbook reference; last commit Oct 26, 2026; chapter map in attack-defense.md)
- https://github.com/AlexFilipin/ConditionalAccess (last commit Feb 28, 2025; uses Graph beta endpoints per its README)
- https://www.mandiant.com/sites/default/files/2022-08/remediation-hardening-strategies-for-m365-defend-against-apt29-white-paper.pdf (link not checked)
- https://media.defense.gov/2020/Dec/17/2002554125/-1/-1/0/AUTHENTICATION_MECHANISMS_CSA_U_OO_198854_20.PDF (NSA advisory; government source, dated 2020)
- https://help.zscaler.com/zia/source-ip-anchoring-config-guide-office-365 (only when the organization uses Zscaler)
