param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Dest
)

# Reads a .po file, extracts header + each (#. + msgctxt + msgid) block,
# writes a pt_BR.po skeleton where msgstr is a copy of the English msgid
# (the project's workflow: another AI translates the msgstr lines).

$lines = Get-Content -LiteralPath $Source -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]

$header = @(
    'msgid ""'
    'msgstr ""'
    '"Project-Id-Version: \n"'
    '"POT-Creation-Date: \n"'
    '"PO-Revision-Date: \n"'
    '"Last-Translator: \n"'
    '"Language-Team: \n"'
    '"Language: pt_BR\n"'
    '"MIME-Version: 1.0\n"'
    '"Content-Type: text/plain; charset=UTF-8\n"'
    '"Content-Transfer-Encoding: 8bit\n"'
    '"Application: Oxygen Not Included POT Version: 2.0\n"'
    ''
)
foreach ($h in $header) { $out.Add($h) }

# Skip the existing header block of the source until first blank line
$i = 0
while ($i -lt $lines.Count -and $lines[$i].Trim() -ne '') { $i++ }
$i++

$state = 'idle'         # idle | id | str
$comment = $null
$ctxt = $null
$idLines = New-Object System.Collections.Generic.List[string]

function Flush() {
    if ($script:comment -ne $null) { $script:out.Add($script:comment) }
    if ($script:ctxt -ne $null) { $script:out.Add($script:ctxt) }
    if ($script:idLines.Count -gt 0) {
        $first = $script:idLines[0]
        $script:out.Add("msgid $first")
        for ($k = 1; $k -lt $script:idLines.Count; $k++) { $script:out.Add($script:idLines[$k]) }
        # msgstr mirrors msgid
        $script:out.Add("msgstr $first")
        for ($k = 1; $k -lt $script:idLines.Count; $k++) { $script:out.Add($script:idLines[$k]) }
    }
    $script:out.Add('')
    $script:comment = $null
    $script:ctxt = $null
    $script:idLines.Clear()
}

for (; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trim = $line.TrimStart()

    if ($trim -eq '') {
        if ($idLines.Count -gt 0) { Flush }
        continue
    }
    if ($trim.StartsWith('#.')) {
        if ($idLines.Count -gt 0) { Flush }
        $comment = $line
        continue
    }
    if ($trim.StartsWith('#')) { continue } # other comments
    if ($trim.StartsWith('msgctxt ')) {
        $ctxt = $line
        continue
    }
    if ($trim.StartsWith('msgid ')) {
        $idLines.Add($trim.Substring(6))
        $state = 'id'
        continue
    }
    if ($trim.StartsWith('msgstr ')) {
        $state = 'str'
        continue
    }
    if ($trim.StartsWith('"')) {
        if ($state -eq 'id') { $idLines.Add($trim) }
        continue
    }
}
if ($idLines.Count -gt 0) { Flush }

# Write
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($Dest, $out, $enc)
Write-Output ("Wrote {0} ({1} lines)" -f $Dest, $out.Count)
