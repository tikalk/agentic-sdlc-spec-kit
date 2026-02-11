# Detect-WorkflowConfig.ps1
# Detects workflow mode and framework options from spec.md metadata
# Returns hashtable: @{mode="build|spec"; tdd=$true|$false; contracts=$true|$false; data_models=$true|$false; risk_tests=$true|$false}

function Get-WorkflowConfig {
    param(
        [string]$SpecFile = "spec.md"
    )
    
    # Default values (spec mode defaults)
    $mode = "spec"
    $tdd = $true
    $contracts = $true
    $data_models = $true
    $risk_tests = $true
    
    # If spec.md doesn't exist, return defaults
    if (-not (Test-Path $SpecFile)) {
        return @{
            mode = $mode
            tdd = $tdd
            contracts = $contracts
            data_models = $data_models
            risk_tests = $risk_tests
        }
    }
    
    # Extract mode (look for line: **Workflow Mode**: build|spec)
    $modeLine = Select-String -Path $SpecFile -Pattern "^\*\*Workflow Mode\*\*:" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($modeLine) {
        $modeValue = ($modeLine.Line -replace '.*:\s*', '').Trim()
        if ($modeValue -match '^(build|spec)$') {
            $mode = $modeValue
        }
    }
    
    # Set option defaults based on mode
    if ($mode -eq "build") {
        $tdd = $false
        $contracts = $false
        $data_models = $false
        $risk_tests = $false
    }
    
    # Extract and override with explicit options
    # Look for line: **Framework Options**: tdd=true, contracts=false, ...
    $optionsLine = Select-String -Path $SpecFile -Pattern "^\*\*Framework Options\*\*:" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($optionsLine) {
        $optionsText = ($optionsLine.Line -replace '.*:\s*', '').Trim()
        
        # Parse: tdd=true, contracts=false, data_models=true, risk_tests=true
        if ($optionsText -match 'tdd=(\w+)') {
            $tdd = $matches[1] -eq 'true'
        }
        if ($optionsText -match 'contracts=(\w+)') {
            $contracts = $matches[1] -eq 'true'
        }
        if ($optionsText -match 'data_models=(\w+)') {
            $data_models = $matches[1] -eq 'true'
        }
        if ($optionsText -match 'risk_tests=(\w+)') {
            $risk_tests = $matches[1] -eq 'true'
        }
    }
    
    # Return as hashtable
    return @{
        mode = $mode
        tdd = $tdd
        contracts = $contracts
        data_models = $data_models
        risk_tests = $risk_tests
    }
}

# Export function if module context
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function Get-WorkflowConfig
}

# If run directly, execute the function and output as JSON
if ($MyInvocation.InvocationName -ne '.' -and $PSCommandPath -eq $MyInvocation.MyCommand.Path) {
    $config = Get-WorkflowConfig @args
    $config | ConvertTo-Json -Compress
}
