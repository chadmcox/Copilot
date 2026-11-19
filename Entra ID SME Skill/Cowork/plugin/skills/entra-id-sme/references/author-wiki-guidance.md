# Author wiki guidance — summarized

Source: Chad Cox, `chadmcox/Azure_Active_Directory` GitHub wiki. Base URL: https://github.com/chadmcox/Azure_Active_Directory/wiki/<page-name>
Ingested Nov 19, 2026 from the wiki repo (wiki last edited May 21, 2025).

Every item in this file is **[Author repo – community, not official Microsoft guidance]**. Lead with Microsoft guidance; use these as practitioner experience. Where an item conflicts with current Microsoft Learn, the conflict is flagged below — state the Learn position first, then the author position.

---

## 1. Entra-ID-Protection (page: `Entra-ID-Protection`)

### Before turning on any user-risk policy
- Clean up existing user risk first. Old risk causes unexpected prompts or blocks at enforcement. Author practice: dismiss low and medium with script, review high manually. Script: `Identity Protection/Dismiss-RiskyUsers.ps1` (**WRITE**, supports `-WhatIf`; follow **Change safety**).
- Author note: low-risk detections older than 6 months are auto-aged-out starting Mar 31, 2024 — **verify at runtime** on Learn before stating.
- Define trusted named locations for all corporate egress. Author view: this removes most false positives. Use the risk-based policy impact workbook to find untrusted IPs shared by many users, then confirm with the network team.
- Proxy/SSE with shared egress (Zscaler, Umbrella): see section 5.

### Remediation prerequisites (author summary — confirm on the risk-policies Learn page)
- Sign-in risk self-remediation: user must be MFA-registered. Federated IdP MFA can remediate when `federatedIdpMfaBehavior = enforceMfaByFederatedIdp`.
- User risk self-remediation: SSPR + password writeback (cloud or federated).
- MFA does not remediate user risk; repeated prompts result. Password change does not remediate sign-in risk.
- Do not put user risk and sign-in risk in the same CA policy: the conditions are ANDed, not ORed. (Learn says the same — see id-protection.md.)

### ID Protection settings (author recommendations)
| Setting | Author recommendation |
|---|---|
| Legacy user risk policy / sign-in risk policy | Disabled (migrate to CA — retired Oct 1, 2026 per Learn) |
| MFA registration policy | All users, exclude break-glass + exclusion group, On |
| Users at risk detected alerts | Notify named admins, level High |
| Weekly digest | On |
| Allow on-premises password change to reset user risk | Enable when PHS is on (including federated) |

### Author risk-based CA set (summarized; full tables on the wiki page)
| Policy | Users | Target | Condition | Grant / session | Use when |
|---|---|---|---|---|---|
| High user risk → password change | All, excl. break-glass | All resources | User risk High | Require password change; SIF every time | SSPR + writeback enabled. Author: allow only from trusted/compliant devices |
| High user risk → block on untrusted/non-compliant devices | All, excl. break-glass | All resources | User risk High + device filter (not compliant and not hybrid joined) | Block | Pair with the password-change policy; SOC must triage |
| Medium+High sign-in risk → MFA | All, excl. break-glass | All resources | Sign-in risk Med/High | Require MFA; SIF every time | Users MFA-registered (or federated MFA with enforceMfaByFederatedIdp) |
| Any sign-in risk → block register security info | All, excl. guests, break-glass | User action: Register security information | Low/Med/High | Block | Max protection; also protects shared mailboxes |
| Any sign-in risk → block admin portals | All, excl. break-glass | Microsoft Admin Portals + Windows Azure Service Management API | Low/Med/High | Block | Max protection |
| Any sign-in risk → block privileged roles | Privileged roles (+ Directory Sync Accounts role or separate policy) | All resources | Low/Med/High | Block | Max protection |
| Any user risk → block privileged roles | Same | All resources | Low/Med/High | Block | Max protection |
| Any sign-in risk → block Intune enrollment | All, excl. guests, break-glass | Microsoft Intune Enrollment | Low/Med/High | Block | Max protection |
| High user risk → block all | All, excl. break-glass | All resources | User risk High | Block | No SSPR/writeback. Author notes CISA recommends |
| High sign-in risk → block all | All, excl. break-glass | All resources | Sign-in risk High | Block | Users not MFA-registered. Author notes CISA recommends |

