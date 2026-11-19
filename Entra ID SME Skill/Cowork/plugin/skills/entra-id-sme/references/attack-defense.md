# Attack & Defend — pointers

Primary playbook reference [3P – third party, not Microsoft guidance]: https://github.com/Cloud-Architekt/AzureAD-Attack-Defense
Chapters below were read from a clone of the repo on Nov 19, 2026 (last commit Oct 26, 2026). Chapter **titles** only — content not summarized; open the chapter at runtime and cite it. Always pair each 3P item with Microsoft guidance.

| Scenario | Microsoft guidance (lead with this) | AzureAD-Attack-Defense chapter [3P] |
|---|---|---|
| Password spray | [MS Learn] https://learn.microsoft.com/en-us/security/operations/incident-response-playbook-password-spray ; https://learn.microsoft.com/en-us/defender-xdr/alert-classification-password-spray-attack | `PasswordSpray.md` — Password Spray Attacks |
| Token theft / replay | [MS blog, 2022] https://www.microsoft.com/en-us/security/blog/2022/11/16/token-tactics-how-to-prevent-detect-and-respond-to-cloud-token-theft/ ; PRT: https://learn.microsoft.com/entra/identity/devices/concept-primary-refresh-token ; token protection: https://learn.microsoft.com/entra/identity/devices/protecting-tokens-microsoft-entra-id | `ReplayOfPrimaryRefreshToken.md` — Replay of PRT and other issued tokens from an Azure AD joined device |
| AiTM | Token tactics blog + authentication strengths https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths — verify at runtime | `Adversary-in-the-Middle.md` — Adversary-in-the-Middle (AiTM) Attacks |
| Device code phishing | [MS Learn] https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-authentication-flows ; detection KQL: author-wiki-guidance.md §3 | No dedicated chapter |
| Illicit consent | [MS Learn] https://learn.microsoft.com/defender-office-365/detect-and-remediate-illicit-consent-grants | `ConsentGrant.md` — Consent Grant Attack |
| Federation / SAML forgery, systemic compromise | [MS blog, 2020] https://www.microsoft.com/en-us/security/blog/2020/12/21/advice-for-incident-responders-on-recovery-from-systemic-identity-compromises/ ; [MS blog, 2024] https://www.microsoft.com/en-us/security/blog/2024/01/25/midnight-blizzard-guidance-for-responders-on-nation-state-attack/ | No dedicated chapter; Mandiant APT29 paper [3P] (link not checked) |
| On-prem → cloud pivot | [MS Learn] https://learn.microsoft.com/entra/architecture/protect-m365-from-on-premises-attacks | `LateralMovementADEID.md` — How to prevent lateral movement to Entra ID when your AD has fallen |
| Entra Connect Sync account abuse | Protect M365 from on-prem attacks (above) | `AADCSyncServiceAccount.md` — Abuse of Entra Connect Sync Service Account ; `EntraSyncAba.md` — Abuse of Entra Connect Application-based Authentication |
| Service principals / CI-CD | Workload identity CA + ID Protection workload risk — verify at runtime | `ServicePrincipals-ADO.md` — Service Principals in Azure DevOps (Release) Pipelines |
| Agent identities | Verify Entra Agent ID docs at runtime | `AgentIdentities.md` — Agent Identities |
| Config assessment / monitoring overview | Security operations guide https://learn.microsoft.com/entra/architecture/security-operations-introduction | `AADSecurityConfigAnalyzer.md` — EIDSCA ; `IdentitySecurityMonitoring.md` — Overview of Microsoft Identity Security Monitoring |

Other government source: NSA advisory on authentication mechanisms (2020): https://media.defense.gov/2020/Dec/17/2002554125/-1/-1/0/AUTHENTICATION_MECHANISMS_CSA_U_OO_198854_20.PDF

Author KQL for spray, risk and bad auth types: kql-and-scripts.md, author-wiki-guidance.md.

Output per scenario: Prevent / Detect (KQL, see kql-and-scripts.md) / Respond.
