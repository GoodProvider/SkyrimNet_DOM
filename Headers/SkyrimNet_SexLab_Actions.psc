Scriptname SkyrimNet_SexLab_Actions extends Quest
SkyrimNet_SexLab_Main Property main Auto
SkyrimNet_SexLab_Scene_Manager Property manager Auto
SexLabFramework Property sexlab Auto
Idle Property pa_HugA Auto
Function Trace(String func, String msg, Bool notification=False) global Native
Function Setup() Native
Function StartScene_Consensual_One(String intent, Actor speaker, string style="", String method="", String setting_name="") Native
Function StartScene_Nonconsensual_One(String intent, Actor speaker, string style="", String method="", String setting_name="") Native
Function StartScene_Consensual_Two(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="") Native
Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor target=None, Actor victim, string style="", string method="", String direction="", String setting_name="") Native
Function StartScene_Nonconsensual_Two_SpeakerVictim(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="") Native
Function StartScene_Nonconsensual_Two_TargetVictim(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="") Native
Function StartScene_Consensual_Three(String intent, Actor speaker, Actor target, string style, string direction, string method, String setting_name="", Actor participate) Native
Function StartScene_Nonconsensual_Three(String intent, Actor speaker, Actor target, string style, string method, string direction, bool speaker_victim, String setting_name="", Actor participate) Native
Function SceneStop(Actor speaker, String style) Native
Function SceneStop_Target(Actor speaker, Actor target, String style) Native
Function StartScene_Refused_Two(String intent, Actor speaker, Actor target, string style="", string method="", string direction="") Native
Function SceneStop_Event(Actor speaker, Actor target, String style) Native
Function StartScene_Event(String intent, Actor speaker, Actor target=None, Actor victim=None,     string style="", string method="", String direction="", String event_hook="", String setting_name="",     Actor participate_3=None) Native
Function Change_Outfit(Actor stripper, Actor stripped, String style, String how, String narration) Native
bool Function BodyAnimation_IsEligible(Actor akActor, string contextJson, string paramsJson) Native
