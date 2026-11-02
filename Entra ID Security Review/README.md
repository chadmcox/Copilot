# Entra ID Security Review

Updated Nov 2, 2026

A read-only security review of your Microsoft Entra tenant against the attacks that actually hit Entra, with a score per area, the attack each finding helps stop, and a fix for every finding. It combines four kinds of guidance:

- **CISA SCuBA** *Secure Configuration Baseline for Microsoft Entra ID*, including the policies required by BOD 25-01.
- **CIS** *Microsoft 365 Foundations Benchmark v7.0.0*, the Entra sections.
- The community **[Attack and Defense Playbook for Microsoft Entra](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense)**: password spray, consent grant, service principals, Entra Connect sync and application-based authentication, PRT replay, adversary-in-the-middle, agent identities, and lateral movement from a fallen Active Directory.
- **Incident guidance from Microsoft, NSA and Mandiant**: DEV-0537 (Lapsus$), Solorigate identity IOCs, NSA's *Detecting Abuse of Authentication Mechanisms*, recovery from systemic identity compromise, illicit consent grants, protecting Microsoft 365 from on-premises attacks, the keyCredential disclosure (CVE-2021-42306), resilient access controls, the Entra security operations guide, and Mandiant's APT29 hardening paper.

A skill reads the tenant live through the **Microsoft MCP Server for Enterprise**, so there's no script to run: ask **Copilot Cowork** or **GitHub Copilot** in VS Code.

It complements the [Entra ID Operations Report](../Entra%20ID%20Operations%20Report/README.md). That one checks day-to-day operations against Microsoft's operations guide; this one checks attack paths against CISA, CIS and incident guidance. Some checks appear in both (legacy authentication, consent, PIM); run both if you can.

## Run it

| Way | How |
| --- | --- |
| **Copilot Cowork** (recommended) | Set up the plugin once, activate the reader group in PIM, paste the prompt. See **[Cowork/readme.md](Cowork/readme.md)** |
| **GitHub Copilot** (VS Code) | Install the skill with one script, add the Enterprise MCP server, then ask. See **[GitHub Copilot/readme.md](GitHub%20Copilot/readme.md)** |

Both use the same skill and give the same HTML report from the same template: a score dial, a card per area, the CISA BOD 25-01 count, the phishing-resistant admins funnel, findings you can filter by severity, area, attack or source (search "MS.AAD" or "5.2.2"), CSV export, print, and the manual checklist.

