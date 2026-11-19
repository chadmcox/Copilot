# Microsoft Copilot Autopilot

**Not Windows Autopilot.** If the user means device provisioning, say it's out of scope.

Read on Microsoft Learn on Nov 19, 2026 (prerelease docs; re-fetch before citing): https://learn.microsoft.com/copilot/autopilot/overview

## What it is [MS Learn]
- An always-on, cloud-based agent in Microsoft Copilot. The user describes an outcome, sources and boundaries; it prepares documents, follows up on work and runs recurring routines.
- Has its own workplace identity, memory, computer and workspace. **One Autopilot per user.** Runs while the user's device is off, subject to access, approvals and service availability.
- Appears by name on the **Home** tab in Microsoft Copilot; uses a private Teams chat for updates and approvals; available on iOS/Android through the Microsoft 365 Copilot, Teams and Outlook apps.
- Doesn't expand the data the user can access. Before sending, sharing, deleting or changing something, an automated check decides whether it runs or needs the user's approval. Some operations use its own identity; others use the user's delegated access.
- Can't access local folders or apps; optional Microsoft Edge connection lets it work in the user's browser where enabled.

## Status and availability [MS Learn]
- **Frontier preview.** Off by default. Initially limited to eligible customers in the United States; optimized for English.
- History [3P news, verify]: introduced as Scout on Jun 2, 2026; renamed Autopilot with the Home/Code/Autopilot Copilot on Sep 25, 2026. Check the Copilot blog and roadmap for current status.

## Prerequisites (all required) [MS Learn]
| Requirement | Detail |
|---|---|
| License | Microsoft 365 Copilot license on the accountable user |
| Frontier | User enrolled in Frontier (Microsoft 365 admin center > Copilot > Settings > Copilot Frontier). Frontier alone doesn't enable Autopilot |
| Activation | **Agents > All agents > Autopilot (Frontier) > Activate** (wizard: users, spending policy, security policy, permissions, memory, review) |
| Spending policy | **Copilot > Cost Management > Configuration > Spending policies**, Identity scope, **Autopilot** selected, limits, billing method. A Copilot license doesn't include Autopilot usage |
| Settings | Required agent and AI-provider settings must permit it; Frontier doesn't override them |
| Security | Review the Entra, Purview and Defender protections listed in activation; they're managed in each product and may not be on |

Source: https://learn.microsoft.com/copilot/autopilot/admin-configure ; https://learn.microsoft.com/copilot/autopilot/requirements

## Troubleshoot "Autopilot isn't there" or "stopped responding" (in order)
1. Frontier assignment. 2. Copilot license. 3. Activation scope for Autopilot (Frontier). 4. Spending policy coverage and remaining credits (a user not covered, or out of credits, gets **no explanation**). 5. Agent and AI-provider settings. Allow time for changes; don't have users recreate their Autopilot to troubleshoot.
If a user is in more than one spending policy, the policy with the highest spending limit applies.

## Data, privacy and records [MS Learn]
- Memories and sessions are stored in a file in the user's OneDrive. Users review, export and delete their own memory and conversations.
- Admins can export a user's Autopilot data for an approved compliance or privacy request with Microsoft's export script (grants the admin temporary OneDrive access, recorded in the audit log; remove access afterward). Admins can't delete the data for the user; bulk or departing-user deletion goes to Microsoft support.
- Deleted conversations stay until the user asks Autopilot to permanently remove them.
- Exports may not carry sensitivity labels.

## Design and security notes (map in threat-model.md)
- Its own identity and an always-on cloud computer make it an **autonomous agent** in OWASP and CISA terms: least privilege, human approval for high-impact actions, logging, a kill switch (remove from spending policy or activation scope), sponsor/owner accountability.
- Spending policy = cost control **and** access control.
