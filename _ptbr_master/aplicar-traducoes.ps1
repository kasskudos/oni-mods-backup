<#
.SYNOPSIS
  Re-aplica as traducoes PT-BR mantidas em _ptbr_master\mods de volta para
  as pastas dos mods da Steam, que a Steam sobrescreve a cada atualizacao.

.DESCRIPTION
  Fonte da verdade: _ptbr_master\mods\<id>_<Nome>\<locale>.po
  Destino:          mods\Steam\<id>\translations\<locale>.po (ou loc\)

  Rode este script depois de cada atualizacao de mod (ou sempre antes de
  jogar). Antes de sobrescrever um arquivo, o script faz uma pre-checagem
  semantica (msgctxt + msgid) entre o nosso master e o que a Steam baixou.
  Se houver divergencias (strings novas, orfas, ou texto ingles mudado), o
  script NAO sobrescreve esse arquivo e imprime ao final um prompt pronto
  para colar no Claude resolver.

.EXAMPLE
  pwsh -File aplicar-traducoes.ps1
  pwsh -File aplicar-traducoes.ps1 -DryRun   # so mostra o que faria
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$master   = $PSScriptRoot
$modsRoot = Split-Path $master -Parent          # ...\mods
$steam    = Join-Path $modsRoot 'Steam'
$src      = Join-Path $master 'mods'

if (-not (Test-Path $steam)) { throw "Pasta Steam nao encontrada em: $steam" }

# --- mapa id -> titulo legivel (de mods.json) ---
$nomes = @{}
$modsJson = Join-Path $modsRoot 'mods.json'
if (Test-Path $modsJson) {
    try {
        foreach ($m in (Get-Content $modsJson -Raw | ConvertFrom-Json).mods) {
            $nomes[[string]$m.label.id] = $m.label.title
        }
    } catch {}
}

# --- parser .po: msgctxt -> msgid (concatenado de blocos multi-linha) ---
function Parse-Po {
    param([string]$Path)
    $entries = @{}
    $ctxBuf = New-Object System.Text.StringBuilder
    $idBuf  = New-Object System.Text.StringBuilder
    $state  = 'idle'   # idle | ctx | id | str
    $hasCtx = $false

    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trim = $line.TrimStart()

        $doFlush = $false
        if ($trim -eq '') { $doFlush = $true }
        elseif ($trim.StartsWith('msgctxt ') -and ($hasCtx -or $idBuf.Length -gt 0)) { $doFlush = $true }
        elseif ($trim.StartsWith('msgid ') -and $state -eq 'str') { $doFlush = $true }

        if ($doFlush) {
            if ($hasCtx) {
                $k = $ctxBuf.ToString()
                if ($k -ne '') { $entries[$k] = $idBuf.ToString() }
            }
            $ctxBuf.Clear() | Out-Null
            $idBuf.Clear()  | Out-Null
            $state  = 'idle'
            $hasCtx = $false
            if ($trim -eq '') { continue }
        }

        if ($trim.StartsWith('#')) { continue }

        if ($trim.StartsWith('msgctxt ')) {
            $rest = $trim.Substring(8).Trim()
            if ($rest.StartsWith('"') -and $rest.EndsWith('"') -and $rest.Length -ge 2) {
                $ctxBuf.Append($rest.Substring(1, $rest.Length - 2)) | Out-Null
            }
            $hasCtx = $true
            $state  = 'ctx'
            continue
        }
        if ($trim.StartsWith('msgid ')) {
            $rest = $trim.Substring(6).Trim()
            if ($rest.StartsWith('"') -and $rest.EndsWith('"') -and $rest.Length -ge 2) {
                $idBuf.Append($rest.Substring(1, $rest.Length - 2)) | Out-Null
            }
            $state = 'id'
            continue
        }
        if ($trim.StartsWith('msgstr ')) { $state = 'str'; continue }

        # Linhas de continuacao "..." -- acumulam no buffer do estado atual
        if ($trim.StartsWith('"') -and $trim.EndsWith('"') -and $trim.Length -ge 2) {
            $body = $trim.Substring(1, $trim.Length - 2)
            switch ($state) {
                'ctx' { $ctxBuf.Append($body) | Out-Null }
                'id'  { $idBuf.Append($body)  | Out-Null }
            }
        }
    }
    # flush final
    if ($hasCtx) {
        $k = $ctxBuf.ToString()
        if ($k -ne '') { $entries[$k] = $idBuf.ToString() }
    }
    return $entries
}

