# KQL and scripts — pointers

## Rules
- PowerShell: Microsoft Graph PowerShell SDK only. Never AzureAD or MSOnline modules (retired — see gotchas.md).
- Read-only by default. Any change script follows **Change safety** in SKILL.md: change list, backup first, explicit user confirmation before the runnable script, label **WRITE** (or **DELETES OBJECTS**), `-WhatIf`/`-Confirm`, user runs it.
- KQL: confirm table and column names against the Defender XDR advanced hunting schema or Log Analytics (SigninLogs, AADNonInteractiveUserSignInLogs, AADUserRiskEvents, AuditLogs) docs before sharing.
- Strip tenant IDs, UPNs and secrets from anything shared outside the tenant's admins.
- No live tenant access: deliver the query/script for the user to run and say so.

## Author repos [Author repo – community, not official Microsoft guidance]
Indexed Nov 19, 2026 from a clone of `chadmcox/Azure_Active_Directory` (last commit Nov 1, 2026). File names can change: open the folder at runtime and cite the specific file used. Base: https://github.com/chadmcox/Azure_Active_Directory/tree/master/

Index findings (at indexing time): 127 of 143 scripts outside `_Archive/` connect with `Connect-MgGraph`; none outside `_Archive/` use AzureAD or MSOnline cmdlets. **Never point users to `_Archive/`.** Every WRITE script listed below declares `SupportsShouldProcess` (`-WhatIf` / `-Confirm`) **except Add-HardwareOathTokens and Enable-HardwareOathToken** — for those two, tell the user there is no dry-run switch and to test on one object first.

### KQL — `Log Analytics/Identity Protection Queries` (read-only)
| Area | Files (prefix = source table) |
|---|---|
| Password spray | `AADUserRiskEvents - List of users suspected of password spray…`, `AADUserRiskEvents - Get Identity Protection passwordSpray`, `SigninLogs - List of users suspected of password spray from SigninLogs` |
| Detection drill-down | `AADUserRiskEvents - Get Identity Protection` anonymizedIPAddress / maliciousIPAddress / mcasImpossibleTravel / unfamiliarFeatures details / unlikelyTravel related IPs; unlikelyTravel daily summary and IP stats |
| RBCA gaps (high risk not blocked / not prompted / not remediated) | `SigninLogs - List high risk …` (6 files), `SigninLogs - List low,medium,high risk …` (3 files) |
| Admin exposure | `…risk sign-ins during PIM activation window`, `…risk sign-ins into Microsoft Portals with no risk based conditional access policy` |
| Remediation tracking | `…users that have successfully remediated risk`, `…risky users prompted to change password`, `Review MFA that is being used for signin risk remediation`, `Summary of UserRisk and SignInRisk` |
| Admin actions | `AuditLogs - Get list of users who have been dismissed`, `AuditLogs - Get users marked as safe` |
| Other | `Signinlogs - User potential sign-in from nation state ip`, workbook `Entra Id Protect Risk Based CA Policies.workbook`, folder `TroubleShooting` |

### KQL — `Log Analytics/RBCA Impact` (read-only, run before enabling risk-based CA)
Device compliance with sign-in / user risk · Microsoft admin portal sign-ins with sign-in / user risk · Privileged user with sign-in / user risk · Users with existing user risk that needs remediation · Users with risk not affected by RBCA · Sign-in risk during Intune enrollment / security-info registration / My Sign-ins · Users impacted by legacy ID Protection policy · Sign-in risk redirected to / remediated by external MFA provider · Sign-in risk users who might not have MFA registered · User risk blocked because SSPR not registered · Risk-based policies not using sign-in frequency Every time · Users using report suspicious activity.

### KQL — `Log Analytics/` root (used by the author CA catalog, author-wiki-guidance.md)
`query-MFAPercentageperapp.kql`, `query-noMFAAzureManagement.kql`, `query-AIPHighRiskAllCloudApps.kql`, `query-AIPRiskAzureManagement.kql`, `query-AIPRiskyGuest.kql`, `query-GuestAccessingAzureManagement.kql`, `query-SigninsfromKnownTorExitNodes.kql`. Legacy: `find-msolusage.kql` (MSOnline is retired — historical use only).

