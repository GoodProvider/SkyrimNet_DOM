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

Function RegisterObeyCommand(Actor speaker, Actor superior, String action_desc)
    String speaker_name = GetDisplayname(speaker)
    String superior_name = GetDisplayname(superior)
    String msg = speaker_name+" obeys "+superior_name+" and does "+action_desc
    SkyrimNetApi.RegisterShortLivedEvent("obey_command", "Obey Command", msg, "", 100000, speaker, superior)
EndFunction

;------------------------------------
;  Action Functions 
;------------------------------------
Function StartScene_masturbate(String intent, Actor speaker, Actor Superior, String position="")
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Start", speaker, True) 
    if slave == None 
        return 
    endif 

    if !slave.is_behaviour_masturbate
        if position == "standing"
            slave.EnterMasturbateStanding(superior) 
        elseif position == "laying"
            slave.EnterMasturbateLaying(superior) 
        else
            slave.EnterMasturbateKneeling(superior) 
        endif 
    else
        slave.MasturbateHarder(superior) 
    endif 
EndFunction 
Function StopScene_Masturbate(String intent, Actor speaker, Actor Superior, bool allowed=false)
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Stop", speaker, True) 
    if slave == None 
        return 
    endif 

    if !allowed
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
    if !target || target == speaker 
        target = superior
    endif 
    if !target
        Trace("StartScene_Consensual_Two","target and superior are None, aborting")
        return
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
    if actions == None
        Trace("StartScene_Consensual_Two", "actions is None, aborting")
        return
    endif
    RegisterObeyCommand(speaker, superior, style+" "+direction+" "+method+" with "+target_name)
    actions.StartScene_Consensual_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name) 
EndFunction

Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor superior, Actor target, Actor victim, String style="", string method="", String direction="", String setting_name="")
    String speaker_name = GetDisplayname(speaker)
    String superior_name = GetDisplayname(superior)
    String target_name = GetDisplayname(target)
    String victim_name = GetDisplayname(victim)
    Trace("StartScene_Nonconsensual_Two","intent:"+intent+" speaker:"+speaker_name+" target:"+target_name+" victim:"+victim_name+" style: "+style+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name)
    if actions == None
        Trace("StartScene_Nonconsensual_Two", "actions is None, aborting")
        return
    endif
    RegisterObeyCommand(speaker, superior, style+" "+direction+" "+method)
    actions.StartScene_Nonconsensual_Two(intent, speaker, target, victim, style=style, method=method, direction=direction, setting_name=setting_name) 
EndFunction

Function StartScene_Consensual_Three(String intent, Actor speaker, Actor Superior, Actor target, Actor third, string style="", string method="", String direction="", String setting_name="", Actor participate)
    String speaker_name = GetDisplayname(speaker)
    String target_name = GetDisplayname(target)
    String superior_name = GetDisplayname(superior)
    if !target || target == speaker 
        target = superior
    endif 
    if !target
        Trace("StartScene_Consensual_Two","target and superior are None, aborting")
        return
    endif
    Trace("StartScene_Consensual_Two","intent:"+intent+" speaker:"+speaker_name+" + "+target_name+" style: "+style+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name+" participate:"+GetDisplayname(participate))
    if actions == None
        Trace("StartScene_Consensual_Three", "actions is None, aborting")
        return
    endif
    RegisterObeyCommand(speaker, superior, style+" "+direction+" "+method+" with "+target_name)
    actions.StartScene_Consensual_Three(intent, speaker, target, style, method, direction, setting_name, participate) 
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
    RegisterObeyCommand(speaker, superior, "undress")
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
    RegisterObeyCommand(speaker, superior, "dress")
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

Function Praise_Tell_Execute(Actor speaker, Actor superior)
    DOM_Actor slave = Get_Slave("Praise_Tell_Execute", speaker, true)
    if slave == None
        return
    endif
    slave.StartPraising(superior, "", "tell")
EndFunction
