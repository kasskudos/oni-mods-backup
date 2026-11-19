# Traduções PT-BR dos mods de ONI (pasta-mestre)

Esta pasta é a **fonte da verdade** das nossas traduções. Ela fica **fora** de
`mods\Steam\`, então a Steam nunca a sobrescreve. O problema antigo era editar
os `.po` direto dentro de `mods\Steam\<id>\translations\`: a cada atualização do
mod, a Steam re-baixa a pasta e apaga nossa tradução.

## Como funciona

```
_ptbr_master\
  aplicar-traducoes.ps1     <- copia as traduções de volta pros mods
  mods\                     <- TRADUÇÕES QUE MANTEMOS (edite aqui!)
    2018291283_ModUpdater\pt_BR.po
    2094698134_AirlockDoor\pt_BR.po
    2435244304_BlueprintsFixed\pt.po
    2891895988_ClosestMaterial\pt_BR.po, pt.po
  _referencia\              <- templates + outros idiomas (p/ traduzir no futuro)
```

A pasta de cada mod é nomeada `<id>_<Nome>`. O `<id>` é o Workshop ID e é o que o
script usa pra achar `mods\Steam\<id>\translations\`. O **nome do arquivo** (ex.:
`pt_BR.po` vs `pt.po`) tem que ser exatamente o que aquele mod espera, não renomeie.

## Fluxo de uso

1. **Editar tradução** → edite o `.po` aqui em `mods\`, nunca dentro de `Steam\`.
2. **Aplicar no jogo** → rode o script (de preferência sempre antes de jogar, e
   obrigatoriamente depois de uma atualização de mod):

   ```powershell
   pwsh -File "C:\Users\PICHAU\Documents\Klei\OxygenNotIncluded\mods\_ptbr_master\aplicar-traducoes.ps1"
   ```

   Ver o que ele faria sem alterar nada:

   ```powershell
   pwsh -File "...\aplicar-traducoes.ps1" -DryRun
   ```

O script faz hash dos arquivos e só copia o que mudou. Antes de sobrescrever, ele
salva a versão da Steam como `<arquivo>.bak_steam`.

**Pré-checagem semântica (proteção contra perder strings novas):** antes de
sobrescrever um `.po`, o script compara `msgctxt` + `msgid` entre o seu master e
a versão da Steam. Se detectar qualquer uma destas três situações, ele **NÃO
sobrescreve esse arquivo** e marca como `[!] divergencia semantica`:

- `msgctxt` novos no Steam que não existem no seu master (strings novas);
- `msgctxt` órfãos no seu master que sumiram do Steam (refactor/remoção);
- mesmo `msgctxt` com `msgid` (texto em inglês) diferente.

No fim da execução, o script imprime um prompt pronto pra colar numa sessão do
Claude, com contexto + lista de arquivos + tarefa. O prompt também é salvo em
`_ptbr_master\ultimo-prompt-divergencias.txt`.

## Quando um mod for atualizado e ganhar strings novas

1. Rode o script. Se houver divergência, ele te avisa e gera o prompt.
2. Cole o prompt numa sessão nova do Claude. Ele lê master + Steam, decide se é
   refactor (re-mapear msgctxt), strings novas (esqueleto), ou mudança de msgid,
   e atualiza o master.
3. Rode o script de novo para empurrar o master atualizado pro Steam.

## Status atual

Protegidos (já traduzidos): Airlock Door, Blueprints fixed, Closest Material, Mod Updater.

Pendentes de tradução (material em `_referencia\`): Critter Inventory, Laser Turret,
Tiny Door Updated, No Manual Delivery, Gigawatt Wire, Ronivan's Legacy (grande, 918 strings).
