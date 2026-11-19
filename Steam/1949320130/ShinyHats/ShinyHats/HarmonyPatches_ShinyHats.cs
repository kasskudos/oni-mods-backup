using HarmonyLib;
using JetBrains.Annotations;
using Newtonsoft.Json;
using PeterHan.PLib.Options;
using UnityEngine;

namespace ShinyHats
{
    public class HarmonyPatches_ShinyHats
    {
        [HarmonyPatch(typeof(MinionConfig), nameof(MinionConfig.CreatePrefab))]
        public static class MinionConfig_CreatePrefab_Patch
        {
            public static void Postfix(GameObject __result)
            {
                __result.AddOrGet<ShinyDupeLights>();
            }
        }

/*        [HarmonyPatch(typeof(MinionResume), nameof(MinionResume.ApplyTargetHat))]
        public static class MinionConfig_CreatePrefab_Patch
        {
            public static void Postfix(MinionResume __instance)
            {
                __instance..AddOrGet<ShinyDupeLights>();
            }
        }
*/

    }

    public class ShinyDupeLights : KMonoBehaviour, ISim33ms, ISim1000ms
    {
        [MyCmpGet]
        private MinionIdentity _minionIdentity;

        [MyCmpGet]
        private SuitEquipper _suitEquipper;

        private bool hasHatWithLights;
        private bool isWearingAirtightSuit;

        [CanBeNull]
        private Chore lastChore;

        [CanBeNull]
        private string lastHat;

        [CanBeNull]
        private Room lastRoom;

        private bool roomLightOut;
        public Light2D PersonalLight { get; set; }
        public Light2D DupeLight { get; set; }
        public Light2D SuitLamp { get; set; }

        public static bool HasHatWithLights([CanBeNull] string currentHat)
        {
            // Database.Skills
            return !currentHat.IsNullOrWhiteSpace() &&
                   (currentHat.StartsWith("hat_role_mining") || currentHat.StartsWith("hat_role_research") || currentHat.StartsWith("hat_role_astronaut"));
        }

