Scriptname SkyrimNet_DOM_Events extends Quest  
import SkyrimNet_DOM_Utils

SkyrimNet_DOM_Main Property main  Auto  
SkyrimNet_SexLab_Main Property sexlab_main Auto
Actor Property player  Auto  
String Property player_name Auto

String Property behaviour_current_key = "DOM_behaviour_current" Auto
int Property lastSeenMap = 0 Auto 

float Property timeLastEvent = 0.0 Auto 

bool last_order_refused = False 

String events_log = "Data/SKSE/Plugins/SkyrimNet_DOM/events-log.json"
; --------------------------
; Helper functions 
; --------------------------
Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_Event", func, msg, Notification)
EndFunction
DOM_Actor Function GetSlave(String Func, Actor akActor)
    return SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Decorations",func+".GetSlave", akActor,false,false)
EndFunction


Function DirectNarration(String msg, Actor source, Actor target)
    SaveActorInfo(target)
    SkyrimNet_DOM_Utils.DirectNarration(msg, source, target)
EndFunction

Function DirectNarration_Optional(String event_type, String msg, Actor source, Actor target, bool optional=False)
    SaveActorInfo(target)
    SkyrimNet_DOM_Utils.DirectNarration_Optional(event_type, msg, source, target, optional) 
EndFunction

Function SaveActorInfo(Actor akActor, String actor_json = "")
    if actor_json == ""
        actor_json = SkyrimNet_DOM_Decorators.Get_Actor_Info(akActor)
    endif
    String fname = "Data/SKSE/Plugins/SkyrimNet_DOM/actors/"+akActor.GetDisplayName()+".json"
    Trace("SaveActorInfo","Saving actor info to "+fname)
    Miscutil.WriteToFile(fname, actor_json, append=False)
EndFunction

; --------------------------
; Event Handlers
; --------------------------

Function Register_Events(Quest DOM01)
    main = (self as Quest) as SkyrimNet_DOM_Main
    sexlab_main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    player = Game.GetPlayer()
    player_name = player.GetDisplayName()
    timeLastEvent = Utility.GetCurrentRealTime()

    Trace("Register_Events", "main.d_core: "+main.d_core+" main.d_api:"+main.d_api+" main.d_sexlab:"+main.d_sexlab) 
    main.d_core.SetSendExternalEvents(true)
    main.d_core.SetSendExternalEventsExt(true)
    main.d_core.SetSendExternalEventsExt2(true)
    main.d_core.SetSendExternalEventsExt3(true)

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
    RegisterForModEvent("DOMOnMoodChange", "OnMoodChange")
    RegisterForModEvent("DOMOnBehaviorChange", "OnBehaviorChange")
    ;  -------
    ; will be handled (if at all) by decorators
    ;  -------
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
    RegisterForModEvent("DOMOnSex", "OnSex")
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
    ; Set SexLab events
    ; ----------------------------------
    RegisterForModEvent("HookAnimationStart", "SexLab_AnimationStart")
    RegisterForModEvent("HookAnimationEnd", "SexLab_AnimationEnd")

EndFunction 

;------------------------------------
; Util Functions 
;------------------------------------

Bool Function GetLastOrderRefused_Reset()
    bool current = last_order_refused
    last_order_refused = False 
    return current
EndFunction

int Function RegisterShortLivedEvent(String eventId, String eventType, String description, \
                                    String data, int ttlMs, Actor sourceActor, Actor targetActor=None)
    return SkyrimNetAPI.RegisterShortLivedEvent(eventId, eventType, description, data, ttlMs, sourceActor, targetActor)
endFunction 

int Function RegisterEvent(String eventType, String content, Actor originatorActor, Actor targetActor=None)
    return SkyrimNetAPI.RegisterEvent(eventType, content, originatorActor, targetActor)
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
    DirectNarration(msg, player, slave)
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
    StorageUtil.SetStringValue(akRef, behaviour_current_key, "running_away")
    RegisterShort_AddName("runaway","running", akRef, "is running away. To afraid to turn back!")
    Trace("OnRunaway",(akRef as ACtor).GetDisplayName()+" is running away!")
EndEvent 

