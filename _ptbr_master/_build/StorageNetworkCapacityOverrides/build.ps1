$ErrorActionPreference = 'Stop'
$managed = 'C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @(
    'Assembly-CSharp.dll',
    'Assembly-CSharp-firstpass.dll',
    '0Harmony.dll',
    'UnityEngine.dll',
    'UnityEngine.CoreModule.dll',
    'netstandard.dll'
) | ForEach-Object { '/reference:' + (Join-Path $managed $_) }
& $compiler /nologo /target:library /optimize+ `
    ('/out:' + (Join-Path $PSScriptRoot 'StorageNetworkCapacityOverrides.dll')) `
    @references (Join-Path $PSScriptRoot 'StorageNetworkCapacityOverrides.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
