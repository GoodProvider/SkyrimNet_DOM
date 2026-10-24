Scriptname SkyrimNet_DOM_Main extends Quest  

DOM_CORE Property d_core Auto
DOM_API Property d_api Auto
DOM_Sexlab Property d_sexlab Auto
DOM_Keys Property d_keys Auto
SkyrimNet_SexLab_Main Property sexlab_main Auto 

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Main", func, msg, Notification)
EndFunction

; Punishment reason lookup
String PUNISHMENT_DEFAULT_REASON = "no reason"
int punishment_to_index = 0 
int punishment_to_description = 0
int punishment_default_index = 0

; Optional DD support
Quest Property devices_group = None AUTO

; Plugin_SkyrimNet_DOM dashboard settings (config/plugins/SkyrimNet_DOM/manifest.yaml)
String PLUGIN_CONFIG = "Plugin_SkyrimNet_DOM"
bool Property ext2_enabled = false Auto
int Property notification_ring = 20 Auto
int Property short_lived_ttl = 100000 Auto
; Injury Engine torture by the player: true = WebUI reason list, false = random open reason
bool Property torture_choose_reason = true Auto
; Healing Hands / SexLab Aid by the player on a non-shocked slave: true = WebUI praise reason list, false = DOM picks
bool Property heal_choose_reason = true Auto

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()

;    SkyrimNet_DOM_Actions.Register_Actions() 

    Trace("Setup","starting setup")
    Load_Punishment_To_Index("Data/SKSE/Plugins/StorageUtilData/Diary Of Mine/PunishmentReasons.json")
    Load_Punishment_Reasons("Data/SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json")
    punishment_default_index = JMap.getInt(punishment_to_index, PUNISHMENT_DEFAULT_REASON, 0)

    String err_msg = "" 
    if !MiscUtil.FileExists("Data/DiaryOfMine.esm")
        err_msg = "Data/DiaryOfMine.esm not found"
    endif 
    Quest DOM01 = None 
    Form DOM02 = None
    if err_msg == "" 
        String DOM_FILE = "DiaryOfMine.esm"
        int DOMO1_ID = 0x00000D61
        int DOM02Topic_ID = 0x000ED87C

        DOM01 = Game.GetFormFromFile(DOMO1_ID, "DiaryOfMine.esm") AS Quest 
        if DOM01 == None 
            err_msg = "GetFormFromFile from diaryOfMain.esm failed"
        else 
            d_core = DOM01 as DOM_CORE
            d_api = DOM01 as DOM_API
        endif 

        DOM02 = Game.GetFormFromFile(DOM02Topic_ID,DOM_FILE)
        if DOM02 == None 
            err_msg = "GetFormFromFile for DOM02 from diaryOfMain.esm failed"
        else 
             d_keys = DOM02 as DOM_KEYS
             d_sexlab = DOM02 as DOM_Sexlab 
        endif
    endif 
    if err_msg != ""
        Trace("SetUp", err_msg)
        Debug.MessageBox(err_msg+"\n"+"SkyrimNet_DOM will not work")
        return 
    endif 

    Trace("Setup","DOM01:"+DOM01)
    SkyrimNet_DOM_Decorators.Register_Decorators() 
    ((self as Quest) as SkyrimNet_DOM_Actions).Setup() 
    ((self as Quest) as SkyrimNet_DOM_Events).Setup(DOM01) 

    ; DD Support 
    if MiscUtil.FileExists("Data/SkyrimNetUDNG.esp")
        devices_group = Game.GetFormFromFile(0x800, "SkyrimNetUDNG.esp") as Quest
    else 
        devices_group = None 
    endif

    UnRegisterForModEvent("SkyrimNet_OnPluginConfigSaved")
    RegisterForModEvent("SkyrimNet_OnPluginConfigSaved", "OnPluginConfigSaved")
    ApplyPluginConfig()
EndFunction

Function ApplyPluginConfig()
    ext2_enabled = SkyrimNetApi.GetConfigBool(PLUGIN_CONFIG, "dom.events.ext2", false)

    int ring = SkyrimNetApi.GetConfigInt(PLUGIN_CONFIG, "dom.events.notification_ring", 20)
    if ring < 5
        ring = 5
    elseif ring > 50
        ring = 50
    endif
    notification_ring = ring

    int ttl = SkyrimNetApi.GetConfigInt(PLUGIN_CONFIG, "dom.events.short_lived_ttl", 100000)
    if ttl < 1000
        ttl = 1000
    elseif ttl > 600000
        ttl = 600000
    endif
    short_lived_ttl = ttl

    torture_choose_reason = SkyrimNetApi.GetConfigBool(PLUGIN_CONFIG, "dom.punish.torture_choose_reason", true)
    heal_choose_reason = SkyrimNetApi.GetConfigBool(PLUGIN_CONFIG, "dom.praise.heal_choose_reason", true)

    SkyrimNet_DOM_Events events = (self as Quest) as SkyrimNet_DOM_Events
    if events
        events.notifications_size = notification_ring
        events.ApplyExt2Events()
    endif
    Trace("ApplyPluginConfig", "ext2:"+ext2_enabled+" ring:"+notification_ring+" ttl:"+short_lived_ttl+" torture_choose_reason:"+torture_choose_reason+" heal_choose_reason:"+heal_choose_reason)
