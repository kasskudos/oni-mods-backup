# Proteção de pressão dos líquidos de parede

A versão 1.2.0 protegia apenas `FairLiquidWallVent`. A versão 1.3.0 também protege `FairLiquidWallPump`.

O ajuste adiciona o componente original `ImmuneToPressureDamage` ao final de `DoPostConfigureComplete` nas configurações de bomba e saída de líquido do Wall Pumps. Mantém o ID do mod local para preservar a ativação existente. Não modifica a DLL do Wall Pumps.

O componente marca a célula ocupada pela construção com a propriedade de imunidade à pressão quando a instância é inicializada, inclusive ao carregar um save. Danos já existentes não são reparados pelo ajuste. Outros tipos de dano e os limites de pressão de operação da saída permanecem sob controle do jogo e do mod original.

Compilação: `powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1`.

Instalação: com o jogo fechado, copie a DLL e os dois YAML para `mods/Local/WallLiquidVentPressureImmunity`. Mantenha o mod habilitado e reabra o jogo.
