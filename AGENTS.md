# How to write PowerShell in this repo

These are the owner's rules. Follow them in every script you add or change.

- Use straight Microsoft Graph calls: `Connect-MgGraph` and `Invoke-MgGraphRequest` only (module Microsoft.Graph.Authentication). Don't use the other Microsoft Graph PowerShell modules or their cmdlets (no `Get-Mg*`, `New-Mg*`, `Update-Mg*`): they change too often between versions. Don't use the Az modules either.
- **Use the Entra PowerShell modules (Microsoft.Entra, Microsoft.Entra.Beta) only when Graph can't do it**, such as `Grant-EntraBetaMCPServerPermission` for the Enterprise MCP server. Say in a comment why Graph doesn't work for that step.
- **Exchange Online PowerShell is allowed** (module ExchangeOnlineManagement) for what Graph can't do, such as Defender for Office 365 and Exchange settings. Use `Connect-ExchangeOnline` with read-only `Get-` cmdlets unless the script is meant to make changes, map the cloud choice to `-ExchangeEnvironmentName` (Global: `O365Default`, USGov: `O365USGovGCCHigh`, USGovDoD: `O365USGovDoD`), and disconnect at the end with `Disconnect-ExchangeOnline -Confirm:$false`. Keep Graph calls on `Invoke-MgGraphRequest`.
- Use the Microsoft Graph **beta** endpoint (`https://graph.microsoft.com/beta`) for every call. It usually has more properties and APIs than v1.0.
- Keep it simple. Don't over-complicate the code.
- Never use `+=`. Let the pipeline collect output, or wrap it in `@( )`.
- Don't create custom objects (`[pscustomobject]@{}`, `New-Object PSObject`, classes). Keep data in the pipeline and shape it with `Select-Object` calculated properties (`@{ n = "Name"; e = { ... } }`).
- Use functions for each step, and make them pipeline-friendly (`process { }` blocks) where it fits.
- Follow `@odata.nextLink` for every collection.
- Ask which cloud to connect to. Add `[ValidateSet("Global", "USGov", "USGovDoD")][string]$Environment`; if it's empty, list those clouds from `Get-MgEnvironment` (same module), ask with `Read-Host` into a separate variable (the ValidateSet rejects an empty answer), and default to Global. Build every URL from that cloud's `GraphEndpoint` (never hard-code `graph.microsoft.com`) and pass `-Environment $Environment` to `Connect-MgGraph`.
- Never put tenant IDs, object IDs or email addresses in the repo. Use placeholders like `"<person UPN>"`.

## Script header

Start every script with a `<#PSScriptInfo #>` block, the way the owner's [Azure_Active_Directory](https://github.com/chadmcox/Azure_Active_Directory) scripts do. Put it above the comment-based help (`<# .SYNOPSIS ... #>`) and the `param()` block.

- **.VERSION**: the year and month, like `2026.10`. Change it when you change the script.
- **.GUID**: a new GUID for each new script (`[guid]::NewGuid()`). Keep it when you update the script. Never copy one from another script.
- **.AUTHOR**: `Chad Cox` with the blog and GitHub links below. No email address.
- **.COPYRIGHT**: the sample code disclaimer below, word for word.
- **.description**: one line on what the script does, then the Microsoft Learn URL it's based on.

```powershell
<#PSScriptInfo
.VERSION 2026.10
.GUID <new GUID>
.AUTHOR Chad Cox
    https://blogs.technet.microsoft.com/chadcox/
    https://github.com/chadmcox
.COMPANYNAME
.COPYRIGHT This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys` fees, that arise or result
from the use or distribution of the Sample Code..
.description
<What the script does, in one line.>
url: <Microsoft Learn page title> - <https://learn.microsoft.com/...>
#>
```

## Cowork and GitHub Copilot folders

Each solution that has a skill has two folders, and both use the same skill files:

- **Cowork/**: the Copilot Cowork plugin. The skills live in `Cowork/plugin/skills/`. This is the only copy; don't duplicate a skill anywhere else.
- **GitHub Copilot/**: setup for GitHub Copilot in VS Code and the Copilot CLI. `Install-GitHubCopilotSkill.ps1` copies the skills from `Cowork/plugin/skills/` (or downloads them from GitHub) and puts the solution's scripts in the skill's `scripts` folder.

When you add a file to a skill, or a new skill, add it to both `New-CoworkPluginPackage.ps1` and `Install-GitHubCopilotSkill.ps1`. When a skill step only fits one product, say so in the skill's "If you're running in GitHub Copilot" section.
