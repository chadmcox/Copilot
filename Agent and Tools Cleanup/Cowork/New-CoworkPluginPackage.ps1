<#PSScriptInfo
.VERSION 2026.10
.GUID 87392ee0-7e1a-459f-834f-1ba9daf18804
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
Builds the Agent and Tools Review plugin .zip, or a skill-only .zip, for Copilot Cowork.
url: Build plugins for Copilot Cowork - https://learn.microsoft.com/copilot/cowork/cowork-plugin-development
#>

<#
.SYNOPSIS
    Builds the Agent and Tools Review plugin .zip, or a skill-only .zip, for Copilot Cowork.

.DESCRIPTION
    Copies the plugin folder, puts your OAuth client registration ID (from the Teams Developer
    Portal) and a new app ID into manifest.json, and zips it.

    If the plugin folder isn't next to this script (for example, you downloaded only this
    script), it downloads the plugin files from the GitHub repo instead. That's the only
    network call it makes.

    Two kinds of zip:
      - Plugin (default): the skill plus the Enterprise MCP connector. Upload it in Cowork under
        Customize > Plugins > Upload plugin, or in the admin center under Agents > Tools > Registry.
      - Skill only (-SkillOnly): one skill, in one folder. Upload it in Cowork under
        Customize > Skills > Add > Upload skill. No connector, so Cowork works from the files you
        attach (agent-tools-review) or the browser (admin-center-tools-review). Pick it with -Skill.

.EXAMPLE
    .\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
    .\New-CoworkPluginPackage.ps1 -SkillOnly
    .\New-CoworkPluginPackage.ps1 -SkillOnly -Skill admin-center-tools-review
#>
[CmdletBinding(DefaultParameterSetName = "Plugin")]
param(
    [Parameter(Mandatory, ParameterSetName = "Plugin")][string]$ReferenceId,
    [Parameter(Mandatory, ParameterSetName = "Skill")][switch]$SkillOnly,
    [Parameter(ParameterSetName = "Skill")][ValidateSet("agent-tools-review", "admin-center-tools-review")][string]$Skill = "agent-tools-review",
    [string]$AppId = [guid]::NewGuid().ToString(),
    [string]$OutputFile = $(if ($SkillOnly) { ".\$Skill.zip" } else { ".\AgentToolsReview-Cowork.zip" }),
    [string]$GitHubBaseUrl = "https://raw.githubusercontent.com/chadmcox/Copilot/main/Agent%20and%20Tools%20Cleanup/Cowork/plugin"
)

# Stop at the first error, so a failed download never produces a broken zip.
$ErrorActionPreference = "Stop"

# Every file in the plugin, relative to the plugin folder.
$pluginFiles = @(
    "manifest.json",
    "color.png",
    "outline.png",
    "skills/agent-tools-review/SKILL.md",
    "skills/admin-center-tools-review/SKILL.md"
)

function Copy-PluginFolder([string]$Destination) {
    Copy-Item (Join-Path $PSScriptRoot "plugin") $Destination -Recurse
}

# Downloads each plugin file from GitHub into the same folder layout.
function Get-PluginFromGitHub([string]$Destination) {
    process {
        $file = $_
        $target = Join-Path $Destination $file
        New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
        try { Invoke-WebRequest -Uri "$GitHubBaseUrl/$file" -OutFile $target -UseBasicParsing }
        catch { throw "Couldn't download $GitHubBaseUrl/$file. Check your internet connection, or download the whole Cowork folder from GitHub and run the script from there. $($_.Exception.Message)" }
        Write-Host "Downloaded $file"
    }
}

function Test-PluginFolder {
    $folder = Join-Path $PSScriptRoot "plugin"
    -not ($pluginFiles | Where-Object { -not (Test-Path (Join-Path $folder $_)) })
}

function Set-ManifestValues([string]$ManifestPath) {
    $text = Get-Content $ManifestPath -Raw
    $text = $text.Replace("00000000-0000-0000-0000-000000000000", $AppId)
    $text = $text.Replace("REPLACE-WITH-OAUTH-CLIENT-REGISTRATION-ID", $ReferenceId)
    # Write UTF-8 without a byte order mark; Windows PowerShell 5.1 adds one with Set-Content.
    [System.IO.File]::WriteAllText($ManifestPath, $text, [System.Text.UTF8Encoding]::new($false))
}

# Zips a folder with forward slashes in every path. Compress-Archive in Windows PowerShell 5.1
# writes backslashes, and Microsoft 365 then can't find the files the manifest points to.
# $Prefix puts everything inside one folder in the zip (the skill upload needs that).
function New-ZipFile([string]$Source, [string]$Destination, [string]$Prefix = "") {
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $root = (Resolve-Path $Source).Path.TrimEnd("\", "/")
    $zipPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
    try {
        Get-ChildItem $root -Recurse -File | ForEach-Object {
            $entry = $Prefix + $_.FullName.Substring($root.Length + 1).Replace("\", "/")
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry) | Out-Null
        }
    }
    finally { $zip.Dispose() }
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) "AgentToolsReview-Cowork"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

if (Test-PluginFolder) {
    Copy-PluginFolder $work
}
else {
    Write-Host "The plugin folder isn't next to this script. Downloading it from GitHub."
    $pluginFiles | Get-PluginFromGitHub $work
}

if ($SkillOnly) {
    # The skill upload wants one folder holding SKILL.md, and nothing else.
    New-ZipFile (Join-Path $work "skills/$Skill") $OutputFile "$Skill/"
    Write-Host "Saved $OutputFile. In Copilot Cowork, open Customize > Skills > Add > Upload skill and choose it."
}
else {
    Set-ManifestValues (Join-Path $work "manifest.json")
    # Everything sits at the root of the zip: manifest.json, icons and skills/.
    New-ZipFile $work $OutputFile
    Write-Host "Saved $OutputFile (app ID $AppId). Upload it in Cowork under Customize > Plugins > Upload plugin, or in the Microsoft 365 admin center under Agents > Tools > Registry > Upload. Not under Skills."
}
Remove-Item $work -Recurse -Force
