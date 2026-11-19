Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"
foreach ($id in @('3836529420', '3822615860', '3828419350')) {
    $dll = Get-ChildItem "$PSScriptRoot\..\..\Steam\$id\*.dll" | Select-Object -First 1
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($dll.FullName)
    $queue = [System.Collections.Generic.Queue[Mono.Cecil.TypeDefinition]]::new()
    foreach ($type in $assembly.MainModule.Types) { $queue.Enqueue($type) }
    $lines = @()
    while ($queue.Count) {
        $type = $queue.Dequeue()
        foreach ($nested in $type.NestedTypes) { $queue.Enqueue($nested) }
        foreach ($method in $type.Methods) {
            if (-not $method.HasBody) { continue }
            foreach ($instruction in $method.Body.Instructions) {
                if ($instruction.OpCode.Name -eq 'ldstr' -or ($instruction.OpCode.Name -match 'call' -and $instruction.Operand.ToString() -match 'Localiz|Translat|Strings::Add|RegisterForTranslation')) {
                    $lines += "$($type.FullName) | $($method.Name) | $instruction"
                }
            }
        }
    }
    $lines | Set-Content "$PSScriptRoot\strings-$id.txt" -Encoding UTF8
}