Author "privileged roles" list: Application Admin, Authentication Admin, Cloud Application Admin, Conditional Access Admin, Exchange Admin, Global Admin, Helpdesk Admin, Hybrid Identity Admin, Password Admin, Privileged Authentication Admin, Privileged Role Admin, Security Admin, SharePoint Admin, User Admin.

**Conflicts with current Microsoft Learn — say so when using this set:**
- Learn now recommends **Require risk remediation** for high user risk and **Require authentication strength** + SIF every time for sign-in risk (see id-protection.md). The author set uses the older "Require password change" / "Require MFA" grants. Verify at runtime: https://learn.microsoft.com/entra/identity/conditional-access/policy-risk-based-sign-in and https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-risk-based-user
- "Require multifactor authentication" and "Require authentication strength" can't be combined in one policy [MS Learn] https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths#limitations
- CA isn't enforced for administrative-unit-scoped or custom roles when targeting directory roles [MS Learn] https://learn.microsoft.com/entra/identity/conditional-access/policy-admin-phish-resistant-mfa#create-a-conditional-access-policy

Author KQL that checks each policy's impact: `Log Analytics/RBCA Impact` and `Log Analytics/Identity Protection Queries` (file list in kql-and-scripts.md).

---

## 2. Azure-AD-Conditional-Access-Policies (page: `Azure-AD-Conditional-Access-Policies`)

The page is older (policies dated up to 12/1/2022; author marks the import script "currently out dated"). Use it for **design principles and policy ideas**, not exact settings.

### Author principles
- Goals: protect privileged credentials, require trusted devices, don't depend on trusted networks, always require MFA.
- Back up CA before any change (Backup-CAPolicies).
- One exclusion security group per policy, governed by access reviews, instead of editing policies (script: Add-ExclusionGroups, **WRITE**).
- Always exclude break-glass from all-resource blocks.
- "All users + all resources + MFA" can break Logic Apps, Azure Virtual Desktop, Windows 365, Windows/Linux VM sign-in, SQL integrated auth — test in report-only.
- All-resource blocks can block Intune enrollment or license registration.
- You can't block Exchange Online or SharePoint Online without affecting Teams.
- Licensing (author): CA needs P1; license role members with P2. Verify licensing at runtime.
- On-prem synced "service accounts" should be the exception.

### Policy catalog (names only — open the wiki page for settings)
| Group | Policies |
|---|---|
| Guests | Block Microsoft Azure Management · Sign-in risk Med/High block all · Always require MFA |
| Privileged role members | Always MFA + limit session (SIF 2 hours) · Block legacy auth · Any sign-in risk block · Any user risk block · Require compliant device |
| Directory sync account | Block non-trusted networks · Any sign-in risk block |
| Devices | Require compliant device for Office 365 · Block Exchange ActiveSync · Unmanaged devices: no persistent browser, SIF 1 hour |
| All users | MFA all resources · High sign-in risk block · Sign-in risk MFA · High user risk block · Any sign-in risk block Azure Management · Med/High sign-in risk block security info registration · MFA for device join/registration · Block legacy auth · MFA for Azure Management · MFA for Graph PowerShell/Explorer · MFA for Defender portals · Allow Graph PowerShell/Explorer only for admins + named users |
| Workload identities | Block non-trusted networks · Service principal risk block |
| User-based service accounts | Block untrusted locations · O365-only · Azure-only |
| Other | Block Tor exit nodes (named location, not trusted; script New-TorNamedLocations) · Block countries with no users |

Each policy names an author KQL for impact, e.g. `query-MFAPercentageperapp.kql`, `query-noMFAAzureManagement.kql`, `query-AIPHighRiskAllCloudApps.kql`, `query-GuestAccessingAzureManagement.kql`, `query-SigninsfromKnownTorExitNodes.kql` (folder `Log Analytics/`).

Compare against Microsoft's current templates before recommending: https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-policy-common

---

## 3. Entra-ID-Find-Bad-Authentications-Types (page: `Entra-ID-Find-Bad-Authentications-Types`)

Author KQL (Log Analytics with SigninLogs + AADNonInteractiveUserSignInLogs). Read-only. Confirm column names against the schema before sharing (kql-and-scripts.md rule).

