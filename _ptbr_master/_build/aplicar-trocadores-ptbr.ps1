[CmdletBinding()]
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
$master = Split-Path $PSScriptRoot -Parent
Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"
$mapping = @{}
$json = Get-Content "$master\mods\3822615860_PairedHeatExchangers\strings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($property in $json.PSObject.Properties) { $mapping[$property.Name] = [string]$property.Value }
$path = Join-Path (Split-Path $master -Parent) 'Steam\3822615860\PairedHeatExchangers.dll'
if (-not (Test-Path -LiteralPath $path)) { return }
$bytes = [System.IO.File]::ReadAllBytes($path)
$stream = [System.IO.MemoryStream]::new($bytes, $false)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($stream)
$queue = [System.Collections.Generic.Queue[Mono.Cecil.TypeDefinition]]::new()
foreach ($type in $assembly.MainModule.Types) { $queue.Enqueue($type) }
$replaced = 0
$missing = @()
while ($queue.Count) {
    $type = $queue.Dequeue()
    foreach ($nested in $type.NestedTypes) { $queue.Enqueue($nested) }
    foreach ($method in $type.Methods) {
        if (-not $method.HasBody) { continue }
        foreach ($instruction in $method.Body.Instructions) {
            if ($instruction.OpCode.Name -ne 'ldstr') { continue }
            $original = [string]$instruction.Operand
            if ($mapping.ContainsKey($original)) {
                $translation = $mapping[$original]
                $sourceTokens = @([regex]::Matches($original, '\{[^{}]+\}') | ForEach-Object Value | Sort-Object)
                $targetTokens = @([regex]::Matches($translation, '\{[^{}]+\}') | ForEach-Object Value | Sort-Object)
                if (($sourceTokens -join '|') -cne ($targetTokens -join '|')) { throw "Marcadores diferentes: $original" }
                $instruction.Operand = $translation
                $replaced++
            } elseif ($original -match '[\p{IsCJKUnifiedIdeographs}]') {
                $missing += $original
            }
        }
    }
}
if ($missing.Count) { throw ('Textos novos sem traducao, DLL preservada: ' + ($missing -join '; ')) }
if ($replaced -eq 0) {
    Write-Host '  Paired Heat Exchangers: traducao ja aplicada.'
    $assembly.Dispose()
    $stream.Dispose()
    return
}
if ($DryRun) {
    Write-Host "  Paired Heat Exchangers: $replaced textos seriam traduzidos."
} else {
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $backup = Join-Path $master "_backups\PairedHeatExchangers.$hash.dll"
    if (-not (Test-Path -LiteralPath $backup)) { [System.IO.File]::WriteAllBytes($backup, $bytes) }
    $output = Join-Path $PSScriptRoot 'PairedHeatExchangers.ptbr.dll'
    $assembly.Write($output)
    Copy-Item -LiteralPath $output -Destination $path -Force
    Write-Host "  Paired Heat Exchangers: $replaced textos traduzidos, original preservado em _backups."
}
$assembly.Dispose()
$stream.Dispose()
