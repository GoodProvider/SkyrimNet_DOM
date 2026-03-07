Scriptname SkyrimNet_DOM_Utils

DOM_Actor Function GetSlave(String File, String Func, Actor akActor, bool error_non_dom_actor=false, bool Notification=false) global
    func = func + ".GetSlave"
    DOM_API api = ( Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API)
    if api == None
        Trace(file, func,"DOM_API is None")
        return None 
    endif
    if !api.IsDOMSlave(akActor)
        if error_non_dom_actor
            Trace(file, func,"called on not DOM slave "+akActor.GetDisplayName(),Notification)
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

Function Trace(String File, String Func, String msg, Bool Notification=false) global
    msg = "["+File+"."+Func+"] "+msg
    Debug.Trace(msg)
    if Notification
        Debug.Notification(msg)
    endif 
Endfunction 

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
    ;Trace(file, func,msg) 
    Trace("SkyrimNet_DOM_Utils", "AddPunishmentReason","index:"+index+" "+msg) 
    DirectNarration_Optional("Reason to Punish", msg, slaveActor, superior) 
EndFunction

; Narration Functions 
; ------------------------------------------------------------
; Narration Wrappers 
; ------------------------------------------------------------


Function DirectNarration(String msg, Actor source=None, Actor target=None) global
    SkyrimNetApi.DirectNarration(msg, source, target)
    ;SkyrimNetApi.RegisterEvent("sexlab_event", msg, source, target)
    if source != None 
        msg += " source:"+source.GetDisplayName()
    endif 
    if target != None 
        msg += " target:"+target.GetDisplayName()
    endif
    Trace("SkyrimNet_DOM_Utils", "DirectNarration", msg)
EndFunction

Function DirectNarration_Optional(String event_type, String msg, Actor source=None, Actor target=None, bool optional=False) global
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main

    float unit_meter = 0.01465
    float distance = (unit_meter*main.direct_narration_max_distance) + 1 
    if source != None 
        Actor player = Game.GetPlayer()
        if player == source 
            distance = 0 
        else
            distance = unit_meter*player.GetDistance(source) 
        endif 
    endif 

    String type = "" 
    int last_audio = SkyrimNetAPI.GetTimeSinceLastAudioEnded()/1000 ; in seconds
    if last_audio >= main.direct_narration_cool_off && distance <= main.direct_narration_max_distance
        SkyrimNetApi.DirectNarration(msg, source, target)
        ;SkyrimNetApi.RegisterEvent(event_type, msg, source, target)
        type = "direct"
    else 
        if !optional && msg != ""
            SkyrimNetApi.RegisterEvent(event_type, msg, source, target)
            type = "event"
        else 
            type = "skipped"
        endif 
    endif 

    if source != None 
        msg += " source:"+source.GetDisplayName()
    endif 
    if target != None 
        msg += " target:"+target.GetDisplayName()
    endif
    Trace("SkyrimNet_DOM_Utils", "DirectNarration",type+" last_audio_secs:"+last_audio+">="+main.direct_narration_cool_off+" distance:"+distance+"<"+main.direct_narration_max_distance+" msg:"+msg)
EndFunction

Function RegisterEvent(String event_name, String msg, Actor source=None, Actor target=None) global
    if msg != "" 

        SkyrimNetApi.RegisterEvent(event_name, msg, source, target)

        ; Sets up the log message
        if source != None 
            msg += " source:"+source.GetDisplayName()
        endif 
        if target != None 
            msg += " target:"+target.GetDisplayName()
        endif
        Trace("SkyrimNet_DOM_Utils", "RegisterEvent", "event_name:"+event_name+" msg:"+msg)
    endif 
EndFunction