        public void Sim1000ms(float dt)
        {
            if (this.roomLightOut)
            {
                return;
            }

            ShinyHatsOptions option = ShinyHats_EL_Patch.Options;
            this.isWearingAirtightSuit = this._suitEquipper.IsWearingAirtightSuit();

            MinionResume minionResume = this._minionIdentity.GetComponent<MinionResume>();
            if (minionResume == null)
            {
                return;
            }

            string currentHat = minionResume.CurrentHat;

            if (currentHat.IsNullOrWhiteSpace()) { this.hasHatWithLights = false; }
            else if (currentHat != this.lastHat)
            {
                this.hasHatWithLights = HasHatWithLights(currentHat);
                if (this.hasHatWithLights)
                {
                    switch (currentHat)
                    {
                        case "hat_role_mining1":
                            this.DupeLight.Range = option.hat_role_level1_Range * option.miningRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level1_Lux * option.miningLuxFactor / 100f);
                            this.DupeLight.Color = Color.yellow;
                            //DupeLight.shape = ShinyHats_EL_Patch.DirectedCone.KleiLightShape;
                            //DupeLight.shape = LightShape.Cone;
                            //DupeLight.Angle = 50;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;

                            break;

                        case "hat_role_mining2":
                            this.DupeLight.Range   = option.hat_role_level2_Range * option.miningRangeFactor / 100f;
                            this.DupeLight.Lux     = (int)(option.hat_role_level2_Lux * option.miningLuxFactor / 100f);
                            this.DupeLight.Color   = Color.yellow + Color.yellow + Color.red;
                            //DupeLight.shape = ShinyHats_EL_Patch.DirectedCone.KleiLightShape;
                            this.DupeLight.shape   = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_mining3":
                            this.DupeLight.Range    = option.hat_role_level3_Range * option.miningRangeFactor / 100f;
                            this.DupeLight.Lux      = (int)(option.hat_role_level3_Lux * option.miningLuxFactor / 100f);
                            this.DupeLight.Color    = Color.yellow + Color.red;
                            // DupeLight.shape = ShinyHats_EL_Patch.DirectedCone.KleiLightShape;
                            this.DupeLight.shape    = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_mining4":
                            this.DupeLight.Range    = option.hat_role_level4_Range * option.miningRangeFactor / 100f;
                            this.DupeLight.Lux      = (int)(option.hat_role_level4_Lux * option.miningLuxFactor / 100f);
                            this.DupeLight.Color    = Color.red;
                            // DupeLight.shape = ShinyHats_EL_Patch.DirectedCone.KleiLightShape;
                            this.DupeLight.shape    = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;



                        case "hat_role_research1":
                            this.DupeLight.Range = option.hat_role_level1_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux   = (int)(option.hat_role_level1_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.white;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_research2":
                            this.DupeLight.Range = option.hat_role_level2_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level2_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.white;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_research3":
                            this.DupeLight.Range = option.hat_role_level3_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level3_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.magenta;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_research4":
                            this.DupeLight.Range = option.hat_role_level4_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level4_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.magenta;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_research5": //Atomic
                            this.DupeLight.Range = option.hat_role_level3_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level3_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.green;
                            this.DupeLight.shape = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                            break;

                        case "hat_role_astronaut1":
                            this.DupeLight.Range = option.hat_role_level2_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level2_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = Color.cyan;
                            this.DupeLight.shape = ShinyHats_EL_Patch.Beam5.KleiLightShape;
                            break;

                        case "hat_role_astronaut2":
                            this.DupeLight.Range = option.hat_role_level3_Range * option.researchRangeFactor / 100f;
                            this.DupeLight.Lux = (int)(option.hat_role_level3_Lux * option.researchLuxFactor / 100f);
                            this.DupeLight.Color = new Color(0.9f, 0.6f, 0f);
                            this.DupeLight.shape = ShinyHats_EL_Patch.Beam5.KleiLightShape;
                            break;

                        default:
                            this.DupeLight.enabled = false;
                            break;
                    }
                }
            }

            // Lights out with no suitable gear
            if (!this.hasHatWithLights && !this.isWearingAirtightSuit)
            {
                this.SuitLamp.enabled = this.DupeLight.enabled = false;
                return;
            }

            Chore currentChore = this._minionIdentity.GetComponent<ChoreDriver>()?.GetCurrentChore();
            if (currentChore != null && currentChore != this.lastChore)
            {
                bool wantsToSleep = (currentChore is SleepChore);
                if (wantsToSleep)
                {
                    //SleepChore sleepState = _minionIdentity.GetComponent<ChoreDriver>().GetCurrentChore() as SleepChore;
                    this.SuitLamp.enabled = this.DupeLight.enabled = false;
                    return;
                }
            }
            // bool hasFearInTheDark = (_minionIdentity.GetComponent<SleepChoreMonitor>().GetState. ?. ..GetCurrentChore() is SleepChore);

            this.lastHat = currentHat;
            this.lastChore = currentChore;

            this.DupeLight.enabled = option.useHatLights && this.hasHatWithLights && (!this.isWearingAirtightSuit || !option.useSuitLights && this.isWearingAirtightSuit);
            this.SuitLamp.enabled = option.useSuitLights && this.isWearingAirtightSuit;
        }

        public void Sim33ms(float dt)
        {
            if (!this.hasHatWithLights && !this.isWearingAirtightSuit)
            {
                return;
            }
            Room currentRoom = Game.Instance.roomProber.GetRoomOfGameObject(this._minionIdentity.gameObject);
            if (currentRoom != this.lastRoom)
            {
                this.roomLightOut = false;
                if (IsSleepingRoom(currentRoom))
                {
                    this.SuitLamp.enabled = this.DupeLight.enabled = false;
                    this.roomLightOut = true;
                }
            }

            this.lastRoom = currentRoom;
        }

