function Discover-Directives {
    param(
        [string]$FeatureDescription,
        [string]$TeamDirectivesPath
    )
    
    if (-not (Test-Path $TeamDirectivesPath)) {
        $obj = @{
            candidates = @{
                constitution = ""
                personas = @()
                rules = @()
                skills = @()
                examples = @()
            }
            search_metadata = @{
                keywords = @()
                files_searched = 0
                files_with_matches = 0
            }
        }
        return $obj | ConvertTo-Json -Compress
    }
    
    $constitution = ""
    if (Test-Path "$TeamDirectivesPath/constitutions/constitution.md") {
        $constitution = "$TeamDirectivesPath/constitutions/constitution.md"
    } elseif (Test-Path "$TeamDirectivesPath/constitution.md") {
        $constitution = "$TeamDirectivesPath/constitution.md"
    }
    
    $obj = @{
        candidates = @{
            constitution = $constitution
            personas = @()
            rules = @()
            skills = @()
            examples = @()
        }
        search_metadata = @{
            keywords = @()
            files_searched = 0
            files_with_matches = 0
        }
    }
    return $obj | ConvertTo-Json -Compress
}

function Discover-Skills {
    param(
        [string]$FeatureDescription,
        [string]$TeamDirectivesPath,
        [string]$SkillsCachePath,
        [int]$MaxSkills = 5,
        [double]$Threshold = 0.7
    )
    
    New-Item -ItemType Directory -Path $SkillsCachePath -Force | Out-Null
    
    $cacheMarker = "$SkillsCachePath/.last_refresh"
    $currentTimestamp = [int][double]::Parse((Get-Date -UFormat %s))
    $oneDay = 86400
    
    $needRefresh = $false
    if (Test-Path $cacheMarker) {
        $lastRefresh = [int](Get-Content $cacheMarker)
        $age = $currentTimestamp - $lastRefresh
        if ($age -gt $oneDay) { 
            $needRefresh = $true 
        }
    } else {
        $needRefresh = $true
    }
    
    if ($needRefresh -and (Test-Path "$TeamDirectivesPath/skills")) {
        Write-Host "[specify] Refreshing skills cache (daily refresh)..." -ForegroundColor Yellow
        Copy-Item "$TeamDirectivesPath/skills/*" $SkillsCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $currentTimestamp | Out-File $cacheMarker
    }
    
    $requiredSkills = @()
    $blockedSkills = @()
    
    if (Test-Path "$TeamDirectivesPath/.skills.json") {
        $manifest = Get-Content "$TeamDirectivesPath/.skills.json" -Raw | ConvertFrom-Json
        
        if ($manifest.skills.required) {
            foreach ($skillId in $manifest.skills.required.PSObject.Properties.Name) {
                if ($manifest.skills.required.$skillId.url) {
                    $skillUrl = $manifest.skills.required.$skillId.url
                    $cacheDir = Join-Path $SkillsCachePath (Split-Path $skillId -Leaf)
                    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                    try {
                        Invoke-WebRequest -Uri $skillUrl -OutFile "$cacheDir/SKILL.md" -ErrorAction SilentlyContinue
                        if ((Test-Path "$cacheDir/SKILL.md") -and ((Get-Item "$cacheDir/SKILL.md").Length -gt 0)) {
                            $requiredSkills += "required:$skillId"
                        }
                    } catch { }
                } elseif ($skillId -like "local:*") {
                    $requiredSkills += "required:$skillId"
                } elseif ((Test-Path "$SkillsCachePath/$skillId") -and (Test-Path "$SkillsCachePath/$skillId/SKILL.md")) {
                    $requiredSkills += "required:$skillId"
                }
            }
        }
        
        if ($manifest.skills.blocked) {
            $blockedSkills = $manifest.skills.blocked
        }
    }
    
    $candidates = @()
    foreach ($skillId in $requiredSkills) {
        if ($blockedSkills -contains $skillId) { continue }
        
        $skillPath = if ($skillId -like "local:*") {
            $TeamDirectivesPath + "\" + ($skillId -replace "local:", "")
        } else {
            Join-Path $SkillsCachePath $skillId
        }
        
        $skillName = Split-Path $skillPath -Leaf
        if ((-not (Test-Path "$skillPath/SKILL.md")) -or ((Get-Item "$skillPath/SKILL.md").Length -eq 0)) { continue }
        
        $candidates += [PSCustomObject]@{
            id = "required:$skillName"
            name = $skillName
            source = "manifest"
            base_relevance = 1.0
        }
    }
    
    $candidates = $candidates[0..([Math]::Min($candidates.Count, $MaxSkills) - 1)]
    
    return @{
        candidates = $candidates
        last_refresh = Get-Date -UFormat "%Y-%m-%dT%H:%M:%SZ"
    } | ConvertTo-Json -Compress
}
