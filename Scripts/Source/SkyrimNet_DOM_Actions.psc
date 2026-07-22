Scriptname SkyrimNet_DOM_Actions extends Quest

SkyrimNet_SexLab_Scene_Manager Property manager Auto
SkyrimNet_SexLab_Actions Property actions Auto
import SkyrimNet_DOM_API
import SkyrimNet_SexLab_Utilities

Idle Property pa_HugA Auto  ; IDLE:000F4699

;------------------------------------
; Shared Functions 
;------------------------------------
Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Actions",func, msg, Notification)
EndFunction
DOM_Actor Function Get_Slave(String func, Actor slaveActor,bool error_non_dom_actor=False) global
    return SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions",func, slaveActor, error_non_dom_actor, false)
EndFunction

Function Setup() 
    Quest q = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Scene_Manager
    if q == None 
        Trace("Setup","Failed to get SkyrimNet_SexLab_Scene_Manager")
        return 
    endif 
    manager = q as SkyrimNet_SexLab_Scene_Manager
    actions = q as SkyrimNet_SexLab_Actions
    pa_HugA = Game.GetFormFromFile(0x000F4699, "Skyrim.esm") as Idle
EndFunction

;------------------------------------
;  Action Functions 
;------------------------------------
Function StartScene_masturbate(String intent, Actor speaker, Actor Superior, String style="", String position="")
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Start", speaker, True) 
    if slave == None 
        return 
    endif 

    if style == "forceful"
        style = "hard"
    elseif style == "normal"
        style = ""
    elseif style == "gentle"
        style = "gentle"
    endif 

    ;SkyrimNet_DOM_API. RegisterEvent(String event_name, String msg, Actor source=None, Actor target=None)
    if !slave.is_behaviour_masturbate
        if position == "standing"
            slave.EnterMasturbateStanding(superior) 
        elseif position == "laying"
            slave.EnterMasturbateLaying(superior) 
        else
            slave.EnterMasturbateKneeling(superior) 
        endif 
        RegisterEvent("DOM_Obey", speaker.GetDisplayName()+" obeys, and starts "+position+" to "+style+" masturbate for "+intent, speaker, superior)
    else
        RegisterEvent("DOM_Obey", speaker.GetDisplayName()+" obeys, and tries to "+style+" masturbate harder for "+intent, speaker, superior)
        slave.MasturbateHarder(superior) 
    endif 
EndFunction 
Function StopScene_Masturbate(String intent, Actor speaker, Actor Superior, bool allowed=false)
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Stop", speaker, True) 
    if slave == None 
        return 
    endif 

    if allowed
        RegisterEvent("DOM_Obey", speaker.GetDisplayName()+" obeys, and stops masturbating for "+intent, speaker, superior)
    else
        SkyrimNet_DOM_API.AddPunishmentReason("SkyrimNet_DOM_Actions", "StopScene_Masturbate", superior, speaker, slave, "didnt obey")
    endif 

    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    if main == None 
        Trace("StopScene_Masturbate", "Failed to get SkyrimNet_DOM_Main")
        return 
    endif 
    main.d_keys.DOMDoStandStill(speaker)

EndFunction 


Function StartScene_Consensual_Two(String intent, Actor speaker, Actor Superior, Actor target, string style="", string method="", String direction="", String setting_name="")
    String speaker_name = GetDisplayname(speaker)
    String target_name = GetDisplayname(target)
    String superior_name = GetDisplayname(superior)
    if target  == speaker 
        target = superior
    endif 
    Trace("StartScene_Consensual_Two","intent:"+intent+" speaker:"+speaker_name+" + "+target_name+" style: "+style+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name)
    if method == "hug" || method == "single hug"
        target.playIdleWithTarget(pa_HugA, speaker) 
        Actor sender = speaker 
        Actor receiver = target 
        if direction == "get" || direction == "getting"
            sender = target 
            receiver = speaker 
        endif 
        String msg = sender.GetDisplayName()+" hugs "+receiver.GetDisplayName()+"."
        DirectNarration(msg, speaker, target)
        return None 
    endif 
    RegisterEvent("DOM_Obey", speaker_name+" obeys "+superior_name+" and "+direction+" "+method+" with "+target_name, speaker, target)
    if actions == None
        Trace("StartScene_Consensual_Two", "actions is None, aborting")
        return
    endif
    actions.StartScene_Consensual_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name) 
EndFunction

Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor superior, Actor target=None, string style="", string method="", String direction="", bool speaker_victim=false, String setting_name="")
    String speaker_name = GetDisplayname(speaker)
    String superior_name = GetDisplayname(superior)
    String target_name = GetDisplayname(target)
    Trace("StartScene_Nonconsensual_Two","intent:"+intent+" speaker:"+speaker_name+" target:"+target_name+" speaker_victim:"+speaker_victim+" style: "+style+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name)
    if !speaker_victim
        RegisterEvent("DOM_Obey", speaker_name+" obeys "+superior_name+" and sexually assaults "+target_name+" by "+direction+" "+method, speaker, target)
    endif 
    if actions == None
        Trace("StartScene_Nonconsensual_Two", "actions is None, aborting")
        return
    endif
    actions.StartScene_Nonconsensual_Two(intent, speaker, target, style=style, method=method, direction=direction, speaker_victim=speaker_victim, setting_name=setting_name) 
EndFunction

