Scriptname SkyrimNet_DOM_Main extends Quest  

DOM_CORE Property d_core Auto
DOM_API Property d_api Auto
DOM_Sexlab Property d_sexlab Auto
DOM_Keys Property d_keys Auto
SkyrimNet_SexLab_Main Property sexlab_main Auto 

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_Main", func, msg, Notification)
EndFunction

; Punsihemt 
int punishment_to_index = 0 
int punishment_to_description = 0

; Optional DD support
Skyrimnet_UDNG_Groups Property devices_group = None AUTO

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
    Trace("Setup","starting setup")
    Load_Punishment_To_Index("Data/SKSE/Plugins/StorageUtilData/Diary Of Mine/PunishmentReasons.json")
    Load_Punishment_to_description("Data/SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json")

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
    ((self as Quest) as SkyrimNet_DOM_Events).Register_Events(DOM01) 

    SkyrimNet_DOM_Decorators.Register_Decorators() 
    SkyrimNet_DOM_Actions.Register_Actions() 

    ; DD Support 
    if MiscUtil.FileExists("Data/SkyrimNetUDNG.esp")
        devices_group = Game.GetFormFromFile(0x800, "SkyrimNetUDNG.esp") as skyrimnet_UDNG_Groups
    else 
        devices_group = None 
    endif   
EndFunction

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
    Trace("Load_Punishment_To_Index",index+" punishments loaded from "+fname)
EndFunction 
int Function Get_Punishment_To_Index(String reason)
    return JMap.getInt(punishment_to_index, reason, 0)
EndFunction

Function Load_Punishment_to_description(String fname) 
    if punishment_to_description != 0 
        JValue.release(punishment_to_description) 
    endif 
    punishment_to_description = JMap.object() 
    JValue.retain(punishment_to_description) 

    int punishments = JValue.readFromFile(fname)
    int index = JArray.count(punishments) - 1 
    while 0 <= index  
        String reason = JValue.solveStr(punishments,"["+index+"].reason")
        String description = JValue.solveStr(punishments,"["+index+"].description")
        Trace("Load_Punishment_to_description","reason:"+reason+" description:"+description) 
        JMap.setStr(punishment_to_description, reason, description) 
        index -= 1 
    endwhile 
    Trace("Load_Punishment_To_Description","punishments loaded from "+fname)
EndFunction 
String Function Get_Punishment_To_Description(String reason) 
    return JMap.getStr(punishment_to_description, reason, "")
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