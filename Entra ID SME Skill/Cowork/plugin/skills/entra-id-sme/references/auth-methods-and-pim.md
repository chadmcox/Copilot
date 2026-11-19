# Authentication methods and PIM — pointers

Fetched through Microsoft Learn search on Nov 19, 2026 (summaries below). Re-fetch before citing.

## Authentication methods policy [MS Learn]
- Overview and legacy policy migration: https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage#migration-from-legacy-policies
  - Page states: deprecation announced March 2023; **beginning September 30, 2025, authentication methods can't be managed in the legacy MFA and SSPR policies**.
  - A user enabled for a method in *any* policy can register and use it; to block a method, disable it in all policies.
- Migration guide (wizard + manual; reversible; tenant settings only, not per-user settings): https://learn.microsoft.com/entra/identity/authentication/how-to-authentication-methods-manage
- Legacy MFA service settings page (trusted IPs, verification options): https://learn.microsoft.com/entra/identity/authentication/howto-mfa-mfasettings

When asked about "MFA service settings" or "SSPR authentication methods" in 2025+, answer from the Authentication methods policy and say the legacy policy no longer manages methods.

Author scripts [Author repo – community, not official Microsoft guidance]: `Authentication Methods/` — Get-AuthMethodsPolicy, Get-PerUserMfaState (find leftover per-user MFA), Get-MfaRegistration, Get-StaleAuthMethods (read-only); WRITE scripts listed in kql-and-scripts.md.

## Authentication strengths [MS Learn]
- https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths
  - Built-in: Multifactor authentication strength, Passwordless MFA strength, Phishing-resistant MFA strength.
  - Can't combine **Require multifactor authentication** and **Require authentication strength** in one policy.
  - Email one-time passcode (guest) isn't supported in combinations.
- Admins phishing-resistant: https://learn.microsoft.com/entra/identity/conditional-access/policy-admin-phish-resistant-mfa
  - CA isn't enforced for administrative-unit-scoped or custom roles when targeting directory roles.
  - External authentication methods are incompatible with authentication strengths; use Require MFA instead.
- External users: https://learn.microsoft.com/entra/identity/conditional-access/policy-guests-mfa-strength — authentication strength applies only to external users who authenticate with Entra ID; for email OTP, SAML/WS-Fed, Google, MSA use the MFA grant control.

## Privileged Identity Management [MS Learn]
- Role settings: https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-how-to-change-default-settings
  - Needs at least Privileged Role Administrator to change role settings. Settings are per role.
  - **Lockout warning on the page:** tenant lockout if all Privileged Role Admins/Global Admins are eligible (none active), approval is required, and no approvers are configured. Mitigate with emergency access accounts and named approvers.
  - Activation can require MFA or a CA authentication context.
- Approval workflow: https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-approval-workflow — approvers have 24 hours (not configurable); approvers can't approve their own requests; service principals can't approve.
- Deployment plan: https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan
- Zero Trust "secure the identity control plane" (remove permanent roles, group-based eligible assignments): https://learn.microsoft.com/security/zero-trust/adopt/implement-privileged-access-identity

Author scripts [Author repo – community, not official Microsoft guidance]: `Roles and PIM/` — Get-PrivilegedRoleMembers, Export-PimSettings, Get-StaleRoleAssignments, Get-PrincipalsThatCanElevatePrivileges (read-only). Author KQL: "risk sign-ins during PIM activation window" (Identity Protection Queries).