# Compara nosso master vs versao atual no Steam. Retorna objeto com listas.
function Diff-Po {
    param([string]$Ours, [string]$Theirs)
    $oursMap   = Parse-Po -Path $Ours
    $theirsMap = Parse-Po -Path $Theirs

    # Se algum dos dois nao tem msgctxt (ex: estilo Wireless Power),
    # nao temos como diffar semanticamente; sinalizamos NoCtx.
    if ($oursMap.Count -eq 0 -or $theirsMap.Count -eq 0) {
        return [PSCustomObject]@{
            NoCtx = $true; Novas = @(); Orfas = @(); MsgidMudou = @()
        }
    }

    $oursKeys   = [System.Collections.Generic.HashSet[string]]::new([string[]]@($oursMap.Keys))
    $theirsKeys = [System.Collections.Generic.HashSet[string]]::new([string[]]@($theirsMap.Keys))

    $novas = @($theirsMap.Keys | Where-Object { -not $oursKeys.Contains($_) })
    $orfas = @($oursMap.Keys   | Where-Object { -not $theirsKeys.Contains($_) })
    $mudou = @()
    foreach ($k in $oursMap.Keys) {
        if ($theirsMap.ContainsKey($k) -and $oursMap[$k] -ne $theirsMap[$k]) {
            $mudou += $k
        }
    }

    return [PSCustomObject]@{
        NoCtx = $false
        Novas = $novas
        Orfas = $orfas
        MsgidMudou = $mudou
    }
}

Write-Host ""
Write-Host "  APLICAR TRADUCOES PT-BR  -  Oxygen Not Included" -ForegroundColor Cyan
Write-Host ("  $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')") -ForegroundColor DarkGray
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray

$reaplicados = 0; $okMods = 0; $faltando = 0; $totalMods = 0
$atencao = New-Object System.Collections.Generic.List[object]

