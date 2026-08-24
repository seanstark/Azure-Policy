[CmdletBinding()]
param(
    [Parameter()]
    [uri] $ContentUri,

    [Parameter()]
    [string] $OutputPath = (Join-Path $PSScriptRoot 'output')
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw "This script requires PowerShell 7. Run it with 'pwsh', not Windows PowerShell ('powershell.exe'). Current host: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

if ($IsWindows -and
    [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne
        [System.Runtime.InteropServices.Architecture]::X64) {
    throw 'Windows DSC configuration compilation requires an x64 PowerShell 7 process.'
}

$configurationName = 'MdeDefenderModeConfig'
$configurationPath = Join-Path $PSScriptRoot 'MdeDefenderModeConfig.ps1'
$modulePath = Join-Path $PSScriptRoot 'Modules'
$compiledPath = Join-Path $OutputPath 'compiled'
$packagePath = Join-Path $OutputPath "$configurationName.zip"
$policyPath = Join-Path $OutputPath 'policies'

$requiredModules = @(
    @{ Name = 'GuestConfiguration'; MinimumVersion = '3.4.2' }
    @{ Name = 'PSDesiredStateConfiguration'; MinimumVersion = '2.0.7' }
)

foreach ($requiredModule in $requiredModules) {
    $discoveredModules = @(Get-Module -ListAvailable -Name $requiredModule.Name)
    $availableModule = $discoveredModules |
        Where-Object {
            (-not $requiredModule.MinimumVersion -or $_.Version -ge [version] $requiredModule.MinimumVersion) -and
            (-not $requiredModule.RequiredVersion -or $_.Version -eq [version] $requiredModule.RequiredVersion)
        } |
        Select-Object -First 1

    if (-not $availableModule) {
        $versionRequirement = if ($requiredModule.RequiredVersion) {
            "version $($requiredModule.RequiredVersion)"
        }
        else {
            "version $($requiredModule.MinimumVersion) or later"
        }
        $discoveredVersions = if ($discoveredModules) {
            ($discoveredModules | ForEach-Object { "$($_.Version) at $($_.Path)" }) -join '; '
        }
        else {
            'none'
        }

        throw @"
Required module '$($requiredModule.Name)' $versionRequirement isn't available to this PowerShell process.
Host: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion) $([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)
Discovered versions: $discoveredVersions
PSModulePath: $env:PSModulePath
Install it from this same x64 PowerShell 7 process. See README.md for the command.
"@
    }
}

New-Item -ItemType Directory -Path $compiledPath -Force | Out-Null
$env:PSModulePath = "$modulePath$([System.IO.Path]::PathSeparator)$env:PSModulePath"

Import-Module PSDesiredStateConfiguration
Import-Module GuestConfiguration
. $configurationPath
MdeDefenderModeConfig -OutputPath $compiledPath

$compiledMof = Join-Path $compiledPath 'localhost.mof'
$namedMof = Join-Path $compiledPath "$configurationName.mof"
Move-Item -Path $compiledMof -Destination $namedMof -Force

$packageParameters = @{
    Name          = $configurationName
    Configuration = $namedMof
    Path          = $OutputPath
    Type          = 'AuditAndSet'
    Force         = $true
}
New-GuestConfigurationPackage @packageParameters | Out-Host

if (-not $ContentUri) {
    Write-Host "Package created at '$packagePath'."
    Write-Host 'Publish it to an HTTPS location, then rerun this script with -ContentUri to generate the policies.'
    return
}

if (-not $ContentUri.IsAbsoluteUri -or $ContentUri.Scheme -ne 'https') {
    throw "ContentUri must be an absolute HTTPS URL. Received: '$ContentUri'."
}

$downloadPath = Join-Path ([System.IO.Path]::GetTempPath()) "MdeDefenderModeConfig-$([guid]::NewGuid()).zip"
$extractPath = "$downloadPath-extracted"

try {
    Write-Host "Validating package URL '$ContentUri'..."
    $response = Invoke-WebRequest -Uri $ContentUri -OutFile $downloadPath -PassThru
    if ($response.StatusCode -ne 200 -or (Get-Item $downloadPath).Length -eq 0) {
        throw "The package download returned HTTP $($response.StatusCode) or an empty response."
    }

    Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
    $downloadedMof = Join-Path $extractPath "$configurationName.mof"
    if (-not (Test-Path $downloadedMof -PathType Leaf)) {
        throw "The downloaded file isn't the expected Machine Configuration package. '$configurationName.mof' wasn't found at the ZIP root."
    }

    Write-Host "Package URL validated: HTTP $($response.StatusCode), $((Get-Item $downloadPath).Length) bytes."
}
catch {
    $details = @($_.Exception.Message, $_.ErrorDetails.Message) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
    throw "Unable to download or validate ContentUri '$ContentUri'. $($details -join ' ') Verify that the GitHub release and asset are public and that this machine can follow the download redirect."
}
finally {
    Remove-Item -Path $downloadPath, $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $policyPath -Force | Out-Null

$policyParameter = @(
    @{
        Name                 = 'DefenderMode'
        DisplayName          = 'Defender for Endpoint mode'
        Description          = 'Active writes ForceDefenderPassiveMode as DWORD 0. Passive writes it as DWORD 1.'
        ResourceType         = 'MdeDefenderMode'
        ResourceId           = 'DefenderForEndpointMode'
        ResourcePropertyName = 'Mode'
        DefaultValue         = 'Active'
        AllowedValues        = @('Active', 'Passive')
    }
)

$commonPolicyParameters = @{
    ContentUri    = $ContentUri.AbsoluteUri
    Platform      = 'Windows'
    PolicyVersion = '1.0.0'
    Parameter     = $policyParameter
}

$auditPolicyParameters = $commonPolicyParameters + @{
    PolicyId    = 'c706322c-4437-4fd6-a965-2bdb55de9caf'
    DisplayName = 'Audit Microsoft Defender for Endpoint mode on Windows machines'
    Description = 'Audits ForceDefenderPassiveMode in the Windows registry by using Azure Machine Configuration.'
    Path        = (Join-Path $policyPath 'audit')
    Mode        = 'Audit'
}
try {
    Write-Host 'Generating Audit policy definition...'
    New-GuestConfigurationPolicy @auditPolicyParameters | Out-Host
}
catch {
    $details = @($_.Exception.Message, $_.ErrorDetails.Message, $_.Exception.InnerException.Message) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
    throw "Audit policy generation failed with GuestConfiguration $((Get-Module GuestConfiguration).Version): $($details -join ' | ')"
}

$enforcementPolicyParameters = $commonPolicyParameters + @{
    PolicyId    = '3864c9e3-3c18-49d3-8290-118fd3b8681d'
    DisplayName = 'Configure Microsoft Defender for Endpoint mode on Windows machines'
    Description = 'Configures and autocorrects ForceDefenderPassiveMode in the Windows registry by using Azure Machine Configuration.'
    Path        = (Join-Path $policyPath 'configure')
    Mode        = 'ApplyAndAutoCorrect'
}
try {
    Write-Host 'Generating ApplyAndAutoCorrect policy definition...'
    New-GuestConfigurationPolicy @enforcementPolicyParameters | Out-Host
}
catch {
    $details = @($_.Exception.Message, $_.ErrorDetails.Message, $_.Exception.InnerException.Message) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
    throw "ApplyAndAutoCorrect policy generation failed with GuestConfiguration $((Get-Module GuestConfiguration).Version): $($details -join ' | ')"
}

Write-Host "Policy definitions created under '$policyPath'."