Event OnBehaviourChange(Form akRef, String type)
    String current = StorageUtil.GetStringValue(akRef, behaviour_current_key, "")
    String msg = ""
    if current == "running_away"
        msg = "has been rundown and captured."
        last_order_refused = True
    elseif type == "masturbate"
        msg = "obeys and starts masturbating."
        last_order_refused = False
    elseif current == "masturbate"
        msg = "stops masturbating."
    else 
        msg = "is "+SkyrimNet_DOM_Decorators.BehaviourToString(type)
    endif 
    Actor slave = akRef as Actor
    String name_msg = slave.GetDisplayName()+" "+msg
    if msg != ""
        DirectNarration_Optional("behavoir", name_msg, player, slave, optional=true)
    endif 
    Trace("OnBehaviourChange",current+"->"+type+" "+name_msg)
EndEvent 

Event OnMoodChange(Form akRef, String type)
    Actor slave = akRef as Actor
    String msg = mood_to_Sentence(slave.GetDisplayName(), type) 
    DirectNarration_Optional("mood", msg, player, slave, optional=true)
    Trace("OnMoodChange",msg)
EndEvent 

String Function mood_to_Sentence(String name, String type)
    if type == "shocked"
        return "The weight of recent events proved too much for "+name+", leaving them in a state of deep shock."
    else 
        return name+" feels "+type+"."
    endif 
EndFunction

; ------------------------ 

Event OnCallForHelp(Form akRef, String type)
    Actor akActor = akRef as Actor
    DOM_Actor slave = main.d_api.GetDOMActor(akRef as Actor) 
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

Event OnSex(Form akRef, string sexOrRape, string punishReason, bool hadOrgasm )
    ;Actor slave = akRef as Actor 
    ;Trace("OnSex","slave: "+slave.GetDisplayName()+" sexOrRape: "+sexOrRape+" punishReason: "+punishReason+" hadOrgasm: "+hadOrgasm, true)
    ;if main != None
;
        ;sslThreadController thread = sexlab_main.GetThread(slave)
        ;bool HasPlayer = False 
        ;Actor[] actors = thread.positions 
        ;int i = actors.length - 1 
        ;while i >= 0 && !HasPlayer
            ;if actors[i] == player
                ;HasPlayer = True 
            ;endif 
            ;i -= 1
        ;endwhile
        ;if (HasPlayer && sexlab_main.sex_edit_tags_player) || (!HasPlayer && sexlab_main.sex_edit_tags_nonplayer)
            ;sslBaseAnimation[] anims = sexlab_main.AnimsDialog(sexlab_main.SexLab, thread.positions, "")
            ;if anims.length > 0 && anims[0] != None  
                ;thread.SetAnimations(anims)
            ;endif 
        ;endif 
    ;endif
EndEvent

; sex, rape, grab, masturbate, arousal, kink, magic
Event OnOrgasm(Form akRef, String type)
    Actor slave = akRef as Actor 
    String msg = "An orgasm overwhelms and melts "+slave.GetDisplayName()+"'s mind"
    if type == "rape"
        msg += " despite being raped."
    elseif type == "kink"
        msg += " from "+slave.GetDisplayName()+"'s sexual kink."
    elseif type == "kink"
        msg += ", because of a magical effect."
    else
        msg += "."
    endif 
    sexlab_main.DOMSlave_Orgasmed(slave, msg)
    ;DirectNarration(msg, slave)
EndEvent

Event OnKinkDiscovered(Form akRef, String type)
    Actor slave = akRef as Actor 
    String msg = player.GetDisplayName()+" discovers "+slave.GetDisplayName()+" has a fetish for "+type+"."
    DirectNarration_Optional("kink discovered", msg, player, slave)
EndEvent 


