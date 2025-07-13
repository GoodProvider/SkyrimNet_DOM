Scriptname SkyrimNet_DOM_Events extends Quest  

SkyrimNet_DOM_Main Property main  Auto  
Actor Property player  Auto  
String Property player_name Auto

int Property runningMap = 0 Auto
int Property lastSeenMap = 0 Auto 
DOM_API Property api = None Auto
Function Register_Events(SkyrimNet_DOM_Main _main)
    main = _main 
    player = Game.GetPlayer()
    player_name = player.GetDisplayName()
    Quest DOM01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") AS Quest 
    DOM_core domcore = DOM01 as DOM_Core
    DOM_SlaveManager manager = DOM01 AS DOM_SlaveManager

    if domcore == None
        Trace("Register_Events: DOMcore is None",true)
        return None
    endif
    domcore.SetSendExternalEvents(true)
    domcore.SetSendExternalEventsExt(true)
    domcore.SetSendExternalEventsExt3(true)
    domcore.SetSendExternalEventsExt3(true)
    ; Register for DOM events
    RegisterForModEvent("DOM_CaptureAnimation", "OnCaptureAnimation")
    ;RegisterForModEvent("DOMOnCaptured", "OnCapured") ; handled above
    RegisterForModEvent("DOMOnBehaviourChange", "OnBehaviourChange")
    ; DOMOnMoodChange ; Don't need to tell the LLM will be added by dom_get_info at prompt creation
    ; DOMOnTRainingComplete ; skipping for now.
    RegisterForModEvent("DOMOnInBag", "OnInBag") 
    RegisterForModEvent("DOMOnOutBag", "OnOutBag") 
    RegisterForModEvent("DOMOnCallForHelp", "OnCallForHelp") 
    RegisterForModEvent("DOMOnOrgasm", "OnOrgasm")
    RegisterForModEvent("DOMOnKinkDiscovered", "OnKinkDiscovered")
    RegisterForModEvent("DOMOnLostVirginity", "OnLostVirginity")
    RegisterForModEvent("DOMOnRunaway", "OnRunaway")

    RegisterForModEvent("DOMOnPunished", "OnPunished")
    RegisterForModEvent("DOMOnComforted", "OnComforted")


    ; Individual slaves 
;    int nslaves = manager.GetActorCount()
;    int idx = 0
;	while idx < nslaves
;		DOM_Actor akActor = manager.GetActorByIndex(idx)
;        Register_Individual_Events(akActor)
;        idx += 1
;    endWhile 

    if runningMap == 0
        runningMap = JFormMap.object() 
        JValue.retain(runningMap)
    endif 
EndFunction 

;Function Register_Individual_Events(DOM_Actor akActor)
	;String formid = DOM_Util.ConvertIDToHex(akRef.GetFormID())
    ;RegisterForModEvent("DOMOnPunish"+formid, "OnPunish")
;EndFunction
;------------------------------------
; Util Functions 
;------------------------------------


Function Trace(String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("[SkyrimNet_DOM_Events]", msg, Notification)
EndFunction

float Property timeLastEvent = 0.0 Auto 
int Function RegisterShortLivedEvent(String eventId, String eventType, String description, \
                                    String data, int ttlMs, Actor sourceActor, Actor targetActor)
    Debug.Notification("SkyrimNet:"+description)
    String name = ""
    if targetActor == None 
        name = sourceActor.GetDisplayName()
    else
        name = targetActor.GetDisplayName()
    endif 
    msg = name+" "+msg
    eventId = "DOM "+name+" "+eventId
    eventType = "DOM "+name+" "+eventType
    SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, description, data, ttlMs, sourceActor, targetActor)

    SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
    Bool fucking = False
    if SexLab != None 
        String names = "" 
        if SexLab.IsActorActive(sourceActor) 
            names += sourceActor.GetDisplayName()
        endif 
        if targetActor != None && SexLab.IsActorActive(targetActor)
            if names != ""
                names += ","
            endif 
            names += sourceActor.GetDisplayName()
        endif 
        if names != "" 
            Trace("RegisterShortLivedEvent: "+names+" already having sex")
            fucking = True
        endif 
    endif
    if fucking
        DirectNarration(description, sourceActor, targetActor)
    endif 
    String msg = "*"+description+"*"
    if targetACtor == None 
        return SkyrimNetApi.RegisterDialogue(sourceActor, msg)
    else
        return SkyrimNetApi.RegisterDialoguetoListener(sourceActor, targetActor, msg)
    endif 
    ;SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, description, data, ttlMs, sourceActor, targetActor)
endFunction 

int Function RegisterEvent(String eventType, String content, Actor originatorActor, Actor targetActor)
    DirectNarration(content, originatorActor, targetActor)
    return SkyrimNetApi.RegisterEvent(eventType, content, originatorActor, targetActor)
EndFunction 

int Function DirectNarration(String content, Actor originatorActor = None, Actor targetActor = None) 
    float time = Utility.GetCurrentRealTime()
    float delta = time - timeLastEvent
    Debug.MessageBox(delta+"++"+content)
    if delta > 45 
        timeLastEvent = time 
        return SkyrimNetApi.DirectNarration("*"+content+"*",originatorActor,targetActor)
    endif 
    return 0
EndFunction 


;------------------------------------
; DOM Events 
;------------------------------------
;Function DOMOnCaptured(Form sender, string mood, bool isPlayerSlave)
;    Actor slave = sender as Actor
    ;if !DOMapi.IsDOMSlave(slave)
        ;Debug.Notification("[SkyrimNet_DOM_Library] DOMOnCaptured: sender is not a Dom_Slave")
        ;Debug.Trace("[SkyrimNet_DOM_Library] DOMOnCaptured: sender is not a Dom_Slave")
        ;return
    ;endif
