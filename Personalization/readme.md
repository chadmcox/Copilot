# Copilot Custom Instructions

Tell Copilot who you are and how you work once, so you don't repeat it in every prompt.

## Short version

1. Open Microsoft 365 Copilot and select **Settings** > **Personalization**.
2. Copy the example below that is closest to your role.
3. Edit it to fit you. Keep it to a few paragraphs.
4. Paste it into your custom instructions and save.

## Examples

| File | For |
| --- | --- |
| [Copilot Admin (detailed)](Example%20Copilot%20Admin%20Detailed%20Custom%20Instructions.txt) | Copilot, agent and Power Platform admins |
| [Identity Admin (detailed)](Example%20Identity%20Admin%20Detailed%20Custom%20Instructions.txt) | Entra ID and Active Directory admins |
| [Identity Admin (simple)](Example%20Identity%20Admin%20Simple%20Custom%20Instructions.txt) | A shorter starting point for identity admins |
| [Cyber Security Student](Example%20Cyber%20Security%20Student%20Custom%20Instructions.txt) | Security students |
| [Digital Marketing Student](Example%20Digital%20Marketing%20Student%20Custom%20Instructions.txt) | Marketing students |
| [HOA Board Member](Example%20HOA%20Board%20Member%20Custom%20Instructions.txt) | HOA board and committee volunteers |
| [Personal](Example%20Personal%20Custom%20Instructions.txt) | Personal, non-work use |

## Why bother

Most people use Copilot with the defaults. That works, but answers get a lot closer to what you need when Copilot knows your role, the tools you use, the sources you trust and how you like answers written. The goal isn't a smarter Copilot. It's a Copilot that works the way you do.

Example: ask "Write a PowerShell script to return all Microsoft 365 groups." With my instructions, Copilot already knows to use Microsoft Graph with `Invoke-MgGraphRequest`, follow every page of results, use the pipeline and calculated properties, skip the AzureAD and MSOnline modules, and include documentation links. The result is close to what I'd have written myself.

## What to put in

- **Role and focus:** what you do and the products you work with.
- **How you want answers:** length, format, tone.
- **Trusted sources:** for example Microsoft Learn and official docs over blogs and roadmap guesses.
- **Coding style:** if you write code, the modules and patterns you prefer.
- **What to flag:** limits, prerequisites, and anything it can't verify.

Only include preferences that change the answer. A good profile is a few paragraphs, not pages. Custom instructions don't replace good prompts. They give every prompt a better starting point.

## Microsoft documentation

- [Manage Copilot Personalization and Memory](https://learn.microsoft.com/en-us/microsoft-365/copilot/copilot-personalization-memory)
- [Customize How Microsoft Copilot Responds to You](https://support.microsoft.com/en-us/microsoft-365-copilot/customize-how-microsoft-365-copilot-responds-to-you)
- [Personalize What Microsoft Copilot Remembers](https://support.microsoft.com/en-us/microsoft-365-copilot/personalize-what-microsoft-365-copilot-remembers)
- [Microsoft 365 Copilot Enhanced Personalization Control](https://learn.microsoft.com/en-us/graph/control-enhanced-personalization-privacy)
