Scriptname SkyrimNet_DOM_API
Import SkyrimNet_SexLab_Utilities

Function Trace(String func, String msg, Bool Notification = false) global
    Trace_Helper("SkyrimNet_DOM_API", func, msg, Notification)
EndFunction

Function Trace_Helper(String File, String Func, String msg, Bool Notification=false) global
    msg = "["+File+"."+Func+"] "+msg
    Debug.Trace(msg)
    if Notification
        Debug.Notification(msg)
    endif 
Endfunction 

DOM_Actor Function GetDOM_Actor(String File, String Func, Actor akActor, bool error_non_dom_actor=false, bool Notification=false) global
    func = func + ".GetSlave"
    DOM_API api = ( Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API)
    if api == None
        Trace_Helper(file, func,"DOM_API is None")
        return None 
    endif
    return api.GetDOMActor(akActor)
EndFunction

DOM_Actor Function GetSlave(String File, String Func, Actor akActor, bool error_non_dom_actor=false, bool Notification=false) global
    func = func + ".GetSlave"
    DOM_API api = ( Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API)
    if api == None
        Trace_Helper(file, func,"DOM_API is None")
        return None 
    endif
    if !api.IsDOMSlave(akActor)
        if error_non_dom_actor
            Trace_Helper(file, func,"called on not DOM slave "+akActor.GetDisplayName(),Notification)
        endif
        return None
    endif 
    return api.GetDOMActor(akActor)
EndFunction

Bool Function IsDOMSlave(Actor akActor) global
    DOM_API api = ( Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API)
    if api == None
        return false 
    endif
    return api.IsDOMSlave(akActor)
EndFunction

bool Function Ostim_IsInOstim(Actor akActor) global
    if !MiscUtil.FileExists("Data/Ostim.esp")
        return false 
    endif 
    return OActor.IsInOstim(akActor)
EndFunction 


Function AddPunishmentReason(String file, String func, Actor superior, Actor slaveActor, DOM_Actor slave, String reason_name) global
    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main

    ; DOM_Util d_util = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_UTIL
    int index = main.Get_Punishment_To_Index(reason_name) 
    if superior == None 
        superior = Game.GetPlayer() 
    endif 
    slave.mind.AddNextPunishmentReason(index)
    String slave_name = slaveActor.GetDisplayName() 
    String superior_name = superior.GetDisplayName()
    String msg = main.Get_Punishment_To_Description(reason_name) 
    if msg == ""
        msg = slave_name+" refused to obey "+superior_name+"'s command to "+reason_name+", this will be punished."
    else 
        msg = slave_name+msg+superior_name+". "+slave_name+" knows this will be punished."
    endif 
    Trace("AddPunishmentReason","index:"+index+" "+msg) 
    ;DirectNarration_Optional("Reason to Punish", msg, slaveActor, superior) 
    RegisterEvent("Reason to Punish", msg, slaveActor, superior) 
EndFunction

; -------------------------------------------------------------
Function Start_Masturbate(String intent, Actor speaker, Actor superior, String style="", String position="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM_Actions.esm") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("Start_Masturbate","SkyrimNet_DOM_Actions is None")
        return
    endif
    actions.StartScene_masturbate(intent, speaker, superior, style=style, position=position)
EndFunction

Function StartScene_Consensual_Two(String intent, Actor speaker, Actor Superior, Actor target, string style="", string method="", String direction="", String setting_name="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM_Actions.esm") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Consensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif
    actions.StartScene_Consensual_Two(intent, speaker, superior, target, style=style, method=method, direction=direction, setting_name=setting_name)
EndFunction

Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor superior, Actor target=None, string style="", string method="", String direction="", bool speaker_victim=false, String setting_name="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM_Actions.esm") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Nonconsensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif   
    actions.StartScene_Nonconsensual_Two(intent, speaker, superior, target, style=style, method=method, direction=direction, speaker_victim=speaker_victim, setting_name=setting_name)
EndFunction