### Scripts — read-only reports
| Folder | Scripts |
|---|---|
| Conditional Access Policy | Backup-CAPolicies, Compare-CABaseline, Export-CAPoliciesToCsv, Get-CAExclusions, Get-CAPolicyReport, Get-StaleCAObjects |
| Guest | Get-GuestReport, Get-GuestAccess, Get-PendingGuests, Get-StaleGuests, Get-ViralGuests |
| Identity Protection | Get-RiskDetections, Get-RiskyUsers, Get-RiskyServicePrincipals |
| Authentication Methods | Get-AuthMethodsPolicy, Get-MfaRegistration, Get-PerUserMfaState, Get-UserAuthMethods, Get-StaleAuthMethods, Get-GuestMfaRegistration, Get-HybridUserMfaRegistration, Get-WindowsHelloRegistration, Get-PhoneSignInUsers, Get-UserPhoneMethods, Get-AuthenticatorAppDetails, Get-UnassignedHardwareTokens |
| Roles and PIM | Get-PrivilegedRoleMembers, Get-RoleMembers, Get-StaleRoleAssignments, Export-PimSettings, Get-RoleChanges, Get-ChangesByAdmins, Get-ChangesToAdmins, Get-CustomRoles, Get-AdminUnits, Get-RoleMemberAppliedPolicies, Get-PrincipalsThatCanChangeCredentials, Get-PrincipalsThatCanChangeGroupMembership, Get-PrincipalsThatCanElevatePrivileges, Get-AdminIdsForKql |
| Agent ID | Get-AgentIdentities, Get-StaleAgentIdentities |

### Scripts — WRITE (tenant changes; follow Change safety)
| Script | Label | Graph scopes requested (from script, at indexing) | Run first |
|---|---|---|---|
| Conditional Access Policy/Import-RecommendedCAPolicies | WRITE | Policy.Read.All, Policy.ReadWrite.ConditionalAccess, Application.Read.All | Backup-CAPolicies |
| Conditional Access Policy/Add-BreakGlassExclusions | WRITE | Policy.Read.All, Policy.ReadWrite.ConditionalAccess, User.Read.All | Backup-CAPolicies, Get-CAExclusions |
| Conditional Access Policy/Add-ExclusionGroups | WRITE | Policy.Read.All, Policy.ReadWrite.ConditionalAccess, Group.ReadWrite.All, … | Backup-CAPolicies |
| Conditional Access Policy/New-TorNamedLocations | WRITE | Policy.Read.All, Policy.ReadWrite.ConditionalAccess | Backup-CAPolicies |
| Conditional Access Policy/Remove-StaleCAObjects | WRITE | Policy.ReadWrite.ConditionalAccess, … | Get-StaleCAObjects, Backup-CAPolicies |
| Guest/Remove-StaleGuests | DELETES OBJECTS | User.ReadWrite.All, AuditLog.Read.All | Get-StaleGuests (reviewed) |
| Guest/Remove-PendingGuests | DELETES OBJECTS | User.ReadWrite.All, AuditLog.Read.All | Get-PendingGuests (reviewed) |
| Guest/Reset-GuestRedemption | WRITE | User.Invite.All, User.ReadWrite.All | Get-GuestReport |
| Guest/Add-GuestSponsors | WRITE | User.ReadWrite.All, AuditLog.Read.All | Get-GuestReport |
| Identity Protection/Dismiss-RiskyUsers | WRITE | IdentityRiskyUser.ReadWrite.All | Get-RiskyUsers (reviewed) |
| Authentication Methods/Remove-StaleAuthMethods | DELETES OBJECTS | UserAuthenticationMethod.ReadWrite.All, AuditLog.Read.All, … | Get-StaleAuthMethods (reviewed) |
| Authentication Methods/Remove-HardwareOathToken | DELETES OBJECTS | UserAuthenticationMethod.ReadWrite.All, Policy.ReadWrite.AuthenticationMethod, User.Read.All | Get-UserAuthMethods |
| Authentication Methods/Remove-UnassignedHardwareTokens | DELETES OBJECTS | Policy.ReadWrite.AuthenticationMethod | Get-UnassignedHardwareTokens (reviewed) |
| Authentication Methods/Add-HardwareOathTokens, Enable-HardwareOathToken | WRITE (no `-WhatIf`) | Policy.ReadWrite.AuthenticationMethod, UserAuthenticationMethod.ReadWrite.All, User.Read.All | Get-AuthMethodsPolicy |
| Authentication Methods/New-TemporaryAccessPass | WRITE (creates a credential) | UserAuthenticationMethod.ReadWrite.All | — |
| Roles and PIM/Remove-StaleRoleAssignments | DELETES OBJECTS (role assignments) | RoleManagement.ReadWrite.Directory, … | Get-StaleRoleAssignments (reviewed) |
| Roles and PIM/Add-GroupsToRoles | WRITE | Group.ReadWrite.All, RoleManagement.ReadWrite.Directory | Get-RoleMembers |
| Agent ID/Disable-StaleAgentIdentities | WRITE | AgentIdentity.EnableDisable.All, AgentIdentity.Read.All, … | Get-StaleAgentIdentities (reviewed) |

Scopes are what the script requests, not a least-privilege verdict. Verify least-privilege permissions per API on the Graph reference at runtime.

### Other author repo
- Defender XDR queries: https://github.com/chadmcox/Sentinel-and-Defender-Queries/tree/main/Defender (not indexed — open at runtime).

## Microsoft
- Risk-based policy impact workbook [MS Learn]: https://learn.microsoft.com/entra/id-protection/workbook-risk-based-policy-impact
