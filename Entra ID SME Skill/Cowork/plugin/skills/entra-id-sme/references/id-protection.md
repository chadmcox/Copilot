# ID Protection — pointers

## Fetched at authoring (Nov 2026; page "Last updated 11/17/2026") — re-fetch before citing
Source [MS Learn]: https://learn.microsoft.com/en-us/entra/id-protection/howto-identity-protection-configure-risk-policies
- The page states the legacy risk policies configured in ID Protection "will be retired on October 1, 2026". Migrate to Conditional Access: create equivalent user-risk and sign-in-risk CA policies in report-only (`enabledForReportingButNotEnforced`), with break-glass exclusions, confirm, turn On, then set the legacy policies' Enforce policy to Disabled.
- Do not combine sign-in risk and user risk conditions in the same CA policy.
- License: Microsoft Entra ID P2 or Microsoft Entra Suite for full ID Protection features.
- Microsoft recommendation: user risk High → Require risk remediation (auto-adds Require authentication strength and Sign-in frequency Every time); sign-in risk Medium+High → Require authentication strength (MFA) + Sign-in frequency Every time.
- Users must be MFA-registered before remediation; hybrid users need password writeback.
- Support request path for migration help is documented on the page.
Also check the Microsoft Entra Blog [MS Entra Blog] (https://techcommunity.microsoft.com/category/microsoft-security/blog/microsoft-entra-blog) for a newer retirement or deprecation post; cite its publication date beside the Learn page date. When the current date is past the retirement date, say what the page says and tell the user to check the page for post-retirement behavior; do not guess what happens to unmigrated policies.

## Graph [Graph API] (fetched at authoring)
- `riskRemediation` in conditionalAccessGrantControls.builtInControls; must be ANDed with authenticationStrength; policy must contain userRiskLevels: https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessgrantcontrols?view=graph-rest-1.0

## Verify at runtime [MS Learn]
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-risk-based-user (old howto-…-risk-user URL redirects here)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-risk (current page appears to be https://learn.microsoft.com/entra/identity/conditional-access/policy-risk-based-sign-in — verify)
- https://learn.microsoft.com/entra/id-protection/workbook-risk-based-policy-impact
- https://learn.microsoft.com/en-us/entra/id-protection/how-to-deploy-identity-protection
- https://learn.microsoft.com/en-us/entra/id-protection/
- federatedIdpMfaBehavior: https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-migrate-mfa-server-to-mfa-with-federation#set-federatedidpmfabehavior-to-enforcemfabyfederatedidp

## Author queries [Author repo – community, not official Microsoft guidance]
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Log%20Analytics/Identity%20Protection%20Queries
- https://github.com/chadmcox/Azure_Active_Directory/tree/master/Log%20Analytics/RBCA%20Impact
- Author scripts: https://github.com/chadmcox/Azure_Active_Directory/tree/master/Identity%20Protection — Get-RiskyUsers, Get-RiskDetections, Get-RiskyServicePrincipals (read-only), Dismiss-RiskyUsers (**WRITE**).
- Author practitioner guidance (pre-enforcement risk cleanup, settings, risk-based CA set, Zscaler false positives): **author-wiki-guidance.md** §1 and §5. Note the flagged conflicts with current Learn grant controls.
