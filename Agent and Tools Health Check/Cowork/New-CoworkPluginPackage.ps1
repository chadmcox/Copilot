<#
.SYNOPSIS
    Builds the Agent and Tools Health plugin .zip, or the skill-only .zip, for Copilot Cowork.

.DESCRIPTION
    Copies the plugin folder, puts your OAuth client registration ID (from the Teams Developer
    Portal) and a new app ID into manifest.json, and zips it.

    If the plugin folder isn't next to this script (for example, you downloaded only this
    script), it downloads the plugin files from the GitHub repo instead. That's the only
    network call it makes.

    Two kinds of zip:
      - Plugin (default): the skill plus the Enterprise MCP connector. Upload it in Cowork under
        Customize > Plugins > Upload plugin, or in the admin center under Agents > Tools > Registry.
      - Skill only (-SkillOnly): just the skill, in one folder. Upload it in Cowork under
        Customize > Skills > Add > Upload skill. No connector, so Cowork works from the files you attach.

.EXAMPLE
    .\New-CoworkPluginPackage.ps1 -ReferenceId "<OAuth client registration ID>"
    .\New-CoworkPluginPackage.ps1 -SkillOnly
#>
[CmdletBinding(DefaultParameterSetName = "Plugin")]
param(
    [Parameter(Mandatory, ParameterSetName = "Plugin")][string]$ReferenceId,
    [Parameter(Mandatory, ParameterSetName = "Skill")][switch]$SkillOnly,
    [string]$AppId = [guid]::NewGuid().ToString(),
    [string]$OutputFile = $(if ($SkillOnly) { ".\agent-tools-health.zip" } else { ".\AgentToolsHealth-Cowork.zip" }),
    [string]$GitHubBaseUrl = "https://raw.githubusercontent.com/chadmcox/Copilot/main/Agent%20and%20Tools%20Health%20Check/Cowork/plugin"
)

# Stop at the first error, so a failed download never produces a broken zip.
$ErrorActionPreference = "Stop"

# Every file in the plugin, relative to the plugin folder.
$pluginFiles = @(
    "manifest.json",
    "color.png",
    "outline.png",
    "skills/agent-tools-health/SKILL.md",
    "skills/agent-tools-health/references/rules.md",
    "skills/agent-tools-health/references/guidance.md",
    "skills/agent-tools-health/assets/report-template.html"
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

$work = Join-Path ([System.IO.Path]::GetTempPath()) "AgentToolsHealth-Cowork"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

if (Test-PluginFolder) {
    Copy-PluginFolder $work
}
else {
    Write-Host "The plugin folder isn't next to this script. Downloading it from GitHub."
    $pluginFiles | Get-PluginFromGitHub $work
}

if ($SkillOnly) {
    # The skill upload wants one folder holding SKILL.md and its references, and nothing else.
    New-ZipFile (Join-Path $work "skills/agent-tools-health") $OutputFile "agent-tools-health/"
    Write-Host "Saved $OutputFile. In Copilot Cowork, open Customize > Skills > Add > Upload skill and choose it."
}
else {
    Set-ManifestValues (Join-Path $work "manifest.json")
    # Everything sits at the root of the zip: manifest.json, icons and skills/.
    New-ZipFile $work $OutputFile
    Write-Host "Saved $OutputFile (app ID $AppId). Upload it in Cowork under Customize > Plugins > Upload plugin, or in the Microsoft 365 admin center under Agents > Tools > Registry > Upload. Not under Skills."
}
Remove-Item $work -Recurse -Force
