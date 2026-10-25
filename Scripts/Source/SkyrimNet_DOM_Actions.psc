Scriptname SkyrimNet_DOM_Actions extends Quest

SkyrimNet_SexLab_Scene_Manager Property manager Auto
SkyrimNet_SexLab_Actions Property actions Auto
import SkyrimNet_DOM_API
import SkyrimNet_SexLab_Utilities

Idle Property pa_HugA Auto  ; IDLE:000F4699
SkyrimNet_DOM_Main Property dom_main Auto

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
    dom_main = (self as Quest) as SkyrimNet_DOM_Main
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
    ; speaker arg is the slave; superior is the order-giver
    String msg = superior_name+" orders "+speaker_name+" to "+action_desc
    int ttl = 100000
    if dom_main
        ttl = dom_main.short_lived_ttl
    endif
    SkyrimNetApi.RegisterShortLivedEvent("obey_command", "Obey Command", msg, "", ttl, superior, speaker)
EndFunction

Int Function GateSlave(Actor superior, Actor slave, String kind, String actionDesc, Bool rollObedience=false)
    ; LLM chose the action: no WillObey roll. Player menu clicks pass rollObedience=true.
    return SkyrimNet_DOM_Obedience.TryOrder(superior, slave, kind, actionDesc, rollObedience)
EndFunction

String Function SexOrderDesc(Actor ordered, Actor superior, Actor speaker, Actor target, String method, Actor participate=None)
    Actor partner = SkyrimNet_DOM_Obedience.SexCommandPartner(ordered, superior, speaker, target, participate)
    return SkyrimNet_DOM_Obedience.FormatSexCommand(method, partner)
EndFunction

DOM_Keys Function GetKeys()
    if !dom_main
        Setup()
    endif
    if dom_main && dom_main.d_keys
        return dom_main.d_keys
    endif
    return None
EndFunction

;------------------------------------
;  Action Functions 
;------------------------------------
Function StartScene_masturbate(String intent, Actor speaker, Actor Superior, String position="", Bool rollObedience=false)
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Start", speaker, True) 
    if slave == None 
        return 
    endif 

    String desc = "masturbate"
    if position != ""
        desc = "masturbate "+position
    endif
    Int gate = GateSlave(superior, speaker, "masturbate", desc, rollObedience)
    if gate == 0
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
    SaveThreadsJson()
EndFunction 
Function StopScene_Masturbate(String intent, Actor speaker, Actor Superior, bool allowed=false, Bool rollObedience=false)
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Stop", speaker, True) 
    if slave == None 
        return 
    endif 

    if allowed
        Int gate = GateSlave(superior, speaker, "masturbate_stop", "stop masturbating", rollObedience)
        if gate == 0
            return
        endif
    else
        SkyrimNet_DOM_API.AddPunishmentReason("SkyrimNet_DOM_Actions", "StopScene_Masturbate", superior, speaker, slave, "didnt obey")
    endif 

    if !dom_main
        Trace("StopScene_Masturbate", "Failed to get SkyrimNet_DOM_Main")
        return 
    endif 
    if !dom_main.d_keys
        Trace("StopScene_Masturbate", "dom_main.d_keys is None")
        return
    endif
    dom_main.d_keys.DOMDoStandStill(speaker)
    SaveThreadsJson()
EndFunction

; Push DOM threads after masturbate start/stop so sexlab_get_threads / threads.json stay current.
; SaveThreadsJson is SexLab's shim for DOM (-> Scene_Manager.PushDomThreads); works on older SexLab too.
Function SaveThreadsJson()
    SkyrimNet_SexLab_Scene_Manager sm = manager
    if sm == None
        sm = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Scene_Manager
        manager = sm
    endif
    if sm == None
        Trace("SaveThreadsJson", "SkyrimNet_SexLab_Scene_Manager is None")
        return
    endif
    sm.SaveThreadsJson()
    Trace("SaveThreadsJson", "--- pushed DOM threads")
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
        return
    endif 
    if actions == None
        Trace("StartScene_Consensual_Two", "actions is None, aborting")
        return
    endif
    String sexDesc = SexOrderDesc(speaker, superior, speaker, target, method)
    Int gate = GateSlave(superior, speaker, "sex", sexDesc)
    if gate == 0
        return
    endif
    if gate < 0
        RegisterObeyCommand(speaker, superior, sexDesc)
    endif
    actions.StartScene_Consensual_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name) 
