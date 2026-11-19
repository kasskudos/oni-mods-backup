using System;
using System.Reflection;
using HarmonyLib;
using KMod;
using UnityEngine;

namespace StorageNetworkCapacityOverrides
{
    public sealed class Mod : UserMod2
    {
        private static PropertyInfo specId;

        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            Type specType = AccessTools.TypeByName(
                "StorageNetwork.Buildings.StorageNetworkStorageBuildingSpec");
            if (specType == null)
            {
                Debug.LogWarning("[Storage Network Capacity Overrides] Storage Network not found.");
                return;
            }

            specId = AccessTools.Property(specType, "Id");
            MethodInfo capacityGetter = AccessTools.PropertyGetter(specType, "CapacityKg");
            if (specId == null || capacityGetter == null)
            {
                Debug.LogError("[Storage Network Capacity Overrides] Unsupported spec API.");
                return;
            }

            HarmonyMethod specPostfix = new HarmonyMethod(typeof(Mod), "OverrideSpecCapacity");
            specPostfix.priority = Priority.Last;
            harmony.Patch(capacityGetter, postfix: specPostfix);

            HarmonyMethod storagePostfix = new HarmonyMethod(typeof(Mod), "UpdateExistingLimit");
            storagePostfix.priority = Priority.Last;
            harmony.Patch(AccessTools.Method(typeof(Storage), "OnSpawn"), postfix: storagePostfix);
            Debug.Log("[Storage Network Capacity Overrides] Small 300 t, medium 750 t, large 2500 t.");
        }

        private static bool TryGetCapacity(string id, out float capacity, out float oldCapacity)
        {
            capacity = 0f;
            oldCapacity = 0f;
            switch (id)
            {
                case "StorageNetworkSmallSolidServer":
                case "StorageNetworkSmallLiquidServer":
                case "StorageNetworkSmallGasServer":
                    capacity = 300000f;
                    oldCapacity = 25000f;
                    return true;
                case "StorageNetworkMediumSolidServer":
                case "StorageNetworkMediumLiquidServer":
                case "StorageNetworkMediumGasServer":
                    capacity = 750000f;
                    oldCapacity = 100000f;
                    return true;
                case "StorageNetworkLargeSolidServer":
                case "StorageNetworkLargeLiquidServer":
                case "StorageNetworkLargeGasServer":
                    capacity = 2500000f;
                    oldCapacity = 2500000f;
                    return true;
                default:
                    return false;
            }
        }

        private static void OverrideSpecCapacity(object __instance, ref float __result)
        {
            string id = specId.GetValue(__instance, null) as string;
            float capacity;
            float oldCapacity;
            if (TryGetCapacity(id, out capacity, out oldCapacity))
                __result = capacity;
        }

        private static void UpdateExistingLimit(Storage __instance)
        {
            Building building = __instance.GetComponent<Building>();
            if (building == null || building.Def == null)
                return;

            float capacity;
            float oldCapacity;
            if (!TryGetCapacity(building.Def.PrefabID, out capacity, out oldCapacity))
                return;

            IUserControlledCapacity limit = __instance.GetComponent<IUserControlledCapacity>();
            if (limit != null && capacity > oldCapacity &&
                Math.Abs(limit.UserMaxCapacity - oldCapacity) < 0.1f)
                limit.UserMaxCapacity = __instance.capacityKg;
        }
    }
}
