using HarmonyLib;
using KMod;
using STRINGS;
using System.Reflection;
using UnityEngine;

namespace HVACExpansionPtBr
{
    public sealed class Mod : UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            Debug.Log("[HVAC Expansion PT-BR] Patch registrado.");
        }
    }

    [HarmonyPatch(typeof(GeneratedBuildings), "LoadGeneratedBuildings")]
    internal static class GeneratedBuildingsPatch
    {
        private const string CondenserName = "<link=\"AUTOCONDESNER\">Condensador Automático</link>";
        private const string CondenserDesc = "Resfria e condensa gases.";
        private const string CondenserEffect = "Resfria os <link=\"ELEMENTS_GAS\">Gases</link> canalizados e os condensa em sua forma <link=\"ELEMENTS_LIQUID\">Líquida</link>.\n\nGases que geram subprodutos durante a transição danificam a máquina. Gases quentes demais serão despejados.";

        private const string EvaporatorName = "<link=\"AUTOEVAPORTATOR\">Evaporador Automático</link>";
        private const string EvaporatorDesc = "Aquece e evapora líquidos.";
        private const string EvaporatorEffect = "Aquece os <link=\"ELEMENTS_LIQUID\">Líquidos</link> canalizados e os evapora em sua forma <link=\"ELEMENTS_GAS\">Gasosa</link>.\n\nLíquidos que geram subprodutos durante a transição danificam a máquina. Líquidos frios demais serão despejados.";

        private const string GasUnitName = "<link=\"GASREFRIGERATIONUNIT\">Termo-Aquecedor de Gás</link>";
        private const string GasUnitDesc = "Um termo-aquecedor não elimina o frio, apenas o transfere para outra área.";
        private const string GasUnitEffect = "Aquece o <link=\"ELEMENTS_GAS\">Gás</link> canalizado através dele, resfriando a área ao seu redor.";

        private const string LiquidUnitName = "<link=\"LIQUIDREFRIGERATIONUNIT\">Termo-Aquecedor de Líquido</link>";
        private const string LiquidUnitDesc = "Um termo-aquecedor aquece líquidos e libera o frio em outro lugar.";
        private const string LiquidUnitEffect = "Aquece o <link=\"ELEMENTS_LIQUID\">Líquido</link> canalizado através dele, resfriando a área ao seu redor.";

        [HarmonyPriority(Priority.Last)]
        private static void Prefix()
        {
            Add("STRINGS.BUILDINGS.PREFABS.AUTOCONDESNER.NAME", CondenserName);
            Add("STRINGS.BUILDINGS.PREFABS.AUTOCONDESNER.DESC", CondenserDesc);
            Add("STRINGS.BUILDINGS.PREFABS.AUTOCONDESNER.EFFECT", CondenserEffect);

            Add("STRINGS.BUILDINGS.PREFABS.AUTOEVAPORTATOR.NAME", EvaporatorName);
            Add("STRINGS.BUILDINGS.PREFABS.AUTOEVAPORTATOR.DESC", EvaporatorDesc);
            Add("STRINGS.BUILDINGS.PREFABS.AUTOEVAPORTATOR.EFFECT", EvaporatorEffect);

            Add("STRINGS.BUILDINGS.PREFABS.GASREFRIGERATIONUNIT.NAME", GasUnitName);
            Add("STRINGS.BUILDINGS.PREFABS.GASREFRIGERATIONUNIT.DESC", GasUnitDesc);
            Add("STRINGS.BUILDINGS.PREFABS.GASREFRIGERATIONUNIT.EFFECT", GasUnitEffect);

            Add("STRINGS.BUILDINGS.PREFABS.LIQUIDREFRIGERATIONUNIT.NAME", LiquidUnitName);
            Add("STRINGS.BUILDINGS.PREFABS.LIQUIDREFRIGERATIONUNIT.DESC", LiquidUnitDesc);
            Add("STRINGS.BUILDINGS.PREFABS.LIQUIDREFRIGERATIONUNIT.EFFECT", LiquidUnitEffect);

            Add("STRINGS.MISC.TAGS.FULLYCONDENSABLE", "Totalmente Condensável");
            Add("STRINGS.MISC.TAGS.FULLYEVAPORATABLE", "Totalmente Evaporável");

            Add("STRINGS.RESEARCH.TECHS.REFRIGERATIONCYCLE.NAME", "<link=\"REFRIGERATIONCYCLE\">Ciclo de Refrigeração</link>");
            Add("STRINGS.RESEARCH.TECHS.REFRIGERATIONCYCLE.DESC", "Evapore e condense <link=\"ELEMENTS_LIQUID\">Líquidos</link> e <link=\"ELEMENTS_GAS\">Gases</link>");

            Add("STRINGS.UI.BUILDINGEFFECTS.HEATCONSUMED_AIRREFRIGERATOR", "<link=\"HEAT\">Calor</link>: -{0} (valor aproximado)");
            Add("STRINGS.UI.BUILDINGEFFECTS.HEATCONSUMED_LIQUIDREFRIGERATOR", "<link=\"HEAT\">Calor</link>: -{0} (valor aproximado)");
            Add("STRINGS.UI.BUILDINGEFFECTS.GASHEATING", "<link=\"HEAT\">Fator de aquecimento</link>: {0}");
            Add("STRINGS.UI.BUILDINGEFFECTS.LIQUIDHEATING", "<link=\"HEAT\">Fator de aquecimento</link>: {0}");
            Add("STRINGS.UI.BUILDINGEFFECTS.TOOLTIPS.GASHEATING", "Aumenta em <b>{0}</b> a <style=\"KKeyword\">Temperatura</style> dos <style=\"KKeyword\">Gases</style> canalizados");
            Add("STRINGS.UI.BUILDINGEFFECTS.TOOLTIPS.LIQUIDHEATING", "Aumenta em <b>{0}</b> a <style=\"KKeyword\">Temperatura</style> do <style=\"KKeyword\">Líquido</style> canalizado");
            Add("STRINGS.UI.BUILDINGEFFECTS.TOOLTIPS.HEATGENERATED_GASREFRIGERATIONUNIT", "Dissipa <style=\"KKeyword\">Calor</style> com base no <style=\"KKeyword\">Volume</style> e na <style=\"KKeyword\">Capacidade Térmica Específica</style> do <style=\"KKeyword\">Gás</style> bombeado.\n\nAquecer 1 kg de Oxigênio em <b>{1}</b> consumirá <b>{0}</b>");
            Add("STRINGS.UI.BUILDINGEFFECTS.TOOLTIPS.HEATGENERATED_LIQUIDREFRIGERATIONUNIT", "Dissipa <style=\"KKeyword\">Calor</style> com base no <style=\"KKeyword\">Volume</style> e na <style=\"KKeyword\">Capacidade Térmica Específica</style> do <style=\"KKeyword\">Líquido</style> bombeado.\n\nAquecer 10 kg de Água em <b>{1}</b> consumirá <b>{0}</b>");
            Debug.Log("[HVAC Expansion PT-BR] 24 textos aplicados aos IDs legados.");
        }

        [HarmonyPriority(Priority.Last)]
        private static void Postfix()
        {
            TranslateBuilding("AutoCondesner", CondenserName, CondenserDesc, CondenserEffect);
            TranslateBuilding("AutoEvaportator", EvaporatorName, EvaporatorDesc, EvaporatorEffect);
            TranslateBuilding("GasRefrigerationUnit", GasUnitName, GasUnitDesc, GasUnitEffect);
            TranslateBuilding("LiquidRefrigerationUnit", LiquidUnitName, LiquidUnitDesc, LiquidUnitEffect);
        }

        private static void TranslateBuilding(string id, string name, string description, string effect)
        {
            BuildingDef definition = Assets.GetBuildingDef(id);
            if (definition == null)
            {
                Debug.LogWarning("[HVAC Expansion PT-BR] BuildingDef não encontrado: " + id);
                return;
            }

            bool nameApplied = SetDefinitionText(definition, name, "name", "Name", "<Name>k__BackingField");
            bool descriptionApplied = SetDefinitionText(definition, description, "description", "Description", "<Description>k__BackingField");
            bool effectApplied = SetDefinitionText(definition, effect, "effect", "Effect", "<Effect>k__BackingField");
            Debug.Log("[HVAC Expansion PT-BR] BuildingDef traduzido: " + id
                + " nome=" + nameApplied
                + " descrição=" + descriptionApplied
                + " efeito=" + effectApplied);
        }

        private static bool SetDefinitionText(BuildingDef definition, string value, params string[] fieldNames)
        {
            foreach (string fieldName in fieldNames)
            {
                FieldInfo field = AccessTools.Field(definition.GetType(), fieldName);
                if (field == null)
                    continue;

                field.SetValue(definition, value);
                return true;
            }

            return false;
        }

        private static void Add(string key, string value)
        {
            Strings.Add(key, value);
            ReplaceHvacField(key, value);
        }

        private static void ReplaceHvacField(string key, string value)
        {
            string typeName = null;
            string fieldName = key.Substring(key.LastIndexOf('.') + 1);
            string[] parts = key.Split('.');

            if (key.StartsWith("STRINGS.BUILDINGS.PREFABS.") && parts.Length >= 5)
            {
                switch (parts[3])
                {
                    case "AUTOCONDESNER": typeName = "HVACExpansion.Locale.Buildings+AutoCondenser"; break;
                    case "AUTOEVAPORTATOR": typeName = "HVACExpansion.Locale.Buildings+AutoEvaporator"; break;
                    case "GASREFRIGERATIONUNIT": typeName = "HVACExpansion.Locale.Buildings+GasRefrigerator"; break;
                    case "LIQUIDREFRIGERATIONUNIT": typeName = "HVACExpansion.Locale.Buildings+LiquidRefrigerator"; break;
                }
            }
            else if (key.StartsWith("STRINGS.MISC.TAGS."))
            {
                typeName = "HVACExpansion.Locale.Misc+Tags";
            }
            else if (key.StartsWith("STRINGS.RESEARCH.TECHS.REFRIGERATIONCYCLE."))
            {
                typeName = "HVACExpansion.Locale.Research+Techs+RefrigerationCycle";
            }
            else if (key.StartsWith("STRINGS.UI.BUILDINGEFFECTS.TOOLTIPS."))
            {
                typeName = "HVACExpansion.Locale.UI+BuildingEffects+Tooltips";
                if (fieldName == "HEATGENERATED_GASREFRIGERATIONUNIT")
                    fieldName = "HEATCONSUMED_AIRREFRIGERATOR";
                else if (fieldName == "HEATGENERATED_LIQUIDREFRIGERATIONUNIT")
                    fieldName = "HEATCONSUMED_LIQUIDREFRIGERATOR";
            }
            else if (key.StartsWith("STRINGS.UI.BUILDINGEFFECTS."))
            {
                typeName = "HVACExpansion.Locale.UI+BuildingEffects";
            }

            if (typeName == null)
                return;

            System.Type type = AccessTools.TypeByName(typeName);
            FieldInfo field = type == null ? null : AccessTools.Field(type, fieldName);
            if (field == null)
            {
                Debug.LogWarning("[HVAC Expansion PT-BR] Campo não encontrado: " + typeName + "." + fieldName);
                return;
            }

            field.SetValue(null, new LocString(value, key));
        }
    }
}