EndFunction

; style omitted from quest signature (ExecuteQuestFunction max 8 args); always pass "" to SexLab
Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor superior, Actor target, Actor victim, string method="", String direction="", String setting_name="")
    if !target || target == speaker
        target = superior
    endif
    if !victim
        victim = speaker
    endif
    if !target
        Trace("StartScene_Nonconsensual_Two","target and superior are None, aborting")
        return
    endif
    String speaker_name = GetDisplayname(speaker)
    String superior_name = GetDisplayname(superior)
    String target_name = GetDisplayname(target)
    String victim_name = GetDisplayname(victim)
    Trace("StartScene_Nonconsensual_Two","intent:"+intent+" speaker:"+speaker_name+" target:"+target_name+" victim:"+victim_name+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name)
    if actions == None
        Trace("StartScene_Nonconsensual_Two", "actions is None, aborting")
        return
    endif
    RegisterObeyCommand(speaker, superior, direction+" "+method)
    actions.StartScene_Nonconsensual_Two(intent, speaker, target, victim, style="", method=method, direction=direction, setting_name=setting_name) 
EndFunction

; style omitted from quest signature (ExecuteQuestFunction max 8 args); always pass "" to SexLab
Function StartScene_Consensual_Three(String intent, Actor speaker, Actor Superior, Actor target, string method="", String direction="", String setting_name="", Actor participate)
    String speaker_name = GetDisplayname(speaker)
    String target_name = GetDisplayname(target)
    String superior_name = GetDisplayname(superior)
    if !target || target == speaker 
        target = superior
    endif 
    if !target
        Trace("StartScene_Consensual_Three","target and superior are None, aborting")
        return
    endif
    if participate == None || participate == speaker || participate == target 
        participate = superior
    endif
    Trace("StartScene_Consensual_Three","intent:"+intent+" speaker:"+speaker_name+" + "+target_name+" direction: "+direction+" intent: "+intent+" method:"+method+" setting_name:"+setting_name+" participate:"+GetDisplayname(participate))
    if actions == None
        Trace("StartScene_Consensual_Three", "actions is None, aborting")
        return
    endif
    String sexDesc = SexOrderDesc(speaker, superior, speaker, target, method, participate)
    Int gate = GateSlave(superior, speaker, "sex", sexDesc)
    if gate == 0
        return
    endif
    if gate < 0
        RegisterObeyCommand(speaker, superior, sexDesc)
    endif
    actions.StartScene_Consensual_Three(intent, speaker, target, style="", method=method, direction=direction, setting_name=setting_name, participate=participate) 
EndFunction

;------------------------------------
;  WebUI TargetMenu scene_start (SexLab arg order; tags arrive as method)
;  Superior is always the player. Gate the ordered DOM slave (target when speaker is player).
;------------------------------------
Actor Function WebUI_OrderedSlave(Actor speaker, Actor target, Actor participate=None)
    Actor superior = Game.GetPlayer()
    if target && target != superior && SkyrimNet_DOM_API.IsDOMSlave(target)
        return target
    endif
    if speaker && speaker != superior && SkyrimNet_DOM_API.IsDOMSlave(speaker)
        return speaker
    endif
    if participate && participate != superior && SkyrimNet_DOM_API.IsDOMSlave(participate)
        return participate
    endif
    if target && SkyrimNet_DOM_API.IsDOMSlave(target)
        return target
    endif
    if speaker && SkyrimNet_DOM_API.IsDOMSlave(speaker)
        return speaker
    endif
    return None
EndFunction

Function WebUI_StartScene_Consensual_One(String intent, Actor speaker, string style="", string method="", String setting_name="")
    if actions == None
        Trace("WebUI_StartScene_Consensual_One", "actions is None, aborting")
        return
    endif
    Actor superior = Game.GetPlayer()
    Actor ordered = WebUI_OrderedSlave(speaker, None)
    if ordered
        String sexDesc = SexOrderDesc(ordered, superior, speaker, None, method)
        Int gate = GateSlave(superior, ordered, "sex", sexDesc, true)
        if gate == 0
            return
        endif
    endif
    actions.StartScene_Consensual_One(intent, speaker, style=style, method=method, setting_name=setting_name)
