# Security frameworks and best practices

Rules (from SKILL.md): lead with the Microsoft control, then cite the framework that asks for it; show version and status (final / draft / renamed) checked at runtime; never paste ISO or CIS text (cite IDs, paraphrase); add the mapping disclaimer.

"Checked" = read when this skill was built (Nov 19, 2026). Everything else: **verify at runtime** before citing.

## Government [CISA] [NIST]

| Source | Status | Use for | Link |
|---|---|---|---|
| **Careful Adoption of Agentic AI Services** (CISA, NSA, ASD ACSC, CCCS, NCSC-NZ, NCSC-UK) | Published May 2026 (checked: official PDF) | Agentic AI risk categories — **privilege, design and configuration, behaviour, structural, accountability** — best practices across the lifecycle, and **cyber security prerequisites before implementing AI agents** | https://www.cyber.gov.au/sites/default/files/2026-05/careful_adoption_of_agentic_ai_services.pdf (CISA hosts a copy; search cisa.gov) |
| CISA SCuBA baselines (M365, Entra, Power Platform, Teams, SharePoint, Exchange, Defender) | Versioned; check the current release | Tenant hardening that agents depend on; BOD 25-01 requirements | https://github.com/cisagov/ScubaGear |
| CISA/NSA joint AI guidance (e.g. deploying AI systems securely, AI data security) | Verify titles and dates at runtime | Secure deployment, data protection for AI | https://www.cisa.gov/ai |
| NIST AI RMF 1.0 (AI 100-1) and Generative AI Profile (AI 600-1) | Final (verify) | AI risk governance: Govern, Map, Measure, Manage | https://www.nist.gov/itl/ai-risk-management-framework |
| NIST CSF 2.0 | Final | Program-level outcomes | https://www.nist.gov/cyberframework |
| NIST IR 8596 Cyber AI Profile (CSF 2.0 profile for AI) | Initial preliminary draft Dec 16, 2025 [3P-reported; verify current draft] | AI considerations per CSF subcategory: Secure, Defend, Thwart | https://csrc.nist.gov (search IR 8596) |
| NIST SP 800-53 Rev 5 | Final | Control catalog for mapping | https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final |
| NIST SP 800-53 control overlays for AI | **Renamed Oct 20, 2026** from COSAiS (Securing AI Systems) to **COSIS** (Super Intelligence Systems) (checked: csrc.nist.gov) | AI-specific 800-53 overlays (in development) | https://csrc.nist.gov/Projects/cosis |
| NIST SP 800-218A (SSDF for generative AI) | Final (verify) | Secure development of agents and models | https://csrc.nist.gov/pubs/sp/800/218/a/final |
| NIST SP 800-207 Zero Trust | Final | Agent access as zero trust | https://csrc.nist.gov/pubs/sp/800/207/final |

## Industry [OWASP] [MITRE] [CIS] [ISO] [Industry]

| Source | Status | Use for | Link |
|---|---|---|---|
| **OWASP Top 10 for Agentic Applications 2026** (ASI01–ASI10) | Published Dec 9, 2025 (checked) | Agent threat model (threat-model.md) | https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/ |
| OWASP Top 10 for LLM Applications 2025 (LLM01–LLM10) | Verify | Model and prompt risks under the agent | https://genai.owasp.org/llm-top-10/ |
| MITRE ATLAS | Living knowledge base | Adversary techniques against AI | https://atlas.mitre.org |
| CIS Microsoft 365 Foundations Benchmark | Versioned (licensed; cite IDs only) | Tenant hardening checks | https://www.cisecurity.org/benchmark/microsoft_365 |
| CIS Controls v8.1 | Verify version | Program safeguards | https://www.cisecurity.org/controls |
| ISO/IEC 42001 (AI management system) | Final (licensed; cite clauses only) | AI governance and certification language | https://www.iso.org/standard/42001 |
| ISO/IEC 27001, 27701, 23894 | Final (licensed) | ISMS, privacy, AI risk | iso.org |
| Cloud Security Alliance AI Controls Matrix | Verify version | Cross-industry AI control set | https://cloudsecurityalliance.org/artifacts/ai-controls-matrix |
| EU AI Act (Regulation (EU) 2024/1689) | In force, phased obligations (verify dates) | Only when the organization is in scope | https://eur-lex.europa.eu |

## Manufacturing, mobility and defense supply chain [Industry]
Use when agents touch plant, product, vehicle or controlled defense data.

| Source | Use for |
|---|---|
| NIST SP 800-82 Rev 3 (OT security) | Keep agents away from OT control paths; IT/OT boundaries |
| ISA/IEC 62443 | Zones and conduits; agent access as a conduit |
| ISO/SAE 21434 and UNECE R155 | Automotive cybersecurity when agents touch vehicle engineering data |
| TISAX (ENX) | Automotive supplier information security assessments |
| CMMC 2.0 / NIST SP 800-171 | CUI in defense supply chains; Copilot cloud and data boundary choices (verify GCC/GCC High availability per feature) |

## Mapping table format (Mode 6)
| Framework control (ID) | Requirement in plain words | Microsoft control (Copilot / Cowork / Autopilot / Studio / Agent 365 / Entra / Purview / Defender) | Where to verify | Evidence to collect | Status |
|---|---|---|---|---|---|

Append: *"This maps Microsoft Copilot and agent configuration to framework guidance. It is not a compliance attestation or certification. Meeting a control is the organization's responsibility."*

## Common Microsoft controls to map (verify each on Learn)
- Identity per agent and sponsors: Entra Agent ID, ID Governance (governance.md)
- Least privilege and approvals: connector scopes, data policies, Autopilot approval checks, plugin access
- Access and kill switch: spending policy scope (Cowork, Autopilot), agent activation scope, Agent 365 registry, Conditional Access for agents
- Data protection: Purview sensitivity labels and DLP, SharePoint Advanced Management (oversharing)
- Monitoring: audit logs, Defender, Copilot Credits reports
- Cost guardrails: per-user and policy limits (finops.md)
