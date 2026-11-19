using HarmonyLib;
using KMod;
using System.Reflection;
using UnityEngine;

namespace AirlockDoorPressureImmunity
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);

            string[] configNames =
            {
                "AirlockDoor.AirlockDoorConfig",
                "AirlockDoor.AirlockHalfDoorConfig",
                "PeterHan.AirlockDoor.AirlockDoorConfig",
                "PeterHan.AirlockDoor.AirlockDoorInsulatedConfig"
            };

            HarmonyMethod postfix = new HarmonyMethod(
                typeof(Mod), "AddPressureImmunity");
            postfix.priority = Priority.Last;
            int patched = 0;

            foreach (string configName in configNames)
            {
                System.Type configType = AccessTools.TypeByName(configName);
                if (configType == null)
                    continue;

                MethodInfo target = AccessTools.DeclaredMethod(
                    configType, "DoPostConfigureComplete",
                    new System.Type[] { typeof(GameObject) });
                if (target == null)
                {
                    Debug.LogWarning(
                        "[Airlock Door Pressure Immunity] Missing target: " + configName);
                    continue;
                }

                harmony.Patch(target, postfix: postfix);
                patched++;
                Debug.Log("[Airlock Door Pressure Immunity] Patched: " + configName);
            }

            if (patched == 0)
                Debug.LogWarning("[Airlock Door Pressure Immunity] No supported door configs found.");
        }

        private static void AddPressureImmunity(GameObject __0)
        {
            __0.AddOrGet<ImmuneToPressureDamage>();
            Debug.Log("[Airlock Door Pressure Immunity] Protected prefab: " + __0.name);
        }
    }
}
