# Graph validation

## Rule: v1.0 vs beta
- Fetch the resource page with `?view=graph-rest-1.0` and `?view=graph-rest-beta`.
- Report: **exists in v1.0** / **beta only** / **not found**.
- Beta APIs are subject to change and not supported for production use (Graph docs). A beta-only property is "preview capability — not production-supported via API".
- If the beta URL redirects to v1.0 (observed for several CA pages), try in order: (a) fetch the child type's beta page directly (e.g. `securesigninsessioncontrol?view=graph-rest-beta`), (b) `web_search` for the resource name plus "graph-rest-beta". Only then say the beta page could not be checked. Evidence from a search snippet only = Partially verified.
- Enums marked "evolvable" may need the `Prefer: include-unknown-enum-members` header to return newer members.

## Key resource types (fetch, do not recall)
| Area | Resource type | Learn URL pattern |
|---|---|---|
| CA policy | conditionalAccessPolicy | https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy |
| CA conditions | conditionalAccessConditionSet | .../resources/conditionalaccessconditionset |
| CA auth flows | conditionalAccessAuthenticationFlows | .../resources/conditionalaccessauthenticationflows |
| CA grant | conditionalAccessGrantControls | .../resources/conditionalaccessgrantcontrols |
| CA session | conditionalAccessSessionControls | .../resources/conditionalaccesssessioncontrols |
| Cross-tenant partner | crossTenantAccessPolicyConfigurationPartner | .../resources/crosstenantaccesspolicyconfigurationpartner |
| Cross-tenant default | crossTenantAccessPolicyConfigurationDefault | .../resources/crosstenantaccesspolicyconfigurationdefault |
| Cross-tenant inbound trust | crossTenantAccessPolicyInboundTrust | .../resources/crosstenantaccesspolicyinboundtrust |
| Cross-tenant sync (partner) | crossTenantIdentitySyncPolicyPartner | .../resources/crosstenantidentitysyncpolicypartner |
| Multitenant organization | multiTenantOrganization | .../resources/multitenantorganization |
| CA guest/external user types | conditionalAccessGuestsOrExternalUsers | .../resources/conditionalaccessguestsorexternalusers |
| Token protection (beta) | secureSignInSessionControl | .../resources/securesigninsessioncontrol |
| Auth methods | authenticationMethodsPolicy | .../resources/authenticationmethodspolicy |
| Auth strengths | authenticationStrengthPolicy | .../resources/authenticationstrengthpolicy |
| Risky users | riskyUser | .../resources/riskyuser |
| PIM role settings | unifiedRoleManagementPolicy | .../resources/unifiedrolemanagementpolicy |

Append `?view=graph-rest-1.0` or `?view=graph-rest-beta`.

## Fetched at authoring (Nov 2026) — re-fetch before citing
- **conditionalAccessConditionSet (v1.0)** has `authenticationFlows` (conditionalAccessAuthenticationFlows), `clientAppTypes`, `signInRiskLevels`, `userRiskLevels`, `servicePrincipalRiskLevels`, `insiderRiskLevels`, `clientApplications`, `devices`, `locations`, `platforms`, `users`, `applications`. Page last updated 12/02/2025.
- **conditionalAccessAuthenticationFlows (v1.0)** `transferMethods` values: `none, deviceCodeFlow, authenticationTransfer, unknownFutureValue`. Page last updated 12/03/2024.
- **conditionalAccessGrantControls (v1.0)** `builtInControls` values: `block, mfa, compliantDevice, domainJoinedDevice, approvedApplication, compliantApplication, passwordChange, unknownFutureValue, riskRemediation` (riskRemediation needs the `Prefer: include-unknown-enum-members` header). `riskRemediation` must be paired with `authenticationStrength` via AND, and used only in a policy with `userRiskLevels`. Page last updated 04/28/2026.
- **conditionalAccessSessionControls (v1.0)** properties: `applicationEnforcedRestrictions, cloudAppSecurity, disableResilienceDefaults, persistentBrowser, signInFrequency`. No token-protection property in v1.0. The beta URL redirected to v1.0 at authoring, so beta was **not** verified (verify at runtime for any token-protection / secure sign-in session property).

## Portal setting → Graph property (verify each at runtime)
| Portal setting | Graph resource.property |
|---|---|
| CA "Authentication flows" condition (device code / authentication transfer) | conditionalAccessPolicy.conditions.authenticationFlows.transferMethods |
| CA "Client apps" (legacy auth) | conditions.clientAppTypes |
| CA "User risk" / "Sign-in risk" | conditions.userRiskLevels / signInRiskLevels |
| CA "Require authentication strength" | grantControls.authenticationStrength (a relationship to authenticationStrengthPolicy, not a property; not shown in the JSON representation) |
| CA "Require risk remediation" | grantControls.builtInControls = riskRemediation |
| CA "Sign-in frequency" | sessionControls.signInFrequency |
| CA guest / external user targeting | conditions.users.includeGuestsOrExternalUsers (conditionalAccessGuestsOrExternalUsers) — verify at runtime |
| CA token protection session control | sessionControls.secureSignInSession — reported beta only by validation run (Nov 2026); verify at runtime |
| Cross-tenant inbound MFA / device trust | crossTenantAccessPolicyConfigurationPartner.inboundTrust — verify at runtime |

## Read-only GET examples (user runs; needs Policy.Read.All or equivalent)
```
GET https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies
GET https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/default
GET https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners
GET https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy
GET https://graph.microsoft.com/v1.0/identity/conditionalAccess/authenticationStrength/policies
```
Verify the endpoint path and the least-privileged permission on the API's Learn page before sharing.

```powershell
# Read-only. Microsoft Graph PowerShell SDK.
Connect-MgGraph -Scopes "Policy.Read.All"
Get-MgIdentityConditionalAccessPolicy -All |
  Select-Object DisplayName, State, @{n='TransferMethods';e={$_.Conditions.AuthenticationFlows.TransferMethods}}
```
No live tenant access? Say so and hand the user the query.
