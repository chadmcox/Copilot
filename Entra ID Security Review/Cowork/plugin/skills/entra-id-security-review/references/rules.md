# Rules

Every check below comes from at least one of these sources. The **Sources** column says which, using the short names in [guidance.md](guidance.md), where each source is listed with its link.

- **CISA**: the CISA SCuBA *Secure Configuration Baseline for Microsoft Entra ID* (policy IDs like `MS.AAD.3.1v1`). Policies marked **BOD 25-01** are required for US federal civilian agencies.
- **CIS**: the *CIS Microsoft 365 Foundations Benchmark v7.0.0* (recommendation numbers like `5.2.2.3`), Entra sections 1.1 and 5.
- **Playbook**: the community *Attack and Defense Playbook for Microsoft Entra* (Cloud-Architekt/AzureAD-Attack-Defense), named by chapter.
- **Microsoft, NSA and Mandiant guidance**: the incident and hardening articles in guidance.md, named by short title (for example *Solorigate IOCs* or *DEV-0537*).

**Severities and thresholds are this repo's choices.** CISA's SHALL and BOD 25-01 policies are High, its SHOULD policies Medium. CIS Level 1 is Medium, Level 2 Low, unless the check closes a known attack path (then High). Where a source gives a number (two to eight Global Administrators, 180-day secrets, lockout threshold 10), the rule uses it. When CISA and CIS give different numbers, the rule says which it uses.

Thresholds: inactive after 90 days, sign-in log lookback 30 days. The user can change them in the prompt.

