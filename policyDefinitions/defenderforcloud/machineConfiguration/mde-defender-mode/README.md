# Microsoft Defender for Endpoint mode

This Machine Configuration package audits or configures this Windows registry value:

- Key: `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection`
- Value: `ForceDefenderPassiveMode`
- Type: `REG_DWORD`
- `Active`: `0`
- `Passive`: `1`

The build generates two Azure Policy definitions:

- **Audit** reports the actual guest registry state without changing it.
- **Configure** applies the selected mode and autocorrects drift.

## Prerequisites

Use an **x64 PowerShell 7** process on Windows and install the official authoring modules. ARM64 PowerShell can't compile Windows DSC configurations, even when Windows x64 emulation is available.

```powershell
Install-Module GuestConfiguration -Scope CurrentUser
Install-Module PSDesiredStateConfiguration -RequiredVersion 2.0.7 -Scope CurrentUser
```

Run the build from that same x64 PowerShell 7 process:

```powershell
pwsh -NoProfile -File ./Build-MdeDefenderMode.ps1
```

If module discovery fails, verify the host and module path from the same terminal:

```powershell
$PSVersionTable
[System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
Get-Module -ListAvailable GuestConfiguration, PSDesiredStateConfiguration |
	Select-Object Name, Version, Path
$env:PSModulePath -split [System.IO.Path]::PathSeparator
```

For target Azure VMs, assign the built-in initiative **Deploy prerequisites to enable Guest Configuration policies on virtual machines**. It deploys the Machine Configuration extension and system-assigned managed identity. Register the `Microsoft.GuestConfiguration` resource provider if it isn't already registered.

## Build and publish

Create the `AuditAndSet` package:

```powershell
pwsh ./Build-MdeDefenderMode.ps1
```

Test the package from an elevated PowerShell 7 session:

```powershell
Get-GuestConfigurationPackageComplianceStatus -Path ./output/MdeDefenderModeConfig.zip
```

Publish `output/MdeDefenderModeConfig.zip` to an HTTPS location accessible by the managed machines. Azure Blob Storage is recommended. Then generate the audit and enforcement definitions with the exact published URI:

```powershell
pwsh ./Build-MdeDefenderMode.ps1 -ContentUri 'https://<account>.blob.core.windows.net/<container>/MdeDefenderModeConfig.zip?<sas>'
```

The generated JSON files are written below `output/policies`. The authoring cmdlet calculates and embeds the package content hash, so regenerate both definitions whenever the package changes.

Do not commit a long-lived SAS token. For private Blob Storage, use a managed-identity package access design instead of embedding credentials in source control.

## References

- [Azure Machine Configuration overview](https://learn.microsoft.com/azure/governance/machine-configuration/overview/01-overview-concepts)
- [Create a custom package](https://learn.microsoft.com/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package)
- [Create a custom policy definition](https://learn.microsoft.com/azure/governance/machine-configuration/how-to/create-policy-definition)