Function StartScene_Punish_Two(String intent, Actor speaker, Actor superior, Actor target=None, string style="", string method="", String direction="", String setting_name="")
    String speaker_name = GetDisplayname(speaker)
    String superior_name = GetDisplayname(superior)
    String target_name = GetDisplayname(target)
    Trace("StartScene_Punish_Two","intent:"+intent+" speaker:"+speaker_name+" superior:"+superior_name+" target:"+target_name+" style: "+style+" method:"+method+" direction: "+direction+" setting_name:"+setting_name)
    if target == speaker
        target = superior
    endif
    RegisterEvent("DOM_Obey", speaker_name+" obeys "+superior_name+" and punishes "+target_name+" by "+direction+" "+method, speaker, target)
    if actions == None
        Trace("StartScene_Punish_Two", "actions is None, aborting")
        return
    endif
    actions.StartScene_Punish_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name)
EndFunction

;------------------------------------
;  Refused Functions 
;------------------------------------
Function AddPunishmentReason(String reason, Actor rejector, Actor superior)
    String rejector_name = GetDisplayname(rejector)
    String superior_name = GetDisplayname(superior)
    Trace("AddPunishmentReason","reason: "+reason+" "+rejector_name+" "+superior_name)
    ;String msg = rejector_name+" "+style+" refused "+superior_name+"'s order to "+reason
    ;DirectNarration(msg, rejector, superior) 

    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions","is_not_masturbating_isEligible",rejector, false) 
    if slave != None 
        SkyrimNet_DOM_API.AddPunishmentReason("SkyrimNet_DOM_Actions", "Sex_Start_Helper", superior, rejector, slave, reason) 
    endif 

EndFunction

; ----------------------------------------------
; Dress/Undress
; ----------------------------------------------

Function Undress_Execute(Actor speaker, Actor superior)
    DOM_Actor slave = Get_Slave("Undress_Execute", speaker, true)
    if slave == None
        return
    endif
    if !slave.mind.should_be_naked
        slave.mind.SetObedientTimer(1)
    endif
    slave.SetShouldBeNaked(superior)
EndFunction

Function Dress_Execute(Actor speaker, Actor superior)
    DOM_Actor slave = Get_Slave("Dress_Execute", speaker, true)
    if slave == None
        return
    endif
    slave.UnsetShouldBeNaked(superior)
EndFunction

Bool Function Dress_IsEligible(Actor slaveActor, string contextJson, string paramsJson) global
    return UndressDress_IsEligible(slaveActor, contextJson, paramsJson, true)
EndFunction

Bool Function Undress_IsEligible(Actor slaveActor, string contextJson, string paramsJson) global
    return UndressDress_IsEligible(slaveActor, contextJson, paramsJson, false)
EndFunction

Bool Function UndressDress_IsEligible(Actor slaveActor, string contextJson, string paramsJson, Bool is_naked) global
    String name = slaveActor.GetDisplayName()
    DOM_Actor slave = Get_Slave("UndressDress_IsEligible", slaveActor) 
    if slave == None 
        Trace("UndressDress_IsEligible",name+" is not a name.")
        return false 
    endif 
    bool value = slave.is_naked == is_naked
    if is_naked
        Trace("UndressDress_IsEligible","Slave "+name+" can dress: "+value)
    else 
        Trace("UndressDress_IsEligible","Slave "+name+" can undress: "+value)
    endif 
    return value 
EndFunction 

Function UndressDress_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("UndressDress_Execute", slaveActor.GetDisplayName()+" context:"+ contextJson+" params:"+paramsJson)
    DOM_Actor slave = Get_Slave("SripDress_Execute", slaveActor,true) 
    if slave == None 
        return 
    endif 

    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "undress")
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer()) 
    if choice == "starts to undress" || choice == "starts to dress" || choice == "obey"
        if type == "dress"
            slave.UnsetShouldBeNaked(superior)
        else
            if !slave.mind.should_be_naked
                slave.mind.SetObedientTimer(1)
            endif 
            slave.SetShouldBeNaked(superior)
        endif 
    else 
        String reason = "refusing to strip"
        if choice == "dress" 
            reason = "didnt listen"
        endif 
        SkyrimNet_DOM_API.AddPunishmentReason("SkyrimNet_DOM_Actions", "UndressDress_Execute", superior, slaveActor, slave, reason)
    endif 
EndFunction

Function Words_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("Words_Execute", slaveActor.GetDisplayName()+" context:"+ contextJson+" params:"+paramsJson)
    DOM_Actor slave = Get_Slave("Words_Execute", slaveActor) 
    if slave == None 
        return 
    endif 

    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "accept")
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer()) 
    if choice == "accept"
        String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "being disrespectful")
        if type == "praise"
            String reason = SkyrimNetApi.GetJsonString(paramsJson, "reason", "good slave")
            slave.StartPraising(superior,reason,"tell")
        else
            String kind = SkyrimNetApi.GetJsonString(paramsJson, "kind", "useless")
            if kind == "calling them useless"
                kind = "useless"
            elseif kind == "calling them worthless"
                kind = "worthless"
            elseif kind == "disgraceful"
                kind = "disgrace"
            endif
            slave.StartInsultingWith(superior,kind)
        endif 
    Else
        SkyrimNet_DOM_API.AddPunishmentReason("SkyrimNet_DOM_Actions", "Words_Execute", superior, slaveActor, slave, "didnt listen") 
    endif 
EndFunction