Get-ChildItem $src -Directory | Sort-Object Name | ForEach-Object {
    if (-not (Get-ChildItem -LiteralPath $_.FullName -Filter *.po -File)) { return }
    $id = $_.Name.Split('_')[0]
    $nome = if ($nomes[$id]) { $nomes[$id] } else { $_.Name.Substring($_.Name.IndexOf('_') + 1) }
    if ($nome.Length -gt 42) { $nome = $nome.Substring(0, 39) + '...' }
    $totalMods++
    $modDir = Join-Path $steam $id
    $destDir = $null
    foreach ($sub in 'translations', 'loc') {
        $cand = Join-Path $modDir $sub
        if (Test-Path $cand) { $destDir = $cand; break }
    }

    if (-not $destDir) {
        Write-Host ("  [!] {0,-44} mod nao instalado (sem translations/ nem loc/)" -f $nome) -ForegroundColor DarkYellow
        $faltando++
        return
    }

    $copiou = $false
    $alertou = $false
    Get-ChildItem $_.FullName -Filter *.po | ForEach-Object {
        $dest = Join-Path $destDir $_.Name
        if ($id -eq '3732422991') {
            $referenceCatalog = Join-Path $destDir 'en.po'
            if (Test-Path -LiteralPath $referenceCatalog) {
                $referenceDiff = Diff-Po -Ours $_.FullName -Theirs $referenceCatalog
                if (-not $referenceDiff.NoCtx -and (
                    $referenceDiff.Novas.Count -gt 0 -or
                    $referenceDiff.Orfas.Count -gt 0 -or
                    $referenceDiff.MsgidMudou.Count -gt 0
                )) {
                    $script:alertou = $true
                    $atencao.Add([PSCustomObject]@{
                        Id = $id; Nome = $nome; Arquivo = $_.Name
                        Master = $_.FullName; Steam = $referenceCatalog
                        Novas = $referenceDiff.Novas; Orfas = $referenceDiff.Orfas
                        Mudou = $referenceDiff.MsgidMudou
                    })
                    return
                }
            }
        }
        $igual = (Test-Path $dest) -and ((Get-FileHash $_.FullName).Hash -eq (Get-FileHash $dest).Hash)
        if ($igual) { return }

        # Pre-checagem semantica antes de sobrescrever
        if (Test-Path $dest) {
            $diff = Diff-Po -Ours $_.FullName -Theirs $dest
            $temIssue = (-not $diff.NoCtx) -and (
                $diff.Novas.Count -gt 0 -or $diff.Orfas.Count -gt 0 -or $diff.MsgidMudou.Count -gt 0
            )
            if ($temIssue) {
                $script:alertou = $true
                $atencao.Add([PSCustomObject]@{
                    Id     = $id
                    Nome   = $nome
                    Arquivo = $_.Name
                    Master = $_.FullName
                    Steam  = $dest
                    Novas  = $diff.Novas
                    Orfas  = $diff.Orfas
                    Mudou  = $diff.MsgidMudou
                })
                return
            }
        }

        if (-not $DryRun) {
            if (Test-Path $dest) { Copy-Item $dest "$dest.bak_steam" -Force }
            Copy-Item $_.FullName $dest -Force
        }
        $script:copiou = $true
    }

    if ($alertou) {
        Write-Host ("  [!] {0,-44} divergencia semantica (ver prompt no fim)" -f $nome) -ForegroundColor Magenta
    } elseif ($copiou) {
        $msg = if ($DryRun) { 'precisa reaplicar (a Steam sobrescreveu)' } else { 'RE-APLICADO (a Steam tinha sobrescrito)' }
        Write-Host ("  [>] {0,-44} {1}" -f $nome, $msg) -ForegroundColor Green
        $reaplicados++
    } else {
        Write-Host ("  [ok] {0,-43} ja esta no jogo" -f $nome) -ForegroundColor Gray
        $okMods++
    }
}

Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) {
    Write-Host "  (modo simulacao: nada foi alterado)" -ForegroundColor Cyan
}
elseif ($reaplicados -gt 0) {
    Write-Host ("  >> Reapliquei a traducao em {0} mod(s) que a Steam tinha sobrescrito." -f $reaplicados) -ForegroundColor Green
    Write-Host "  >> IMPORTANTE: reabra o jogo para ver as mudancas." -ForegroundColor Yellow
}
else {
    Write-Host ("  >> Tudo certo! Suas traducoes de {0} mod(s) ja estao no jogo." -f $okMods) -ForegroundColor Green
    Write-Host "  >> Nada precisou ser feito (nenhuma sobrescrita da Steam)." -ForegroundColor DarkGray
}
if ($faltando -gt 0) {
    Write-Host ("  >> {0} mod(s) da lista nao estao instalados na Steam." -f $faltando) -ForegroundColor DarkYellow
}