**Legacy authentication (successful, last 14 days)**
```kql
union SigninLogs, AADNonInteractiveUserSignInLogs
| where TimeGenerated > ago(14d) and ResultType == 0
| extend ClientAppUsed = iff(isempty(ClientAppUsed) == true, "Unknown", ClientAppUsed)
| extend isLegacyAuth = case(ClientAppUsed contains "Browser", "No", ClientAppUsed contains "Mobile Apps and Desktop clients", "No", ClientAppUsed contains "Exchange ActiveSync", "Yes", ClientAppUsed contains "Exchange Online PowerShell","Yes", ClientAppUsed contains "Authenticated SMTP","Yes", ClientAppUsed contains "Unknown", "Unknown", "Yes")
| where isLegacyAuth == "Yes"
| distinct Category, UserDisplayName, UserPrincipalName=tolower(UserPrincipalName), AppDisplayName, ClientAppUsed, isLegacyAuth, UserAgent
```

**ROPC (successful, home tenant, last 14 days)**
```kql
union SigninLogs, AADNonInteractiveUserSignInLogs
| where TimeGenerated > ago(14d) and AuthenticationProtocol == 'ropc' and HomeTenantId == ResourceTenantId and ResultType == 0
| distinct AppDisplayName, UPN = tolower(UserPrincipalName), ConditionalAccessStatus, AuthenticationRequirement, ClientAppUsed
| summarize apps=make_list(AppDisplayName) by UPN, ConditionalAccessStatus, AuthenticationRequirement, ClientAppUsed
```

**Device code flow (successful, home tenant, last 14 days; excludes broker/first-party sign-in apps)**
```kql
let excludeapps = pack_array("Windows Sign In","Microsoft Authenticator App","Microsoft Authentication Broker","Microsoft Account Controls V2","Microsoft Intune Company Portal","Microsoft Mobile Application Management");
union SigninLogs, AADNonInteractiveUserSignInLogs
| where TimeGenerated >= ago(14d) and AppDisplayName !in (excludeapps) and HomeTenantId == ResourceTenantId and ResultType == 0
| where AuthenticationProtocol == "deviceCode"
| project TimeGenerated, UserPrincipalName, ResultType, ResultDescription, UserAgent, IPAddress, Location, AppDisplayName, ResourceDisplayName, AuthenticationProtocol, AuthenticationRequirement
```
Pair with Microsoft policy pages: block legacy auth, block authentication flows (conditional-access.md).

---

## 4. Entra-ID-Reduce-the-chance-of-successful-password-sprays (page: `Entra-ID-Reduce-the-chance-of-successful-password-sprays`)

Author's ordered list (each item links to Microsoft Learn; re-verify each at runtime):
1. On-prem Entra Password Protection.
2. Risk-based CA: sign-in risk and user risk.
3. MFA for all users.
4. CA with Defender for Endpoint device risk.
5. Device-based CA (Intune compliance).
6. Block legacy authentication.
7. Restrict PowerShell endpoints used in sprays. **Outdated:** the linked "Blocking PowerShell for EDU" page targets MSOnline/AzureAD PowerShell, which Microsoft retired in 2025 (see gotchas.md). Replace with a CA policy on Microsoft Graph PowerShell / Graph Explorer (author CA catalog above).

Use the password spray playbook (attack-defense.md) as the Microsoft lead source; the 2018 ADFS and 2021 DART blog posts on the wiki page are superseded by it.

---

## 5. Entra-ID-Protection-stop-false-positive-risk-caused-by-Zscaler (page: `Entra-ID-Protection-stop-false-positive-risk-caused-by-Zscaler`)

Use only when the organization uses Zscaler (or similar SSE/proxy with shared egress) and sees false-positive sign-in risk (atypical travel etc.).

Author position, in order:
1. Preferred: require trusted/compliant device + MFA for all sign-ins; trusted locations then matter little.
2. Author caveat: false positives fade as the model learns from MFA completions; one concern is that proxy-in-the-middle activity could be missed.
3. Workaround used with multiple organizations: create a named location from Zscaler's published egress ranges (https://config.zscaler.com/zscaler.net/cenr), mark it trusted, and add a CA policy that requires MFA from that location (report-only first). Then restore the Med/High sign-in-risk MFA policy. Author notes Zscaler ASNs 62044 and 53813 appear in the workbook's untrusted-IP list.
4. Zscaler options [3P]: Source IP Anchoring for O365 CA (https://help.zscaler.com/zia/source-ip-anchoring-config-guide-office-365), direct-to-Microsoft logon URLs per Zscaler's M365 best practices.

Risk statement to include: marking a third-party proxy's whole egress as trusted lowers sign-in risk for every tenant user behind it. Present as a tradeoff, not a default.
