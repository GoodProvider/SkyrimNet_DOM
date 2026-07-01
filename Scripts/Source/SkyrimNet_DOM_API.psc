Scriptname SkyrimNet_DOM_API

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
    Trace("DirectNarration", msg)
EndFunction

int Function DirectNarration_Optional(String event_type, String msg, Actor source=None, Actor target=None, bool optional=False) global
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if main == None 
        Trace("DirectNarration_Optional","SkyrimNet_SexLab_Main is None")
        return 0
    endif 

    bool source_none = source == None 
    bool target_none = target == None 
    Trace("DirectNarration_Optional","event_type:"+event_type+" msg:"+msg+" source_none:"+source_none+" target_none:"+target_none)

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
    int queue_size = SkyrimNetAPI.GetSpeechQueueSize()
    int last_audio = SkyrimNetAPI.GetTimeSinceLastAudioEnded()/1000 ; in seconds
    float time_current = Utility.GetCurrentRealTime() 
    float time_delta = time_current - main.direct_narration_last_time 

    if time_delta > main.direct_narration_cool_off && queue_size == 0 && (last_audio >= main.direct_narration_cool_off && distance <= main.direct_narration_max_distance)
        SkyrimNetApi.DirectNarration(msg, source, target)
        main.direct_narration_last_time = time_current
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
    Trace("DirectNarration_Optional","type:"+type+" narration_delta:"+time_delta+" queue_size:"+queue_size+" last_audio_secs:"+last_audio+">?"+main.direct_narration_cool_off+" distance:"+distance+"<?"+main.direct_narration_max_distance+" msg:"+msg)
    if type == "direct"
        return 1
    else 
        return 0
    endif 
EndFunction

int Function RegisterEvent(String event_name, String msg, Actor source=None, Actor target=None) global
    if msg != "" 
        ; Sets up the log message
        if source != None 
            msg += " source:"+source.GetDisplayName()
        endif 
        if target != None 
            msg += " target:"+target.GetDisplayName()
        endif
        Trace("RegisterEvent", "event_name:"+event_name+" msg:"+msg)

        return SkyrimNetApi.RegisterEvent(event_name, msg, source, target)
    endif 
    return 0
EndFunction