# --- Prompt para o Claude resolver mods com divergencia semantica ---
if ($atencao.Count -gt 0) {
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor Magenta
    Write-Host ("   ATENCAO: {0} arquivo(s) com divergencia semantica." -f $atencao.Count) -ForegroundColor Magenta
    Write-Host "   Esses NAO foram sobrescritos. Copie o bloco abaixo e" -ForegroundColor Magenta
    Write-Host "   cole numa sessao do Claude para revisar e atualizar:" -ForegroundColor Magenta
    Write-Host "  =========================================================" -ForegroundColor Magenta
    Write-Host ""

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('---8<--- INICIO DO PROMPT --->8---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Preciso que voce atualize traducoes PT-BR de mods do Oxygen Not Included.')
    [void]$sb.AppendLine('O script aplicar-traducoes.ps1 detectou divergencias semanticas entre a')
    [void]$sb.AppendLine('fonte da verdade (em mods\_ptbr_master\mods\) e a versao que a Steam')
    [void]$sb.AppendLine('acabou de baixar apos atualizacao do mod. Esses arquivos NAO foram')
    [void]$sb.AppendLine('sobrescritos: o master continua intacto, e a versao da Steam tambem.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Contexto do projeto: leia mods\_ptbr_master\README.md.')
    [void]$sb.AppendLine('Memoria do fluxo: ~\.claude\projects\<...>\memory\oni-traducao-ptbr-setup.md')
    [void]$sb.AppendLine('(se existir).')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Arquivos com pendencias:')
    [void]$sb.AppendLine('')
    $i = 1
    foreach ($a in $atencao) {
        [void]$sb.AppendLine(("{0}. {1} (ID {2}) - {3}" -f $i, $a.Nome, $a.Id, $a.Arquivo))
        [void]$sb.AppendLine(("   Master:      {0}" -f $a.Master))
        [void]$sb.AppendLine(("   Steam atual: {0}" -f $a.Steam))
        [void]$sb.AppendLine(("   Strings novas no Steam (nao existem no nosso): {0}" -f $a.Novas.Count))
        if ($a.Novas.Count -gt 0) {
            $amostra = ($a.Novas | Select-Object -First 5) -join ', '
            $extra = if ($a.Novas.Count -gt 5) { (" (+{0} mais)" -f ($a.Novas.Count - 5)) } else { '' }
            [void]$sb.AppendLine(("      ex: {0}{1}" -f $amostra, $extra))
        }
        [void]$sb.AppendLine(("   Strings orfas no nosso (sumiram do Steam): {0}" -f $a.Orfas.Count))
        if ($a.Orfas.Count -gt 0) {
            $amostra = ($a.Orfas | Select-Object -First 5) -join ', '
            $extra = if ($a.Orfas.Count -gt 5) { (" (+{0} mais)" -f ($a.Orfas.Count - 5)) } else { '' }
            [void]$sb.AppendLine(("      ex: {0}{1}" -f $amostra, $extra))
        }
        [void]$sb.AppendLine(("   Texto ingles (msgid) mudou para mesmo msgctxt: {0}" -f $a.Mudou.Count))
        if ($a.Mudou.Count -gt 0) {
            $amostra = ($a.Mudou | Select-Object -First 5) -join ', '
            $extra = if ($a.Mudou.Count -gt 5) { (" (+{0} mais)" -f ($a.Mudou.Count - 5)) } else { '' }
            [void]$sb.AppendLine(("      ex: {0}{1}" -f $amostra, $extra))
        }
        [void]$sb.AppendLine("")
        $i++
    }
    [void]$sb.AppendLine('Tarefa para cada arquivo acima:')
    [void]$sb.AppendLine(' 1. Leia o Master e a versao Steam.')
    [void]$sb.AppendLine(' 2. Decida o cenario:')
    [void]$sb.AppendLine('    (a) Refactor de namespace (orfas = novas, mesma quantidade, mesmo')
    [void]$sb.AppendLine('        texto ingles) -> mapeie nossas traducoes para as novas chaves.')
    [void]$sb.AppendLine('    (b) Strings novas que o autor adicionou -> mantenha o resto e gere')
    [void]$sb.AppendLine('        esqueleto (msgstr = msgid em ingles) para essas, listando')
    [void]$sb.AppendLine('        para tradutor humano/IA depois.')
    [void]$sb.AppendLine('    (c) msgid mudou -> reavalie a traducao existente.')
    [void]$sb.AppendLine('    (d) Misto -> aplique (a)+(b)+(c) conforme cada entrada.')
    [void]$sb.AppendLine(' 3. Atualize APENAS o arquivo Master. Nao toque no Steam.')
    [void]$sb.AppendLine(' 4. No final, rode novamente aplicar-traducoes.ps1 (pelo atalho ou')
    [void]$sb.AppendLine('    pwsh -File ...) para empurrar o Master atualizado pro Steam.')
    [void]$sb.AppendLine(' 5. Se gerou esqueletos novos, atualize a lista em')
    [void]$sb.AppendLine('    mods\_ptbr_master\PROMPT-PARA-IA-TRADUTORA.md com a contagem.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Cuidado conhecido (caso Ronivans): NAO use .po de outro idioma como')
    [void]$sb.AppendLine('base para preencher msgstr; traduza sempre a partir do msgid em ingles.')
    [void]$sb.AppendLine('Em arquivos .po as aspas vem escapadas (\"); ao validar links/tags,')
    [void]$sb.AppendLine('desescape antes do regex.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('---8<--- FIM DO PROMPT --->8---')

    Write-Host $sb.ToString() -ForegroundColor White

    # Salva tambem em arquivo para o usuario abrir/copiar com calma
    $promptFile = Join-Path $master 'ultimo-prompt-divergencias.txt'
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($promptFile, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
        Write-Host ("  (prompt tambem salvo em: {0})" -f $promptFile) -ForegroundColor DarkGray
    }
}

Write-Host ""
$heatExchangerTranslation = Join-Path $PSScriptRoot '_build\aplicar-trocadores-ptbr.ps1'
if (Test-Path -LiteralPath $heatExchangerTranslation) {
    & $heatExchangerTranslation -DryRun:$DryRun
}
Write-Host "  (pode fechar esta janela)" -ForegroundColor DarkGray
Write-Host ""
