using HarmonyLib;
using Klei.AI;
using KMod;
using UnityEngine;

namespace NoCritterCramScaleGrowthFix
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            DreckoConfig.SCALE_INITIAL_GROWTH_PCT = 1.0f;
            Debug.Log("[No Critter Cram Scale Growth Fix] Patch loaded.");
            Debug.Log("[No Critter Cram Scale Growth Fix] Normal Dreckos now mature with fully grown scales.");
        }
    }

    [HarmonyPatch(typeof(HappinessMonitor), nameof(HappinessMonitor.InitializeStates))]
    internal static class HappinessMonitorPatch
    {
        private static void Postfix(
            Effect ___miserableWildEffect,
            Effect ___miserableTameEffect)
        {
            string scaleGrowthAttributeId = Db.Get().Amounts.ScaleGrowth.deltaAttribute.Id;
            int removedModifiers = RemoveScaleGrowthPenalty(
                ___miserableWildEffect,
                scaleGrowthAttributeId);
            removedModifiers += RemoveScaleGrowthPenalty(
                ___miserableTameEffect,
                scaleGrowthAttributeId);

            Debug.Log(
                "[No Critter Cram Scale Growth Fix] Removed "
                + removedModifiers
                + " miserable scale growth modifier(s).");
        }

        private static int RemoveScaleGrowthPenalty(
            Effect effect,
            string scaleGrowthAttributeId)
        {
            if (effect == null || effect.SelfModifiers == null)
                return 0;

            int removedModifiers = 0;
            for (int index = effect.SelfModifiers.Count - 1; index >= 0; index--)
            {
                AttributeModifier modifier = effect.SelfModifiers[index];
                if (modifier.AttributeId != scaleGrowthAttributeId)
                    continue;

                effect.SelfModifiers.RemoveAt(index);
                removedModifiers++;
            }

            return removedModifiers;
        }
    }
}
