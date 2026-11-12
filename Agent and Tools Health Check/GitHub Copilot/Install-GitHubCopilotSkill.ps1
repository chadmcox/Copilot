<#PSScriptInfo
.VERSION 2026.11
.GUID 23ee387e-6f48-4066-a019-5ba4452656b1
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
Installs the Agent and Tools Health skill for GitHub Copilot in VS Code and the Copilot CLI.
url: Use Agent Skills in VS Code - https://code.visualstudio.com/docs/agent-customization/agent-skills
#>

<#
.SYNOPSIS
    Installs the Agent and Tools Health skill for GitHub Copilot in VS Code and the Copilot CLI.

.DESCRIPTION
    Copies the skill (the same one Copilot Cowork uses) into a folder GitHub Copilot reads, and
    puts Get-AgentToolsHealth.ps1 in the skill's scripts folder so Copilot can run it for you.

      - User (default): ~/.copilot/skills. Works in every VS Code workspace and in the Copilot CLI.
      - Workspace: <folder>/.github/skills, plus <folder>/.vscode/mcp.json with the Microsoft MCP
        Server for Enterprise (unless -NoMcpConfig). Everyone who opens that folder gets both.

    Running it again updates the skill. If the files aren't next to this script (for example, you
    downloaded only this script), it downloads them from the GitHub repo. That's the only network
    call it makes. It doesn't sign in to anything or change your tenant.

.EXAMPLE
    .\Install-GitHubCopilotSkill.ps1
    .\Install-GitHubCopilotSkill.ps1 -Scope Workspace -WorkspacePath "C:\Copilot Health Checks"
#>
[CmdletBinding()]
param(
    [ValidateSet("User", "Workspace")][string]$Scope = "User",
    [string]$WorkspacePath = (Get-Location).Path,
    [switch]$NoMcpConfig,
    [string]$GitHubBaseUrl = "https://raw.githubusercontent.com/chadmcox/Copilot/main/Agent%20and%20Tools%20Health%20Check"
)

# Stop at the first error, so a failed download never leaves a half-installed skill.
$ErrorActionPreference = "Stop"

$skillNames = @("agent-tools-health", "agent-admin-settings")
$mcpUrl = "https://mcp.svc.cloud.microsoft/enterprise"

# Every file to install: where it is in this solution folder, and where it goes under the skills folder.
$files = @(
    @{ Source = "Cowork/plugin/skills/agent-tools-health/SKILL.md"; Target = "agent-tools-health/SKILL.md" },
    @{ Source = "Cowork/plugin/skills/agent-tools-health/references/rules.md"; Target = "agent-tools-health/references/rules.md" },
    @{ Source = "Cowork/plugin/skills/agent-tools-health/references/guidance.md"; Target = "agent-tools-health/references/guidance.md" },
    @{ Source = "Cowork/plugin/skills/agent-tools-health/assets/report-template.html"; Target = "agent-tools-health/assets/report-template.html" },
    @{ Source = "Get-AgentToolsHealth.ps1"; Target = "agent-tools-health/scripts/Get-AgentToolsHealth.ps1" },
    @{ Source = "Cowork/plugin/skills/agent-admin-settings/SKILL.md"; Target = "agent-admin-settings/SKILL.md" },
    @{ Source = "Cowork/plugin/skills/agent-admin-settings/references/settings.md"; Target = "agent-admin-settings/references/settings.md" }
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

# Adds the Enterprise MCP server to the workspace's .vscode/mcp.json, or says how to add it.
function Set-WorkspaceMcpConfig {
    $path = Join-Path $WorkspacePath ".vscode/mcp.json"
    $config = @'
{
  "servers": {
    "microsoft-mcp-server-for-enterprise": {
      "type": "http",
      "url": "https://mcp.svc.cloud.microsoft/enterprise"
    }
  }
}
'@
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
        # UTF-8 without a byte order mark; Windows PowerShell 5.1 adds one with Set-Content.
        [System.IO.File]::WriteAllText($path, $config, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Wrote $path with the Microsoft MCP Server for Enterprise."
    }
    elseif ((Get-Content $path -Raw) -match [regex]::Escape($mcpUrl)) {
        Write-Host "$path already has the Microsoft MCP Server for Enterprise."
    }
    else {
        Write-Warning "$path already exists, so it wasn't changed. Add this server to its ""servers"" section:"
        Write-Host '    "microsoft-mcp-server-for-enterprise": { "type": "http", "url": "https://mcp.svc.cloud.microsoft/enterprise" }'
    }
}

$skillsFolder = Get-SkillsFolder

# Start clean, so files removed from the skill don't linger after an update.
$skillNames | ForEach-Object { Join-Path $skillsFolder $_ } | Where-Object { Test-Path $_ } |
    ForEach-Object { Remove-Item $_ -Recurse -Force }

$files | Install-SkillFile $skillsFolder

if ($Scope -eq "Workspace" -and -not $NoMcpConfig) { Set-WorkspaceMcpConfig }

Write-Host ""
Write-Host "Installed the skills ($($skillNames -join ', ')) in $skillsFolder."
if ($Scope -eq "User") {
    Write-Host "To use the Enterprise MCP in VS Code, add it once: Command Palette > MCP: Add Server > HTTP > $mcpUrl"
}
Write-Host "In VS Code, open Copilot Chat in Agent mode and type /$($skillNames[0]), or ask: Run the agent and tools health check."
Write-Host "In the Copilot CLI, run copilot and ask the same thing."
