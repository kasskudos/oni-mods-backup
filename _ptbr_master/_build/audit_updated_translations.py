import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def parse(path):
    entries = []
    current = {}
    field = None
    for line in path.read_text(encoding='utf-8-sig').splitlines() + ['']:
        if not line.strip():
            if current:
                entries.append(current)
            current = {}
            field = None
            continue
        match = re.match(r'^(msgctxt|msgid|msgstr) (".*")$', line)
        if match:
            field = match[1]
            current[field] = ast.literal_eval(match[2])
        elif line.startswith('"') and field:
            current[field] += ast.literal_eval(line)
    return {entry['msgctxt']: entry for entry in entries if entry.get('msgctxt')}


for mod_id in (['1887986467', '2094698134', '2047308624', '1831438994', '2499782382'] if __name__ == '__main__' else []):
    directory = next((ROOT / 'mods').glob(f'{mod_id}_*'))
    master = parse(directory / 'pt_BR.po')
    installed_dir = ROOT.parent / 'Steam' / mod_id / 'translations'
    templates = sorted(installed_dir.glob('*.pot')) or sorted(installed_dir.glob('*.po'))
    print(f'\n{directory.name}: {len(master)} entries in master')
    for path in templates:
        try:
            other = parse(path)
        except (SyntaxError, ValueError) as error:
            print(f'{path.name}: invalid source catalog: {error}')
            continue
        added = set(other) - set(master)
        removed = set(master) - set(other)
        changed = [key for key in master.keys() & other.keys() if master[key]['msgid'] != other[key]['msgid']]
        print(f'{path.name}: {len(other)} entries, added={len(added)}, removed={len(removed)}, changed={len(changed)}')
        if path.suffix == '.pot' or mod_id == '2499782382':
            for key in sorted(added):
                print('NEW', key, json.dumps(other[key]['msgid'], ensure_ascii=False))
            for key in sorted(changed):
                print('CHANGED', key, json.dumps(other[key]['msgid'], ensure_ascii=False))
    for key, entry in master.items():
        if not entry.get('msgstr'):
            print('EMPTY', key)
        if sorted(re.findall(r'\{[^{}]+\}', entry['msgid'])) != sorted(re.findall(r'\{[^{}]+\}', entry['msgstr'])):
            print('BAD_PLACEHOLDERS', key)
