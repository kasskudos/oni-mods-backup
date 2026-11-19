param([string]$Target)
$ErrorActionPreference = 'Stop'
Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"
$master = Split-Path $PSScriptRoot -Parent
$map = @{}
$json = Get-Content "$master\mods\3822615860_PairedHeatExchangers\strings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($p in $json.PSObject.Properties) { $map[$p.Name] = [string]$p.Value }
function Get-Snapshot([string]$Path, [bool]$Translate) {
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($Path)
    $queue = [System.Collections.Generic.Queue[Mono.Cecil.TypeDefinition]]::new()
    foreach ($type in $assembly.MainModule.Types) { $queue.Enqueue($type) }
    $result = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count) {
        $type = $queue.Dequeue()
        foreach ($nested in $type.NestedTypes) { $queue.Enqueue($nested) }
        $result.Add($type.FullName)
        foreach ($field in $type.Fields) { $result.Add($field.FullName) }
        foreach ($method in $type.Methods) {
            $result.Add($method.FullName)
            if (-not $method.HasBody) { continue }
            foreach ($instruction in $method.Body.Instructions) {
                $operand = [string]$instruction.Operand
                if ($instruction.Operand -is [Mono.Cecil.Cil.Instruction]) { $operand = [string]$instruction.Operand.Offset }
                if ($instruction.Operand -is [Mono.Cecil.Cil.Instruction[]]) { $operand = ($instruction.Operand | ForEach-Object Offset) -join ',' }
                if ($Translate -and $instruction.OpCode.Name -eq 'ldstr' -and $map.ContainsKey($operand)) { $operand = $map[$operand] }
                $result.Add("$($instruction.Offset)|$($instruction.OpCode.Name)|$operand")
            }
            foreach ($handler in $method.Body.ExceptionHandlers) { $result.Add([string]$handler) }
        }
    }
    $assembly.Dispose()
    return $result
}
$backup = Get-ChildItem "$master\_backups\PairedHeatExchangers.*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$expected = Get-Snapshot $backup.FullName $true
if (-not $Target) { $Target = "$master\..\Steam\3822615860\PairedHeatExchangers.dll" }
$actual = Get-Snapshot $Target $false
if (($expected -join "`n") -cne ($actual -join "`n")) {
    for ($i = 0; $i -lt [Math]::Min($expected.Count, $actual.Count); $i++) {
        if ($expected[$i] -cne $actual[$i]) { Write-Host "EXPECTED $($expected[$i])`nACTUAL $($actual[$i])"; break }
    }
    throw 'Unexpected assembly change.'
}
Write-Host "Validado: $($actual.Count) registros de tipos, campos, metodos e instrucoes; somente os textos mapeados mudaram."
