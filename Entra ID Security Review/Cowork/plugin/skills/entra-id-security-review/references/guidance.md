# Sources behind the checks

Every finding names its sources in brackets after the fix, using the short names below. **Which source backs which check is this repo's mapping.** The CISA policy IDs and CIS numbers come from the published baselines, but check them against your own copy before you cite them in an audit, and say they're this repo's mapping when you present them.

## Baselines

| Short name | Source | Version used |
| --- | --- | --- |
| **CISA** | CISA SCuBA, *M365 Secure Configuration Baseline for Microsoft Entra ID* (`MS.AAD.*`). Policies marked BOD 25-01 are required for US federal civilian agencies under Binding Operational Directive 25-01. https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md and https://www.cisa.gov/resources-tools/services/secure-cloud-business-applications-scuba-project | Baseline on GitHub as of Oct 29, 2026, including MS.AAD.9.1v1 (risky AI agents) |
| **CIS** | CIS, *Microsoft 365 Foundations Benchmark*, Entra sections 1.1 (admin accounts) and 5 (Microsoft Entra admin center). https://www.cisecurity.org/benchmark/microsoft_365 | v7.0.0 (May 19, 2026). The numbers here follow v7.0.0's new numbering, read from Prowler's public CIS 7.0 mapping; check them against the CIS PDF |
| **Playbook** | Thomas Naunheim, Sami Lamppu and contributors, *Attack and Defense Playbook for Microsoft Entra* (Cloud-Architekt/AzureAD-Attack-Defense). https://github.com/Cloud-Architekt/AzureAD-Attack-Defense | Main branch, Nov 2026 |
| **EIDSCA (Playbook)** | The Playbook's Entra ID Security Config Analyzer: recommended values for the authorization policy, consent settings, password rules and authentication methods. https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/AADSecurityConfigAnalyzer.md | Config v3 |

## Playbook chapters

| Short name | Chapter | What the review takes from it |
| --- | --- | --- |
| Playbook: Password spray | [Password Spray](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/PasswordSpray.md) | Block legacy authentication, MFA for all, banned passwords and smart lockout, no password expiry, limit guest enumeration |
| Playbook: Consent grant | [Consent Grant](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/ConsentGrant.md) | No app registration by users, restricted user consent, risk-based step-up, admin consent workflow, review of delegated and application permissions |
| Playbook: Service principals in Azure DevOps | [Service Principals in Azure DevOps](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/ServicePrincipals-ADO.md) | Certificates or federated credentials instead of secrets, least privilege for service principals, no service principals in privileged roles |
| Playbook: Entra Connect sync account | [Microsoft Entra Connect Sync Service Account](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/AADCSyncServiceAccount.md) | Tier 0 for Entra Connect, block soft and hard match, remove old sync accounts, restrict the sync account to its server IPs, watch TAP and password resets |
| Playbook: Replay of PRT | [Replay of Primary Refresh Token](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/ReplayOfPrimaryRefreshToken.md) | No local admin for users, TPM and compliance, risk-based response, token protection |
| Playbook: Adversary-in-the-Middle | [Adversary-in-the-Middle (AiTM) Attacks](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/Adversary-in-the-Middle.md) | Phishing-resistant MFA, managed devices in Conditional Access, risk policies, attack disruption |
| Playbook: Entra Connect application-based authentication | [Microsoft Entra Connect Sync Application-based Authentication](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/EntraSyncAba.md) | No owners on privileged apps, app instance property lock, app management policy to block secrets, review roles that can add app credentials |
| Playbook: Agent identities | [Agent Identities](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/AgentIdentities.md) | AI Administrator as Tier 0, sponsors instead of owners, blueprint creation, Conditional Access for agents |
| Playbook: Lateral movement | [How to prevent lateral movement to Entra ID when your Active Directory has fallen](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense/blob/main/LateralMovementADEID.md) | Cloud-only admins, admin Conditional Access policy, legacy MFA bypasses, trusted locations, Seamless SSO, MFA registration |

## Microsoft, NSA and Mandiant guidance

