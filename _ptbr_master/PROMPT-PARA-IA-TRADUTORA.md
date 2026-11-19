# Prompt para a IA tradutora

Você vai traduzir um arquivo de tradução (`.po`, formato gettext) do jogo
**Oxygen Not Included** para **português brasileiro**. O arquivo já está pronto:
cada texto a traduzir está duplicado em inglês no campo `msgstr`. Sua tarefa é
**editar apenas os campos `msgstr`**, substituindo o inglês pela tradução em PT-BR,
mexendo só nesse arquivo.

## Arquivo a traduzir

> (Aponte a IA para UM destes por vez. Comece pelos menores.)
>
> _(Sem arquivos pendentes no momento. Quando o script de aplicação detectar
> divergências semânticas, ele gera um prompt específico em
> `ultimo-prompt-divergencias.txt` ou os esqueletos novos aparecem em
> `_referencia\<id>_<Nome>\pt_BR.po`.)_

## Regras invioláveis

1. **Edite SOMENTE as linhas que começam com `msgstr`** (e suas linhas de
   continuação entre aspas, logo abaixo). Traduza o texto em inglês que está ali.
2. **NUNCA altere**: linhas `msgid`, linhas `msgctxt`, comentários (`#.`), nem o
   **bloco de cabeçalho** (a primeira entrada, do topo até a primeira linha em branco).
   O `msgid` é a referência original, ele permanece em inglês.
3. **Preserve exatamente, sem traduzir nem remover:**
   - **Marcadores de variável**: `{0}`, `{1}`, `{2}`, etc. Mantenha-os no texto.
   - **Alvos de link**: em `<link="ALGUMACOISA">texto</link>`, a palavra dentro das
     aspas (`ALGUMACOISA`) é um código, **não traduza**. Traduza só o `texto` visível.
     Ex.: `<link="CREATURES">Critters</link>` → `<link="CREATURES">Criaturas</link>`.
   - **Tags de estilo/markup**: `<style="...">`, `</style>`, `<b>`, `</b>`,
     `<color=...>`, `<link=...>`, `</link>`. A palavra dentro de `<style="X">`
     também é código, não traduza.
   - **Escapes**: `\n` (quebra de linha), `\"` (aspas), `\\`. Mantenha onde estão.
   - **A estrutura de aspas**: se o texto tiver várias linhas entre aspas
     (`msgstr ""` seguido de linhas `"..."`), mantenha o texto válido em gettext
     (cada trecho entre aspas). Pode manter o mesmo formato do `msgid` acima.
4. **Não adicione nem remova entradas.** Um `msgstr` para cada `msgid`.
5. Traduza com português natural e fluido. Nos textos de descrição/efeito o jogo
   costuma ter um tom levemente bem-humorado, mantenha esse espírito.

## Glossário (use estes termos para manter consistência com o jogo base)

| Inglês | PT-BR |
|---|---|
| Duplicant(s) | Duplicante(s) |
| Critter(s) | Criatura(s) |
| Power | Energia |
| Automation | Automação |
| Wire | Fio |
| Pipe / Conduit | Tubulação / Conduto |
| Liquid / Gas | Líquido / Gás |
| Building | Construção |
| Tile | Ladrilho |
| Door | Porta |
| Storage | Armazenamento |
| Germ(s) | Germe(s) |
| Heat / Temperature | Calor / Temperatura |
| Insulated | Isolado(a) |
| Refined Metal | Metal Refinado |
| Delivery / Supply | Entrega / Suprimento |
| Sweep / Sweeper | Varrer / Varredor |
| Watt / Wattage | Watt / Potência |

Na dúvida sobre um termo, use o equivalente da tradução oficial em PT-BR do jogo.

## Exemplo

Antes:
```
msgctxt "AsLimc.LaserTurret.LocStrings.LaserTurret.NAME"
msgid "<link=\"LASERTURRET\">Laser Turret</link>"
msgstr "<link=\"LASERTURRET\">Laser Turret</link>"
```
Depois (só o msgstr mudou):
```
msgctxt "AsLimc.LaserTurret.LocStrings.LaserTurret.NAME"
msgid "<link=\"LASERTURRET\">Laser Turret</link>"
msgstr "<link=\"LASERTURRET\">Torre de Laser</link>"
```

Ao terminar, salve o arquivo. Não crie outros arquivos.
