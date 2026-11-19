# Capacidades personalizadas da Rede de Armazenamento

Com o multiplicador geral `ServerCapacityMultiplier` em 1, o ajuste define:

- Servidores pequenos de sólidos, líquidos e gases: 300.000 kg.
- Servidores médios de sólidos, líquidos e gases: 750.000 kg.
- Servidores grandes de sólidos, líquidos e gases: 2.500.000 kg.

O postfix de `StorageNetworkStorageBuildingSpec.CapacityKg` usa os IDs específicos dos nove servidores. Os servidores refrigerados, de partículas e de baterias, o núcleo e os armazenamentos intermediários das portas mantêm suas especificações originais. A DLL do Storage Network permanece intacta.

O multiplicador geral do Storage Network continua sendo aplicado pelo mod original. Para manter os valores acima, deixe esse multiplicador em 1. O `OtherMultiplier` do Bigger Capacity também está em 1 na configuração atual.

`Storage.capacityKg` não é serializado na versão inspecionada do jogo: as instâncias carregadas recebem a capacidade do prefab atualizado. Ao carregar um servidor cujo limite manual ainda é exatamente a antiga capacidade máxima de 25.000 ou 100.000 kg, o ajuste eleva esse limite ao novo máximo. Limites manuais inferiores são preservados.

Instale a DLL e os dois YAML em `mods/Local/StorageNetworkCapacityOverrides`, ative **Rede de Armazenamento, Capacidades Personalizadas** e reinicie o jogo. Mantenha o Storage Network ativado.

Para compilar: `powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1`.

Antes de desativar o ajuste, reduza o conteúdo dos servidores pequenos e médios para caber na capacidade original.
