# How to write PowerShell in this repo

These are the owner's rules. Follow them in every script you add or change.

- Use straight Microsoft Graph calls: `Connect-MgGraph` and `Invoke-MgGraphRequest` only (module Microsoft.Graph.Authentication). Don't require any other module or cmdlet (no `Get-Mg*`, `New-Mg*`, Entra or Az modules).
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
