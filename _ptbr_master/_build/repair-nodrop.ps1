[CmdletBinding()]
param([switch]$Install)
$ErrorActionPreference = 'Stop'
$master = Split-Path $PSScriptRoot -Parent
$target = Join-Path (Split-Path $master -Parent) 'Steam\1868454866\NoDrop.dll'
$expectedHash = '668BE85BBDD6D3344041F501E058E5C7E71B2F7C0162B26F32BB79B9250D349F'
$output = Join-Path $PSScriptRoot 'NoDrop.nullguard.dll'
Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"
$bytes = [IO.File]::ReadAllBytes($target)
$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
$stream = [IO.MemoryStream]::new($bytes, $false)
$resolver = [Mono.Cecil.DefaultAssemblyResolver]::new()
$resolver.AddSearchDirectory((Split-Path $target -Parent))
$resolver.AddSearchDirectory('C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed')
$parameters = [Mono.Cecil.ReaderParameters]::new()
$parameters.AssemblyResolver = $resolver
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($stream, $parameters)
try {
    if ($assembly.MainModule.Types.Name -contains 'PtbrMasterNoDropNullGuardV1') {
        Write-Host 'No Drop: null guards already installed.'
        return
    }
    if ($hash -ne $expectedHash) { throw 'Unrecognized NoDrop.dll version. Review the new binary before patching.' }
    $type = $assembly.MainModule.Types | Where-Object FullName -eq 'Ony.OxygenNotIncluded.NoDrop.FetchChore_FindFetchTarget'
    $method = $type.Methods | Where-Object Name -eq 'Prefix'
    if (-not $method) { throw 'Expected Prefix method was not found.' }
    $il = $method.Body.GetILProcessor()
    $instructions = @($method.Body.Instructions)
    $equality = ($instructions | Where-Object { $_.Operand -is [Mono.Cecil.MethodReference] -and $_.Operand.FullName -eq 'System.Boolean UnityEngine.Object::op_Equality(UnityEngine.Object,UnityEngine.Object)' } | Select-Object -First 1).Operand
    $itemStore = $instructions | Where-Object Offset -eq 0x50
    $pickupStore = $instructions | Where-Object Offset -eq 0x60
    $nextItem = $instructions | Where-Object Offset -eq 0x9a
    if ($itemStore.OpCode.Name -ne 'stloc.3' -or $pickupStore.OpCode.Name -ne 'stfld' -or $nextItem.OpCode.Name -ne 'ldloca.s' -or -not $equality) { throw 'Unexpected loop structure.' }
    $anchor = $itemStore.Next
    foreach ($instruction in @(
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $equality),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $nextItem)
    )) { $il.InsertBefore($anchor, $instruction) }
    $anchor = $pickupStore.Next
    foreach ($instruction in @(
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_S, $method.Body.Variables[4]),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $pickupStore.Operand),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $equality),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $nextItem)
    )) { $il.InsertBefore($anchor, $instruction) }
    $marker = [Mono.Cecil.TypeDefinition]::new('LocalFix', 'PtbrMasterNoDropNullGuardV1', [Mono.Cecil.TypeAttributes]::NotPublic, $assembly.MainModule.TypeSystem.Object)
    $assembly.MainModule.Types.Add($marker)
    $assembly.Write($output)
} finally {
    $assembly.Dispose()
    $stream.Dispose()
}

# Reopen the generated binary and verify both guards and all short branch ranges.
$check = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($output)
try {
    $patched = ($check.MainModule.Types | Where-Object FullName -eq $type.FullName).Methods | Where-Object Name -eq 'Prefix'
    $guards = @($patched.Body.Instructions | Where-Object { $_.OpCode.Name -eq 'brtrue' -and $_.Operand.OpCode.Name -eq 'ldloca.s' })
    if ($guards.Count -ne 2) { throw 'Generated binary does not contain both guards.' }
    foreach ($instruction in $patched.Body.Instructions) {
        if ($instruction.OpCode.OperandType -eq [Mono.Cecil.Cil.OperandType]::ShortInlineBrTarget) {
            $distance = $instruction.Operand.Offset - ($instruction.Offset + $instruction.GetSize())
            if ($distance -lt -128 -or $distance -gt 127) { throw 'Short branch exceeds its valid range.' }
        }
    }
} finally { $check.Dispose() }
Write-Host "Prepared and structurally verified: $output"
if ($Install) {
    if (Get-Process OxygenNotIncluded -ErrorAction SilentlyContinue) { throw 'Close ONI before installing the corrected DLL.' }
    $backup = Join-Path $master "_backups\NoDrop.$hash.dll"
    if (-not (Test-Path -LiteralPath $backup)) { [IO.File]::WriteAllBytes($backup, $bytes) }
    Copy-Item -LiteralPath $output -Destination $target -Force
    if ((Get-FileHash $target).Hash -ne (Get-FileHash $output).Hash) { throw 'Installed DLL hash verification failed.' }
    Write-Host "Installed null guards. Original DLL saved to $backup"
}
