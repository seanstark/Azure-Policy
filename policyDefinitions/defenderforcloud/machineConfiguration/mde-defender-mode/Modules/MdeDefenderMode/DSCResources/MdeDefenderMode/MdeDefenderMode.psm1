$registrySubKey = 'SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection'
$registryValueName = 'ForceDefenderPassiveMode'

function Get-RegistryValue {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $registryKey = $null

    try {
        $registryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($registrySubKey)
        if ($null -eq $registryKey -or
            $registryKey.GetValueKind($registryValueName) -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
            return -1
        }

        return [int] $registryKey.GetValue($registryValueName)
    }
    catch {
        return -1
    }
    finally {
        if ($null -ne $registryKey) {
            $registryKey.Dispose()
        }
    }
}

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Passive')]
        [string] $Mode
    )

    $currentMode = if ((Get-RegistryValue) -eq 1) { 'Passive' } else { 'Active' }
    return @{
        Name = $Name
        Mode = $currentMode
    }
}

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Passive')]
        [string] $Mode
    )

    $expectedValue = if ($Mode -eq 'Passive') { 1 } else { 0 }
    return (Get-RegistryValue) -eq $expectedValue
}

function Set-TargetResource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Passive')]
        [string] $Mode
    )

    $registryPath = "HKLM:\$registrySubKey"
    $expectedValue = if ($Mode -eq 'Passive') { 1 } else { 0 }

    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty `
        -Path $registryPath `
        -Name $registryValueName `
        -PropertyType DWord `
        -Value $expectedValue `
        -Force | Out-Null
}

Export-ModuleMember -Function Get-TargetResource, Test-TargetResource, Set-TargetResource