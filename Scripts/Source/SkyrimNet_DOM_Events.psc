Scriptname SkyrimNet_DOM_Events extends Quest  

SkyrimNet_DOM_Main Property main  Auto  
Actor Property player  Auto  
String Property player_name Auto

int Property runningMap = 0 Auto
int Property lastSeenMap = 0 Auto 
DOM_API Property d_api = None Auto

float Property timeLastEvent = 0.0 Auto 

Function Register_Events(SkyrimNet_DOM_Main _main)
    main = _main 
    player = Game.GetPlayer()
    player_name = player.GetDisplayName()
    timeLastEvent = Utility.GetCurrentRealTime()

    Quest DOM01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") AS Quest 
    DOM_core d_core = DOM01 as DOM_Core
    ; DOM_SlaveManager d_manager = DOM01 AS DOM_SlaveManager
    d_api = DOM01 as DOM_API

    if d_core == None
        Trace("Register_Events: DOMcore is None",true)
        return None
    endif
    d_core.SetSendExternalEvents(true)
    d_core.SetSendExternalEventsExt(true)
    d_core.SetSendExternalEventsExt2(true)
    d_core.SetSendExternalEventsExt3(true)

    ; ----------------------------------
    ; SetSendExternalEvents 
    ; ----------------------------------
    ; Register for DOM events
    RegisterForModEvent("DOM_CaptureAnimation", "OnCaptureAnimation")
    ;RegisterForModEvent("DOMOnCaptured", "OnCapured") ; handled above
    RegisterForModEvent("DOMOnBehaviourChange", "OnBehaviourChange")
    RegisterForModEvent("DOMOnInBag", "OnInBag") 
    RegisterForModEvent("DOMOnOutBag", "OnOutBag") 
    RegisterForModEvent("DOMOnCallForHelp", "OnCallForHelp") 
    RegisterForModEvent("DOMOnOrgasm", "OnOrgasm")
    RegisterForModEvent("DOMOnKinkDiscovered", "OnKinkDiscovered")
    RegisterForModEvent("DOMOnLostVirginity", "OnLostVirginity")
    RegisterForModEvent("DOMOnRunaway", "OnRunaway")
    RegisterForModEvent("DOMOnRunaway", "OnRunaway")
    ;  -------
    ; will be handled (if at all) by decorators
    ;  -------
    ; DOMOnMoodChange ; Don't need to tell the LLM will be added by dom_get_info at prompt creation
    ; DOMOnTRainingComplete ; skipping for now.
    ;DOMOnDrunkennessChange(Form sender, int drunkLevel) 
    ;DOMOnTrainingStatusUpdate(Form sender, string type, int value) ; type = freshly captured, degraded, mesmerized, ... value = 1, 2, 3, ...
    ;DOMOnHEXACOChange(Form sender, string trait, float value)
    ;DOMOnFACETChange(Form sender, string facet, float value)
    ;DOMOnTrainingStatChange(Form sender, string stat, float value)

    ; ----------------------------------
    ; SetSendExternalEvents2
    ; ----------------------------------
    ; RegisterForModEvent("DOMOnSex", "OnSex") handeled by SkyrimNet_SexLab
    RegisterForModEvent("DOMOnPriceInspection", "OnPriceInspection")
    RegisterForModEvent("DOMOnBodyInspection", "OnBodyInspection")
    RegisterForModEvent("DOMOnKissed", "OnKissed")
    RegisterForModEvent("DOMOnPraised", "OnPraised")
    RegisterForModEvent("DOMOnPunished", "OnPunished")
    RegisterForModEvent("DOMOnFlattered", "OnFlattered")
    RegisterForModEvent("DOMOnInsulted", "OnInsulted")
    RegisterForModEvent("DOMOnComforted", "OnComforted")
    RegisterForModEvent("DOMOnPromised", "OnPromised")
    RegisterForModEvent("DOMOnThreatened", "OnThreatened")
    RegisterForModEvent("DOMOnUndress", "OnUndress")
    RegisterForModEvent("DOMOnWashSelf", "OnWashSelf")
    RegisterForModEvent("DOMOnBranded", "OnBranded")
    RegisterForModEvent("DOMOnSalute", "OnSalute")
    ; RegisterForModEvent("DOMOnRecruited", "OnRecruited")
    RegisterForModEvent("DOMOnReleased", "OnReleased")

    ; ----------------------------------
    ; SetSendExternalEvents3
    ; ----------------------------------
    ;DOMOnDiaryUpdate(Form sender, string entryType, string entryReason, bool isSuccess, string fullText)
    RegisterForModEvent("DOMOnNotificationSent", "OnNotificationSent")

    if runningMap == 0
        runningMap = JFormMap.object() 
        JValue.retain(runningMap)
    endif 

    String events_log = "Data/SkyrimNet_DOM/events-log.json"
    int events = JArray.object() 
    Jvalue.WriteToFile(events, events_log) 
