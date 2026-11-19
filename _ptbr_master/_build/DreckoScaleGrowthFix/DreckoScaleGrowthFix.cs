using HarmonyLib;
using KMod;
using UnityEngine;

namespace DreckoScaleGrowthFix
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            DreckoConfig.SCALE_INITIAL_GROWTH_PCT = 1.0f;
            Debug.Log("[Drecko Scale Growth Fix] Normal Dreckos now mature with fully grown scales.");
        }
    }
}
