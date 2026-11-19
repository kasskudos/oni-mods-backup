using PeterHan.PLib.Lighting;
using PeterHan.PLib.Options;
using HarmonyLib;
using PeterHan.PLib.Core;
//using PeterHan.PLib.Core;

namespace ShinyHats
{
    // All code taken from Expanded Lights.
    //


    public class ShinyHats_EL_Patch
    {
        public static bool didStartUp_Building;
        public static bool didStartUp_Db;
        public static ShinyHatsOptions Options;

        /// <summary>
        ///     Light shape: Directed cone according to component rotation
        /// </summary>
        public static ILightShape 
            DirectedCone,
            Beam5,
            SmoothCircle,
            OffsetCone,
            FixedSemi,
            Semicircle,
            OffsetSemi;

        public class Mod_OnLoad : KMod.UserMod2
        {

            public override void OnLoad(Harmony harmony)
            {
                PUtil.InitLibrary(false);
                harmony.PatchAll();

                PLightManager lightManager = new();

                DirectedCone = lightManager.Register("SkyLib.LightShape.Cone", LightDefs.LightCone);
                Beam5        = lightManager.Register("SkyLib.LightShape.Beam5", LightDefs.LinearLight5);
                SmoothCircle = lightManager.Register("SkyLib.LightShape.Circle", LightDefs.LightCircle);
                OffsetCone   = lightManager.Register("SkyLib.LightShape.OffsetCone", LightDefs.OffsetCone);
                FixedSemi    = lightManager.Register("SkyLib.LightShape.FixedSemi", LightDefs.FixedLightSemicircle);
                Semicircle   = lightManager.Register("SkyLib.LightShape.Semicircle", LightDefs.LightSemicircle);
                OffsetSemi   = lightManager.Register("SkyLib.LightShape.OffsetSemi", LightDefs.OffsetSemicircle);
                /*
                                DirectedCone = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.Cone", LightDefs.LightCone);
                                Beam5 = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.Beam5", LightDefs.LinearLight5);
                                SmoothCircle = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.Circle", LightDefs.LightCircle);
                                OffsetCone = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.OffsetCone", LightDefs.OffsetCone);
                                FixedSemi = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.FixedSemi", LightDefs.FixedLightSemicircle);
                                Semicircle = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.Semicircle", LightDefs.LightSemicircle);
                                OffsetSemi = PLightShape.Register("SkyLib.LightShape.KillfaceCannotCode.OffsetSemi", LightDefs.OffsetSemicircle);
                */

                Options = new ShinyHatsOptions();

                ShinyHatsOptions newOptions = POptions.ReadSettings<ShinyHatsOptions>();
                if (newOptions != null)
                {
                    Options = newOptions;
                }
                new POptions().RegisterOptions(this, typeof(ShinyHatsOptions));

                //POptions.RegisterOptions(new Mod_OnLoad(), typeof(ShinyHatsOptions));
                POptions.ReadSettings<ShinyHatsOptions>();
            }
        }


    }
}