;    Debug.TraceAndBox("Before capture")
;    SkyrimNetApi.RegisterShortLivedEvent("dom_event", \
;        player.GetDisplayName()+" over powers "+slave.GetDisplayName()+", forcing them to the ground, and enslaving them.",\
;        player, slave)
;    Debug.TraceAndBox("Added capture event")
;EndFunction

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
    msg += slave.GetDisplayName()+" thier body, but not their mind."
    Trace("OnCaptureAnimation : "+ msg)
;    SkyrimNetApi.DirectNarration("*"+msg+"*", player, slave)

    RegisterEvent("captured slave",msg, player, slave)
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

Event OnRunaway(Form akRef)
    JFormMap.setInt(runningMap, akRef, 1)
    Actor slave = (akRef as Actor)
    Actor target = None
    String name  = slave.GetDisplayName()
    String msg = name+" is running away. To afraid to turn back!"
    OnHelper("runaway","running", slave, msg)
EndEvent 

Event OnBehaviourChange(Form akRef, String type)
    Bool haskey = JMap.hasKey(runningMap,akRef)
    if JFormMap.hasKey(runningMap, akRef)
        JFormMap.removeKey(runningMap, akRef)
        OnHelper("runaway", "captured", akRef, "has been rundown and captured.")
    endif 
EndEvent 

Event OnCallForHelp(Form akRef, String type)
    Dom_Actor slave = api.GetDOMActor(akRef as Actor)
    String msg = None
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
    OnHelper("call for help", "call for help", akRef, msg)
EndEvent 


Event OnInBag(Form akRef)
    OnHelper("bag", "in bag",akRef, "was put in a tiny sufficating smelly ichy bag.")
EndEvent 
Event OnOutBag(Form akRef)
    OnHelper("bag", "out bag",akRef, "is finally taken out that tiny sufficating smelly ichy bag.")
EndEvent 

; sex, rape, grab, masturbate, arousal, kink, magic
Event OnOrgasm(Form akRef, String type)
    String msg = None
    if type == "grab"
        msg += "forced to orgasms by being skilled hands."
    elseif type == "kink"
        msg += "orgasms from exploitation of their sexual kink."
    elseif type == "sex"
        msg += "orgasms from sex." 
    elseif type == "masturbate"
        msg += "orgasms from masturbation." 
    else
        msg += "forced to orgasms by "+type+"."
    endif 
    OnHelper("orgasm", "orgasm",akRef, msg)
EndEvent

; guilt, rape, insult, threat, sex, care, 
Event OnComforted(Form akRef, String type, Bool isObedient)
    Debug.MessageBox(type+" "+isObedient)
    String name = (akRef as Actor).GetDisplayName()
    String msg = None
    if type == "sex" 
        msg = " comforts "+name+" with in loveing sex"
    elseif type == "care"
        msg = " comforts "+name+" with a warm hug"
    elseif type == "insult"
        msg = " pretends to comfort "+name+" with an "+type
    elseif type == "threat"
        msg = " pretends to comfort "+name+" with an "+type
    else ; guilt, rape
        msg = " pretends to comfort "+name+" with "+type
    endif 
    String accepted = None
    if isObedient 
        msg = player_name+msg+"."
        accepted = "accepted"
    else
        msg = player_name+" tires to"+msg+", but they refuse!"
        accepted = "rejected"
    endif 
    OnHelper("comforted "+type+accepted, "comforted "+type+accepted,akRef, msg)
EndEvent 

Event OnKinkDiscovered(Form akRef, String type)
    Actor slave = akRef as Actor 
    String msg = "*"+player.GetLeveledActorBase()+" discovered "+slave.GetDisplayName()+" "+type+" kink.*"
    RegisterEvent("kink discovered", msg, player, slave)
EndEvent 

Event OnHelper(String eventId, String eventType, Form akRef, String msg, int ttl=100000)
    Actor slave = akRef as Actor 
    RegisterShortLivedEvent(eventId, eventType, msg, "", 120000, slave, None)
EndEvent 

Event OnPunished(Form akRef, string punish_method, string punish_reason, bool is_obedient)
    Actor slave = akRef as Actor 
    String slave_name = slave.GetDisplayName()
    Debug.MessageBox("OnPunishement "+slave_name+" "+punish_method+" "+punish_reason)
    Trace("OnPunishement "+slave_name+" "+punish_method+" "+punish_reason)

    String msg = player.GetDisplayName()+" punished " \
        + slave_name+" with "+punish_method+" for "+punish_reason+"."

    if punish_method == "whip" 
        msg += " Leaving red angry welts across "+slave_name+"'s body and speckles of her blood on the floor."
    elseif punish_method == "spank"
        msg += " Leaving "+slave_name+"'s ass bright red and stinging."
    endif 
    Trace("OnPunished: "+msg)
    Debug.MessageBox("punished!!")
    RegisterShortLivedEvent("punished "+Utility.GetCurrentGameTime(), "punish "+punish_method, \
        msg, "", 120000, Game.GetPlayer(), slave)
    
    ; Remember this punishement
    ;int time_type = JArray.object()
    ;JArray.AddFlt(time_type, Utility.GetCurrentGameTime())
    ;JArray.AddStr(time_type, type)
    ;JArray.AddObj(recent_punishments, time_type)
EndEvent 

