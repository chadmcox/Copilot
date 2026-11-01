# Rules

Every check below comes from Microsoft's [Microsoft Entra operations reference guide](https://learn.microsoft.com/entra/architecture/ops-guide-intro) and its four sections: [identity and access management](https://learn.microsoft.com/entra/architecture/ops-guide-iam), [authentication management](https://learn.microsoft.com/entra/architecture/ops-guide-auth), [governance](https://learn.microsoft.com/entra/architecture/ops-guide-govern) and [operations](https://learn.microsoft.com/entra/architecture/ops-guide-ops). The **Guide** column names the heading in the guide the check comes from. Put it in each finding's Reference, like "Ops guide: Authentication > Consent grants".

**Severities and thresholds are this repo's choices, not Microsoft's.** The guide says what to do; it doesn't rank it. Where the guide gives a number (sync errors older than 100 days, components six months behind, a 30-minute delta sync, two emergency access accounts), the rule uses it.

Thresholds: inactive after 90 days, sign-in log lookback 30 days, credential warning 30 days before expiry. The user can change them in the prompt.

Each finding has an **Area** (Identity and access, Authentication, Governance, Operations), an **Item** (the policy, app, role, setting or a count such as "12 guest accounts"), a **Topic** (the guide heading, such as Conditional Access or Consent grants), a **Severity** (High, Medium, Low, Info), a **Check** (what's wrong), a **Fix** and a **Reference**.

**Don't name people.** For users, guests and admins, report counts ("3 Global Administrators aren't registered for MFA"), not names or UPNs, unless the user asks. Apps, policies, groups and roles can be named.

**Microsoft apps.** Skip consent and credential checks for Microsoft's own service principals: those whose `appOwnerOrganizationId` is the same as the Microsoft Graph service principal's, or whose `publisherName` starts with "Microsoft". They aren't yours to fix.

**Licenses.** Read `subscribedSkus` once. A service plan named `AAD_PREMIUM` means Entra ID P1; `AAD_PREMIUM_P2` means P2; `Entra_Identity_Governance` (or `ENTRA_ID_GOVERNANCE`) means ID Governance. Where a rule says *P1* or *P2*, skip it (and say so in the notes) when the tenant doesn't have that plan, because the guide only recommends it with that license.

## Identity and access management

| Check | Severity | Topic | Fix | Guide |
| --- | --- | --- | --- | --- |
| Sync is on (`organization.onPremisesSyncEnabled` true) and `onPremisesLastSyncDateTime` is more than 24 hours ago | High | Synchronization | Sync has stopped. Check the Microsoft Entra Connect server, or promote the staging server | IAM > Sync failover or disaster recovery |
| Sync is on and the last sync is more than 1 hour ago (the default delta sync runs every 30 minutes) | Medium | Synchronization | Check why delta sync takes longer than 30 minutes; see the factors that affect Entra Connect performance | IAM > Microsoft Entra Connect delta sync cycle baseline |
| Users with an `onPremisesProvisioningErrors` entry older than 100 days (one finding with the count) | Medium | Synchronization | Fix or clean up the objects in error. Long-standing sync errors cause support incidents | IAM > Identify and resolve synchronization issues |
| Users with newer sync errors (one finding with the count) | Low | Synchronization | Fix them before they reach 100 days | IAM > Identify and resolve synchronization issues |
| Groups with `hasMembersWithLicenseErrors` true | Medium | Licensing | Find and fix the license assignment errors now (each group by name) | IAM > Group-based licensing |
| Licensed users with a license assigned directly (a `licenseAssignmentStates` entry with no `assignedByGroup`), one finding with the count | Medium | Licensing | Move to group-based licensing, with dynamic groups where the data is good | IAM > Group-based licensing |
| A dynamic group whose rule takes in every user (for example `user.objectId -ne null` or `user.accountEnabled -eq true`) with no `user.userType -eq "Member"` part | Medium | All users group | It includes guests. Add `user.userType -eq "Member"`, or check it's meant to include guests before you use it for apps, licenses or Conditional Access | IAM > Assignment of apps with "All users" group |

## Authentication management

| Check | Severity | Topic | Fix | Guide |
| --- | --- | --- | --- | --- |
| Security defaults are off and no enabled Conditional Access policy requires MFA (or an authentication strength) for all users | High | Strong credentials | Require MFA for everyone with Conditional Access (or turn on security defaults) | Auth > Strong credential management |
| Admins (`userRegistrationDetails` with `isAdmin` true) not registered for MFA, one finding with the count | High | Strong credentials | Every privileged account must have MFA. Register them now | Auth > Strong credential management |
| Admins with per-user MFA `enabled` or `enforced` (from `/users/{id}/authentication/requirements`) | Medium | Conditional Access | Use Conditional Access for MFA instead of per-user MFA, then turn per-user MFA off | Auth > Conditional Access implementation |
| The authentication methods policy `policyMigrationState` is `preMigration` or `migrationInProgress` | Medium | Password policies | Finish moving the legacy MFA and SSPR method settings to the authentication methods policy | Auth > Password policies |
| Microsoft Authenticator, FIDO2 (passkeys) and Windows Hello aren't offered: neither `MicrosoftAuthenticator` nor `Fido2` is `enabled` | Medium | Passwordless | Turn on passkeys (FIDO2) or Microsoft Authenticator so people can go passwordless | Auth > Windows Hello for Business |
| No admin is passwordless capable (`isPasswordlessCapable`), or under half are | Low | Passwordless | Start with admins: register passkeys or Windows Hello for Business | Auth > Windows Hello for Business |
| `Sms` or `Voice` is `enabled` | Low | Passwordless | Phase out phone methods for stronger ones (Authenticator, passkeys) | Auth > Strong credential management |
| No **Password Rule Settings** directory setting, or `EnableBannedPasswordCheck` is false | Low | Password protection | Add a custom banned password list (company names, products, places) | Auth > Enable self-service password reset and password protection |
| Sync is on and `EnableBannedPasswordCheckOnPremises` is false, or `BannedPasswordCheckOnPremisesMode` is `Audit` | Medium | Password protection | Deploy on-premises password protection and move it from Audit to Enforced | Auth > Enable self-service password reset and password protection |
| A verified domain's `passwordValidityPeriodInDays` isn't 2147483647 (passwords expire) | Low | Password policies | Microsoft's password guidance is not to force expiry; set passwords to never expire and rely on MFA, password protection and risk policies | Auth > Password policies |
| A domain's `authenticationType` is `Federated` | Medium | On-premises outage resiliency | Plan to move to cloud authentication; until then make sure password hash sync is on as a backup | Auth > On-premises outage authentication resiliency |
| An app registration has client secrets (`passwordCredentials`); one finding per app | Medium | Programmatic credentials | Ask the owner how the secret is stored. Use a certificate, managed identity or federated credential instead, or Key Vault if that isn't possible | Auth > Programmatic usage of credentials |
| A secret or certificate on an app expired, or expires within 30 days | Low | Programmatic credentials | Remove the expired one, or roll it before it expires | Auth > Programmatic usage of credentials |
| A non-Microsoft service principal has its own `passwordCredentials` | Medium | Programmatic credentials | Ask the owner what uses it, then remove it or replace it with a certificate | Auth > Programmatic usage of credentials |
| No named locations | Medium | Named locations | Define your corporate IP ranges as trusted named locations, to improve risk detection | Auth > Named locations |
| *P2:* no enabled Conditional Access policy uses `signInRiskLevels`, or none uses `userRiskLevels` (one finding each) | High | Risk-based access | Add sign-in risk and user risk policies (require MFA, and a secure password change for high user risk) | Auth > Risk-based access policies |
| *P2:* users at high risk (`riskyUsers` with `riskState` atRisk and `riskLevel` high), one finding with the count | High | Risk-based access | Investigate and remediate them, and send risk events to your SIEM | Auth > Key operational processes (triage risk events) |
| No enabled Conditional Access policy uses a device grant (`compliantDevice` or `domainJoinedDevice`) | Medium | Device trust | Require a compliant or hybrid-joined device for corporate apps | Auth > Device trust access policies |
| No enabled Conditional Access policy uses `approvedApplication` or `compliantApplication` | Low | Client application access | If people use mobile apps on personal devices, require app protection policies | Auth > Client application access policies |
| No enabled Conditional Access policy blocks legacy authentication (`clientAppTypes` exchangeActiveSync and other, with a block grant) | High | Legacy authentication | Block legacy authentication with Conditional Access, starting in report-only | Auth > Legacy authentication |
| *P1:* successful legacy authentication sign-ins in the last 30 days (`clientAppUsed` Exchange ActiveSync, IMAP4, POP3, Authenticated SMTP, Other clients, and similar); one finding with the count per client type | Medium | Legacy authentication | Move those people to modern clients, disable the protocol at the mailbox, then block it | Auth > Legacy authentication |
| An enabled policy targets All cloud apps with a block grant and excludes no users, groups or roles (skip policies that only target legacy `clientAppTypes`) | High | Conditional Access | Exclude your emergency access accounts, and narrow the policy; All apps with block risks locking everyone out | Auth > Conditional Access implementation |
| An enabled policy includes individual users (user IDs in `includeUsers`) | Medium | Conditional Access | Assign policies to groups, not people | Auth > Conditional Access implementation |
| An enabled policy excludes individual users (other than emergency access accounts) instead of a group | Low | Conditional Access | Use an exclusion group, and review it with an access review | Auth > Conditional Access implementation |
| More than 30 Conditional Access policies (enabled and report-only) | Low | Conditional Access | Consolidate into a small set of core policies that cover many apps | Auth > Conditional Access implementation |
| User consent includes `ManagePermissionGrantsForSelf.microsoft-user-default-legacy` (users can consent to any app) | High | Consent grants | Turn off user consent, or limit it to verified publishers and low-impact permissions, and turn on the admin consent workflow | Auth > Consent grants |
| User consent is allowed with Microsoft's low or recommended policy | Low | Consent grants | The guide says to remove self-service consent and govern it; at least keep the admin consent workflow on | Auth > Consent grants |
| The admin consent workflow (`adminConsentRequestPolicy.isEnabled`) is off | Medium | Consent grants | Turn it on so people can ask for apps they can't consent to | Auth > Consent grants |
| A non-Microsoft app has a delegated grant (`oauth2PermissionGrants`) for `Directory.AccessAsUser.All`, `user_impersonation`, `EWS.AccessAsUser.All` or `EAS.AccessAsUser.All` | High | Consent grants | Check the app is known and needed; remove the grant if not | Auth > Consent grants |
| A non-Microsoft app has a delegated grant for `Mail.Read`, `Mail.Read.Shared`, `Mail.ReadWrite` or `Mail.Send`, or any `*.ReadWrite*` scope | Medium | Consent grants | Check it's needed and the narrowest scope; remove grants that aren't | Auth > Consent grants |
| A non-Microsoft app has a high-privilege Microsoft Graph application permission (from the Graph service principal's `appRoleAssignedTo`): `Directory.ReadWrite.All`, `RoleManagement.ReadWrite.Directory`, `AppRoleAssignment.ReadWrite.All`, `Application.ReadWrite.All`, `Mail.ReadWrite`, `Mail.Send`, `Sites.FullControl.All`, `Files.ReadWrite.All`, `User.ReadWrite.All`, `Group.ReadWrite.All`, `Policy.ReadWrite.*` or `full_access_as_app` | High | Consent grants | Replace it with a narrower permission, or remove it. Review app permissions on a schedule | Auth > Consent grants |
| Users can register applications (`defaultUserRolePermissions.allowedToCreateApps` true) | Medium | User and group settings | Set it to No and have IAM register apps on request | Auth > User and group settings |
| Users can create security groups (`allowedToCreateSecurityGroups` true), or Microsoft 365 groups (`Group.Unified` setting `EnableGroupCreation` true with no `GroupCreationAllowedGroupId`) | Low | User and group settings | Turn it off until you have a self-service group plan, or limit it to a group | Auth > User and group settings |
| Guest invitations: `allowInvitesFrom` is `everyone` | Medium | User and group settings | Limit invitations to admins and the Guest Inviter role, or use entitlement management | Auth > User and group settings |
| `allowInvitesFrom` is `adminsGuestInvitersAndAllMembers` | Low | User and group settings | Decide whether members should invite guests; use entitlement management for controlled external access | Auth > User and group settings |

## Governance

Privileged roles are the role definitions with `isPrivileged` true. Microsoft marks some reader roles as privileged too (Global Reader, Security Reader); they count. **Emergency access accounts**: ask the user which accounts they are. If they don't say, treat cloud-only users with a permanent Global Administrator assignment that are excluded from at least one MFA policy as the likely ones, and say that's a guess.

| Check | Severity | Topic | Fix | Guide |
| --- | --- | --- | --- | --- |
| Fewer than two cloud-only (`onPremisesSyncEnabled` not true) user accounts with a permanent Global Administrator assignment | High | Emergency access accounts | Create two cloud-only emergency access accounts, permanently assigned Global Administrator, following Microsoft's emergency access guidance | Governance > Emergency access accounts |
| No permanent Global Administrator is excluded from any Conditional Access policy that requires MFA, and no emergency access accounts were named | Medium | Emergency access accounts | Exclude the emergency access accounts from the policies that could lock them out (protect them with phishing-resistant methods instead) | Auth > Conditional Access implementation (break glass) |
| Five or more Global Administrators (users, active and eligible) | Medium | Privileged account usage | Assign less-privileged roles; keep Global Administrator for the few who need it | Governance > Privileged account usage |
| *P2:* users with a permanent active assignment (`roleAssignmentSchedules`, `assignmentType` Assigned, expiration `noExpiration`) to a privileged role, not counting the emergency access accounts; one finding per role with the count | High | Privileged account usage | Make them eligible in PIM, so the role is activated just in time | Governance > Privileged account usage |
| *P2:* no eligible role assignments at all (`roleEligibilitySchedules` is empty) | High | Privileged account usage | Deploy Privileged Identity Management for Entra roles | Governance > Privileged account usage |
| A user synced from on-premises (`onPremisesSyncEnabled` true) holds a privileged role; one finding with the count | High | Privileged account usage | Use separate cloud-only admin accounts | Governance > Privileged account usage |
| A user who holds a privileged role also has a license with Exchange Online (a day-to-day account); one finding with the count | Medium | Privileged account usage | Use a separate account for admin work, with no mailbox | Governance > Privileged account usage |
| A service principal holds a privileged role (one finding per app and role) | Medium | Privileged account usage | Check it needs the role, and assign the least-privileged one | Governance > Privileged account usage |
| *P2:* activating Global Administrator or Privileged Role Administrator in PIM doesn't require MFA (`Enablement_EndUser_Assignment` lacks `MultiFactorAuthentication` and the authentication context rule is off) | High | Privileged account usage | Require MFA (or an authentication context) on activation | Governance > Privileged account usage (security gates) |
| *P2:* activating those roles needs no approval (`Approval_EndUser_Assignment` `isApprovalRequired` false) | Medium | Privileged account usage | Require approval for the most privileged roles | Governance > Privileged account usage (security gates) |
| *P2:* activation lasts more than 8 hours (`Expiration_EndUser_Assignment` `maximumDuration`) | Low | Privileged account usage | Shorten it (Microsoft's default is 8 hours) | Governance > Privileged account usage |
| *P2 or ID Governance:* no access review definitions | Medium | Access reviews | Set up recurring access reviews for apps, groups and roles | Governance > Access reviews to applications |
| *P2:* no access review covers privileged roles (scope on `roleManagement` or PIM) | Medium | Access reviews | Review privileged role assignments regularly, automated through PIM | Governance > Privileged account usage |
| Guests exist, and no access review covers guests (`userType eq 'Guest'` in the scope) | Medium | Access reviews | Set up a recurring review of guest access | Governance > Access reviews to external identities |
| Guests who haven't signed in for 90 days, or never signed in and were created more than 90 days ago (one finding with the count) | Low | Access reviews | Review and remove them; an access review can do it automatically | Governance > Access reviews to external identities |
| A group excluded from an enabled Conditional Access policy isn't covered by any access review | Low | Access reviews | Review exception groups regularly so people don't stay outside the policy | Auth > Conditional Access implementation |
| *ID Governance or P2:* no access packages in entitlement management | Low | Entitlement management | Bundle app and group access into access packages with approval and expiry | Governance > Entitlement management |

## Operations

| Check | Severity | Topic | Fix | Guide |
| --- | --- | --- | --- | --- |
| An active Microsoft Entra recommendation (`directory/recommendations`, `status` active) with priority high | High | Identity Secure Score | Follow its action steps; it's on Microsoft's list for this tenant | Ops > Identity secure score |
| An active recommendation with priority medium | Medium | Identity Secure Score | Follow its action steps | Ops > Identity secure score |
| An active recommendation with priority low | Low | Identity Secure Score | Plan it | Ops > Identity secure score |
| An active Microsoft Entra Health alert (`reports/healthMonitoring/alerts`, `state` active) | High | Monitoring | Investigate it now: high-severity alerts first | Ops > Microsoft Entra Connect Health alert baseline |
| Fewer than two technical notification addresses (`organization.technicalNotificationMails`) | Medium | Notifications | Send notifications to a distribution list or shared mailbox the team watches, with at least two recipients. Don't list the addresses in the report | Ops > Notifications |

Use the recommendation's `displayName` as the item, its `featureAreas` as the topic, and its first action step's URL in the fix. Recommendations overlap some checks above (for example risk policies). Keep both, and say in the notes that the Operations area repeats Microsoft's own list.

## Scoring

Each check is an item. A check that passes scores 100. A check that raises findings starts at 100 and loses 25 for each High, 10 for each Medium and 3 for each Low, never below 0. An area's score is the average of its checks. Checks that couldn't run (403, no license, no data) aren't counted; list them in the notes. Rating: Green 80+, Amber 50-79, Red under 50.

## Well-protected admins funnel

Count the **users** with an active or eligible privileged role.

1. Privileged users: all of them.
2. MFA registered: registered for MFA (`userRegistrationDetails`).
3. Cloud-only: and not synced from on-premises.
4. Just in time: and holding no permanent active privileged assignment (emergency access accounts count as passing).
5. Passwordless capable: and `isPasswordlessCapable` true.

Well protected % = step 5 / step 1.

## Manual checks (not readable through the Enterprise MCP)

The guide has many process and on-premises checks that no API answers. List them all, grouped by area. If the browser is available, read the admin center pages and say what you see; never change a setting.

**Assign owners to key tasks** (every section of the guide starts with this): confirm each task has an owner. IAM: license decisions and assignment, license errors, provisioning identities to apps. Authentication: SSO lifecycle, Conditional Access design, archiving sign-in and risk logs to a SIEM, triaging security reports and risk events. Governance: archiving audit logs, reviewing access to apps, external identities and privileged roles, security gates for activating roles, reviewing consent grants, designing access packages, reviewing CA exceptions. Operations: Identity Secure Score, Entra Connect servers, IdFix reports, Connect Health alerts, hybrid agent logs.

**Identity and access management**
- Microsoft Entra Connect is less than six months behind the latest version, with automatic upgrade on (Entra admin center > Entra Connect > Connect Sync).
- A staging-mode Connect server exists and matches production.
- The source anchor is `ms-DS-ConsistencyGuid`, custom sync rules have precedence under 100 and are simple, and sync is scoped by OU or a cloudFiltered attribute (not group filtering).
- Password hash sync is on (Entra admin center > Entra Connect > Connect Sync), even if you federate.
- Apps are provisioned with automatic user provisioning, not CSV files or manual steps (Enterprise apps > each app > Provisioning).

**Authentication management**
- Self-service password reset is on for all users (Entra admin center > Protection > Password reset > Properties).
- Seamless SSO is on if you use password hash sync or pass-through authentication.
- Smart lockout (Protection > Authentication methods > Password protection) and AD FS extranet smart lockout are set.
- Apps use SSO with Entra ID, not local accounts or another identity provider; AD FS apps are migrated (Enterprise apps > Usage & insights > AD FS application activity).
- **Restrict access to Microsoft Entra admin center** is Yes (Entra ID > Users > User settings).
- Sign-in, audit and risk logs are sent to a SIEM or Log Analytics (Entra ID > Monitoring & health > Diagnostic settings) and used in incident response.

**Governance**
- A testing approach exists for configuration changes (staged rollout, report-only policies, staging-mode sync, a test tenant for branding).
- The Azure EA portal (or Microsoft Customer Agreement billing) allows only Entra accounts, with delegated roles in place.

**Operations**
- Microsoft Entra Connect Health is installed for sync and AD FS, with email notifications on.
- At least two pass-through authentication agents, and at least two private network connectors in each production connector group, all on automatic updates.
- Hybrid agent logs (application proxy, pass-through authentication, password writeback, password protection, NPS extension) are archived and monitored.
- Message Center notifications go to more than one person or a shared mailbox.
- AD FS has extranet smart lockout on and unused WS-Trust endpoints off.
- Servers running Entra Connect, AD FS and their SQL are protected like domain controllers (Tier 0).
- Identity Secure Score is reviewed on a schedule, with owners for its improvement actions (Entra ID > Overview > Recommendations).
