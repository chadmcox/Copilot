<#
.SYNOPSIS
    Checks that every test in the Maester AI governance pack is mapped to a rule in a health check.

.DESCRIPTION
    Reads each Test.MP.AIGOV.*.ps1 in the pack (its Id and Severity) and every MP.AIGOV ID in the
    Maester column of the health checks' rules.md files. Fails when a pack test isn't in any
    rules.md and isn't listed in maester-not-covered.txt. Warns when a rules.md names an ID the pack
    doesn't have, or when no rule for an ID has the pack's severity.

    Runs in GitHub Actions (.github/workflows/maester-coverage.yml); it also runs locally.

.EXAMPLE
    ./.github/scripts/Test-MaesterCoverage.ps1 -PackPath ../maester-ai-governance-pack
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackPath,
    [string]$RepoPath = (Join-Path $PSScriptRoot "../.."),
    # One pack ID per line, with a reason after a #, for tests you chose not to cover.
    [string]$NotCoveredFile = (Join-Path $PSScriptRoot "../maester-not-covered.txt")
)

# Pack tests: Id, Severity and Title from each test's [MaesterTest()] attribute.
function Get-PackTest([string]$Path) {
    Get-ChildItem (Join-Path $Path "pack/tests") -Filter "Test.MP.AIGOV.*.ps1" | ForEach-Object {
        $text = Get-Content $_.FullName -Raw
        $_ | Select-Object @{ n = "Id"; e = { [regex]::Match($text, "Id\s*=\s*'(MP\.AIGOV\.\d+)'").Groups[1].Value } },
            @{ n = "Severity"; e = { [regex]::Match($text, "Severity\s*=\s*'(\w+)'").Groups[1].Value } },
            @{ n = "Title"; e = { [regex]::Match($text, "Title\s*=\s*'([^']+)'").Groups[1].Value } }
    } | Where-Object Id
}

# One row per (rule, pack ID) in the health checks' rules.md tables. Severity is the second cell.
function Get-RuleMapping([string]$Path) {
    Get-ChildItem $Path -Recurse -Filter "rules.md" | Where-Object FullName -match "Health Check" | ForEach-Object {
        $file = $_.FullName.Substring((Resolve-Path $Path).Path.Length).TrimStart("/", "\")
        Get-Content $_.FullName | Where-Object { $_ -match '^\| ' -and $_ -match 'MP\.AIGOV\.\d+' } | ForEach-Object {
            $severity = ($_.Trim().Trim("|") -split "\|")[1].Trim()
            [regex]::Matches($_, 'MP\.AIGOV\.\d+') | ForEach-Object Value |
                Select-Object @{ n = "Id"; e = { $_ } }, @{ n = "Severity"; e = { $severity } }, @{ n = "File"; e = { $file } }
        }
    }
}

$pack = @(Get-PackTest $PackPath)
if (-not $pack) { Write-Host "::error::No pack tests found under $PackPath/pack/tests"; exit 1 }
$rules = @(Get-RuleMapping $RepoPath)
$notCovered = @(if (Test-Path $NotCoveredFile) {
    Get-Content $NotCoveredFile | ForEach-Object { ($_ -split "#")[0].Trim() } | Where-Object { $_ }
})
$byId = $rules | Group-Object Id -AsHashTable -AsString
if (-not $byId) { $byId = @{} }

$report = @($pack | Sort-Object Id | Select-Object Id, Title,
    @{ n = "PackSeverity"; e = { $_.Severity } },
    @{ n = "RuleSeverity"; e = { @($byId[$_.Id] | Where-Object { $_ } | ForEach-Object Severity | Sort-Object -Unique) -join ", " } },
    @{ n = "Files"; e = { @($byId[$_.Id] | Where-Object { $_ } | ForEach-Object File | Sort-Object -Unique) -join ", " } },
    @{ n = "Status"; e = {
        $sev = @($byId[$_.Id] | Where-Object { $_ } | ForEach-Object Severity)
        if (-not $sev -and $_.Id -in $notCovered) { "Not covered (by choice)" }
        elseif (-not $sev) { "Missing" }
        elseif ($_.Severity -notin $sev) { "Severity differs" }
        else { "Covered" } } })

$report | Where-Object Status -eq "Missing" | ForEach-Object { Write-Host "::error::$($_.Id) ($($_.Title)) isn't mapped in any health check rules.md. Add the rule, or list it in maester-not-covered.txt with a reason." }
$report | Where-Object Status -eq "Severity differs" | ForEach-Object { Write-Host "::warning::$($_.Id) is $($_.PackSeverity) in the pack but $($_.RuleSeverity) in $($_.Files)." }
$rules | Where-Object { $_.Id -notin $pack.Id } | Sort-Object Id, File -Unique | ForEach-Object { Write-Host "::warning::$($_.File) names $($_.Id), which isn't in the pack." }
$notCovered | Where-Object { $byId.ContainsKey($_) } | ForEach-Object { Write-Host "::warning::$_ is in maester-not-covered.txt but is mapped in a rules.md. Remove it from the file." }

$table = @(
    "| Pack test | Status | Pack severity | Rule severity | Where |"
    "| --- | --- | --- | --- | --- |"
    $report | ForEach-Object { "| $($_.Id) $($_.Title) | $($_.Status) | $($_.PackSeverity) | $($_.RuleSeverity) | $($_.Files) |" }
)
if ($env:GITHUB_STEP_SUMMARY) { "## Maester AI governance pack coverage`n" + ($table -join "`n") | Out-File $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
$report | Format-Table Id, Status, PackSeverity, RuleSeverity -AutoSize | Out-Host

$missing = @($report | Where-Object Status -eq "Missing").Count
Write-Host "$($pack.Count) pack tests, $(@($report | Where-Object Status -ne 'Missing').Count) mapped or excluded, $missing missing."
if ($missing) { exit 1 }
