Configuration MdeDefenderModeConfig {
    Import-DscResource -ModuleName MdeDefenderMode -ModuleVersion '1.0.0'

    MdeDefenderMode DefenderForEndpointMode {
        Name = 'ForceDefenderPassiveMode'
        Mode = 'Active'
    }
}