        protected override void OnPrefabInit()
        {
            ShinyHatsOptions option = ShinyHats_EL_Patch.Options;
            if (this._minionIdentity != null)
            {
                if (this._minionIdentity.gameObject != null)
                {
                    this.SuitLamp         = this._minionIdentity.gameObject.AddComponent<Light2D>();
                    this.SuitLamp.Color   = Color.yellow;
                    this.SuitLamp.Offset  = new Vector2(0f, 1f);
                    this.SuitLamp.Range   = option.atmosuit_Range;
                    this.SuitLamp.Lux     = option.atmoSuit_Lux;
                    this.SuitLamp.shape   = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                    this.SuitLamp.enabled = false;

                    this.DupeLight         = this._minionIdentity.gameObject.AddComponent<Light2D>();
                    this.DupeLight.Color   = Color.white;
                    this.DupeLight.Offset  = new Vector2(0f, 1f);
                    this.DupeLight.Range   = 3;
                    //DupeLight.Lux   = LightsOutPatches.ConfigManager.Config.DupeLightLux;
                    this.DupeLight.shape   = ShinyHats_EL_Patch.SmoothCircle.KleiLightShape;
                    this.DupeLight.enabled = false; // option.DupeLight;

                }
            }

        }

        private static bool IsSleepingRoom([CanBeNull] Room currentRoom)
        {
            if (currentRoom == null)
            {
                return false;
            }
            return (currentRoom.roomType == Db.Get().RoomTypes.Barracks || currentRoom.roomType == Db.Get().RoomTypes.Bedroom);
        }
    }

    // ...
    [JsonObject(MemberSerialization.OptIn)]
    public class ShinyHatsOptions
    {
        private const string LightSettings = "02 Hat Light Settings";
        private const string Main = "01 Main";
        private const string MiningHatModifier = "04 Mining Hat Modifier";
        private const string ResearcherHatModifier = "05 Researcher Hat Modifier";
        private const string Suits = "03 Suit Light Settings";

        public ShinyHatsOptions()
        {
            this.useHatLights  = true;
            this.useSuitLights = true;

            this.miningLuxFactor     = 100;
            this.researchLuxFactor   = 80;
            this.miningRangeFactor   = 100;
            this.researchRangeFactor = 100;

            this.hat_role_level1_Lux = 600;
            this.hat_role_level2_Lux = 700;
            this.hat_role_level3_Lux = 850;
            this.hat_role_level4_Lux = 1000;

            this.hat_role_level1_Range = 3f;
            this.hat_role_level2_Range = 4f;
            this.hat_role_level3_Range = 5f;
            this.hat_role_level4_Range = 5f;

            this.atmosuit_Range = 10f;
            this.atmoSuit_Lux = 2000;
        }

        [Option("Light Lux", "Default: 2000", Suits)]
        [Limit(0, 3000)]
        [JsonProperty]
        public int atmoSuit_Lux { get; set; }

        [Option("Light Range", "Default: 10", Suits)]
        [Limit(1, 15)]
        [JsonProperty]
        public float atmosuit_Range { get; set; }

        [Option("Level 1 Lux", "Default: 600", LightSettings)]
        [Limit(0, 2000)]
        [JsonProperty]
        public int hat_role_level1_Lux { get; set; }

        [Option("Level 1 Range", "Default: 3", LightSettings)]
        [Limit(1, 10)]
        [JsonProperty]
        public float hat_role_level1_Range { get; set; }

        [Option("Level 2 Lux", "Default: 700", LightSettings)]
        [Limit(0, 2000)]
        [JsonProperty]
        public int hat_role_level2_Lux { get; set; }

        [Option("Level 2 Range", "Default: 4", LightSettings)]
        [Limit(1, 10)]
        [JsonProperty]
        public float hat_role_level2_Range { get; set; }

        [Option("Level 3 Lux", "Default: 850", LightSettings)]
        [Limit(0, 2000)]
        [JsonProperty]
        public int hat_role_level3_Lux { get; set; }

