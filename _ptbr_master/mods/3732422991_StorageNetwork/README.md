# Rede de Armazenamento

Tradução do Storage Network, Workshop 3732422991, versão Steam 1.2.6.

Os arquivos `pt_BR.po` e `pt.po` são aplicados automaticamente pelo script principal quando o mod estiver instalado em `mods/Steam/3732422991/translations`.

O catálogo original deste mod usa chinês no campo `msgid` e inglês no `msgstr` de `en.po`. Esses `msgid` chineses foram preservados como referência original. As traduções foram escritas em português a partir do catálogo inglês e conferidas quanto a variáveis, links, estilos e quebras de linha.

Referências preservadas em `_referencia/3732422991_StorageNetwork`: `steam-en.po` corresponde ao pacote baixado pela Steam; `en.po` corresponde ao GitHub e pode estar adiantado em relação à versão publicada. Não substituir a referência Steam pela do GitHub sem conferir a versão instalada.

O mapa editorial em `_build/storage-network-ptbr.tsv` e o gerador `_build/build_storage_network_translation.py` permitem reconstruir o catálogo. O mapa também inclui textos já encontrados no GitHub para futuras atualizações.

O carregador oficial procura `translations/<codigo-do-idioma>.po`. São mantidas as variantes `pt_BR` e `pt` para os códigos de português usados pelas traduções do jogo.

Após atualizar o mod, execute `aplicar-traducoes.ps1`. Se o catálogo inglês trouxer chaves novas, o script interrompe a aplicação dos arquivos deste mod para revisão.
