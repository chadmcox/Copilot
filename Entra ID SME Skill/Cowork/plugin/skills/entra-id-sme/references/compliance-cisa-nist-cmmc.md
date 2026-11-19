# Compliance mapping — CISA SCuBA, NIST, CMMC

## Mandatory disclaimer (append to every compliance answer)
> This maps Microsoft Entra / Defender for Identity configuration to control requirements. It is not a compliance attestation or certification. Meeting a control is the organization's responsibility, and the authorizing assessor makes the determination.

## Mapping workflow
1. Identify the control ID (CMMC practice e.g. IA.L2-3.5.3, NIST control, SCuBA MS.AAD.x.x).
2. Fetch the control text from the official source and the Microsoft Learn mapping page.
3. Map → Entra/MDI configuration, citing the Learn page.
4. Name the Graph resource.property that proves the setting (graph-validation.md), with v1.0/beta status.
5. Give the read-only GET or script to collect evidence.
6. Append the disclaimer.

## Output table
| Control ID | Control intent (cited) | Entra/MDI configuration | Graph property | v1.0/beta | Source |
|---|---|---|---|---|---|

## Sources (verify at runtime)
- CISA SCuBA Entra ID baseline [CISA]: https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md — flags each policy as BOD 25-01 Requirement / Automated Check / Manual; assumes E3/G3; lists CISA highly-privileged roles.
- NIST NCP checklist, Entra ID SCuBA 2.0 [NIST]: https://ncp.nist.gov/checklist/1082
- Entra for CMMC [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-for-cmmc-compliance
- CMMC L1 [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-1-controls
- CMMC L2 AC [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-access-control
- CMMC L2 IA [MS Learn] (page last updated 10/23/2023 per validation run — check newer CA guidance such as authentication strengths; SKILL.md rule 6 (conflicts and staleness) applies): https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-identification-and-authentication
- CMMC L2 additional [MS Learn]: https://learn.microsoft.com/en-us/entra/standards/configure-cmmc-level-2-additional-controls
- Entra standards (NIST AAL, FedRAMP, M-22-09): https://github.com/MicrosoftDocs/entra-docs/tree/main/docs/standards
- CMMC practice text itself: cite the DoD CMMC assessment guide [DoD CMMC] — locate via web_search at runtime. The full PDF may be cut off by the fetch size limit; if so, cite the matching NIST SP 800-171 requirement text [NIST] and say the DoD guide page was not fetched.
- Controls Entra cannot meet alone (e.g. local/console access): say "could not verify this is configurable in Entra" and name the area to check (e.g. Windows sign-in / device docs) rather than inventing a mapping.