EndFunction

Function WebUI_StartScene_Consensual_Two(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="")
    if actions == None
        Trace("WebUI_StartScene_Consensual_Two", "actions is None, aborting")
        return
    endif
    Actor superior = Game.GetPlayer()
    Actor ordered = WebUI_OrderedSlave(speaker, target)
    String target_name = GetDisplayname(target)
    String sexDesc = SexOrderDesc(ordered, superior, speaker, target, method)
    if ordered
        Int gate = GateSlave(superior, ordered, "sex", sexDesc, true)
        if gate == 0
            return
        endif
    endif
    Trace("WebUI_StartScene_Consensual_Two", "intent:"+intent+" speaker:"+GetDisplayname(speaker)+" target:"+target_name+" style:"+style+" method:"+method)
    actions.StartScene_Consensual_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name)
EndFunction

Function WebUI_StartScene_Consensual_Three(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="", Actor participate)
    if actions == None
        Trace("WebUI_StartScene_Consensual_Three", "actions is None, aborting")
        return
    endif
    Actor superior = Game.GetPlayer()
    Actor ordered = WebUI_OrderedSlave(speaker, target, participate)
    String target_name = GetDisplayname(target)
    String sexDesc = SexOrderDesc(ordered, superior, speaker, target, method, participate)
    if ordered
        Int gate = GateSlave(superior, ordered, "sex", sexDesc, true)
        if gate == 0
            return
        endif
    endif
    Trace("WebUI_StartScene_Consensual_Three", "intent:"+intent+" speaker:"+GetDisplayname(speaker)+" target:"+target_name+" participate:"+GetDisplayname(participate))
    actions.StartScene_Consensual_Three(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name, participate=participate)
EndFunction

; Abuse comfort:sex / comfort:rape — transform + mind (no DOM Anim_Sexlab) then SexLab scene.
Function ComfortTransform(Actor speaker, Actor target, String line, Bool registerObey=true)
    if line != ""
        SkyrimNetApi.TransformDialogue(line)
    endif
    if registerObey && target && speaker
        RegisterObeyCommand(target, speaker, line)
    endif
EndFunction

Function ApplyComfortMindSex(Actor abuser, Actor target)
    if !dom_main
        Setup()
    endif
    DOM_Actor slave = Get_Slave("ApplyComfortMindSex", target, false)
    if !slave || !slave.mind
        return
    endif
    DOM_Mind mind = slave.mind
    DOM_Core core = None
    if dom_main
        core = dom_main.d_core
    endif
    Float mod = 1.0
    Float speed = 100.0
    if core
        mod = core.GetPredatorModifier(abuser)
        speed = core.train_speed_tell
    endif
    if mind.StartGuilt()
        mind.TrainHumiliation(speed * 0.1 * mod)
        mind.number_of_comfort = mind.number_of_comfort + 1
        mind.SendNotificationAbuse("Comforting "+GetDisplayname(target)+" with sex")
        if core
            core.TrainSkillPredator(abuser, 0.5)
        endif
    else
        Trace("ApplyComfortMindSex", GetDisplayname(target)+" refused comfort guilt")
    endif
EndFunction

Function ApplyComfortMindRape(Actor abuser, Actor target)
    if !dom_main
        Setup()
    endif
    DOM_Actor slave = Get_Slave("ApplyComfortMindRape", target, false)
    if !slave || !slave.mind
        return
    endif
    DOM_Mind mind = slave.mind
    DOM_Core core = None
    if dom_main
        core = dom_main.d_core
    endif
    Float mod = 1.0
    Float speed = 100.0
    if core
        mod = core.GetPredatorModifier(abuser)
        speed = core.train_speed_tell
    endif
    mind.TrainSubmission(speed * 0.1 * mod)
    mind.SendNotificationAbuse("Pretending to comfort "+GetDisplayname(target)+" with rape")
    if core
        core.TrainSkillPredator(abuser, 0.5)
    endif
EndFunction

