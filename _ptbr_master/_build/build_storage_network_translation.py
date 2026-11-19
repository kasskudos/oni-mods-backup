import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / '_referencia/3732422991_StorageNetwork/steam-en.po'
texts = json.loads((ROOT / '_build/storage-network-texts.json').read_text(encoding='utf-8'))
translations = {}
for line in (ROOT / '_build/storage-network-ptbr.tsv').read_text(encoding='utf-8').splitlines():
    index, translation = line.split('\t', 1)
    index = int(index)
    assert index not in translations, index
    translations[index] = translation.replace(r'\n', '\n')
assert set(translations) == set(range(len(texts)))
mapping = {text: translations[index] for index, text in enumerate(texts)}
mapping.update({
    'Heat generated while the cold storage server cools. Lower target temperatures generate more heat.': 'Calor gerado durante o resfriamento do servidor refrigerado. Temperaturas desejadas mais baixas geram mais calor.',
    'Transfer this item to a target storage building in the current scene.': 'Transfere este item para uma construção de armazenamento no cenário atual.',
    'Progress': 'Progresso',
    '{0} order · batch x{1}': '{0} Ordem, Lote x{1}',
    '{0} product machines are waiting for materials; {1} machines are producing shortages.': '{0} máquinas do produto aguardando materiais; {1} máquinas produzindo o que falta.',
    '{0} machines are processing this order with {1} cores.': '{0} máquinas processando esta ordem com {1} núcleos.',
    '{0}, created on cycle {1}.': '{0}, criada no ciclo {1}.',
    'Complete': 'Concluída',
    'Abnormal Cancel': 'Cancelada por Anomalia',
})


def read_fields(block):
    result = {}
    field = None
    for line in block.splitlines():
        match = re.match(r'^(msgctxt|msgid|msgstr) (".*")$', line)
        if match:
            field = match[1]
            result[field] = ast.literal_eval(match[2])
        elif line.startswith('"') and field:
            result[field] += ast.literal_eval(line)
    return result


blocks = re.split(r'(?m)(?=^msgctxt )', source.read_text(encoding='utf-8-sig').strip())
result = []
count = 0
missing = []
for block in blocks:
    entry = read_fields(block)
    if not entry.get('msgctxt'):
        result.append(block.replace('Language: en', 'Language: pt_BR'))
        continue
    english = entry['msgstr']
    if english not in mapping:
        missing.append((entry['msgctxt'], english))
        continue
    translated = mapping[english]
    for original in [entry['msgid'], english]:
        assert sorted(re.findall(r'\{[^{}]+\}', original)) == sorted(re.findall(r'\{[^{}]+\}', translated)), (entry['msgctxt'], 'placeholders', original, translated)
        assert re.findall(r'</?(?:link|style|color|size|b|i)(?:=[^>]+|\s[^>]*)?>', original) == re.findall(r'</?(?:link|style|color|size|b|i)(?:=[^>]+|\s[^>]*)?>', translated), (entry['msgctxt'], 'markup', original, translated)
    assert english.count('\n') == translated.count('\n'), (entry['msgctxt'], 'newlines')
    assert not re.search(r'[\u4e00-\u9fff\ufffd]', translated), entry['msgctxt']
    original_part = block[:block.index('msgstr ')]
    result.append(original_part + 'msgstr ' + json.dumps(translated, ensure_ascii=False))
    count += 1
if missing:
    print(json.dumps(missing, ensure_ascii=False, indent=2))
    raise ValueError('Additional source entries need translation')
destination = ROOT / 'mods/3732422991_StorageNetwork'
destination.mkdir(parents=True, exist_ok=True)
for locale in ['pt_BR', 'pt']:
    content = '\n\n'.join(result).replace('Language: pt_BR', f'Language: {locale}') + '\n'
    (destination / f'{locale}.po').write_text(content, encoding='utf-8')
print(f'{count} entries translated; {len(mapping)} unique texts. Placeholders, markup, and line breaks validated.')
