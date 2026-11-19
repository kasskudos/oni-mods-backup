$ErrorActionPreference = 'Stop'
Add-Type -Path "$PSScriptRoot\mono.cecil.0.11.6\lib\net40\Mono.Cecil.dll"
foreach ($id in '1887986467','2094698134','1831438994') {
    $dll = Get-ChildItem "$PSScriptRoot\..\..\Steam\$id\*.dll" | Select-Object -First 1
    $assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($dll.FullName)
    $queue = [System.Collections.Generic.Queue[Mono.Cecil.TypeDefinition]]::new()
    foreach ($type in $assembly.MainModule.Types) { $queue.Enqueue($type) }
    $methods = @()
    while ($queue.Count) {
        $type = $queue.Dequeue()
        foreach ($nested in $type.NestedTypes) { $queue.Enqueue($nested) }
        if ($type.FullName -notmatch '(SmartPumpsStrings|AirlockDoorStrings|CritterInventoryStrings)') { continue }
        foreach ($method in $type.Methods | Where-Object Name -eq '.cctor') {
            $instructions = @($method.Body.Instructions | ForEach-Object {
                $operand = $_.Operand
                if ($operand -is [Mono.Cecil.MethodReference]) {
                    $operand = @{ name = $operand.FullName; parameters = $operand.Parameters.Count }
                } elseif ($operand -is [Mono.Cecil.FieldReference]) {
                    $operand = $operand.DeclaringType.FullName.Replace('/', '.') + '.' + $operand.Name
                } elseif ($operand -is [Mono.Cecil.TypeReference]) {
                    $operand = $operand.FullName
                }
                @{ opcode = $_.OpCode.Name; operand = $operand }
            })
            $methods += @{ type = $type.FullName; instructions = $instructions }
        }
    }
    $methods | ConvertTo-Json -Depth 8 | Set-Content "$PSScriptRoot\current-strings-$id.json" -Encoding UTF8
    $assembly.Dispose()
}