| Short name | Article |
| --- | --- |
| DEV-0537 | Microsoft Threat Intelligence, [DEV-0537 criminal actor targeting organizations for data exfiltration and destruction](https://www.microsoft.com/security/blog/2022/03/22/dev-0537-criminal-actor-targeting-organizations-for-data-exfiltration-and-destruction/) (Mar 2022). MFA for all users and locations, no SMS or voice, number matching, risk policies for MFA registration and device enrollment, break-glass accounts stored offline, help desk verification, alerts on role and tenant-wide changes |
| NSA | NSA, [Detecting Abuse of Authentication Mechanisms](https://media.defense.gov/2020/Dec/17/2002554125/-1/-1/0/AUTHENTICATION_MECHANISMS_CSA_U_OO_198854_20.PDF) (Dec 2020). Harden and monitor federation (forged SAML), lock down tenant SSO configuration, watch service principal credentials |
| IR recovery | Microsoft DART, [Advice for incident responders on recovery from systemic identity compromises](https://www.microsoft.com/security/blog/2020/12/21/advice-for-incident-responders-on-recovery-from-systemic-identity-compromises/) (Dec 2020). Cloud-only privileged accounts, PIM, review high-risk app permissions, remove unexpected credentials, rotate the token-signing certificate, review "MFA satisfied by claim in the token" |
| Solorigate IOCs | Microsoft Identity, [Understanding "Solorigate"'s Identity IOCs](https://techcommunity.microsoft.com/t5/azure-active-directory-identity/understanding-quot-solorigate-quot-s-identity-iocs-for-identity/ba-p/2007610) (Dec 2020). Modified federation trusts, credentials added to apps and service principals, new application permissions |
| Securing identity with Zero Trust | Microsoft, [Securing identity with Zero Trust](https://learn.microsoft.com/security/zero-trust/deploy/identity) |
| Security operations guide | Microsoft, [Microsoft Entra security operations guide](https://learn.microsoft.com/entra/architecture/security-operations-introduction), including [applications](https://learn.microsoft.com/entra/architecture/security-operations-applications) and [privileged accounts](https://learn.microsoft.com/entra/architecture/security-operations-privileged-accounts) |
| Sensitive operations report | Microsoft, [Sensitive operations report workbook](https://learn.microsoft.com/entra/identity/monitoring-health/workbook-sensitive-operations-report): credential changes, new permissions, role changes for service principals, federation changes |
| AADInternals blog | Nestori Syynimaa, [AADInternals blog (o365blog.com)](https://o365blog.com/): research on device registration, cross-tenant sync, Seamless SSO and pass-through authentication abuse |
| Security roadmap | Microsoft, [Security roadmap: top priorities for the first 30 days, 90 days and beyond](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/security-roadmap?view=o365-worldwide) (this link may now redirect; Microsoft's current privileged access roadmap is in [Securing privileged access](https://learn.microsoft.com/entra/identity/role-based-access-control/security-planning#develop-a-roadmap)). Used to order the "fix these first" list: MFA and legacy authentication first, then privileged access, then apps |
| Illicit consent grants | Microsoft, [Detect and remediate illicit consent grants](https://learn.microsoft.com/defender-office-365/detect-and-remediate-illicit-consent-grants) |
| Protect M365 from on-premises | Microsoft, [Protect Microsoft 365 from on-premises attacks](https://learn.microsoft.com/entra/architecture/protect-m365-from-on-premises-attacks): cloud-only admins with phishing-resistant credentials, no on-premises account with cloud privileges, cloud authentication, monitoring of tenant-wide changes |
| MSRC keyCredential guidance | MSRC, [Guidance for Azure AD keyCredential property information disclosure (CVE-2021-42306)](https://msrc.microsoft.com/blog/2021/11/guidance-for-azure-active-directory-ad-keycredential-property-information-disclosure-in-application-and-service-principal-apis/) (Nov 2021). Some Azure Automation Run As apps stored private keys in keyCredentials; rotate those credentials and look for misuse |
| Resilient access controls | Microsoft, [Create a resilient access control management strategy](https://learn.microsoft.com/entra/identity/authentication/concept-resilient-controls): emergency access accounts, contingency policies, more than one MFA method |
| Least privileged roles by task | Microsoft, [Least privileged roles by task in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/role-based-access-control/delegate-by-task) |
| Mandiant APT29 | Mandiant, [Remediation and Hardening Strategies for Microsoft 365 to Defend Against APT29 (v1.3)](https://www.mandiant.com/sites/default/files/2022-08/remediation-hardening-strategies-for-m365-defend-against-apt29-white-paper.pdf) (2022). AD FS as Tier 0, federated domain review, cloud-only admins with no ImmutableID, review app credentials and mail permissions, partner relationships |

## CISA SCuBA Entra ID policies

How the review checks each policy. **Live** means a Graph call through the Enterprise MCP; **Manual** means it's on the manual checklist.

| Policy | BOD 25-01 | In short | Checked |
| --- | --- | --- | --- |
| MS.AAD.1.1v1 | Yes | Block legacy authentication | Live |
| MS.AAD.2.1v1 | Yes | Block users detected as high risk | Live (P2) |
| MS.AAD.2.2v1 | | Notify admins of high-risk users | Manual |
| MS.AAD.2.3v1 | Yes | Block high-risk sign-ins | Live (P2) |
| MS.AAD.3.1v1 | Yes | Phishing-resistant MFA for all users | Live |
| MS.AAD.3.2v2 | Yes | MFA for all users | Live |
| MS.AAD.3.3v2 | Yes | Authenticator shows login context | Live |
| MS.AAD.3.4v1 | Yes | Authentication methods migration complete | Live |
| MS.AAD.3.5v2 | Yes | SMS, voice and email OTP disabled | Live |
| MS.AAD.3.6v1 | Yes | Phishing-resistant MFA for highly privileged roles | Live |
| MS.AAD.3.7v1 | | Managed devices required for authentication | Live |
| MS.AAD.3.8v1 | | Managed devices required to register MFA | Live |
| MS.AAD.3.9v1 | | Block device code flow | Live |
| MS.AAD.4.1v1 | | Security logs sent to the SOC | Manual |
| MS.AAD.5.1v1 | Yes | Only admins register apps | Live |
| MS.AAD.5.2v1 | Yes | User consent restricted | Live |
| MS.AAD.5.3v1 | Yes | Admin consent workflow | Live |
| MS.AAD.5.5v1 | | Block app password addition | Live |
| MS.AAD.5.6v1 | | App password lifetime 180 days or less | Live |
| MS.AAD.5.7v1 | | App certificate lifetime 365 days or less | Live |
| MS.AAD.6.1v1 | Yes | Passwords don't expire | Live |
| MS.AAD.7.1v1 | Yes | Two to eight Global Administrators | Live |
| MS.AAD.7.2v1 | Yes | Finer-grained roles instead of Global Administrator | Live |
| MS.AAD.7.3v1 | Yes | Cloud-only privileged accounts | Live |
| MS.AAD.7.4v1 | Yes | No permanent active highly privileged assignments | Live (P2) |
| MS.AAD.7.5v1 | Yes | Highly privileged roles assigned only through PIM | Live, from the audit log for the lookback period |
| MS.AAD.7.6v1 | Yes | Global Administrator activation needs approval | Live (P2) |
| MS.AAD.7.7v1 | Yes | Alert on highly privileged assignments | Live (P2): PIM notification recipients |
| MS.AAD.7.8v1 | Yes | Alert on Global Administrator activation | Live (P2): PIM notification recipients |
| MS.AAD.7.9v1 | | Alert on other highly privileged activations | Live (P2) |
| MS.AAD.8.1v1 | | Guests have limited or restricted access | Live |
| MS.AAD.8.2v1 | | Only Guest Inviters invite guests | Live |
| MS.AAD.8.3v1 | | Guest invites only to allowed domains | Manual |
| MS.AAD.9.1v1 | Yes | Block risky AI agents | Live (the policy; risky agents themselves return 403) |

## CIS Microsoft 365 v7.0.0, Entra recommendations

| Number | In short | Checked |
| --- | --- | --- |
| 1.1.1 | Admin accounts are cloud-only | Live |
| 1.1.2 | Two emergency access accounts | Live, plus manual |
| 1.1.3 | Two to four Global Administrators | Live |
| 1.1.4 | Admin accounts have a reduced license footprint | Live |
| 5.1.2.1 | Per-user MFA is off | Live (admins) |
| 5.1.2.2 | Users can't register apps | Live |
| 5.1.2.3 | Users can't create tenants | Live |
| 5.1.2.4 | Restrict access to the Entra admin center | Manual |
| 5.1.2.5, 5.1.2.6 | Keep me signed in hidden; LinkedIn connections off | Manual |
| 5.1.3.1, 5.1.3.4 | Group creation limited | Live |
| 5.1.4.1 to 5.1.4.6 | Device join, device limit, local admins, LAPS, BitLocker keys | Live |
| 5.1.5.1, 5.1.5.2 | User consent; admin consent workflow | Live |
| 5.1.5.3 to 5.1.5.6 | App management policy: block secrets, secret lifetime, custom secrets, certificate lifetime | Live |
| 5.1.6.1 | Guest invites to allowed domains | Manual |
| 5.1.6.2, 5.1.6.3 | Guest access restricted; who can invite | Live |
| 5.1.8.1 | Password hash sync on | Manual (403) |
| 5.2.2.1 to 5.2.2.17 | Conditional Access: MFA, legacy auth, admin sessions, phishing-resistant admins, risk, managed devices, MFA registration, Intune enrollment, device code, sign-in frequency, locations, token protection, authentication transfer | Live |
| 5.2.3.1 to 5.2.3.10 | Authenticator context, banned passwords, MFA capable, SMS and email off, system-preferred MFA, smart lockout, Authenticator Lite | Live |
| 5.2.4.1 to 5.2.4.5 | Self-service password reset settings | Manual |
| 5.3.1 to 5.3.5 | PIM, access reviews for guests and roles, approval for Global Administrator and Privileged Role Administrator | Live (P2 or ID Governance) |

## Not checked here

- **Exchange, SharePoint, Teams and Defender** settings in the CISA and CIS baselines (for example Exchange `ApplicationImpersonation`, mailbox auditing, SharePoint sharing). This review covers Entra only.
- **Detections and hunting queries** from the Playbook (KQL for Sentinel and Defender XDR). The review checks the configuration that prevents the attacks and the audit events that reveal them, not your SIEM rules; those are on the manual checklist.
- **On-premises Active Directory** hardening (tiering, krbtgt rotation, AD FS servers). The review only checks what Entra shows about them.
