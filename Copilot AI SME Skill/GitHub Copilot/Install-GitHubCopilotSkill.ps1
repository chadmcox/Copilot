<#PSScriptInfo
.VERSION 2026.11
.GUID ac76990a-ca7a-4e15-9069-a3a86bc231b2
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
Installs the Copilot AI SME skill for GitHub Copilot in VS Code and the Copilot CLI.
url: Use Agent Skills in VS Code - https://code.visualstudio.com/docs/agent-customization/agent-skills
#>

<#
.SYNOPSIS
    Installs the Copilot AI SME skill for GitHub Copilot in VS Code and the Copilot CLI.

.DESCRIPTION
    Copies the skill (the same one Copilot Cowork uses) into a folder GitHub Copilot reads. The skill
    checks answers with the Microsoft Learn MCP and the Microsoft Release Communications MCP, and can
    read the tenant through the Microsoft MCP Server for Enterprise, so there's no script to install.

      - User (default): ~/.copilot/skills. Works in every VS Code workspace and in the Copilot CLI.
      - Workspace: <folder>/.github/skills, plus <folder>/.vscode/mcp.json with the Learn, Release
        Communications and Enterprise MCP servers (unless -NoMcpConfig). Everyone who opens that folder
        gets the skill and the servers.

    Running it again updates the skill. If the files aren't next to this script (for example, you
    downloaded only this script), it downloads them from the GitHub repo. That's the only network
    call it makes. It doesn't sign in to anything or change your tenant.

.EXAMPLE
    .\Install-GitHubCopilotSkill.ps1
    .\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Copilot AI SME"
#>
[CmdletBinding()]
param(
    [ValidateSet("User", "Workspace")][string]$Scope = "User",
    [string]$WorkspacePath = (Get-Location).Path,
    [switch]$NoMcpConfig,
    [string]$GitHubBaseUrl = "https://raw.githubusercontent.com/chadmcox/Copilot/main/Copilot%20AI%20SME%20Skill"
)

# Stop at the first error, so a failed download never leaves a half-installed skill.
$ErrorActionPreference = "Stop"

$skillNames = @("copilot-ai-sme")
# The MCP servers the skill uses: name and URL. Learn and Release Communications need no sign-in.
$mcpServers = @(
    @{ Name = "microsoft-learn"; Url = "https://learn.microsoft.com/api/mcp" },
    @{ Name = "microsoft-release-communications"; Url = "https://www.microsoft.com/releasecommunications/mcp" },
    @{ Name = "microsoft-mcp-server-for-enterprise"; Url = "https://mcp.svc.cloud.microsoft/enterprise" }
)

# Every file to install: where it is in this solution folder, and where it goes under the skills folder.
$files = @(
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/SKILL.md"; Target = "copilot-ai-sme/SKILL.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/autopilot.md"; Target = "copilot-ai-sme/references/autopilot.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/blogs-and-feeds.md"; Target = "copilot-ai-sme/references/blogs-and-feeds.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/copilot-studio.md"; Target = "copilot-ai-sme/references/copilot-studio.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/cowork.md"; Target = "copilot-ai-sme/references/cowork.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/finops.md"; Target = "copilot-ai-sme/references/finops.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/gotchas.md"; Target = "copilot-ai-sme/references/gotchas.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/governance.md"; Target = "copilot-ai-sme/references/governance.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/health-checks.md"; Target = "copilot-ai-sme/references/health-checks.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/licensing.md"; Target = "copilot-ai-sme/references/licensing.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/security-frameworks.md"; Target = "copilot-ai-sme/references/security-frameworks.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/sources.md"; Target = "copilot-ai-sme/references/sources.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/tests.md"; Target = "copilot-ai-sme/references/tests.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/threat-model.md"; Target = "copilot-ai-sme/references/threat-model.md" },
    @{ Source = "Cowork/plugin/skills/copilot-ai-sme/references/whats-new-workflow.md"; Target = "copilot-ai-sme/references/whats-new-workflow.md" }
)

function Get-SkillsFolder {
    if ($Scope -eq "User") { Join-Path $HOME ".copilot/skills" }
    else { Join-Path $WorkspacePath ".github/skills" }
}

# Copies one file from this solution folder, or downloads it from GitHub when it isn't here.
function Install-SkillFile([string]$SkillsFolder) {
    process {
        $local = Join-Path (Split-Path $PSScriptRoot) $_.Source
        $target = Join-Path $SkillsFolder $_.Target
        New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
        if (Test-Path $local) {
            Copy-Item $local $target -Force
        }
        else {
            $url = "$GitHubBaseUrl/$($_.Source.Replace(' ', '%20'))"
            try { Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing }
            catch { throw "Couldn't download $url. Check your internet connection, or download the whole solution folder from GitHub and run the script from there. $($_.Exception.Message)" }
        }
        Write-Host "Installed $($_.Target)"
    }
}

# Adds the MCP servers to the workspace's .vscode/mcp.json, or says which ones to add.
function Set-WorkspaceMcpConfig {
    $path = Join-Path $WorkspacePath ".vscode/mcp.json"
    $entries = $mcpServers | ForEach-Object { '    "{0}": {{ "type": "http", "url": "{1}" }}' -f $_.Name, $_.Url }
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
        $config = "{`n  ""servers"": {`n" + ($entries -join ",`n") + "`n  }`n}`n"
        # UTF-8 without a byte order mark; Windows PowerShell 5.1 adds one with Set-Content.
        [System.IO.File]::WriteAllText($path, $config, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Wrote $path with the Learn, Release Communications and Enterprise MCP servers."
    }
    else {
        $text = Get-Content $path -Raw
        $missing = @($mcpServers | Where-Object { $text -notmatch [regex]::Escape($_.Url) })
        if ($missing.Count -eq 0) { Write-Host "$path already has all three MCP servers." }
        else {
            Write-Warning "$path already exists, so it wasn't changed. Add these servers to its ""servers"" section:"
            $missing | ForEach-Object { Write-Host ('    "{0}": {{ "type": "http", "url": "{1}" }}' -f $_.Name, $_.Url) }
        }
    }
}

$skillsFolder = Get-SkillsFolder

# Start clean, so files removed from the skill don't linger after an update.
$skillNames | ForEach-Object { Join-Path $skillsFolder $_ } | Where-Object { Test-Path $_ } |
    ForEach-Object { Remove-Item $_ -Recurse -Force }

$files | Install-SkillFile $skillsFolder

if ($Scope -eq "Workspace" -and -not $NoMcpConfig) { Set-WorkspaceMcpConfig }

Write-Host ""
Write-Host "Installed the skill in $skillsFolder."
if ($Scope -eq "User") {
    Write-Host "Add these MCP servers in VS Code once (Command Palette > MCP: Add Server > HTTP):"
    $mcpServers | ForEach-Object { Write-Host "    $($_.Url)" }
    Write-Host "Learn and Release Communications need no sign-in. The Enterprise MCP is optional, for read-only tenant reads."
}
Write-Host "In VS Code, open Copilot Chat in Agent mode and type /$($skillNames[0]), or ask, for example: Who can use Cowork in my tenant, and what controls the cost?"
