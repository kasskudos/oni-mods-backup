# Proteção contra pressão para portas Airlock

Mod local que adiciona `ImmuneToPressureDamage` aos prefabs completos das seguintes portas:

- Airtight Door, Workshop `2093302246`: `AirlockMechanizedDoor` (1×2) e `AirlockHalfMechanizedDoor` (1×1).
- Airlock Door, Workshop `2094698134`: `PAirlockDoor` e `PAirlockDoorInsulated` (3×2).

Compilar com `powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1`.
Instalar a DLL e os dois arquivos YAML em `mods\Local\AirlockDoorPressureImmunity`.
Ativar o mod no menu do ONI e reiniciar o jogo antes de carregar a colônia.

O patch roda após `DoPostConfigureComplete`, inclusive na porta pequena que chama a configuração da porta base do jogo. Usa `AddOrGet` para não duplicar o componente. Tipos de mods ausentes são ignorados. As DLLs da Steam e os arquivos de save não são modificados.

O componente protege somente contra dano de pressão de líquidos. Outros tipos de dano continuam com o comportamento original.

Verificação em jogo: procurar `[Airlock Door Pressure Immunity] Protected prefab:` no `Player.log`, conferir os quatro IDs presentes e testar as portas em uma cópia da colônia ou no sandbox. Compilar e conferir a DLL não substitui esse teste em execução.
