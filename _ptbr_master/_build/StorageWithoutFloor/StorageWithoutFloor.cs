using HarmonyLib;
using KMod;
using UnityEngine;

namespace StorageWithoutFloor
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);

            HarmonyMethod postfix = new HarmonyMethod(typeof(Mod), "AllowWithoutFloor");
            postfix.priority = Priority.Last;
            harmony.Patch(
                AccessTools.Method(typeof(StorageLockerConfig), "CreateBuildingDef"),
                postfix: postfix);
            harmony.Patch(
                AccessTools.Method(typeof(StorageLockerSmartConfig), "CreateBuildingDef"),
                postfix: postfix);
            Debug.Log("[Storage Without Floor] Patched normal and smart storage bins.");
        }

        private static void AllowWithoutFloor(BuildingDef __result)
        {
            __result.BuildLocationRule = BuildLocationRule.Anywhere;
            __result.ContinuouslyCheckFoundation = false;
        }
    }
}
