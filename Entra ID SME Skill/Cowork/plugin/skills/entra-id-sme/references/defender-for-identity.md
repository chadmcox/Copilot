# Microsoft Defender for Identity — pointers

Not summarized at authoring. Verify at runtime.

| Topic | Page [MS Learn] |
|---|---|
| Docs hub (sensors, alerts, lateral movement paths) | https://learn.microsoft.com/en-us/defender-for-identity/ |
| Security posture assessments (list; find AD CS-related assessments here) | https://learn.microsoft.com/en-us/defender-for-identity/security-assessment |
| Account assessments | https://learn.microsoft.com/en-us/defender-for-identity/security-posture-assessments/accounts |
| Certificates (AD CS) assessments | https://learn.microsoft.com/en-us/defender-for-identity/security-posture-assessments/certificates |

For "which assessments cover AD CS": the security-assessment overview lists categories only (AD CS = "Certificates"). Fetch the Certificates category page above, list only the assessment names it shows, and link each. Do not name assessments from memory.

Identity advanced hunting in Defender XDR: confirm table names (e.g. on the Defender XDR advanced hunting schema page) before writing KQL.

Author queries [Author repo – community, not official Microsoft guidance]: https://github.com/chadmcox/Sentinel-and-Defender-Queries/tree/main/Defender