        [Option("Level 3 Range", "Default: 5", LightSettings)]
        [Limit(1, 10)]
        [JsonProperty]
        public float hat_role_level3_Range { get; set; }

        [Option("Level 4 Lux", "Default: 1000", LightSettings)]
        [Limit(0, 2000)]
        [JsonProperty]
        public int hat_role_level4_Lux { get; set; }

        [Option("Level 4 Range", "Default: 5", LightSettings)]
        [Limit(1, 10)]
        [JsonProperty]
        public float hat_role_level4_Range { get; set; }


        [Option("Lux Percent", "The lux for the miner's hat is multiplied with this value. Default 100 %.", MiningHatModifier)]
        [Limit(0, 100)]
        [JsonProperty]
        public int miningLuxFactor { get; set; }

        [Option("Range Percent", "The range for the miner's hat is multiplied with this value. Default 100 %.", MiningHatModifier)]
        [Limit(0, 100)]
        [JsonProperty]
        public int miningRangeFactor { get; set; }

        [Option("Lux Percent", "The lux for the researcher's and astronaut's hat is multiplied with this value. Default 80 %", ResearcherHatModifier)]
        [Limit(0, 100)]
        [JsonProperty]
        public int researchLuxFactor { get; set; }

        [Option("Range Percent", "The range for the researcher's and astronaut's hat is multiplied with this value. Default 100 %", ResearcherHatModifier)]
        [Limit(0, 100)]
        [JsonProperty]
        public int researchRangeFactor { get; set; }

        [Option("Use Hat Lights", "", Main)]
        [JsonProperty]
        public bool useHatLights { get; set; }

        [Option("Use Suit Lights", "", Main)]
        [JsonProperty]
        public bool useSuitLights { get; set; }

        /*
         [Option("Use Duplicant Lights", "", Main)]
          [JsonProperty]
          public bool useDupeLights { get; set; }
      */
    }
}

/*
[HarmonyPatch(typeof(MinionResume))]
[HarmonyPatch("AddHat")]
public class ShinyHats
{
    public const int LIGHTBUG_LUX = 1800;
    public static readonly Vector2 LIGHTBUG_OFFSET = new Vector2(-0.1f, 0f);
    public static readonly Color LIGHTBUG_OVERLAYCOLOR = new Color(0.56f, 0.56f, 0.56f, 1f);
    public static readonly Color LIGHTBUG_COLOR_PURPLE = new Color(0.64f, 0.41f, 0.12f);

    public static void Postfix(MinionResume __instance, string hat_id, KBatchedAnimController controller)
    {
        if (!hat_id.StartsWith("hat_role_mining"))
        {
            return;
        }

        GameObject gameObject = controller.gameObject;
        Light2D light2D = gameObject.AddOrGet<Light2D>();
        light2D.Color = LIGHTBUG_COLOR_PURPLE;
        light2D.overlayColour = LIGHTBUG_OVERLAYCOLOR;
        light2D.Range = 5f;
        light2D.Angle = 0f;
        light2D.Direction = new Vector2(0f, -1f);
        light2D.Offset = LIGHTBUG_OFFSET;
        light2D.shape = LightShape.Cone; // cone
        light2D.drawOverlay = true;
        light2D.Lux = LIGHTBUG_LUX;
        light2D.enabled = true;
        gameObject.AddOrGet<LightSymbolTracker>().targetSymbol = "snapTo_light_locator";
        //gameObject.AddOrGetDef<CreatureLightToggleController.Def>();

        gameObject.AddOrGetDef<LightController.Def>();
    }
}

[HarmonyPatch(typeof(MinionResume))]
[HarmonyPatch("RemoveHat")]
public class ShinyHatsRemove
{
    public static void Prefix(MinionResume __instance, KBatchedAnimController controller)
    {
        GameObject gameObject = controller.gameObject;
        Light2D light2D = gameObject.AddOrGet<Light2D>();
        if (light2D != null) light2D.enabled = false;
    }
}
*/
// MinionResume
// public void RemoveHat()