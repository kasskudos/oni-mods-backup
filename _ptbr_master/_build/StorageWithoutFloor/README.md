# Armários de Armazenamento sem Piso

Ajuste local para os armários padrão `StorageLocker` e `StorageLockerSmart`.

Os postfixes de `CreateBuildingDef` definem `BuildLocationRule.Anywhere` e desativam a verificação contínua de fundação. A capacidade e os filtros continuam sendo definidos pelo jogo e pelos demais mods, incluindo Bigger Capacity.

Instalação: copie a DLL e os dois arquivos YAML para `mods/Local/StorageWithoutFloor`. Ative **Armários de Armazenamento sem Piso** no menu de mods e reinicie o jogo.

Os armários continuam ocupando 1 × 2 células. A alteração permite construí-los verticalmente sem pisos intermediários. Duplicantes precisam ter acesso para construir, entregar e retirar materiais.

Para compilar, execute `powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1`. O compilador usa as bibliotecas da instalação local do jogo.

Para remover o ajuste, providencie piso sob os armários suspensos antes de desativar o mod.
