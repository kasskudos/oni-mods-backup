import json
import re
import shutil
from datetime import datetime
from pathlib import Path

from audit_updated_translations import ROOT, parse


def extract(mod_id):
    methods = json.loads((ROOT / f'_build/current-strings-{mod_id}.json').read_text(encoding='utf-8-sig'))
    if isinstance(methods, dict):
        methods = [methods]
    result = {}
    for method in methods:
        stack = []
        for instruction in method['instructions']:
            opcode, operand = instruction['opcode'], instruction['operand']
            if opcode == 'ldstr':
                stack.append(operand)
            elif opcode.startswith('ldc.i4.'):
                suffix = opcode.removeprefix('ldc.i4.')
                stack.append(int(operand) if suffix == 's' else int(suffix))
            elif opcode == 'ldc.i4':
                stack.append(int(operand))
            elif opcode == 'newarr':
                stack.append([None] * stack.pop())
            elif opcode == 'dup':
                stack.append(stack[-1])
            elif opcode == 'stelem.ref':
                value, index, array = stack.pop(), stack.pop(), stack.pop()
                array[index] = value
            elif opcode == 'ldsfld':
                stack.append({'STRINGS.UI.PRE_KEYWORD': '<style="KKeyword">', 'STRINGS.UI.PST_KEYWORD': '</style>'}[operand])
            elif opcode == 'call':
                count = operand['parameters']
                args = stack[-count:] if count else []
                if count:
                    del stack[-count:]
                name = operand['name']
                if 'LocString::op_Implicit' in name:
                    value = args[0]
                elif 'System.String::Concat' in name:
                    value = ''.join(args[0] if isinstance(args[0], list) else args)
                elif 'FormatAsLink' in name:
                    target = args[1].replace('_', '').upper()
                    value = f'<link="{target}">{args[0]}</link>'
                elif 'FormatAsNegativeRate' in name:
                    value = f'<style="consumed">{args[0]}</style>'
                elif 'FormatAsAutomationState' in name:
                    state = 'logic_on' if args[1] == 0 else 'logic_off'
                    value = f'<b><style="{state}">{args[0]}</style></b>'
                else:
                    raise ValueError(name)
                stack.append(value)
            elif opcode == 'stsfld':
                result[operand] = {'msgctxt': operand, 'msgid': stack.pop()}
            elif opcode not in ('ret', 'nop'):
                raise ValueError(opcode)
        assert not stack, method['type']
    return result


def save(path, entries):
    header = 'msgid ""\nmsgstr ""\n"Language: pt_BR\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"\n'
    blocks = [header]
    for entry in entries.values():
        original, translated = entry['msgid'], entry['msgstr']
        assert translated, entry['msgctxt']
        assert sorted(re.findall(r'\{[^{}]+\}', original)) == sorted(re.findall(r'\{[^{}]+\}', translated)), entry
        assert re.findall(r'<[^>]+>', original) == re.findall(r'<[^>]+>', translated), entry
        blocks.append('\n'.join(f'{key} {json.dumps(entry[key], ensure_ascii=False)}' for key in ('msgctxt', 'msgid', 'msgstr')))
    backup = ROOT / '_backups' / f'{path.parent.name}.{datetime.now():%Y%m%d-%H%M%S}.po'
    shutil.copy2(path, backup)
    path.write_text('\n\n'.join(blocks) + '\n', encoding='utf-8')
    assert parse(path) == entries
    print(f'{path.parent.name}: {len(entries)} entries validated and saved.')