The Enterprise MCP server is [global cloud only](https://learn.microsoft.com/graph/mcp-server/overview), so this review doesn't run in GCC High or DoD.

## What it checks

Eight areas, about 110 checks. Every finding names the attack it helps stop and its sources (CISA policy ID, CIS number, Playbook chapter or article). The full rule list is in [rules.md](Cowork/plugin/skills/entra-id-security-review/references/rules.md), and the source list with links and the CISA and CIS coverage tables is in [guidance.md](Cowork/plugin/skills/entra-id-security-review/references/guidance.md).

| Area | Checks |
| --- | --- |
| **Privileged access** | Two to eight Global Administrators (CISA) and two to four (CIS). Finer-grained roles. Synced admins and cloud admins with an ImmutableID. Permanent highly privileged assignments, PIM approval, MFA on activation and alert recipients. Phishing-resistant MFA for admins and registered passkeys. Admin sessions. Admins with mailboxes. Emergency access accounts. Service principals in privileged roles, owners of privileged apps and role-assignable groups, guests with roles |
| **Authentication** | MFA and phishing-resistant MFA for everyone. Methods migration. SMS, voice and email OTP. Authenticator context, Authenticator Lite, system-preferred MFA, suspicious activity reports. FIDO2 attestation, TAP lifetime. Banned passwords, on-premises password protection, smart lockout, password expiry. MFA capable members, per-user MFA |
| **Conditional Access and risk** | Legacy authentication block and recent legacy sign-ins. Device code flow and authentication transfer. User, sign-in, service principal and agent risk. Managed devices. Protecting MFA registration and device enrollment. Token protection, sign-in frequency, locations, trusted-location MFA skips. Lockout safety. The sync account restricted to its server |
| **Applications and consent** | Users registering apps and agent blueprints. User consent, risky-app consent, group owner consent, admin consent workflow. App management policy (block secrets, secret and certificate lifetime). Secrets, long-lived credentials and credentials on service principals. App instance lock, redirect URIs. Risky delegated grants, high-privilege Graph permissions, Exchange `full_access_as_app`. Old Run As apps (CVE-2021-42306) |
| **Hybrid and federation** | Federated domains. Old sync accounts. The Entra Connect application-based authentication app's owners and secrets. Hybrid Identity Administrator. On-premises attributes in privileged dynamic groups |
| **External identities** | Guest access level, who can invite, email-verified join, cross-tenant MFA trust and inbound cross-tenant sync, inactive guests, guest access reviews |
| **Tenant and devices** | Tenant creation, group creation, BitLocker key reads, device join, device limit, local admins on join, LAPS, MFA to register devices |
| **Recent changes** | The last 30 days of the audit log for the signs the sources describe: federation changes, role assignments outside PIM, credentials and owners added to privileged apps, new Graph permissions, sync feature changes, TAPs and password resets on admins and sync accounts, Conditional Access changes |

**Scores:** each check is an item. A passing check scores 100; a failing one loses 25 for each High, 10 for each Medium and 3 for each Low finding. An area's score is the average of its checks. Green 80+, Amber 50–79, Red under 50. Checks that need a license the tenant doesn't have (Entra ID P1, P2, ID Governance or Workload ID) are skipped and listed in the notes.

**Severities, scores and the mapping of checks to sources are this repo's choices.** CISA's SHALL and BOD 25-01 policies are High and its SHOULD policies Medium; CIS Level 1 is Medium and Level 2 Low, unless the check closes a known attack path. Where a source gives a number (eight Global Administrators, 180-day secrets, lockout threshold 10), the rule uses it, and where CISA and CIS differ, the rule says which it uses.

**People aren't named.** The review gives counts for users, guests and admins ("3 admins are synced from on-premises"). Apps, policies, groups and roles are named.

## Not readable through the Enterprise MCP (manual checklist in the report)

Some of the guidance is process, on-premises or Defender, and some Graph data has no MCP scope. The report lists these as a checklist, and Cowork or VS Code can read the admin center pages in the browser if you turn that on.

- **Federation settings** for federated domains (`federationConfiguration` returns 403): MFA behavior, signing certificate and issuer.
- **Entra Connect sync features** (`/directory/onPremisesSynchronization` returns 403): BlockSoftMatch and BlockCloudObjectTakeoverThroughHardMatch, password hash sync, Seamless SSO.
- **Partner relationships** (GDAP and DAP; 403) and **risky agents** (403).
- Legacy MFA settings (trusted IPs, remember MFA), SSPR, Keep me signed in, LinkedIn, Restrict access to the Entra admin center, guest domain allowlist.
- Privileged access workstations, offline break-glass credentials, help desk verification, Tier 0 for Entra Connect and AD FS, Defender XDR attack disruption, app governance, logs sent to a SIEM, the alerts the security operations guide recommends, and a recovery plan for a systemic identity compromise.

## Who runs it: Copilot Entra ID Operations Reader

The review reads the same things as the Entra ID Operations Report, with the same role, so it uses the same group: **Copilot Entra ID Operations Reader**, a role-assignable group under PIM that holds **Global Reader**. See [Who runs it](../Entra%20ID%20Operations%20Report/README.md#who-runs-it-copilot-entra-id-operations-reader) and the [Group Assignment Guide](../Group%20Assignment%20Guide/readme.md#copilot-entra-id-operations-reader).

1. **Create the group** with `New-CopilotGroups.ps1` and `New-CopilotAdminPim.ps1` in the Group Assignment Guide, if you haven't for the Operations Report. People activate it for 8 hours with MFA, a reason and approval.
2. **Scope the Cowork plugin to the group** when you upload it: Agents > Tools > Registry > Upload > Scope users > Specific users or groups > Copilot Entra ID Operations Reader.
3. Members also need a Microsoft 365 Copilot license and Cowork access, or a GitHub Copilot plan for VS Code. The Enterprise MCP server acts as the signed-in person, so they see only what their activated role allows.

| Entra role | What the review reads with it |
| --- | --- |
| **Global Reader** | Everything the review reads: users, groups, domains, licenses, apps, service principals, owners and credentials, consent grants, the authorization, consent, app management, authentication methods, device registration and cross-tenant policies, Conditional Access, sign-in and audit logs, MFA registration, risky users and service principals, role assignments and PIM settings, access reviews |

Security Reader plus Reports Reader covers most of the review if you'd rather not use Global Reader; the authentication methods, guest invite and cross-tenant checks may then be skipped.

**Making the fixes** isn't part of the review. Use the matching admin role through its own PIM group, for the change only.

## What's in this folder

| File | What it is |
| --- | --- |
| [Cowork/](Cowork/readme.md) | Cowork setup guide, plugin, skill, rules, sources and report template |
| [GitHub Copilot/](GitHub%20Copilot/readme.md) | GitHub Copilot setup guide (VS Code), and the script that installs the skill |

The report describes your tenant's weak spots. Keep it private; the `.gitignore` here excludes the report and CSV files.

## References

- CISA SCuBA: [M365 Secure Configuration Baseline for Microsoft Entra ID](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md) and [BOD 25-01](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
- CIS: [Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365)
- [Attack and Defense Playbook for Microsoft Entra](https://github.com/Cloud-Architekt/AzureAD-Attack-Defense)
- Every other article, with what the review takes from it: [guidance.md](Cowork/plugin/skills/entra-id-security-review/references/guidance.md)
- [Overview](https://learn.microsoft.com/graph/mcp-server/overview) and [Get started](https://learn.microsoft.com/graph/mcp-server/get-started) with the Microsoft MCP Server for Enterprise

## What's verified and what isn't

Checked against the sources and a live test tenant on Nov 2, 2026.

**Tested through the Enterprise MCP:** the authorization, consent, app management, authentication methods (including the Authenticator feature settings), authentication strength, device registration and cross-tenant policies; directory settings; Conditional Access with session controls; role definitions, role assignments with `onPremisesImmutableId`, PIM policy rules with notification recipients; app registrations with owners and app instance lock; service principals with owners; role-assignable groups with owners; members' MFA capability; risky service principals; and the audit log filters for every Recent changes check. The calls that return 403 are listed above.

**From the published baselines:** CISA policy IDs and BOD 25-01 marks from the ScubaGear baseline on GitHub (Oct 29, 2026). CIS v7.0.0 numbers from Prowler's public CIS 7.0 mapping, not the CIS PDF itself; check them against your copy.

**This repo's own choices:** severities and scores, the mapping of each check to its sources and attack, adding four roles to CISA's highly privileged list, the 90-day inactivity and 30-day lookback, the high-privilege permission list, the Run As name match, and the guess at emergency access accounts.

**Not tested in a live tenant:** the federated-domain and Entra Connect application-based authentication checks (the test tenant is cloud-only), and whether Global Reader alone reads every call in every tenant.