Each finding has an **Area** (Privileged access, Authentication, Conditional Access and risk, Applications and consent, Hybrid and federation, External identities, Tenant and devices, Recent changes), an **Item** (the policy, app, role, setting or a count), a **Topic** (the attack it helps stop, from the list below), a **Severity** (High, Medium, Low, Info), a **Check** (what's wrong), a **Fix** and the **Sources** in brackets at the end of the fix.

**Topics** (the attack scenario each finding helps stop): Password spray, MFA fatigue and phone fraud, Token theft and AiTM, Consent phishing, App credential abuse, Privilege escalation, Lateral movement from on-premises, Federation trust abuse, Guest and cross-tenant abuse, Device registration abuse, Agent identities, Lockout and resilience.

**Don't name people.** For users, guests and admins, report counts, not names or UPNs, unless the user asks. Apps, policies, groups and roles can be named.

**Microsoft apps.** Skip consent, owner and credential checks for Microsoft's own service principals: those whose `appOwnerOrganizationId` is Microsoft's (the same as the Microsoft Graph service principal's) or whose `publisherName` starts with "Microsoft". The one exception is the **Entra Connect application-based authentication** app (display name starting `ConnectSyncProvisioning_`), which lives in your tenant: check it.

**Licenses.** Read `subscribedSkus` once. `AAD_PREMIUM` means Entra ID P1; `AAD_PREMIUM_P2` means P2; `Entra_Identity_Governance` (or `ENTRA_ID_GOVERNANCE`) means ID Governance. Skip checks marked *P1* or *P2* (and say so in the notes) when the tenant doesn't have that plan.

**Highly privileged roles** (CISA's list, plus four the Playbook and Microsoft's guidance treat as Tier 0):

| Role | Template ID | Why |
| --- | --- | --- |
| Global Administrator | `62e90394-69f5-4237-9190-012177145e10` | CISA |
| Privileged Role Administrator | `e8611ab8-c189-46e8-94e1-60213ab1f814` | CISA |
| User Administrator | `fe930be7-5e62-47db-91af-98c3a49a38b1` | CISA |
| SharePoint Administrator | `f28a1f50-f6e7-4571-818b-6a12f2af6b6c` | CISA |
| Exchange Administrator | `29232cdf-9323-42fd-ade2-1d097af3e4de` | CISA |
| Hybrid Identity Administrator | `8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2` | CISA |
| Application Administrator | `9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3` | CISA |
| Cloud Application Administrator | `158c047a-c907-4556-b7ef-446551a6b5f7` | CISA |
| Privileged Authentication Administrator | `7be44c8a-adaf-4e2a-84d6-ab2649e08a13` | Resets any admin's credentials (Playbook: Lateral movement) |
| Security Administrator | `194ae4cb-b126-40b2-bd5b-6091b380977d` | Changes Identity Protection and security settings |
| Conditional Access Administrator | `b1be1c3e-b65d-4f19-8427-f6fa0d97feb9` | Can turn off the policies that protect everyone |
| AI Administrator | `d2562ede-74db-457e-a7b6-544e236ebb61` | Playbook: Agent identities says treat it as Tier 0 |

Where a rule says *privileged roles* without "highly", it means every role definition with `isPrivileged` true, plus Exchange and SharePoint Administrator.

**Emergency access accounts.** Ask the user which accounts they are. If they don't say, treat cloud-only users with a permanent Global Administrator assignment that are excluded from at least one MFA policy as the likely ones, and say that's a guess.

## Privileged access

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| Fewer than two, or more than eight, users hold Global Administrator (active and eligible, each user counted once) | High | Privilege escalation | Keep two to eight. CIS asks for two to four; this rule flags more than four as a separate Low finding | CISA MS.AAD.7.1v1 (BOD 25-01); CIS 1.1.3 |
| More than four (and no more than eight) users hold Global Administrator | Low | Privilege escalation | Move people to finer-grained roles until two to four remain | CIS 1.1.3 |
| More users hold Global Administrator than hold all the other highly privileged roles together (CISA's ratio: GA users ÷ other highly privileged users > 1) | Medium | Privilege escalation | Give admins finer-grained roles instead of Global Administrator | CISA MS.AAD.7.2v1 (BOD 25-01); Least privileged roles by task |
| A user synced from on-premises (`onPremisesSyncEnabled` true) holds a highly privileged role; one finding with the count | High | Lateral movement from on-premises | Use separate cloud-only admin accounts. Remove the role from the synced account | CISA MS.AAD.7.3v1 (BOD 25-01); CIS 1.1.1; Protect M365 from on-premises; Playbook: Lateral movement; Mandiant APT29 |
| A cloud-only user who holds a highly privileged role has an `onPremisesImmutableId` set; one finding with the count | High | Federation trust abuse | Clear the ImmutableID. With one set, a forged SAML token or a hard match can take over the account | Mandiant APT29; Playbook: Entra Connect sync account |
| *P2:* users with a permanent active assignment (`roleAssignmentSchedules`, `assignmentType` Assigned, no end date) to a highly privileged role, not counting emergency access accounts; one finding per role with the count | High | Privilege escalation | Make them eligible in PIM, so the role is activated just in time | CISA MS.AAD.7.4v1 (BOD 25-01); CIS 5.3.1; IR recovery |
| *P2:* activating Global Administrator doesn't need approval (`Approval_EndUser_Assignment` `isApprovalRequired` false) | High | Privilege escalation | Require approval to activate Global Administrator | CISA MS.AAD.7.6v1 (BOD 25-01); CIS 5.3.4 |
| *P2:* activating Privileged Role Administrator doesn't need approval | Medium | Privilege escalation | Require approval to activate Privileged Role Administrator | CIS 5.3.5 |
| *P2:* PIM sends Global Administrator assignment and activation alerts only to the default recipients (`Notification_Admin_Admin_Assignment`, `Notification_Admin_Admin_Eligibility` and `Notification_Admin_EndUser_Assignment` have no `notificationRecipients`) | Medium | Privilege escalation | Add a monitored security mailbox to the PIM notification settings for Global Administrator | CISA MS.AAD.7.7v1, MS.AAD.7.8v1 (BOD 25-01); DEV-0537 (alert on role changes) |
| *P2:* the same, for the other highly privileged roles (one finding listing the roles) | Low | Privilege escalation | Add a monitored mailbox, different from the Global Administrator one, for the other highly privileged roles | CISA MS.AAD.7.9v1 |
| *P2:* activating a highly privileged role doesn't require MFA or an authentication context (`Enablement_EndUser_Assignment` lacks `MultiFactorAuthentication` and the `AuthenticationContext_EndUser_Assignment` rule is off) | High | Token theft and AiTM | Require an authentication context on activation that asks for phishing-resistant MFA | Protect M365 from on-premises; Playbook: Agent identities (AI Administrator) |
| No enabled Conditional Access policy requires the **Phishing-resistant MFA** authentication strength (`00000000-0000-0000-0000-000000000004`, or a custom strength with only `windowsHelloForBusiness`, `fido2`, `x509CertificateMultiFactor`) for the highly privileged roles (`includeRoles`) | High | Token theft and AiTM | Require phishing-resistant MFA for admins with Conditional Access | CISA MS.AAD.3.6v1 (BOD 25-01); CIS 5.2.2.5; Playbook: Adversary-in-the-Middle; Protect M365 from on-premises |
| No enabled Conditional Access policy for admin roles sets a sign-in frequency (`sessionControls.signInFrequency`) and a non-persistent browser (`persistentBrowser.mode` never) | Medium | Token theft and AiTM | Set a sign-in frequency of 4 hours or less and never persist the browser session for admins | CIS 5.2.2.4; Playbook: Lateral movement (admin policy) |
| A user who holds a highly privileged role has a license with Exchange Online, SharePoint or Teams (a day-to-day account); one finding with the count | Medium | Token theft and AiTM | Use a separate admin account with no productivity license (Entra ID P1 or P2 only) | CIS 1.1.4; Protect M365 from on-premises |
| A highly privileged user isn't registered for a phishing-resistant method (`methodsRegistered` has none of `fido2SecurityKey`, `passKeyDeviceBound`, `passKeyDeviceBoundAuthenticator`, `passKeyDeviceBoundWindowsHello`, `windowsHelloForBusiness`, `macOsSecureEnclaveKey`); one finding with the count | High | Token theft and AiTM | Register a passkey or Windows Hello for Business for every admin | CISA MS.AAD.3.6v1; DEV-0537; Protect M365 from on-premises |
| Fewer than two emergency access accounts: cloud-only users with a permanent Global Administrator assignment | High | Lockout and resilience | Create two cloud-only emergency access accounts with phishing-resistant credentials, stored offline | CIS 1.1.2; Resilient access controls; DEV-0537 (break glass offline) |
| An emergency access account isn't excluded from at least one enabled policy that could lock it out (an All users policy with an MFA, device or block grant) and has no phishing-resistant method | Medium | Lockout and resilience | Exclude them from policies that could lock them out, and register a FIDO2 key for each | CIS 1.1.2; Resilient access controls |
| A service principal holds a highly privileged role (one finding per app and role) | High | App credential abuse | Check it needs the role. Service principals skip MFA and PIM; give the least role, or remove it | Solorigate IOCs; NSA; Playbook: Service principals in Azure DevOps |
| A user, or a service principal, owns an app or service principal that holds a highly privileged role or a high-privilege Graph permission (from `owners`); one finding per app | High | Privilege escalation | Remove the owners. An owner can add a credential and act as the app | Playbook: Entra Connect application-based authentication; Playbook: Agent identities |
| A group that holds a highly privileged role (role-assignable group) has owners | Medium | Privilege escalation | Remove the owners, or make sure they already hold Privileged Role Administrator; owners can add themselves | Least privileged roles by task; Protect M365 from on-premises (group owners) |
| A guest holds a privileged role (one finding with the count) | High | Guest and cross-tenant abuse | Remove the role. Admins must be members of your tenant | Securing identity with Zero Trust; Mandiant APT29 |

## Authentication

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| Security defaults are off and no enabled Conditional Access policy requires MFA (or an authentication strength) for All users and All resources | High | Password spray | Require MFA for everyone with Conditional Access | CISA MS.AAD.3.2v2 (BOD 25-01); CIS 5.2.2.2; DEV-0537; Playbook: Password spray |
| No enabled Conditional Access policy requires **Phishing-resistant MFA** for All users | Medium | Token theft and AiTM | Roll out passkeys or Windows Hello for Business, then require phishing-resistant MFA for everyone | CISA MS.AAD.3.1v1 (SHALL; rated Medium here because it needs a rollout first); Playbook: Adversary-in-the-Middle |
| The authentication methods policy `policyMigrationState` isn't `migrationComplete` | High | MFA fatigue and phone fraud | Finish moving the legacy MFA and SSPR method settings, then set it to Migration complete. Legacy MFA settings (trusted IPs, remember MFA) bypass MFA | CISA MS.AAD.3.4v1 (BOD 25-01); Playbook: Lateral movement (MFA bypasses) |
| `Sms` or `Voice` is `enabled` (one finding each) | High | MFA fatigue and phone fraud | Turn off SMS and voice call; SIM swap and phone fraud beat them | CISA MS.AAD.3.5v2 (BOD 25-01); CIS 5.2.3.5; DEV-0537 |
| `Email` is `enabled` for members (not only `allowExternalIdToUseEmailOtp` for guests) | Medium | MFA fatigue and phone fraud | Turn off email OTP as an authentication method | CISA MS.AAD.3.5v2; CIS 5.2.3.7 |
| Microsoft Authenticator is enabled and `displayAppInformationRequiredState` or `displayLocationInformationRequiredState` isn't `enabled` for all users (with no exclusions) | High | MFA fatigue and phone fraud | Show the app name and location in Authenticator notifications | CISA MS.AAD.3.3v2 (BOD 25-01); CIS 5.2.3.1; DEV-0537 |
| Microsoft Authenticator `companionAppAllowedState` (Authenticator Lite) isn't `disabled` | Low | MFA fatigue and phone fraud | Turn off Authenticator Lite in companion apps | CIS 5.2.3.10 |
| `systemCredentialPreferences.state` isn't `enabled` for all users | Medium | MFA fatigue and phone fraud | Turn on system-preferred MFA so people get their strongest method first | CIS 5.2.3.6; EIDSCA (Playbook) |
| `reportSuspiciousActivitySettings.state` isn't `enabled` for all users | Low | MFA fatigue and phone fraud | Let people report MFA prompts they didn't start; reports raise user risk | EIDSCA (Playbook); DEV-0537 |
| `Fido2` is enabled with `isAttestationEnforced` false | Low | Token theft and AiTM | Enforce attestation, and limit to approved key models if you can | EIDSCA (Playbook) |
| `TemporaryAccessPass` is enabled with `isUsableOnce` false, or `maximumLifetimeInMinutes` over 480 | Low | Privilege escalation | Make TAPs one-time with a short lifetime. A TAP on the sync account or an admin is a backdoor | Playbook: Entra Connect sync account (TAP backdoor); EIDSCA |
| No **Password Rule Settings** directory setting, or `EnableBannedPasswordCheck` is false | Medium | Password spray | Turn on the custom banned password list with company names, products and places | CIS 5.2.3.2; Playbook: Password spray; DEV-0537 |
| Sync is on and `EnableBannedPasswordCheckOnPremises` is false, or `BannedPasswordCheckOnPremisesMode` is `Audit` | Medium | Password spray | Deploy on-premises password protection in Enforced mode | CIS 5.2.3.3; Playbook: Password spray |
| Smart lockout: `LockoutThreshold` over 10 or `LockoutDurationInSeconds` under 60 | Medium | Password spray | Set the threshold to 10 or less and the duration to at least 60 seconds | CIS 5.2.3.8, 5.2.3.9; EIDSCA; Playbook: Password spray |
| A verified domain's `passwordValidityPeriodInDays` isn't 2147483647 (passwords expire) | Medium | Password spray | Set passwords to never expire, and rely on MFA and banned passwords | CISA MS.AAD.6.1v1 (BOD 25-01); Playbook: Password spray (NIST) |
| *P1:* member users who aren't MFA capable (`userRegistrationDetails`, `userType` member, `isMfaCapable` false); one finding with the count and the percentage | Medium | Password spray | Run a registration campaign; require registration from a managed device or trusted location | CIS 5.2.3.4; IR recovery (verify MFA details) |
| Admins with per-user MFA `enabled` or `enforced` (from `/users/{id}/authentication/requirements`) | Low | MFA fatigue and phone fraud | Use Conditional Access for MFA instead, then turn per-user MFA off | CIS 5.1.2.1 |

## Conditional Access and risk

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| No enabled Conditional Access policy blocks legacy authentication (`clientAppTypes` `exchangeActiveSync` and `other`, block grant, All users) | High | Password spray | Block legacy authentication, starting in report-only | CISA MS.AAD.1.1v1 (BOD 25-01); CIS 5.2.2.3; Playbook: Password spray |
| *P1:* successful legacy authentication sign-ins in the last 30 days (`clientAppUsed` Exchange ActiveSync, IMAP4, POP3, Authenticated SMTP, Other clients); one finding with the count per type | Medium | Password spray | Move those people to modern clients, then block the protocol | Playbook: Password spray; Mandiant APT29 |
| No enabled policy blocks the device code flow (`conditions.authenticationFlows.transferMethods` includes `deviceCodeFlow`, block grant, All users) | Medium | Token theft and AiTM | Block device code flow, with exceptions only for devices that need it | CISA MS.AAD.3.9v1; CIS 5.2.2.12 |
| No enabled policy blocks authentication transfer (`transferMethods` includes `authenticationTransfer`) | Medium | Token theft and AiTM | Block authentication transfer | CIS 5.2.2.17 |
| *P2:* no enabled policy blocks high user risk (`userRiskLevels` high, block grant, or a secure password change). CISA asks for block | High | Token theft and AiTM | Block users at high risk, or require a secure password change with sign-in frequency every time | CISA MS.AAD.2.1v1 (BOD 25-01); CIS 5.2.2.6; DEV-0537; Playbook: Replay of PRT |
| *P2:* no enabled policy blocks high sign-in risk (`signInRiskLevels` high, block grant) | High | Token theft and AiTM | Block high-risk sign-ins | CISA MS.AAD.2.3v1 (BOD 25-01); CIS 5.2.2.7; DEV-0537 |
| *P2:* no enabled policy covers medium sign-in risk (block, or MFA with sign-in frequency every time) | Medium | Token theft and AiTM | Block medium and high sign-in risk, or require MFA every time for medium | CIS 5.2.2.8; DEV-0537; Playbook: Adversary-in-the-Middle |
| *P2:* users at high risk (`riskyUsers` with `riskState` atRisk and `riskLevel` high); one finding with the count | High | Token theft and AiTM | Investigate and remediate them now: revoke sessions, reset credentials, check MFA methods | CISA MS.AAD.2.1v1; IR recovery; Playbook: Replay of PRT |
| *P2 plus Workload ID:* service principals at risk (`riskyServicePrincipals` atRisk); one finding per app | High | App credential abuse | Investigate; remove unexpected credentials and permissions | Solorigate IOCs; NSA |
| No enabled policy targets agent identities with agent risk high (`agentIdRiskLevels` high, block grant) | Medium | Agent identities | Block high-risk agents with Conditional Access for agents | CISA MS.AAD.9.1v1 (BOD 25-01); Playbook: Agent identities |
| No enabled policy requires a compliant or hybrid-joined device (`compliantDevice` or `domainJoinedDevice`) for All users | Medium | Token theft and AiTM | Require a managed device for access; a stolen token from a phishing proxy then fails | CISA MS.AAD.3.7v1; CIS 5.2.2.9; Playbook: Adversary-in-the-Middle; DEV-0537 |
| No enabled policy protects security info registration (user action `urn:user:registersecurityinfo`) with a managed device, a trusted location or MFA | High | MFA fatigue and phone fraud | Require a managed device (CISA) or a trusted location for MFA registration. Attackers register their own MFA after a password leak | CISA MS.AAD.3.8v1; CIS 5.2.2.10; DEV-0537; Playbook: Lateral movement |
| No enabled policy requires sign-in frequency every time for Microsoft Intune Enrollment (app `d4ebce55-015a-49b5-a083-c84d1797ae8c`) | Low | Device registration abuse | Require reauthentication every time for device enrollment | CIS 5.2.2.11; DEV-0537 (block device enrollment on risk) |
| No enabled policy uses token protection (`sessionControls.secureSignInSession`) for Exchange Online, SharePoint Online or Teams | Low | Token theft and AiTM | Pilot token protection for those apps on Windows | CIS 5.2.2.16; Playbook: Replay of PRT |
| No enabled policy for All users sets a sign-in frequency of 7 days or less | Low | Token theft and AiTM | Set periodic reauthentication of 7 days or less | CIS 5.2.2.13 |
| No trusted named location, or a policy blocks no untrusted countries | Low | Password spray | Define trusted locations; block countries you never sign in from | CIS 5.2.2.14, 5.2.2.15 |
| A trusted named location (`isTrusted` true) is used to skip MFA (an MFA policy excludes it) | Medium | Lateral movement from on-premises | Don't skip MFA from trusted locations; an attacker inside the network then signs in with only a password | DEV-0537 (no location-based MFA exclusions); Playbook: Lateral movement (delete trusted locations) |
| An enabled policy with All resources and a block grant excludes no users, groups or roles | High | Lockout and resilience | Exclude your emergency access accounts | Resilient access controls |
| An enabled policy excludes individual users (other than emergency access accounts) instead of a group | Low | Lockout and resilience | Use an exclusion group and review it with an access review | Resilient access controls; Securing identity with Zero Trust |
| An enabled MFA policy excludes the **Directory Synchronization Accounts** role, and no other enabled policy targets that role with a location or block control | Medium | Lateral movement from on-premises | Add a policy that lets the sync account sign in only from your Entra Connect server IPs | Playbook: Entra Connect sync account |

## Applications and consent

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| Users can register applications (`defaultUserRolePermissions.allowedToCreateApps` true) | High | Consent phishing | Set it to No; let admins (or Application Developers) register apps | CISA MS.AAD.5.1v1 (BOD 25-01); CIS 5.1.2.2; Playbook: Consent grant |
| Users can create agent identity blueprints (`allowedToCreateAgentIdentityBlueprints` true) | Medium | Agent identities | Set it to No and use the Agent ID Developer role | Playbook: Agent identities |
| User consent includes `ManagePermissionGrantsForSelf.microsoft-user-default-legacy` (users can consent to any app) | High | Consent phishing | Turn off user consent, or allow only verified publishers and low-impact permissions | CISA MS.AAD.5.2v1 (BOD 25-01); CIS 5.1.5.1; Illicit consent grants; Playbook: Consent grant |
| User consent is allowed with Microsoft's low or recommended policy | Low | Consent phishing | CISA asks for user consent restricted; this passes CISA but CIS Level 2 asks for no user consent | CIS 5.1.5.1 (L2) |
| The admin consent workflow (`adminConsentRequestPolicy.isEnabled`) is off | High | Consent phishing | Turn it on, with a group of reviewers | CISA MS.AAD.5.3v1 (BOD 25-01); CIS 5.1.5.2; Illicit consent grants |
| Group owner consent (if there's no **Consent Policy Settings** object in `/settings`, don't guess the defaults: put this and the next check on the manual list): the **Consent Policy Settings** setting `EnableGroupSpecificConsent` is true and `ConstrainGroupSpecificConsentToMembersOfGroupId` is empty | Medium | Consent phishing | Turn off group owner consent, or limit it to one group | EIDSCA (Playbook); Playbook: Consent grant |
| `BlockUserConsentForRiskyApps` isn't true (Consent Policy Settings), or `allowUserConsentForRiskyApps` is true | High | Consent phishing | Block user consent to apps Microsoft flags as risky | EIDSCA (Playbook); Playbook: Consent grant |
| The default app management policy is off, or doesn't block new client secrets (`applicationRestrictions.passwordCredentials` has no `passwordAddition` restriction), and no custom app management policy does | Medium | App credential abuse | Block client secret creation for new apps; use certificates or federated credentials | CISA MS.AAD.5.5v1; CIS 5.1.5.3; Playbook: Entra Connect application-based authentication |
| No `passwordLifetime` restriction of 180 days or less | Medium | App credential abuse | Limit client secret lifetime to 180 days | CISA MS.AAD.5.6v1; CIS 5.1.5.4 |
| No `customPasswordAddition` restriction | Low | App credential abuse | Block custom (user-chosen) client secrets | CIS 5.1.5.5 |
| No `keyCredentials` `asymmetricKeyLifetime` restriction. CIS asks for 180 days, CISA 365 | Low | App credential abuse | Limit certificate lifetime; this rule passes at 365 days (CISA) and notes CIS wants 180 | CISA MS.AAD.5.7v1; CIS 5.1.5.6 |
| A non-Microsoft app has a client secret (`passwordCredentials`); one finding per app | Medium | App credential abuse | Ask the owner how it's stored; move to a certificate, managed identity or federated credential | Security operations guide (applications); Playbook: Service principals in Azure DevOps |
| A client secret lasts more than 180 days from its start date, or a certificate more than 365 days | Low | App credential abuse | Replace it with a shorter-lived credential | Security operations guide (applications); CISA MS.AAD.5.6v1, 5.7v1 |
| A non-Microsoft **service principal** (not the app registration) has its own `passwordCredentials` or `keyCredentials` | High | App credential abuse | Find out who added it. Credentials on the service principal itself were a Solorigate persistence trick | Solorigate IOCs; NSA; IR recovery; Mandiant APT29 |
| A multi-tenant app (`signInAudience` not `AzureADMyOrg`) registered in this tenant has app instance property lock off (`servicePrincipalLockConfiguration.isEnabled` false) | Medium | App credential abuse | Turn on app instance property lock for all properties | Playbook: Entra Connect application-based authentication |
| An app registration has a redirect URI with `http://` (other than `localhost`) or a wildcard | Medium | Consent phishing | Use https and exact URIs; remove ones you don't own | Security operations guide (applications) |
| A non-Microsoft app has a delegated grant (`oauth2PermissionGrants`) with `consentType` AllPrincipals for `Directory.AccessAsUser.All`, `user_impersonation`, `EWS.AccessAsUser.All`, `EAS.AccessAsUser.All`, any `Mail.*`, `Files.ReadWrite.All` or `Sites.*.All` | High | Consent phishing | Check the app is known; remove the grant if not | Illicit consent grants; IR recovery; Playbook: Consent grant |
| A non-Microsoft app has a delegated grant (Principal consent) for `Mail.Read`, `Mail.ReadWrite`, `Mail.Send` or `offline_access` plus `Files.Read.All`; one finding per app with the count of users | Medium | Consent phishing | Check the app and the users who consented; revoke grants you don't recognize | Illicit consent grants |
| A non-Microsoft app has a high-privilege Microsoft Graph application permission: `RoleManagement.ReadWrite.Directory`, `AppRoleAssignment.ReadWrite.All`, `Application.ReadWrite.All`, `Directory.ReadWrite.All`, `Domain.ReadWrite.All`, `Policy.ReadWrite.*`, `User.ReadWrite.All`, `Group.ReadWrite.All`, `Mail.ReadWrite`, `Mail.Send`, `Files.ReadWrite.All`, `Sites.FullControl.All`, `UserAuthenticationMethod.ReadWrite.All` | High | Privilege escalation | Replace with a narrower permission or remove it. Several of these can grant themselves Global Administrator | IR recovery; Solorigate IOCs; Playbook: Consent grant; Playbook: Entra Connect application-based authentication |
| A non-Microsoft app has the Exchange Online `full_access_as_app` permission (Office 365 Exchange Online, appId `00000002-0000-0ff1-ce00-000000000000`) | High | App credential abuse | Replace it with Graph permissions scoped by RBAC for Applications; APT29 used this to read mail | Mandiant APT29; IR recovery |
| An app registration that looks like an old Azure Automation Run As account (display name ending `_RunAs` or containing `RunAsAccount`) still has a certificate | Medium | App credential abuse | Run As accounts are retired; delete the app, or rotate the certificate if anything still uses it. Some stored private keys in keyCredentials (CVE-2021-42306) | MSRC keyCredential guidance |

## Hybrid and federation

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| A domain's `authenticationType` is `Federated`; one finding per domain | High | Federation trust abuse | Move to cloud authentication (password hash sync or passkeys). A stolen token-signing key lets an attacker sign in as anyone | Protect M365 from on-premises; NSA; IR recovery; Solorigate IOCs; Mandiant APT29 |
| More than one account holds **Directory Synchronization Accounts** (`d29b2b05-8046-44ba-8758-1e26182fcf32`), or a holder is a user rather than the Entra Connect service principal | Medium | Lateral movement from on-premises | Remove old sync accounts; move Entra Connect to application-based authentication | Playbook: Entra Connect sync account; Playbook: Entra Connect application-based authentication |
| The Entra Connect application-based authentication app (`ConnectSyncProvisioning_*`) has owners, or a client secret | High | Lateral movement from on-premises | Remove owners and secrets; keep only the certificate Entra Connect manages, in a TPM | Playbook: Entra Connect application-based authentication |
| Sync is on and the Hybrid Identity Administrator role has permanent holders | Medium | Lateral movement from on-premises | Make it eligible in PIM | CISA MS.AAD.7.4v1; Playbook: Entra Connect sync account |
| Sync is on and dynamic groups that grant privileged access (role-assignable, or used in a Conditional Access exclusion) use an on-premises attribute (`user.onPremises*`, `extensionAttribute*`, `department`, `employeeId`) in their rule | Medium | Lateral movement from on-premises | Don't let on-premises attributes decide privileged or exclusion group membership | Protect M365 from on-premises (dynamic groups) |

## External identities

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| `guestUserRoleId` is `a0b1b346-4d3e-4e8b-98f8-753987be4970` (guests have the same access as members) | High | Guest and cross-tenant abuse | Set guest access to limited (`10dae51f-b6af-4016-8d66-8c2a99b929b3`) or restricted (`2af84b1e-32c8-42b7-82bc-daa82404023b`) | CISA MS.AAD.8.1v1; CIS 5.1.6.2; Playbook: Password spray (user enumeration) |
| `allowInvitesFrom` is `everyone` | Medium | Guest and cross-tenant abuse | Limit invitations to admins and the Guest Inviter role | CISA MS.AAD.8.2v1; CIS 5.1.6.3 |
| `allowInvitesFrom` is `adminsGuestInvitersAndAllMembers` | Low | Guest and cross-tenant abuse | CISA wants only Guest Inviters; consider entitlement management for external access | CISA MS.AAD.8.2v1 |
| `allowEmailVerifiedUsersToJoinOrganization` is true, or `allowedToSignUpEmailBasedSubscriptions` is true | Low | Guest and cross-tenant abuse | Turn off email-verified join and self-service sign-up | EIDSCA (Playbook) |
| The cross-tenant default (`crossTenantAccessPolicy/default`) `inboundTrust.isMfaAccepted` is true | Medium | Guest and cross-tenant abuse | Trust MFA only from specific partner tenants, not every tenant | Securing identity with Zero Trust; AADInternals blog (cross-tenant) |
| A partner configuration allows inbound cross-tenant sync (`identitySynchronization` `isSyncAllowed` true) | Medium | Guest and cross-tenant abuse | Check you expect that tenant to create users in yours; remove it if not | AADInternals blog (cross-tenant) |
| Guests who haven't signed in for 90 days, or never and were created more than 90 days ago (one finding with the count) | Low | Guest and cross-tenant abuse | Remove them, or set up an access review that does | CIS 5.3.2; Mandiant APT29 |
| *P2 or ID Governance:* guests exist and no access review covers them | Medium | Guest and cross-tenant abuse | Set up a recurring review of guest access | CIS 5.3.2 |

## Tenant and devices

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| Users can create tenants (`allowedToCreateTenants` true) | Medium | Guest and cross-tenant abuse | Set it to No | CIS 5.1.2.3; EIDSCA |
| Users can create security groups (`allowedToCreateSecurityGroups` true) | Low | Privilege escalation | Turn it off, or limit it with a self-service group plan | CIS 5.1.3.1 |
| Anyone can create Microsoft 365 groups (`Group.Unified` setting `EnableGroupCreation` true with no `GroupCreationAllowedGroupId`) | Low | Privilege escalation | Limit group creation to a group | CIS 5.1.3.4 |
| Users can read BitLocker keys for their own devices (`allowedToReadBitlockerKeysForOwnedDevice` true) | Low | Device registration abuse | Set it to No | CIS 5.1.4.6; Playbook: Replay of PRT (block users viewing recovery keys) |
| Anyone can join devices (`deviceRegistrationPolicy.azureADJoin.allowedToJoin` is all users) | Low | Device registration abuse | Limit Entra join to a group | CIS 5.1.4.1 |
| `userDeviceQuota` is more than 10 | Medium | Device registration abuse | Set the device limit to 10 or less | CIS 5.1.4.2; AADInternals blog (device registration abuse) |
| `azureADJoin.localAdmins.enableGlobalAdmins` is true | Medium | Lateral movement from on-premises | Don't add Global Administrators as local admins on every joined device | CIS 5.1.4.3; Playbook: Replay of PRT |
| `azureADJoin.localAdmins.registeringUsers` is all users | Medium | Device registration abuse | Don't make the registering user a local admin; most PRT theft needs local admin | CIS 5.1.4.4; Playbook: Replay of PRT |
| `localAdminPassword.isEnabled` is false (Windows LAPS off) | Medium | Lateral movement from on-premises | Turn on Microsoft Entra LAPS | CIS 5.1.4.5 |
| `multiFactorAuthConfiguration` is `notRequired` and no Conditional Access policy covers the user action **Register or join devices** (`urn:user:registerdevice`) | Medium | Device registration abuse | Require MFA to register or join devices, with Conditional Access | DEV-0537; AADInternals blog (device registration abuse) |

## Recent changes

These read the directory audit log for the lookback period (30 days by default; the audit log keeps 30 days with P1 or P2, 7 without). Each is the sign of an attack the sources describe, so a hit needs someone to confirm it was expected. Skip a hit that came from a change the user tells you about.

| Check | Severity | Topic | Fix | Sources |
| --- | --- | --- | --- | --- |
| `Set domain authentication` or `Set federation settings on domain` events; one finding per domain | High | Federation trust abuse | Confirm the change was planned. An unexpected one is how Solorigate added its own federation trust | Solorigate IOCs; NSA; Mandiant APT29; Sensitive operations report |
| `Add member to role` events logged by `Core Directory` for a highly privileged role, where `initiatedBy.app.displayName` isn't `MS-PIM` (a direct assignment outside PIM); one finding per role with the count | High | Privilege escalation | Assign highly privileged roles only through PIM, and alert on direct assignments | CISA MS.AAD.7.5v1 (BOD 25-01); Protect M365 from on-premises (monitor) |
| `Add service principal credentials`, or `Update application – Certificates and secrets management`, on a non-Microsoft app that holds a privileged role or a high-privilege permission; one finding per app | High | App credential abuse | Confirm who added it and why; remove it if unknown | Solorigate IOCs; Security operations guide (applications); Sensitive operations report |
| `Add app role assignment to service principal` where the resource is Microsoft Graph or Exchange Online and the permission is on the high-privilege list; one finding per app | Medium | Privilege escalation | Confirm the grant was approved | IR recovery; Security operations guide (applications) |
| `Add owner to application` or `Add owner to service principal` on an app that holds a privileged role or a high-privilege permission | Medium | Privilege escalation | Confirm the new owner; remove if unexpected | Security operations guide (applications); Playbook: Entra Connect application-based authentication |
| `Set DirSync feature` events (for example soft or hard match turned back on), or a Temporary Access Pass added (`Admin registered temporary access pass method for user`) or `Reset user password` for a Directory Synchronization Accounts holder or an admin | Medium | Lateral movement from on-premises | Confirm the change was planned. A TAP or password reset on the sync account or an admin is a known backdoor | Playbook: Entra Connect sync account |
| `Update conditional access policy` or `Delete conditional access policy` events (one Info finding with the count, naming the policies) | Info | Lockout and resilience | Check each change went through your change process | DEV-0537 (alert on tenant-wide security changes); Protect M365 from on-premises (monitor) |

## Scoring

Each check is an item. A check that passes scores 100. A check that raises findings starts at 100 and loses 25 for each High, 10 for each Medium and 3 for each Low, never below 0. An area's score is the average of its checks. Checks that couldn't run (403, no license, no data) aren't counted; list them in the notes. Rating: Green 80+, Amber 50-79, Red under 50.

Also give the **CISA BOD 25-01 count**: how many of the BOD 25-01 policies the tenant meets out of those the review could check, for example "16 of 21 BOD 25-01 policies met". List the ones not met in the notes.

## Phishing-resistant admins funnel

Count the **users** with an active or eligible highly privileged role.

1. Highly privileged users: all of them.
2. Cloud-only: and not synced from on-premises, with no `onPremisesImmutableId`.
3. Just in time: and holding no permanent active highly privileged assignment (emergency access accounts count as passing).
4. Phishing-resistant method: and registered for one of the methods in the Privileged access rules.
5. Phishing-resistant required: and covered by an enabled Conditional Access policy that requires the Phishing-resistant MFA strength for their role (or All users).

Phishing-resistant admins % = step 5 / step 1.

## Manual checks (not readable through the Enterprise MCP)

List them all, grouped by area. If the browser is available, read the admin center pages and say what you see; never change a setting.

**Privileged access**
- Admins use dedicated privileged access workstations, not their day-to-day devices (Protect M365 from on-premises; Playbook: Agent identities).
- Emergency access accounts' credentials are stored offline, not in an online password vault, and their sign-ins raise an alert (DEV-0537; CIS 1.1.2).
- Partner (CSP) relationships: only GDAP, with the least roles, and no old DAP relationships (Microsoft 365 admin center > Settings > Partner relationships). The MCP returns 403 for `delegatedAdminRelationships` (Mandiant APT29).
- Help desk verifies identity before resetting an admin's or executive's password or MFA (DEV-0537).

**Authentication**
- Legacy per-user MFA settings: no trusted IPs, "skip MFA for federated users on my intranet" off, "remember MFA on trusted devices" off (Playbook: Lateral movement).
- MFA fraud alerts and the notification email for risky users go to a monitored mailbox (CISA MS.AAD.2.2v1).
- Self-service password reset needs two methods, notifies users and all admins when an admin's password is reset (CIS 5.2.4.1 to 5.2.4.5).
- **Keep me signed in** is hidden (CIS 5.1.2.5) and LinkedIn account connections are off (CIS 5.1.2.6) in Entra ID > Users > User settings.

**Conditional Access and risk**
- Microsoft Defender XDR automatic attack disruption is on, with the Defender for Identity action account set up (Playbook: Adversary-in-the-Middle).
- Global Secure Access compliant network or Defender for Cloud Apps session control for sensitive apps, if you have them (Playbook: Adversary-in-the-Middle).
- Contingency Conditional Access policies exist in report-only for an MFA provider outage (Resilient access controls).

**Applications and consent**
- Defender for Cloud Apps app governance (OAuth app policies) is on, with alerts for new high-privilege apps (Playbook: Consent grant).
- A process exists to review app permissions and consent grants every quarter, with owners for each app (Illicit consent grants; Security operations guide).
- Azure DevOps service connections use workload identity federation, not secrets (Playbook: Service principals in Azure DevOps).

**Hybrid and federation**
- Entra Connect sync features: **BlockSoftMatch** and **BlockCloudObjectTakeoverThroughHardMatch** are on (Entra admin center > Entra Connect, or `Get-EntraDirSyncFeature`). The MCP returns 403 for `/directory/onPremisesSynchronization` (Playbook: Entra Connect sync account).
- Password hash sync is on, even if you federate (CIS 5.1.8.1; Resilient access controls).
- Seamless SSO is off unless you need it, and the `AZUREADSSOACC` key is rolled every 30 days if it's on (Playbook: Lateral movement).
- AD FS (if federated): token-signing certificate auto-rollover on, `federatedIdpMfaBehavior` is `enforceMfaByFederatedIdp` or `rejectMfaByFederatedIdp` (not accept), and the issuer URI and signing certificate match your AD FS servers. The MCP returns 403 for `federationConfiguration` (NSA; IR recovery; Solorigate IOCs).
- Entra Connect, AD FS, PTA agents and Cloud Sync agents are managed as Tier 0, patched, with a TPM-backed application certificate (Playbook: Entra Connect sync account; Playbook: Entra Connect application-based authentication).
- Tier 0 on-premises accounts (Domain Admins, Entra Connect service accounts) aren't synced (Protect M365 from on-premises; Mandiant APT29).

**External identities**
- Guest invitations are limited to an allowlist of domains (CISA MS.AAD.8.3v1; CIS 5.1.6.1).

**Tenant and devices**
- **Restrict access to Microsoft Entra admin center** is Yes (CIS 5.1.2.4).
- Device compliance requires TPM, BitLocker and Defender for Endpoint risk score, with no grace period (Playbook: Replay of PRT).

**Monitoring**
- Entra sign-in, audit, non-interactive, service principal and risk logs go to a SIEM or Log Analytics (CISA MS.AAD.4.1v1; Security operations guide).
- Alerts exist for: credentials added to apps and service principals, federation or domain authentication changes, new app role assignments to Graph, consent to apps by admins, role assignments outside PIM, changes to Conditional Access, cross-tenant settings and sync features, sign-ins by emergency access accounts (Security operations guide; Solorigate IOCs; Protect M365 from on-premises; DEV-0537).
- Sign-ins with "MFA requirement satisfied by claim in the token" are reviewed where AD FS doesn't send MFA claims (IR recovery).
- A recovery plan for a systemic identity compromise exists: who rotates the token-signing keys, the sync account, app credentials and the krbtgt account, from clean devices (IR recovery; Playbook: Lateral movement).