airlock_translations = {
    'BUILDING.STATUSITEMS.AIRLOCKSTOREDCHARGE.NAME': 'Carga Disponível: {0}/{1}',
    'BUILDING.STATUSITEMS.AIRLOCKSTOREDCHARGE.TOOLTIP': 'Esta porta possui <b>{0}</b> de <style="KKeyword">Energia</style> armazenada\n\nConsome até <style="consumed">{2}</style> por utilização',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.NAME': '<link="PAIRLOCKDOOR">Porta de Comporta de Ar</link>',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.DESC': 'É de mau gosto sugar para o espaço Duplicantes sem rota de fuga através de <link="PRESSUREDOOR">Comportas de Ar Mecanizadas</link>. As Portas de Comporta de Ar permitem a passagem segura dos Duplicantes sem perder nenhum de seus fluidos misteriosos.',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.EFFECT': 'Bloqueia o fluxo de <link="ELEMENTSLIQUID">Líquidos</link> e <link="ELEMENTSGAS">Gases</link>, mesmo enquanto os Duplicantes passam.\n\nNão permite passagem quando não há <link="POWER">Energia</link> disponível.\n\n<link="CRITTERS">Criaturas</link> nunca podem atravessar esta porta.',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.LOGIC_OPEN': 'Desbloquear/Bloquear',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.LOGIC_OPEN_ACTIVE': '<b><style="logic_on">Sinal Verde</style></b>: Desbloquear porta',
    'BUILDINGS.PREFABS.PAIRLOCKDOOR.LOGIC_OPEN_INACTIVE': '<b><style="logic_off">Sinal Vermelho</style></b>: Bloquear porta',
    'BUILDINGS.PREFABS.PAIRLOCKDOORINSULATED.NAME': '<link="PAIRLOCKDOORINSULATED">Porta de Comporta de Ar Isolada</link>',
    'BUILDINGS.PREFABS.PAIRLOCKDOORINSULATED.DESC': 'É de mau gosto sugar para o espaço Duplicantes sem rota de fuga através de <link="INSULATEDDOOR">Portas Isoladas</link>. As Portas de Comporta de Ar Isoladas permitem a passagem segura dos Duplicantes sem perder nenhum de seus fluidos misteriosos.',
    'BUILDINGS.PREFABS.PAIRLOCKDOORINSULATED.EFFECT': 'Bloqueia o fluxo de <link="ELEMENTSLIQUID">Líquidos</link> e <link="ELEMENTSGAS">Gases</link>, mesmo enquanto os Duplicantes passam.\n\nNão permite passagem quando não há <link="POWER">Energia</link> disponível.\n\n<link="CRITTERS">Criaturas</link> nunca podem atravessar esta porta.\n\nO fluxo de <link="HEAT">Calor</link> através desta porta é bastante reduzido.',
    'DUPLICANTS.MODIFIERS.PASSINGAIRLOCK.NAME': 'Atravessando Comporta de Ar',
    'DUPLICANTS.MODIFIERS.PASSINGAIRLOCK.TOOLTIP': 'Este Duplicante está atravessando uma <style="KKeyword">Porta de Comporta de Ar</style> e está temporariamente isolado do ambiente ao redor'
}

for mod_id in ['1887986467', '2094698134', '1831438994']:
    path = next((ROOT / 'mods').glob(f'{mod_id}_*')) / 'pt_BR.po'
    previous = parse(path)
    current = extract(mod_id)
    for key, entry in current.items():
        if mod_id == '2094698134':
            entry['msgstr'] = airlock_translations[key.removeprefix('PeterHan.AirlockDoor.AirlockDoorStrings.')]
        elif mod_id == '1831438994':
            assert previous[key]['msgid'] == entry['msgid']
            entry['msgstr'] = previous[key]['msgstr']
        else:
            if key in previous and previous[key]['msgid'] == entry['msgid']:
                entry['msgstr'] = previous[key]['msgstr']
                continue
            old_key = key.replace('PETERHAN_FILTERED', 'FILTERED')
            old = previous.get(old_key)
            if 'Deprecated building.' in entry['msgid']:
                entry['msgstr'] = 'Construção obsoleta. Continua funcionando, mas substitua pela versão atual quando possível.'
            elif '.UI.FRONTEND.' in key:
                entry['msgstr'] = {
                    'Filtered Gas Pump': 'Bomba de Gás Filtrante',
                    'Filtered Liquid Pump': 'Bomba de Líquido Filtrante',
                    'Vacuum Pump': 'Bomba de Vácuo',
                    'Power Consumption': 'Consumo de Energia',
                    'Pump Rate (kg/s)': 'Vazão da Bomba (kg/s)',
                }[entry['msgid']]
            else:
                assert old, key
                source = old['msgid'].replace('FILTEREDGASPUMP', 'PETERHANFILTEREDGASPUMP').replace('FILTEREDLIQUIDPUMP', 'PETERHANFILTEREDLIQUIDPUMP') if 'PETERHAN_FILTERED' in key else old['msgid']
                assert source == entry['msgid'], (key, source, entry['msgid'])
                entry['msgstr'] = old['msgstr'].replace('FILTEREDGASPUMP', 'PETERHANFILTEREDGASPUMP').replace('FILTEREDLIQUIDPUMP', 'PETERHANFILTEREDLIQUIDPUMP') if 'PETERHAN_FILTERED' in key else old['msgstr']
    save(path, current)

hvac_path = ROOT / 'mods/2499782382_HVACExpansion/pt_BR.po'
old = parse(hvac_path)
installed = parse(ROOT.parent / 'Steam/2499782382/translations/pt_BR.po')
renames = {'AUTOCONDESNER': 'AUTOCONDENSER', 'AUTOEVAPORTATOR': 'AUTOEVAPORATOR', 'GASREFRIGERATIONUNIT': 'GASREFRIGERATOR', 'LIQUIDREFRIGERATIONUNIT': 'LIQUIDREFRIGERATOR'}
updated = {}
for key, entry in old.items():
    entry = dict(entry)
    for before, after in renames.items():
        entry = {name: value.replace(before, after) for name, value in entry.items()}
    updated[entry['msgctxt']] = entry
assert set(updated) == set(installed)
assert all(updated[key]['msgid'] == installed[key]['msgid'] for key in updated)
save(hvac_path, updated)