;---------------------------------------------------
; Events 2 
;---------------------------------------------------
Event OnPriceInspection(Form sender, float value, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+" inspects "+slave.GetDisplayName()+" and finders her worth could be "+value+"."
    if !isObedient 
        msg = msg + slave.GetDisplayName()+" disobediently didn't cooperate with the inspection and finds it insulting. "
    endif 
    DirectNarration_Optional("price inspection", msg, player, slave)
EndEvent 

Event OnBodyInspection(Form sender, string inspectionMethod, string inspectionResults, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+"'s hands inspect every inch of "+slave.GetDisplayName()+", With special attention on their genitals, ass, and mouth."
    if !isObedient 
        msg = msg + slave.GetDisplayName()+" disobediently didn't cooperate with the inspection. "
    endif 
    DirectNarration_Optional("price inspection", msg, player, slave)
EndEvent 
Event OnKissed(Form sender, string kissType, string kissResults, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+" gives "+slave.GetDisplayName()+" a "+kissType+" kiss."
    if kissResults != "" 
        msg = slave.GetDisplayName()+" thinks, "+kissResults 
    elseif !isObedient
        msg = slave.GetDisplayName()+" submit to "+player.GetDisplayName()+"'s "+kissType+" kiss."
    endif 
    DirectNarration_Optional("price inspection", msg, player, slave)
EndEvent 

Event OnPunished(Form akRef, string punish_method, string punish_reason, bool is_obedient)
    Actor slave = akRef as Actor 
    String slave_name = slave.GetDisplayName()

    String msg = player.GetDisplayName()+" punished " \
        + slave_name+" with "+punish_method+" for "+punish_reason+"."

    if punish_method == "whip" 
        msg += " Leaving red angry welts across "+slave_name+"'s body and speckles of her blood on the floor."
    elseif punish_method == "slmain.d_aping"
        msg += " Leaving "+slave_name+"'s check bright red and stinging."
    elseif punish_method == "spanking"
        msg += " Leaving "+slave_name+"'s ass bright red and stinging."
    elseif punish_method == "choking"
        msg += slave_name+" struggles to breath. "
    endif 
    if !is_obedient
        msg += slave_name+" refuses to submit."
    endif 
    DirectNarration_Optional("punished", msg, player, slave)  
    Trace("OnPunishment",msg) 
EndEvent 

; guilt, rape, insult, threat, sex, care, 
Event OnComforted(Form akRef, String type, Bool isObedient)
    last_order_refused = !isObedient
    Actor slave = akRef as Actor 
    String name = slave.GetDisplayName()
    String msg = player.GetDisplayName()
    Bool pretending = False
    if type == "sex" 
        msg = " tries to comfort "+name+" with loving sex"
    elseif type == "care"
        msg = " tries to comfort "+name+" with a warm hug"
    elseif type == "insult" || type == "threat"
        msg = " pretends to comfort "+name+" with an "+type
        pretending = True
    else ; guilt, rape
        msg = " pretends to comfort "+name+" with "+type
        pretending = True
    endif 
    String accepted = ""
    if isObedient 
        if pretending
            msg += ". "+name+" tries to be comforted."
        else
            msg += ". "+name+" is comforted."
        endif 
        accepted = "accepted"
    else
        if pretending
            msg += ", but "+name+" isn't fooled and rejects it!"
        else
            msg += ", but "+name+" rejects it!"
        endif 
        accepted = "rejected"
    endif 
    DirectNarration_Optional("comforted "+type+":"+accepted, msg, player, slave)
EndEvent 

Event OnPraised(Form sender, string praise_method, string praise_reason, bool isObedient)
    last_order_refused = !isObedient
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

    DirectNarration_Optional("praised", msg, player, slave)  
EndEvent 

Event OnFlattered(Form sender, string flatteryType, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" flattered "+name+" with "+flatteryType+". "

    if isObedient 
        msg = msg + name+" is flattered and shows gratitude for "+ower+"'s words'." 
    else 
        msg = msg + name+" refused to listen "+ower+"." 
    endif

    DirectNarration_Optional("flattered", msg, player, slave)  
EndEvent 

Event OnInsulted(Form sender, string insultType, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" insults "+name+" with "+insultType+" words. "

    if isObedient 
        msg = msg + name+" shows acceptance of "+ower+"'s cruel words." 
    else 
        msg = msg + name+" rejects "+ower+"'s cruel words." 
    endif

    DirectNarration_Optional("insult", msg, player, slave)  
EndEvent 

Event OnPromised(Form sender, string promisedOath, bool isAccepted)
    last_order_refused = !isAccepted
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

    DirectNarration_Optional("promised", msg, player, slave)  
EndEvent 

Event OnThreatened(Form sender, string threatenedFor, bool isAccepted)
    last_order_refused = !isAccepted
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" threatens "+name+" for "+threatenedFor +". "

    if isAccepted 
        msg = msg + name+" accepts "+ower+"'s warning'." 
    else 
        msg = msg + name+" refuses to accept "+ower+"'s warning." 
    endif

    DirectNarration_Optional("threatened", msg, player, slave)  
EndEvent 

Event OnUndress(Form sender, string undressType, bool isObedient) ; If isObedient is false stripping didn't occur
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orderd "+name+" to undress ("+undressType+")."

    if isObedient 
        msg = msg + name+" submits and undresses."
    else 
        msg = msg + name+" refuses undress!"
    endif

    DirectNarration_Optional("undress", msg, player, slave)  
EndEvent 

Event OnWashSelf(Form sender, string washType, bool isObedient) ; If isObedient is false washing didn't occur
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orderd "+name+" to wash themselves ("+washType+")."

    if isObedient 
        msg = msg + name+" submits and washes their body."
    else 
        msg = msg + name+" refuses wash themselves!"
    endif

    DirectNarration_Optional("washSelf", msg, player, slave)  
EndEvent 

Event OnBranded(Form sender, string markName, string markArea, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" burns the brand "+markName+" on "+name+"'s "+markArea+"'s flesh.."

    if isObedient 
        msg = msg + name+" submits to the branding."
    else 
        msg = msg + name+" struggles and resists the branding!"
    endif

    DirectNarration_Optional("brand", msg, player, slave)  
EndEvent 

Event OnSalute(Form sender, string saluteType, string salutePose, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" orders "+name+" to salute while "+salutePose+"ing. "

    if isObedient 
        msg = msg + name+" submits."
    else 
        msg = msg + name+" refuses to salute!"
    endif

    DirectNarration_Optional("onsalute", msg, player, slave)  
EndEvent 

Event OnRecruited(Form sender, string mood, bool isNewActor) ; If not new actor, slaver was previously in DOM
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" recruits a "+mood+" "+name+" as a slave trainer."

    DirectNarration_Optional("rectuit", msg, player, slave)  
EndEvent 

Event OnReleased(Form sender, string mood, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" frees "+name+" from slavery."
    if !isObedient 
        msg = msg + name+" doesn't want to be freed and resists the release!"
    endif  
    DirectNarration_Optional("released", msg, player, slave)  
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

;---------------------------------------------------
; SexLab Events
;---------------------------------------------------

Event SexLab_AnimationStart(int ThreadID, bool HasPlayer)
    ; Get the thread that triggered this event via the thread id
    sslThreadController Thread = sexlab_main.sexlab.GetController(ThreadID)
    Actor[] actors = Thread.Positions
    int i = actors.length - 1   
    while  0 <= i
        DOM_Actor domActor = main.d_api.GetDomActor(actors[i])
        if domActor != None 
            Trace("SexLab_AnimationStart","main.d_sexlab:"+main.d_sexlab)
            Trace("SexLab_AnimationStart","main.d_sexlab:"+main.d_sexlab+" DOMAnimatingFaction:", main.d_sexlab.DOMAnimatingFaction)
            actors[i].SetFactionRank(main.d_sexlab.DOMAnimatingFaction, 2)
                    bool isACtive = sexlab_main.sexlab.IsActorActive(actors[i])
            bool canIdle = domActor.canIdle
            Trace("SexLab_AnimationStart","ThreadID: "+ThreadID+" Actor: "+actors[i].GetDisplayName()+" IsActorActive: "+isACtive+" canIdle: "+canIdle)
        endif 
        i -= 1
    endwhile 
EndEvent 

Event SexLab_AnimationEnd(int ThreadID, bool HasPlayer)
	; Get the thread that triggered this event via the thread id
	sslThreadController Thread = sexlab_main.sexlab.GetController(ThreadID)
    Actor[] actors = Thread.Positions
    int i = actors.length - 1   
    while  0 <= i
        DOM_Actor domActor = main.d_api.GetDomActor(actors[i])
        if domActor != None 
            actors[i].RemoveFromFaction(main.d_sexlab.DOMAnimatingFaction)
        endif 
        i -= 1
    endwhile 
EndEvent

Function GetActorsReadyForScene(sslThreadModel thread)
    Actor[] actors = thread.Positions 
    int i = actors.length - 1
    while 0 <= i
        main.d_sexlab.GetReadyForScene(actors[i], main.d_api.GetDomActor(actors[i]))
        actors[i].SetFactionRank(main.d_sexlab.DOMAnimatingFaction, 2)
        i -= 1
    endwhile
EndFunction 

Function GetActorsFinishedWithScene(sslThreadController thread)
	; Get our list of actors that were in this animation thread.
	Actor[] actors = Thread.Positions

    int i = actors.length - 1
    while 0 <= i
        if main.d_api.IsDOMSlave(actors[i])
            main.d_api.GetDomActor(actors[i]).OnSexEnd()
            actors[i].RemoveFromFaction(main.d_sexlab.DOMAnimatingFaction)
            main.d_sexlab.ClearAnimatingFaction(actors[i])
        endif 
        i -= 1 
    endwhile 
EndFunction