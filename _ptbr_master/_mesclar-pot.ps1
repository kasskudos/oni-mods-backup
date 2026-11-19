<#
Mescla um master .po PT-BR com um template .pot novo do mod.
Resultado: <Master>.merged.po contendo:
 - Entradas existentes cuja msgctxt continua no .pot E msgid igual -> tradução preservada.
 - Entradas com msgid diferente -> tradução preservada MAS marcada com "#. [REVISAR: msgid mudou]".
 - Entradas novas no .pot -> esqueleto (msgstr = msgid).
 - Entradas órfãs no nosso -> descartadas (autor removeu).
A ordem segue o template (.pot). Cabeçalho original do master é preservado.
#>
param(
    [Parameter(Mandatory=$true)][string]$Master,
    [Parameter(Mandatory=$true)][string]$Pot,
    [string]$Out = $null
)
$ErrorActionPreference = 'Stop'
if (-not $Out) { $Out = "$Master.merged.po" }

function Read-PoBlocks {
    param([string]$Path)
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $i = 0
    $header = @()
    while ($i -lt $lines.Count -and $lines[$i].Trim() -ne '') { $header += $lines[$i]; $i++ }

    $blocks = @()
    while ($i -lt $lines.Count) {
        if ($lines[$i].Trim() -eq '') { $i++; continue }
        $cmt = @(); $ctxL = @(); $idL = @(); $strL = @()
        $state = 'cmt'
        while ($i -lt $lines.Count -and $lines[$i].Trim() -ne '') {
            $l = $lines[$i]
            $t = $l.TrimStart()
            if ($t.StartsWith('#')) { $cmt += $l }
            elseif ($t.StartsWith('msgctxt ')) { $state = 'ctx'; $ctxL += $l }
            elseif ($t.StartsWith('msgid '))   { $state = 'id';  $idL  += $l }
            elseif ($t.StartsWith('msgstr '))  { $state = 'str'; $strL += $l }
            elseif ($t.StartsWith('"')) {
                if     ($state -eq 'ctx') { $ctxL += $l }
                elseif ($state -eq 'id')  { $idL  += $l }
                elseif ($state -eq 'str') { $strL += $l }
            }
            $i++
        }
        # extrai ctx e msgid concatenados (sem aspas)
        $ctx = ''
        foreach ($cl in $ctxL) {
            $t = $cl.TrimStart()
            $body = if ($t.StartsWith('msgctxt ')) { $t.Substring(8).Trim() } else { $t.Trim() }
            if ($body.Length -ge 2 -and $body.StartsWith('"') -and $body.EndsWith('"')) {
                $ctx += $body.Substring(1, $body.Length - 2)
            }
        }
        $mid = ''
        foreach ($cl in $idL) {
            $t = $cl.TrimStart()
            $body = if ($t.StartsWith('msgid ')) { $t.Substring(6).Trim() } else { $t.Trim() }
            if ($body.Length -ge 2 -and $body.StartsWith('"') -and $body.EndsWith('"')) {
                $mid += $body.Substring(1, $body.Length - 2)
            }
        }
        $blocks += [PSCustomObject]@{
            Comment = $cmt; Ctx = $ctx; Msgid = $mid
            CtxLines = $ctxL; IdLines = $idL; StrLines = $strL
        }
    }
    return [PSCustomObject]@{ Header = $header; Blocks = $blocks }
}

$masterData = Read-PoBlocks -Path $Master
$potData    = Read-PoBlocks -Path $Pot

$ourByCtx = @{}
foreach ($b in $masterData.Blocks) { if ($b.Ctx -ne '') { $ourByCtx[$b.Ctx] = $b } }
$potCtxs = $potData.Blocks | ForEach-Object { $_.Ctx } | Where-Object { $_ -ne '' }

$nNovas = 0; $nMudou = 0; $nMantido = 0
$outLines = @()
$outLines += $masterData.Header
$outLines += ''

foreach ($pb in $potData.Blocks) {
    if ($pb.Ctx -eq '') { continue }
    foreach ($c in $pb.Comment) { $outLines += $c }
    $existing = $ourByCtx[$pb.Ctx]
    $useStrLines = $null
    if ($existing -and $existing.Msgid -eq $pb.Msgid) {
        $useStrLines = $existing.StrLines
        $nMantido++
    } elseif ($existing) {
        $outLines += '#. [REVISAR: msgid (texto ingles) mudou desde a ultima traducao]'
        $useStrLines = $existing.StrLines
        $nMudou++
    } else {
        $outLines += '#. [NOVA: traduzir]'
        $nNovas++
    }
    foreach ($l in $pb.CtxLines) { $outLines += $l }
    foreach ($l in $pb.IdLines)  { $outLines += $l }
    if ($useStrLines) {
        foreach ($l in $useStrLines) { $outLines += $l }
    } else {
        foreach ($l in $pb.IdLines) {
            $t = $l.TrimStart()
            if ($t.StartsWith('msgid ')) { $outLines += 'msgstr ' + $t.Substring(6) } else { $outLines += $l }
        }
    }
    $outLines += ''
}

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($Out, $outLines, $enc)
$orfas = @($ourByCtx.Keys | Where-Object { $_ -notin $potCtxs })
Write-Output "Wrote: $Out"
Write-Output "  Mantidas (msgid igual): $nMantido"
Write-Output "  Mudou msgid (revisar):  $nMudou"
Write-Output "  Novas (esqueleto):      $nNovas"
Write-Output "  Orfas descartadas:      $($orfas.Count)"
