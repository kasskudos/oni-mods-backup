using HarmonyLib;
using KMod;
using System;
using System.Reflection;
using UnityEngine;

namespace WallLiquidVentPressureImmunity
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            string[] configNames =
            {
                "FairONI.LiquidWallVent",
                "WallPumps.LiquidWallVent",
                "LiquidWallVent",
                "FairONI.LiquidWallPump",
                "WallPumps.LiquidWallPump",
                "LiquidWallPump"
            };

            HarmonyMethod postfix = new HarmonyMethod(typeof(Mod), "AddPressureImmunity");
            postfix.priority = Priority.Last;
            int patched = 0;
            foreach (string configName in configNames)
            {
                Type configType = AccessTools.TypeByName(configName);
                if (configType == null)
                    continue;

                MethodInfo target = AccessTools.DeclaredMethod(
                    configType, "DoPostConfigureComplete", new Type[] { typeof(GameObject) });
                if (target == null)
                {
                    Debug.LogWarning("[Wall Liquid Pressure Immunity] Missing target: " + configName);
                    continue;
                }

                harmony.Patch(target, postfix: postfix);
                patched++;
                Debug.Log("[Wall Liquid Pressure Immunity] Patched: " + configName);
            }

            if (patched == 0)
                Debug.LogError("[Wall Liquid Pressure Immunity] No supported wall liquid configs found.");
        }

        private static void AddPressureImmunity(GameObject __0)
        {
            __0.AddOrGet<ImmuneToPressureDamage>();
            Debug.Log("[Wall Liquid Pressure Immunity] Protected prefab: " + __0.name);
        }
    }
}