EndFunction 

;------------------------------------
; Util Functions 
;------------------------------------

Function SaveEvent(String eventId, String eventType, String msg)
	;String formid = DOM_Util.ConvertIDToHex(slave.GetFormID())
    ;RegisterForModEvent("DOMOnPunish"+formid, "OnPunish")
    if eventId != "" 
        msg = eventId+"."+eventType+": "+msg
    else 
        msg = eventType+": "+msg
    endif 

    Trace(msg, false)

    String events_log = "Data/SkyrimNet_DOM/events-log.json"
    int events = JValue.ReadFromFile(events_log) 
    JArray.addStr(events, msg)
    Jvalue.WriteToFile(events, events_log) 
EndFunction


Function Trace(String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("[SkyrimNet_DOM.Events]", msg, Notification)
EndFunction

int Function RegisterShortLivedEvent(String eventId, String eventType, String description, \
                                    String data, int ttlMs, Actor sourceActor, Actor targetActor=None)
    SaveEvent(eventId, eventType, description) 
    return SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, description, data, ttlMs, sourceActor, targetActor)
endFunction 

int Function RegisterEvent(String eventType, String content, Actor originatorActor, Actor targetActor=None)
    SaveEvent("", eventType, content) 
    return SkyrimNetApi.RegisterEvent(eventType, content, originatorActor, targetActor)
EndFunction 

int Function DirectNarration(String eventType, String content, Actor originatorActor = None, Actor targetActor = None) 
    float time = Utility.GetCurrentRealTime()
    float delta = time - timeLastEvent
    if delta > 25 
        timeLastEvent = time 
        SaveEvent("(direct)", eventType,content) 
        return SkyrimNetApi.DirectNarration(content,originatorActor,targetActor)
    else 
        return RegisterEvent(eventType, content, originatorActor, targetActor) 
    endif 
    return 0
EndFunction 

Function RegisterShort_AddName(String eventId, String eventType, Form akRef, String description, int ttl=100000)
    Actor slave = akRef as Actor 
    description = slave.GetDisplayName()+" "+description 
    RegisterShortLivedEvent(eventId, eventType, description, "", ttl, slave, None)
EndFunction 

; ----------------------------------
; SetSendExternalEvents 
; ----------------------------------

Event OnCaptureAnimation(Form akTarget, string capture_msg, bool is_from_behind, bool is_unconscious)
    Actor slave = akTarget as Actor 
    String msg = player.GetDisplayName()
    if is_from_behind
        msg += " comes from behind, "
    endif 
    msg += " grabs them by the throat, throws them to the ground, and enslaves "
    if  is_unconscious
        msg += " an unconscious "
    endif 
    msg += slave.GetDisplayName()+" their body, but not their mind."
    DirectNarration("captured slave",msg, player, slave)
EndEvent

Event OnLostVirginity(Form akRef, String type )
    Actor slave = akRef as Actor 
    String msg = slave.GetDisplayName()
    if type == "same"
        msg += " had sex with a person of the same gender for the first time."
    elseif type == "gang"
        msg += " had an orgy for the first time."
    else
        msg += " lost their "+type+" virginity"
        if type != "oral"
            msg += " with red blood flowing down their legs."
        endif
    endif 
    RegisterEvent("lost virginity",msg, player, slave) 
EndEvent 

; ------------------------ 

Event OnRunaway(Form akRef)
    JFormMap.setInt(runningMap, akRef, 1)
    RegisterShort_AddName("runaway","running", akRef, "is running away. To afraid to turn back!")
EndEvent 

Event OnBehaviourChange(Form akRef, String type)
    Bool haskey = JMap.hasKey(runningMap,akRef)
    if JFormMap.hasKey(runningMap, akRef)
        JFormMap.removeKey(runningMap, akRef)
        RegisterShort_AddName("runaway", "captured", akRef, "has been rundown and captured.")
    endif 
EndEvent 

; ------------------------ 

