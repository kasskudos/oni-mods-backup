# Correção do consumo exibido pela estufa

Diagnóstico da DLL Greenhouse 1.4.7 e das bibliotecas do jogo instalado:

- `Greenhouse.UpdatePower` atualiza `EnergyConsumer.BaseWattageRating` e desativa `Operational.IsActive` quando a demanda é zero.
- `EnergyConsumer.WattsUsed` retorna zero quando o consumidor está inativo.
- `EnergyConsumer.WattsNeededWhenActive` retorna a demanda configurada quando positiva, mas usa `BuildingDef.EnergyConsumptionWhenActive` quando ela é zero ou negativa.
- `OverlayModes.Power.UpdatePowerLabels` usa `WattsNeededWhenActive`, mostrando os 573,3334 W da definição da estufa quando ela está ociosa.

O postfix mantém o valor zero de demanda somente para as estufas `SaitoGreenhouse`, `SaitoAquaticGreenhouse` e `SaitoHangingGreenhouse`. Como o getter também alimenta estimativas de demanda do circuito, essas estimativas passam a respeitar a demanda dinâmica zero. O cálculo do consumo efetivo, a iluminação e o controle térmico permanecem sob responsabilidade do mod original.

Instale a DLL e os dois YAML em `mods/Local/GreenhousePowerDisplayFix`, ative **Estufa, Correção do Consumo Exibido** e reinicie o jogo. A correção pode ser desativada sem modificar as construções do save.

Validação: compilação contra as bibliotecas instaladas e conferência dos caminhos de cálculo e exibição na IL. A validação visual depende de ativar o ajuste e carregar o jogo.
