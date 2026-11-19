# Multitenant and guest — pointers

## Topology decision (structure; cite each row from the pages below)
| Option | Fits when | Verify at |
|---|---|---|
| B2B collaboration (guests) | Ad hoc / partner access | https://learn.microsoft.com/entra/external-id/cross-tenant-access-overview |
| B2B direct connect | Teams shared channels without guest objects | cross-tenant access overview (above) |
| Cross-tenant synchronization | Same organization, many users need member-like access | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview |
| Multitenant organization (MTO) | Subsidiaries sharing M365 apps such as Teams | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview ; comparison: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview |

These options often combine (e.g. MTO with cross-tenant sync for B2B members, plus B2B direct connect for Teams shared channels).

Configure cross-tenant sync (incl. cross-cloud): https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure
Governance: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-governance
Cross-tenant sign-in activity script: https://learn.microsoft.com/entra/external-id/cross-tenant-access-overview#cross-tenant-sign-in-activity-powershell-script

## Trust settings
Inbound trust of partner MFA / compliant device / hybrid joined device claims → crossTenantAccessPolicyConfigurationPartner / Default (Graph). Verify property names at runtime (graph-validation.md).

## Guest CA and lifecycle
- CISA SCuBA defines resource vs home tenant terms for guests [CISA]: https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md
- Guest targeting in CA: verify conditionalAccessUsers guest/external user properties at runtime.
- Token protection for guests: check https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection and the Windows deployment guide (external-user limits) https://learn.microsoft.com/en-us/entra/identity/conditional-access/deployment-guide-token-protection-windows , plus Graph beta secureSignInSessionControl. Verify at runtime.

## Author scripts [Author repo – community, not official Microsoft guidance]
https://github.com/chadmcox/Azure_Active_Directory/tree/master/Guest — Get-GuestReport, Get-StaleGuests, Get-ViralGuests (read-only reports), Remove-StaleGuests (**DELETES OBJECTS**).

Guest cleanup order: 1) run Get-StaleGuests and review the report; 2) back up / export the list; 3) confirm the recovery option (soft-delete window and restore steps: verify at runtime on Microsoft Learn); 4) only then, with explicit user confirmation, give Remove-StaleGuests with `-WhatIf` first. Follow **Change safety** in SKILL.md.