Event OnCallForHelp(Form akRef, String type)
    Actor akActor = akRef as Actor
    DOM_Actor slave = d_api.GetDOMActor(akRef as Actor) 
    String msg = akActor.GetDisplayName() 
    if type == "inbag"
        msg += "called for help from within a bag, only muffled sounds escape."
    elseif type == "leashed"
        msg += "tried to call for help, but it was magically suppressed."
    elseif type == "mumbles" || slave.has_mouth_gag
        msg = "tried to call for help, but only mumbles."
    elseif type == "fights"
        msg = "calls for help, while fighting for her freedom!"
    else
        msg = "yelling for someone to help them!"
    endif 
    RegisterShort_AddName("call for help", "call for help", akRef, msg)
EndEvent 


Event OnInBag(Form akRef)
    RegisterShort_AddName("bag", "in bag",akRef, "was put in a tiny sufficating smelly ichy bag.")
EndEvent 
Event OnOutBag(Form akRef)
    RegisterShort_AddName("bag", "out bag",akRef, "is finally taken out of a tiny sufficating smelly ichy bag.")
EndEvent 

; sex, rape, grab, masturbate, arousal, kink, magic
Event OnOrgasm(Form akRef, String type)
    Actor slave = akRef as Actor 
    String msg = slave.GetDisplayName() 
    if type == "grab"
        msg += " was forced to orgasm by being skilled hands."
    elseif type == "kink"
        msg += " orgasms as a result of their sexual kink."
    elseif type == "sex"
        msg += " orgasms from sex." 
    elseif type == "masturbate"
        msg += " orgasms from masturbation." 
    else
        msg += " forced to orgasms by "+type+"."
    endif 
    DirectNarration("orgasm", msg, slave)
EndEvent

Event OnKinkDiscovered(Form akRef, String type)
    Actor slave = akRef as Actor 
    String msg = player.GetDisplayName()+" discovers "+slave.GetDisplayName()+" has a fetish for "+type+"."
    RegisterEvent("kink discovered", msg, player, slave)
EndEvent 


;---------------------------------------------------
; Events 2 
;---------------------------------------------------
Event OnPriceInspection(Form sender, float value, bool isObedient)
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+" inspects "+slave.GetDisplayName()+" and finders her worth could be "+value+"."
    if !isObedient 
        msg = msg + slave.GetDisplayName()+" disobediently didn't cooperate with the inspection and finds it insulting. "
    endif 
    DirectNarration("price inspection", msg, player, slave)
EndEvent 

Event OnBodyInspection(Form sender, string inspectionMethod, string inspectionResults, bool isObedient)
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+"'s hands inspect every inch of "+slave.GetDisplayName()+", With special attention on their genitals, ass, and mouth."
    if !isObedient 
        msg = msg + slave.GetDisplayName()+" disobediently didn't cooperate with the inspection. "
    endif 
    DirectNarration("price inspection", msg, player, slave)
EndEvent 
Event OnKissed(Form sender, string kissType, string kissResults, bool isObedient)
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+" gives "+slave.GetDisplayName()+" a "+kissType+" kiss."
    if kissResults != "" 
        msg = slave.GetDisplayName()+" thinks, "+kissResults 
    endif 
    DirectNarration("price inspection", msg, player, slave)
EndEvent 

Event OnPunished(Form akRef, string punish_method, string punish_reason, bool is_obedient)
    Actor slave = akRef as Actor 
    String slave_name = slave.GetDisplayName()

    String msg = player.GetDisplayName()+" punished " \
        + slave_name+" with "+punish_method+" for "+punish_reason+"."

    if punish_method == "whip" 
        msg += " Leaving red angry welts across "+slave_name+"'s body and speckles of her blood on the floor."
    elseif punish_method == "slap"
        msg += " Leaving "+slave_name+"'s check bright red and stinging."
    elseif punish_method == "spank"
        msg += " Leaving "+slave_name+"'s ass bright red and stinging."
    elseif punish_method == "choke"
        msg += slave_name+" struggles to breath. "
    endif 
    DirectNarration("punished", msg, player, slave)  
EndEvent 

; guilt, rape, insult, threat, sex, care, 
Event OnComforted(Form akRef, String type, Bool isObedient)
    Actor slave = akRef as Actor 
    String name = slave.GetDisplayName()
    String msg = player.GetDisplayName()+" tries to "
    if type == "sex" 
        msg = " comfort "+name+" with loving sex"
    elseif type == "care"
        msg = " comfort "+name+" with a warm hug"
    elseif type == "insult" || type == "threat"
        msg = " pretend to comfort "+name+" with an "+type
    else ; guilt, rape
        msg = " pretend to comfort "+name+" with "+type
    endif 
    msg = msg + ", "+name
    String accepted = ""
    if isObedient 
        msg = msg +name+" is comforted."
        accepted = "accepted"
    else
        msg = msg + " but "+name+" rejects it!"
        accepted = "rejected"
    endif 
    RegisterEvent("comforted "+type+":"+accepted, msg, player, slave)