EndFunction

Event OnPluginConfigSaved(string eventName, string strArg, float numArg, Form sender)
    Trace("OnPluginConfigSaved", "--- reloading plugin config")
    ApplyPluginConfig()
EndEvent

Function Load_Punishment_To_Index(String fname) 
    if punishment_to_index != 0 
        JValue.release(punishment_to_index) 
    endif 
    punishment_to_index = JMap.object() 
    JValue.retain(punishment_to_index)

    int punishments = JValue.readFromFile(fname)
    int key_obj  = JMap.getObj(punishments, "punishmentsList")
    String str_index = "Punish000"
    int index = 0 
    while JMap.HasKey(key_obj, str_index) 
        String reason = JValue.solveStr(key_obj,"."+str_index+".reason")
        JMap.setInt(punishment_to_index, reason, index)
        index += 1 
        if index < 10 
            str_index = "Punish00"+index
        elseif index < 100
            str_index = "Punish0"+index
        else
            str_index = "Punish"+index
        endif 
    endwhile 
    ;Trace("Load_Punishment_To_Index",index+" punishments loaded from "+fname)
EndFunction 
int Function Get_Punishment_To_Index(String reason)
    int index = JMap.getInt(punishment_to_index, reason, -1)
    if index < 0
        Trace("Get_Punishment_To_Index", "unknown reason token: "+reason)
        return punishment_default_index
    endif
    return index
EndFunction

; True when reason is a loaded punishment token (free text is not).
bool Function Has_Punishment_Reason(String reason)
    return JMap.hasKey(punishment_to_index, reason)
EndFunction

Function Register_Punishment_Reason(String name, int index, String description)
    if name == ""
        return
    endif
    int existing = JMap.getInt(punishment_to_index, name, -1)
    if existing >= 0 && existing != index
        Trace("Register_Punishment_Reason", "index conflict for "+name+": was "+existing+", now "+index)
    endif
    JMap.setInt(punishment_to_index, name, index)
    if description != ""
        JMap.setStr(punishment_to_description, name, description)
    endif
EndFunction

Function Load_Punishment_Reasons(String fname)
    if punishment_to_description != 0
        JValue.release(punishment_to_description)
    endif
    punishment_to_description = JMap.object()
    JValue.retain(punishment_to_description)

    int punishments = JValue.readFromFile(fname)
    if punishments == 0
        Trace("Load_Punishment_Reasons", "failed to read "+fname)
        return
    endif

    int count = JArray.count(punishments)
    int i = 0
    while i < count
        String reason = JValue.solveStr(punishments, "["+i+"].reason")
        String description = JValue.solveStr(punishments, "["+i+"].description")
        int index = JValue.solveInt(punishments, "["+i+"].index", -1)
        if reason != "" && index >= 0
            Register_Punishment_Reason(reason, index, description)
            int aliases = JValue.solveObj(punishments, "["+i+"].aliases")
            if aliases != 0
                int acount = JArray.count(aliases)
                int j = 0
                while j < acount
                    String alias_string = JArray.getStr(aliases, j)
                    Register_Punishment_Reason(alias_string, index, description)
                    j += 1
                endwhile
            endif
        endif
        i += 1
    endwhile
EndFunction

; Description of reason only ("" when punishment_reason.json does not know it; no default fallback)
String Function Get_Punishment_Description_Exact(String reason)
    return JMap.getStr(punishment_to_description, reason, "")
EndFunction

String Function Get_Punishment_To_Description(String reason)
    String description = JMap.getStr(punishment_to_description, reason, "")
    if description == ""
        description = JMap.getStr(punishment_to_description, PUNISHMENT_DEFAULT_REASON, "")
    endif
    return description
EndFunction

;String Function Get_Reason_to_Punishment(String k) 
    ;return JMap.GetStr(reason_to_punishment, k, "") 
;EndFunction
;
;String[] Function Get_PunishmentReasons() 
    ;return JMap.allKeysPArray(reason_to_punishment) 
;EndFunction

bool Function IsDomSlave(ACtor akActor) 
    return d_api.IsDOMSlave(akACtor) 
EndFunction