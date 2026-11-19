import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'Steam/3828419350/translations/ja.po'
translations = r'''radiação insuficiente ({0} de {1} rads)
radiação excessiva ({0}, máximo de {1} rads)
frio demais ({0}, requer {1})
quente demais ({0}, máximo de {1})
atmosfera inadequada (requer {0})
pressão muito baixa ({0} de {1} por ladrilho)
pressão muito alta ({0}, máximo de {1} por ladrilho)
claridade excessiva ({0} lux, requer escuridão)
luz insuficiente ({0} de {1} lux)
requer {0}
sem polinização
acima da superfície da água (aumente o nível do tanque)
{0} de {1} células: {2}
vazio (forneça líquido por tubulação)
a da sala ({0}, {1} por ladrilho)
({0} por ladrilho)
{0} (temperatura da sala)
{0} (isolado)
{0} (aquecendo até {1})
{0} (resfriando até {1})
{0} (regulado para {1})
tudo certo
1 problema
{0} problemas
Energia
Sem energia: a iluminação e a regulação térmica estão desligadas
Com energia, consumindo {0}
Nada precisa de energia no momento
Ambiente
Temperatura {0}
Atmosfera: {0}
Luz: {0} lux (sala: {1}, iluminação interna: {2})
Radiação: {0} rads (sala: {1}, lâmpada: {2})
Lâmpada de radiação consumindo {0} de Fosforita para as plantas mutantes
A lâmpada de radiação precisa de Fosforita para fornecer {0} rads às plantas mutantes
Pesquisa
{0}: requer {1}
Iluminação interna
Toque do Fazendeiro
Isolamento
Aquecimento
Resfriamento
Plantas (domesticadas)
Plantas (selvagens)
{0} {1}: crescendo, {2}%
{0} {1}: crescida, convertendo {2} em {3}
{0} {1}: sem crescer, {2}
{0}: {1} galhos, {2} prontos para colher (até {3})
Néctar: {0} de {1} nas árvores; a luz permite {2}% da produção máxima ({3} lux)
Os galhos precisam de luz para crescer: {0} de {1} lux
{0}: {1} de {2} segmentos da trepadeira crescidos, {3} figos maduros
Mimikas: {0} no tanque, {1} de {2} plantas polinizadas
Viveiro de Mimikas fechado ao redor dos brotos ({0}), {1}
Precisa de polinização: ative a Polinização por Mimikas
Precisa de polinização, mas os Brotos de Mimika precisam de dois espaços livres (somente plantas que ocupam um espaço)
Toque do Fazendeiro: {0} de {1} plantas cuidadas
Sem {0} ({1})
forneça por tubulação
Sem {0} no tanque (forneça por tubulação)
aguardando entrega
Sem plantas: escolha uma na aba de configuração
<link="SAITOGREENHOUSE">Estufa</link>
Dezoito espaços de cultivo em três prateleiras, atrás do vidro.
Cultiva 18 plantas em três prateleiras de seis (escolha a planta na aba de configuração). As prateleiras se adaptam à planta: bandejas suspensas para plantas de teto, como a Pimenta Pincha, dois níveis de três para árvores e uma trepadeira para o Nó de Ovagro.\n\nDuplicantes entregam as sementes, o fertilizante e a água, e colhem as plantas maduras na base. Cada planta segue as regras do cultivo original: temperatura, atmosfera e pressão, luz ou escuridão, radiação e mutações.\n\nForneça gás por tubulação para criar uma atmosfera própria ou utilize a atmosfera da sala. Uma tubulação de líquido e um trilho de transporte podem fornecer água e sólidos no lugar dos Duplicantes.\n\nRecursos integrados, liberados pela pesquisa da construção original correspondente: iluminação para plantas que precisam de luz (consumo proporcional à luz acrescentada), Toque do Fazendeiro, isolamento e regulação térmica. No Spaced Out, uma lâmpada de radiação consome Fosforita como os Insetos Brilhantes para fornecer a radiação necessária às plantas mutantes.
<link="SAITOAQUATICGREENHOUSE">Estufa Aquática</link>
Dezoito espaços de cultivo subaquático em três prateleiras, dentro de um tanque de vidro.
Cultiva 18 plantas subaquáticas, como Alface Aquática, Tublia e Starnacle, em três prateleiras de seis, com bandejas suspensas para Seakomb (escolha a planta na aba de configuração).\n\nForneça líquido por tubulação para encher o tanque até o nível definido: ele fornece a água e o ambiente das plantas; prateleiras acima da superfície não permitem o crescimento. Duplicantes entregam as sementes e o fertilizante sólido e fazem a colheita na base; uma saída de líquido escoa as colheitas líquidas.\n\nRecursos integrados, liberados pela pesquisa da construção original correspondente: iluminação para plantas que precisam de luz, Toque do Fazendeiro e regulação térmica de todo o tanque (um Aquecedor de Líquidos e um Aquarregulador).
<link="SAITOGREENHOUSE">Estufa</link>
Dezoito espaços de cultivo em três prateleiras, atrás do vidro.
Cultiva 18 plantas em três prateleiras de seis (escolha a planta na aba de configuração). As prateleiras se adaptam à planta: bandejas suspensas para plantas de teto, como a Pimenta Pincha, dois níveis de três para árvores e uma trepadeira para o Nó de Ovagro.\n\nDuplicantes entregam as sementes, o fertilizante e a água, e colhem as plantas maduras na base. Cada planta segue as regras do cultivo original: temperatura, atmosfera e pressão, luz ou escuridão, radiação e mutações.\n\nForneça gás por tubulação para criar uma atmosfera própria ou utilize a atmosfera da sala. Uma tubulação de líquido e um trilho de transporte podem fornecer água e sólidos no lugar dos Duplicantes.\n\nRecursos integrados, liberados pela pesquisa da construção original correspondente: iluminação para plantas que precisam de luz (consumo proporcional à luz acrescentada), Toque do Fazendeiro, isolamento e regulação térmica. No Spaced Out, uma lâmpada de radiação consome Fosforita como os Insetos Brilhantes para fornecer a radiação necessária às plantas mutantes.
Aplicando Toque do Fazendeiro em {Target}
Este Duplicante está cuidando das plantas em {Target} para acelerar seu crescimento
Plantas: {0} plantadas, {1} crescendo, {2} maduras
Plantas: {0} plantadas, {1} crescendo, {2} maduras
Atmosfera: {0}
Atmosfera: {0}
Temperatura: {0}
Temperatura: {0}
Plantas sem crescer: {0}
Plantas sem crescer: {0}
Diagnóstico: {0}
Diagnóstico: {0}
Pesquisa necessária: {0}
Plantas: Domesticadas
Plantas: Selvagens
Plantas domesticadas crescem na velocidade normal e precisam de fertilizante e água, como em um ladrilho de cultivo. Plantas selvagens crescem a um quarto da velocidade e não consomem recursos, como as plantas na natureza.
Colheita Automática: Ligada
Colheita Automática: Desligada
Ligada: Duplicantes colhem assim que as plantas amadurecem. Desligada: as plantas maduras aguardam até você pressionar Colher, como uma planta original com a colheita automática desligada. Como no jogo original, uma planta deixada madura solta sua colheita sozinha após algum tempo (4 ciclos para a maioria das plantas).
Colher
Solicita que um Duplicante colha as plantas maduras agora.
Toque do Fazendeiro: Ligado
Toque do Fazendeiro: Desligado
Uma Estação Agrícola integrada: um Duplicante com a habilidade Toque do Fazendeiro cuida de cada planta usando 5 kg de Fertilizante, acelerando seu crescimento por algum tempo, como uma Estação Agrícola original.
Polinização por Mimikas: Ligada
Polinização por Mimikas: Desligada
Dois espaços no centro da prateleira intermediária cultivam Brotos de Mimika no lugar da planta escolhida (com plantas suspensas, ficam em um pequeno viveiro no piso dessa fileira). Cada broto libera uma Mimika na estufa aproximadamente a cada 5 ciclos; Mimikas vivem 5 ciclos, polinizam uma planta em crescimento por minuto (+25% de crescimento por 600 s) e endurecem, virando Mimillet (uma semente de Broto de Mimika), ao morrer. Hastes de Sweatcorn murcham sem polinização.\n\nQuando a estufa está quente ou fria demais, ou com uma atmosfera inadequada para os brotos, um pequeno viveiro se fecha ao redor deles e mantém condições adequadas consumindo 20 W; sua porta abre para liberar cada Mimika.
Disponível apenas para plantas que ocupam um espaço: árvores, o Nó de Ovagro e plantas largas não deixam espaço para Brotos de Mimika.
Galhos de Bonbon: Colher Madeira
Galhos de Bonbon: Manter para Néctar
Manter: os galhos da Árvore Bonbon permanecem na árvore e produzem Néctar. Colher: Duplicantes cortam galhos crescidos para obter 75 kg de Madeira por galho, como na colheita original; um galho cortado não produz Néctar até crescer novamente.
Isolamento: Ligado
Isolamento: Desligado
Isolado: o interior assume a temperatura do gás fornecido por tubulação em vez da temperatura da sala, e os gases liberados pelas plantas ficam dentro da estufa.
Regulação Térmica: Ligada
Regulação Térmica: Desligada
Um Aquecedor de Ambiente e um Termorregulador integrados mantêm o interior isolado na temperatura desejada (definida no controle deslizante). O aquecimento consome 120 W; o resfriamento consome 240 W e libera calor na sala.
Esvaziar Gases
Libera na sala todos os gases armazenados. As plantas passam a utilizar a atmosfera da sala.
Regulação Térmica: Ligada
Regulação Térmica: Desligada
Um Aquecedor de Líquidos e um Aquarregulador integrados mantêm o líquido do tanque na temperatura desejada (definida no controle deslizante). O aquecimento consome 960 W; o resfriamento consome 1.200 W e libera calor na sala.
Esvaziar Tanque
Engarrafa todo o líquido do tanque ao lado da construção para os Duplicantes transportarem. Sem líquido, as plantas ressecam.
Nível de Enchimento
células
O tanque recebe líquido até atingir {0} células (1.000 kg de água equivalem a uma célula). Plantas em prateleiras acima da superfície da água não crescem.
Temperatura Desejada
A regulação térmica mantém o interior a {0}.
Plantas
Planta
A planta cultivada nos 18 espaços, como em um ladrilho de cultivo. Duplicantes entregam as sementes; mudar a seleção arranca as plantas atuais e deixa suas sementes junto à construção. Plantas largas ocupam vários espaços.
Variante
A mutação que será cultivada: a Original, qualquer variante identificada ou uma variante específica. A variante escolhida ocupa os espaços conforme suas sementes chegam; plantas Originais crescem nos espaços restantes até lá.
Nenhuma
Mistas
{0} ({1} espaços)
Original
Qualquer variante
Nada plantado
{0} plantadas, {1} crescendo
{0} mutantes, {1} Originais\npor enquanto (substituídas conforme as sementes chegam)
Aguardando sementes
Radiação interna: {0} rads
A lâmpada de radiação acrescenta {0} rads\n({1} de Fosforita)
Semente mutante por colheita: {0}\n(chance de semente: {1}, mutação: {2};\nmelhor em {3} rads)'''.splitlines()