EndEvent 

Event OnPraised(Form sender, string praise_method, string praise_reason, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    if praise_method == "pat"
        praise_method = "pat on the head"
    endif 

    String msg = ower+" praised "+name+" with "+praise_method+" for "+praise_reason+". "

    if isObedient 
        msg = msg + name+" shows gratitude for the praise." 
    else 
        msg = msg + name+" refused to listen and rejects the praise." 
    endif

    DirectNarration("praised", msg, player, slave)  
EndEvent 

Event OnFlattered(Form sender, string flatteryType, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" flattered "+name+" with "+flatteryType+". "

    if isObedient 
        msg = msg + name+" is flattered and shows gratitude for "+ower+"'s words'." 
    else 
        msg = msg + name+" refused to listen "+ower+"." 
    endif

    DirectNarration("flattered", msg, player, slave)  
EndEvent 

Event OnInsulted(Form sender, string insultType, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" insults "+name+" with "+insultType+" words. "

    if isObedient 
        msg = msg + name+" shows acceptance of "+ower+"'s cruel words." 
    else 
        msg = msg + name+" rejects "+ower+"'s cruel words." 
    endif

    DirectNarration("insult", msg, player, slave)  
EndEvent 

Event OnPromised(Form sender, string promisedOath, bool isAccepted)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    if promisedOath == "to be sacrificed"
        promisedOath = "that they will be sacrificed."
    endif 

    String msg = ower+" promises "+name+" "+promisedOath +". "

    if isAccepted 
        msg = msg + name+" believe "+ower+"'s promise'." 
    else 
        msg = msg + name+" refuses to believe "+ower+"'s promise." 
    endif

    DirectNarration("promised", msg, player, slave)  
EndEvent 

Event OnThreatened(Form sender, string threatenedFor, bool isAccepted)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" threatens "+name+" for "+threatenedFor +". "

    if isAccepted 
        msg = msg + name+" accepts "+ower+"'s warning'." 
    else 
        msg = msg + name+" refuses to accept "+ower+"'s warning." 
    endif

    DirectNarration("threatened", msg, player, slave)  
EndEvent 

Event OnUndress(Form sender, string undressType, bool isObedient) ; If isObedient is false stripping didn't occur
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orderd "+name+" to undress ("+undressType+")."

    if isObedient 
        msg = msg + name+" submits and undresses."
    else 
        msg = msg + name+" refuses undress!"
    endif

    DirectNarration("undress", msg, player, slave)  
EndEvent 

Event OnWashSelf(Form sender, string washType, bool isObedient) ; If isObedient is false washing didn't occur
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orderd "+name+" to wash themselves ("+washType+")."

    if isObedient 
        msg = msg + name+" submits and washes their body."
    else 
        msg = msg + name+" refuses wash themselves!"
    endif

    DirectNarration("washSelf", msg, player, slave)  
EndEvent 

Event OnBranded(Form sender, string markName, string markArea, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" burns the brand "+markName+" on "+name+"'s "+markArea+"'s flesh.."

    if isObedient 
        msg = msg + name+" submits to the branding."
    else 
        msg = msg + name+" struggles and resists the branding!"
    endif

    DirectNarration("brand", msg, player, slave)  
EndEvent 

Event OnSalute(Form sender, string saluteType, string salutePose, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orders "+name+" to salute while "+salutePose+"ing. "

    if isObedient 
        msg = msg + name+" submits."
    else 
        msg = msg + name+" refuses to salute!"
    endif

    DirectNarration("onsalute", msg, player, slave)  
EndEvent 

Event OnRecruited(Form sender, string mood, bool isNewActor) ; If not new actor, slaver was previously in DOM
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" recruits a "+mood+" "+name+" as a slave trainer."

    DirectNarration("rectuit", msg, player, slave)  
EndEvent 

Event OnReleased(Form sender, string mood, bool isObedient)
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" frees "+name+" from slavery."
    DirectNarration("released", msg, player, slave)  
EndEvent 

;---------------------------------------------------
; Events 3 
;---------------------------------------------------
Event OnNotificationSent(Form sender, string actorStatus, bool isPlayersSlave, string fullText)
    Actor slave = sender as Actor 
    if isPlayersSlave 
        RegisterShortLivedEvent("slave", "misc", fullText, "", 120000, slave)
    endif 
EndEvent