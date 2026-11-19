using HarmonyLib;
using KMod;
using UnityEngine;

namespace GreenhousePowerDisplayFix
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            harmony.Patch(
                AccessTools.PropertyGetter(typeof(EnergyConsumer), "WattsNeededWhenActive"),
                postfix: new HarmonyMethod(typeof(Mod), "UseGreenhouseIdleDemand"));
            Debug.Log("[Greenhouse Power Display Fix] Installed idle demand correction.");
        }

        private static void UseGreenhouseIdleDemand(EnergyConsumer __instance, ref float __result)
        {
            if (__instance.BaseWattageRating != 0f)
                return;

            Building building = __instance.GetComponent<Building>();
            if (building == null || building.Def == null)
                return;

            string id = building.Def.PrefabID;
            if (id == "SaitoGreenhouse" || id == "SaitoAquaticGreenhouse" ||
                id == "SaitoHangingGreenhouse")
                __result = 0f;
        }
    }
}
