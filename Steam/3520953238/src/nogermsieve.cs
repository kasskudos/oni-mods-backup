using HarmonyLib;
using UnityEngine;

namespace gariba.nogermsieve
{
    [HarmonyPatch(typeof(ElementConverter), "ConvertMass")]
	public static class GermFreeWaterPatch
		{
			public static void Postfix(ElementConverter __instance)
			    {
				if (__instance.gameObject.GetComponent<WaterPurifier>() != null)
					{
						var outputStorage = __instance.GetComponent<Storage>();
						if (outputStorage != null)
						{
							foreach (GameObject item in outputStorage.items)
							{
							if (item != null && item.TryGetComponent(out PrimaryElement elem))
								{
								elem.ModifyDiseaseCount(-elem.DiseaseCount, "nogermsieve");
								}
							}
						}
					}
				}
		}

}
