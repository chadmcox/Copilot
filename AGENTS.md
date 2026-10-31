# How to write PowerShell in this repo

These are the owner's rules. Follow them in every script you add or change.

- Use straight Microsoft Graph calls: `Connect-MgGraph` and `Invoke-MgGraphRequest` only (module Microsoft.Graph.Authentication). Don't require any other module or cmdlet (no `Get-Mg*`, `New-Mg*`, Entra or Az modules).
- Use the Microsoft Graph **beta** endpoint (`https://graph.microsoft.com/beta`) for every call. It usually has more properties and APIs than v1.0.
- Keep it simple. Don't over-complicate the code.
- Never use `+=`. Let the pipeline collect output, or wrap it in `@( )`.
- Don't create custom objects (`[pscustomobject]@{}`, `New-Object PSObject`, classes). Keep data in the pipeline and shape it with `Select-Object` calculated properties (`@{ n = "Name"; e = { ... } }`).
- Use functions for each step, and make them pipeline-friendly (`process { }` blocks) where it fits.
- Follow `@odata.nextLink` for every collection.
- Ask which cloud to connect to. Add `[ValidateSet("Global", "USGov", "USGovDoD", "China")][string]$Environment`; if it's empty, list `Get-MgEnvironment` (same module), ask with `Read-Host` into a separate variable (the ValidateSet rejects an empty answer), and default to Global. Build every URL from that cloud's `GraphEndpoint` (never hard-code `graph.microsoft.com`) and pass `-Environment $Environment` to `Connect-MgGraph`.
- Never put tenant IDs, object IDs or email addresses in the repo. Use placeholders like `"<person UPN>"`.