Function WebUI_StartScene_Comfort_Sex(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="")
    if !dom_main || actions == None
        Setup()
    endif
    if actions == None
        Trace("WebUI_StartScene_Comfort_Sex", "actions is None, aborting")
        return
    endif
    if intent == ""
        intent = "comfort with sex"
    endif
    Actor superior = Game.GetPlayer()
    if !speaker
        speaker = superior
    endif
    String spName = GetDisplayname(speaker)
    String tgName = GetDisplayname(target)
    ; Roll first: a refusal must leave no comfort on the mind. A gated order registers the obey command itself.
    Actor ordered = WebUI_OrderedSlave(speaker, target)
    String sexDesc = SexOrderDesc(ordered, superior, speaker, target, method)
    if ordered
        Int gate = GateSlave(superior, ordered, "sex", sexDesc, true)
        if gate == 0
            return
        endif
    endif
    ComfortTransform(speaker, target, spName+" comforts "+tgName+" with loving sex.", ordered == None)
    ApplyComfortMindSex(speaker, target)
    Trace("WebUI_StartScene_Comfort_Sex", "intent:"+intent+" speaker:"+spName+" target:"+tgName)
    actions.StartScene_Consensual_Two(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name)
EndFunction

Function WebUI_StartScene_Comfort_Rape(String intent, Actor speaker, Actor target, string style="", string method="", String direction="", String setting_name="")
    if !dom_main || actions == None
        Setup()
    endif
    if actions == None
        Trace("WebUI_StartScene_Comfort_Rape", "actions is None, aborting")
        return
    endif
    if intent == ""
        intent = "pretend to comfort by sexual assault"
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    String spName = GetDisplayname(speaker)
    String tgName = GetDisplayname(target)
    ComfortTransform(speaker, target, spName+" pretends to comfort "+tgName+" by sexual assault.")
    ApplyComfortMindRape(speaker, target)
    Trace("WebUI_StartScene_Comfort_Rape", "intent:"+intent+" speaker:"+spName+" target:"+tgName)
    actions.StartScene_Nonconsensual_Two_TargetVictim(intent, speaker, target, style=style, method=method, direction=direction, setting_name=setting_name)
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

; UndressDress_Execute → DOM_Actor.SetShouldBeNaked (PAH Diary of Mine)
Function UndressDress_Execute(Actor speaker, Actor superior)
    DOM_Actor slave = Get_Slave("UndressDress_Execute", speaker, true)
    if slave == None
        return
    endif
    if !superior
        superior = Game.GetPlayer()
    endif
    Int gate = GateSlave(superior, speaker, "undress", "undress")
    if gate == 0
        return
    endif
    if gate < 0
        RegisterObeyCommand(speaker, superior, "undress")
    endif
    if !slave.mind
        Trace("UndressDress_Execute", GetDisplayname(speaker)+" mind is None, aborting")
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
    if !superior
        superior = Game.GetPlayer()
    endif
    Int gate = GateSlave(superior, speaker, "dress", "dress")
    if gate == 0
        return
    endif
    if gate < 0
        RegisterObeyCommand(speaker, superior, "dress")
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
        Trace("UndressDress_IsEligible",name+" is not a slave.")
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

; YAML wrapper: gate then DOM_Keys. op=entertain|action|follow|stand|display
Function DOMOrder_Execute(Actor akTarget, String kind, String actionDesc, String op, String arg, String arg2="")
    if !akTarget
        Trace("DOMOrder_Execute", "akTarget is None")
        return
    endif
    Actor superior = Game.GetPlayer()
    Int gate = GateSlave(superior, akTarget, kind, actionDesc)
    if gate == 0
        return
    endif
    if gate < 0
        ; no DLL / unknown kind: gate said nothing, so narrate the order like Menu.FinishOrder
        DirectNarration(superior.GetDisplayName()+" orders "+akTarget.GetDisplayName()+" to "+actionDesc+".", superior, akTarget)
        RegisterObeyCommand(akTarget, superior, actionDesc)
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("DOMOrder_Execute", "d_keys is None kind="+kind)
        return
    endif
    if op == "entertain"
        keys.DOMDoEntertain(akTarget, arg)
    elseif op == "follow"
        keys.DOMDoFollowMe(akTarget)
    elseif op == "stand"
        keys.DOMDoStandStill(akTarget)
    elseif op == "display"
        keys.DOMDoDisplay(akTarget)
    else
        Bool theFlag = arg2 == "1" || arg2 == "true"
        String typeArg = arg2
        if theFlag
            typeArg = ""
        endif
        keys.DOMDoActionActor(akTarget, arg, typeArg, theFlag)
    endif
EndFunction
