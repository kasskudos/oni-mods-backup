using HarmonyLib;
using KMod;
using System;
using System.Reflection;
using UnityEngine;

namespace RonivansEndothermicBalance
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            Debug.Log("[Ronivan Endothermic Balance] Patch registrado.");
        }
    }

    internal static class BalanceValues
    {
        internal const float WaterRate = 0.94f;
        internal const float NitrateRate = 0.06f;
        internal const float ProductRate = 1f;
        internal const float MinimumTemperature = 223.15f;

        internal const float DesalinatorAmmoniumWaterRate = 5f;
        internal const float DesalinatorSteamRate = 0.5f;
        internal const float RecoveredWaterRate = 5.2f;
        internal const float RecoveredAmmoniaRate = 0.3f;

        internal static readonly SimHashes AmmoniumWater = CustomElementHash("AmmoniumWater");
        internal static readonly SimHashes AmmoniumSalt = CustomElementHash("AmmoniumSalt");
        internal static readonly SimHashes AmmoniaGas = CustomElementHash("AmmoniaGas");

        internal static Tag AmmoniumWaterTag
        {
            get { return AmmoniumWater.CreateTag(); }
        }

        internal static Tag AmmoniumSaltTag
        {
            get { return AmmoniumSalt.CreateTag(); }
        }

        private static SimHashes CustomElementHash(string elementId)
        {
            return (SimHashes)Hash.SDBMLower(elementId);
        }
    }

    [HarmonyPatch]
    internal static class EndothermicUnitPatch
    {
        private static bool Prepare()
        {
            return AccessTools.TypeByName(
                "Dupes_Industrial_Overhaul.Chemical_Processing.Buildings.Chemical_EndothermicUnitConfig") != null;
        }

        private static MethodBase TargetMethod()
        {
            Type configType = AccessTools.TypeByName(
                "Dupes_Industrial_Overhaul.Chemical_Processing.Buildings.Chemical_EndothermicUnitConfig");
            return configType == null ? null : AccessTools.Method(configType, "ConfigureBuildingTemplate");
        }

        [HarmonyPriority(Priority.Last)]
        private static void Postfix(GameObject go)
        {
            MinimumOperatingTemperature minimumTemperature = go.GetComponent<MinimumOperatingTemperature>();
            if (minimumTemperature != null)
                minimumTemperature.minimumTemperature = BalanceValues.MinimumTemperature;

            ElementConverter converter = go.GetComponent<ElementConverter>();
            if (converter == null)
            {
                Debug.LogError("[Ronivan Endothermic Balance] Conversor da Unidade Endotérmica não encontrado.");
                return;
            }

            converter.consumedElements = new ElementConverter.ConsumedElement[]
            {
                new ElementConverter.ConsumedElement(SimHashes.Water.CreateTag(), BalanceValues.WaterRate),
                new ElementConverter.ConsumedElement(BalanceValues.AmmoniumSaltTag, BalanceValues.NitrateRate)
            };
            converter.outputElements = new ElementConverter.OutputElement[]
            {
                new ElementConverter.OutputElement(
                    BalanceValues.ProductRate,
                    BalanceValues.AmmoniumWater,
                    BalanceValues.MinimumTemperature,
                    true,
                    true,
                    0f,
                    0.5f,
                    0f,
                    0xff,
                    0)
            };

            Debug.Log("[Ronivan Endothermic Balance] Unidade Endotérmica ajustada: água=0,94 kg/s, nitrato=0,06 kg/s, mínimo=-50 °C, refrigeração original preservada.");
        }
    }

    [HarmonyPatch]
    internal static class ThermalDesalinatorPatch
    {
        private static bool Prepare()
        {
            return AccessTools.TypeByName(
                "Dupes_Industrial_Overhaul.Chemical_Processing.Buildings.Chemical_ThermalDesalinatorConfig") != null;
        }

        private static MethodBase TargetMethod()
        {
            Type configType = AccessTools.TypeByName(
                "Dupes_Industrial_Overhaul.Chemical_Processing.Buildings.Chemical_ThermalDesalinatorConfig");
            return configType == null ? null : AccessTools.Method(configType, "ConfigureBuildingTemplate");
        }

        [HarmonyPriority(Priority.Last)]
        private static void Postfix(GameObject go)
        {
            ElementConverter[] converters = go.GetComponents<ElementConverter>();
            if (converters == null || converters.Length < 2)
            {
                Debug.LogError("[Ronivan Endothermic Balance] Conversor de água amoniacal do Dessalinizador Térmico não encontrado.");
                return;
            }

            ElementConverter ammoniumWaterConverter = converters[1];
            ammoniumWaterConverter.consumedElements = new ElementConverter.ConsumedElement[]
            {
                new ElementConverter.ConsumedElement(BalanceValues.AmmoniumWaterTag, BalanceValues.DesalinatorAmmoniumWaterRate),
                new ElementConverter.ConsumedElement(SimHashes.Steam.CreateTag(), BalanceValues.DesalinatorSteamRate)
            };
            ammoniumWaterConverter.outputElements = new ElementConverter.OutputElement[]
            {
                new ElementConverter.OutputElement(BalanceValues.RecoveredWaterRate, SimHashes.Water, 327.15f, false, true),
                new ElementConverter.OutputElement(BalanceValues.RecoveredAmmoniaRate, BalanceValues.AmmoniaGas, 321.15f, false, true)
            };

            Debug.Log("[Ronivan Endothermic Balance] Dessalinizador ajustado: água=5,2 kg/s, amônia=0,3 kg/s.");
        }
    }

    [HarmonyPatch(typeof(ElementLoader), "Load")]
    internal static class AmmoniumWaterTransitionsPatch
    {
        [HarmonyPriority(Priority.Last)]
        private static void Postfix()
        {
            Element ammoniumWater = ElementLoader.FindElementByHash(BalanceValues.AmmoniumWater);
            if (ammoniumWater == null)
            {
                Debug.LogError("[Ronivan Endothermic Balance] Elemento AmmoniumWater não encontrado.");
                return;
            }

            ammoniumWater.lowTempTransitionOreMassConversion = BalanceValues.WaterRate;
            ammoniumWater.highTempTransitionOreMassConversion = BalanceValues.NitrateRate;
            Debug.Log("[Ronivan Endothermic Balance] Transições da água amoniacal ajustadas para 94/6.");
        }
    }
}
