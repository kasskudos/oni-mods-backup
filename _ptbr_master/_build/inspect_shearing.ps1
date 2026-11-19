$ErrorActionPreference = 'Stop'

Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"

function Get-AllTypes {
    param([Mono.Cecil.AssemblyDefinition] $Assembly)

    $pending = [System.Collections.Generic.Queue[Mono.Cecil.TypeDefinition]]::new()
    foreach ($module in $Assembly.Modules) {
        foreach ($type in $module.Types) {
            $pending.Enqueue($type)
        }
    }

    while ($pending.Count -gt 0) {
        $type = $pending.Dequeue()
        $type
        foreach ($nestedType in $type.NestedTypes) {
            $pending.Enqueue($nestedType)
        }
    }
}

function Show-MatchingTypes {
    param(
        [string] $AssemblyPath,
        [string] $TypePattern,
        [switch] $ShowAllInstructions
    )

    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($AssemblyPath)
    foreach ($type in (Get-AllTypes $assembly | Where-Object FullName -Match $TypePattern)) {
        "TYPE $($type.FullName)"
        foreach ($field in $type.Fields) {
            " FIELD $($field.FieldType.FullName) $($field.Name)"
        }
        foreach ($method in $type.Methods) {
            " METHOD $($method.FullName)"
            if (-not $method.HasBody) {
                continue
            }
            foreach ($instruction in $method.Body.Instructions) {
                $text = $instruction.ToString()
                if ($ShowAllInstructions -or $text -match 'Miser|Happ|Growth|Scale|Shear|Overcrowd|Crowd|Cramp|Effect') {
                    "   $text"
                }
            }
        }
    }
}

$managedPath = 'C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed'
$gameAssembly = Join-Path $managedPath 'Assembly-CSharp.dll'
$critterMod = Join-Path $PSScriptRoot '..\..\Steam\3010968005\NoCritterCram.dll'

if ($args.Count -gt 0 -and $args[0] -eq 'target') {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
    foreach ($type in (Get-AllTypes $assembly | Where-Object FullName -Match 'ModifierSet|DreckoConfig|GlossyDreckoConfig|FertilityShearable')) {
        foreach ($method in ($type.Methods | Where-Object Name -Match 'CreateCritteEffects|GetScaleGrowthName|CreatePrefab|CreateDrecko|Configure|InitializeStates|\.ctor')) {
            "METHOD $($method.FullName)"
            if ($method.HasBody) {
                foreach ($instruction in $method.Body.Instructions) {
                    "   $instruction"
                }
            }
        }
    }
    exit 0
}

if ($args.Count -gt 0 -and $args[0] -eq 'miserable') {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
    foreach ($type in (Get-AllTypes $assembly)) {
        foreach ($method in $type.Methods) {
            if (-not $method.HasBody) {
                continue
            }
            $hasTarget = @($method.Body.Instructions | Where-Object {
                $_.ToString() -match 'Miserable|MISERABLE|miserable'
            }).Count -gt 0
            if ($hasTarget -or $type.FullName -match '^HappinessMonitor') {
                "METHOD $($method.FullName)"
                foreach ($instruction in $method.Body.Instructions) {
                    "   $instruction"
                }
            }
        }
    }
    exit 0
}

if ($args.Count -gt 0 -and $args[0] -eq 'happyeffects') {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
    foreach ($type in (Get-AllTypes $assembly | Where-Object FullName -Match '^HappinessMonitor')) {
        foreach ($method in ($type.Methods | Where-Object Name -NotMatch '^InitializeStates$|^\.ctor$')) {
            "METHOD $($method.FullName)"
            if ($method.HasBody) {
                foreach ($instruction in $method.Body.Instructions) {
                    "   $instruction"
                }
            }
        }
    }
    exit 0
}

if ($args.Count -gt 0 -and $args[0] -eq 'happyctor') {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
    foreach ($type in (Get-AllTypes $assembly | Where-Object FullName -EQ 'HappinessMonitor')) {
        foreach ($field in $type.Fields) {
            "FIELD $($field.FieldType.FullName) $($field.Name)"
        }
        foreach ($method in ($type.Methods | Where-Object Name -EQ '.ctor')) {
            "METHOD $($method.FullName)"
            foreach ($instruction in $method.Body.Instructions) {
                "   $instruction"
            }
        }
    }
    exit 0
}

if ($args.Count -gt 0 -and $args[0] -eq 'effectrefs') {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
    foreach ($type in (Get-AllTypes $assembly)) {
        foreach ($method in $type.Methods) {
            if (-not $method.HasBody) {
                continue
            }
            $hasTarget = @($method.Body.Instructions | Where-Object {
                $_.ToString() -match 'miserableWildEffect|miserableTameEffect'
            }).Count -gt 0
            if ($hasTarget) {
                "METHOD $($method.FullName)"
                foreach ($instruction in $method.Body.Instructions) {
                    "   $instruction"
                }
            }
        }
    }
    exit 0
}

if ($args.Count -gt 0 -and $args[0] -eq 'modifierapi') {
    foreach ($assemblyName in @('Assembly-CSharp.dll', 'Assembly-CSharp-firstpass.dll')) {
        $path = Join-Path $managedPath $assemblyName
        $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($path)
        foreach ($type in (Get-AllTypes $assembly | Where-Object FullName -Match '^Klei\.AI\.(Modifier|Effect|AttributeModifier)$')) {
            "TYPE $($type.FullName)"
            foreach ($field in $type.Fields) {
                " FIELD $($field.Attributes) $($field.FieldType.FullName) $($field.Name)"
            }
            foreach ($property in $type.Properties) {
                " PROPERTY $($property.PropertyType.FullName) $($property.Name)"
            }
            foreach ($method in $type.Methods) {
                " METHOD $($method.Attributes) $($method.FullName)"
            }
        }
    }
    exit 0
}

Show-MatchingTypes $gameAssembly 'ScaleGrowthMonitor|WellFedShearable'
Show-MatchingTypes $critterMod '.' -ShowAllInstructions

"REFERENCES"
$game = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($gameAssembly)
foreach ($type in (Get-AllTypes $game)) {
    foreach ($method in $type.Methods) {
        if (-not $method.HasBody) {
            continue
        }
        $matches = @($method.Body.Instructions | Where-Object {
            $_.ToString() -match 'ScaleGrowth|SCALE_GROWTH|Miserable|Miser|Overcrowd|Crowd|Cramp'
        })
        if ($matches.Count -eq 0) {
            continue
        }
        "CALLER $($method.FullName)"
        foreach ($match in $matches) {
            "   $match"
        }
    }
}