blocks = SOURCE.read_text(encoding='utf-8-sig').strip().split('\n\n')
entries = []
for block in blocks:
    values = {}
    field = None
    for line in block.splitlines():
        match = re.match(r'^(msgctxt|msgid|msgstr) (".*")$', line)
        if match:
            field = match[1]
            values[field] = ast.literal_eval(match[2])
        elif line.startswith('"') and field:
            values[field] += ast.literal_eval(line)
    if 'msgctxt' in values:
        entries.append(values)
assert len(entries) == len(translations), (len(entries), len(translations))
output = ['msgid ""\nmsgstr ""\n"Language: pt_BR\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"']
seen = {}
for entry, translated in zip(entries, translations):
    translated = translated.replace(r'\n', '\n')
    source = entry['msgid']
    assert sorted(re.findall(r'\{[^{}]+\}', source)) == sorted(re.findall(r'\{[^{}]+\}', translated)), entry
    assert re.findall(r'<[^>]+>', source) == re.findall(r'<[^>]+>', translated), entry
    assert source.count('\n') == translated.count('\n'), entry
    assert source not in seen or seen[source] == translated, source
    seen[source] = translated
    output.append('\n'.join(f'{key} {json.dumps(value, ensure_ascii=False)}' for key, value in [('msgctxt', entry['msgctxt']), ('msgid', source), ('msgstr', translated)]))
destination = ROOT / 'mods/3828419350_Greenhouse'
destination.mkdir(parents=True, exist_ok=True)
for name in ['pt_BR.po', 'pt.po']:
    (destination / name).write_text('\n\n'.join(output) + '\n', encoding='utf-8')
print(f'Greenhouse: {len(entries)} entries translated and validated.')
