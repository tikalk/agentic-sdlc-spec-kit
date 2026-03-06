# Detect-WorkflowConfig.ps1
# Returns framework options from spec.md metadata
# Returns default framework options for spec-driven development

function Get-WorkflowConfig {
    # Return default framework options
    return @{
        tdd = $true
        contracts = $true
        data_models = $true
        risk_tests = $true
    }
}

# Export function if module context
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function Get-WorkflowConfig
}

# If run directly, execute the function and output as JSON
if ($MyInvocation.InvocationName -ne '.' -and $PSCommandPath -eq $MyInvocation.MyCommand.Path) {
    $config = Get-WorkflowConfig
    $config | ConvertTo-Json -Compress
}
