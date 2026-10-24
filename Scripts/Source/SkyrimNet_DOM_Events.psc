Scriptname SkyrimNet_DOM_Events extends Quest  
import SkyrimNet_DOM_API
import SkyrimNet_SexLab_Utilities

SkyrimNet_DOM_Main Property main  Auto  
SkyrimNet_SexLab_Main Property sexlab_main Auto
SkyrimNet_SexLab_Handler_DOM Property handler Auto
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
int Property notifications_size = 20 Auto
int actor_to_notifications = 0 
int actor_to_notifications_next = 0 
int capture_narrated = 0 

; --------------------------
; Helper functions 
; --------------------------
Function Trace(String func, String msg, Bool Notification = false) global
    Trace_Helper("SkyrimNet_DOM_Events", func, msg, Notification)
EndFunction
DOM_Actor Function GetSlave(String Func, Actor akActor)
    return SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Events",func+".GetSlave", akActor)
EndFunction

Function Setup(Quest DOM01) 
    main = (self as Quest) as SkyrimNet_DOM_Main
    sexlab_main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    handler = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab_Handler_DOM.esp") as SkyrimNet_SexLab_Handler_DOM
    
    if sexlab_main == None 
        Trace("Setup","sexlab_main is None, aborting")
        return 
    endif 
    if handler == None 
        Trace("Setup","handler is None; DOM events will still register (orgasm handler calls guarded)")
    endif 
    player = Game.GetPlayer()
    player_name = player.GetDisplayName()

    if actor_to_notifications == 0 
        actor_to_notifications = JMap.object() 
        JValue.retain(actor_to_notifications) 
    endif 
    if actor_to_notifications_next == 0
        actor_to_notifications_next = JMap.object()
        JValue.retain(actor_to_notifications_next)
    endif
    if capture_narrated == 0
        capture_narrated = JMap.object()
        JValue.retain(capture_narrated)
    endif
    Register_Events(DOM01)
EndFunction

Function DirectNarration(String msg, Actor slave)
    SaveActorInfo(slave)
    SkyrimNet_SexLab_Utilities.DirectNarration(msg, slave)
EndFunction

Function DirectNarration_Optional(String event_type, String msg, Actor slave, bool optional=False)
    SaveActorInfo(slave)
    String slave_name = Actor_name(slave)
    Trace("DirectNarration_Optional", "event_type:"+event_type+" msg:"+msg+" slave:"+slave_name+" optional:"+optional)
    if SkyrimNet_DOM_Obedience.ShouldSkipEventNarration(slave)
        Trace("DirectNarration_Optional", "skip armed for "+slave_name)
        return
    endif
    if !SkyrimNet_SexLab_Utilities.DirectNarration_Optional(event_type, msg, slave, None, optional) 
        AddNotification(msg, slave)
    endif
EndFunction

Function SaveActorInfo(Actor akActor, String actor_json = "")
    if akActor == None
        Trace("SaveActorInfo","akActor is None, skipping")
        return
    endif
    if actor_json == ""
        actor_json = SkyrimNet_DOM_Decorators.Get_Actor_Info(akActor)
    endif
    if actor_json != "" 
        String fname = "Data/SKSE/Plugins/SkyrimNet_DOM/actors/"+akActor.GetDisplayName()+".json"
        Trace("SaveActorInfo","Saving actor info to "+fname)
        Miscutil.WriteToFile(fname, actor_json, append=False)
    endif 
EndFunction

String Function Actor_name(Actor akActor)
    if akActor == None 
        return "None"
    else 
        return akActor.GetDisplayName()
    endif
EndFunction 

; --------------------------
; Event Handlers
; --------------------------

Function Register_Events(Quest DOM01)
    main = (self as Quest) as SkyrimNet_DOM_Main
    sexlab_main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    player = Game.GetPlayer()
    if !player
        Trace("Register_Events", "player is None, aborting")
        return
    endif
    player_name = player.GetDisplayName()
    timeLastEvent = Utility.GetCurrentRealTime()

    if !main || !main.d_core || !main.d_api
        Trace("Register_Events", "main, d_core, or d_api is None, aborting")
        return
    endif
    Trace("Register_Events", "main.d_core: "+main.d_core+" main.d_api:"+main.d_api+" main.d_sexlab:"+main.d_sexlab) 
    main.d_api.SetSendExternalEvents(true)
    main.d_api.SetSendExternalEventsExt(true)

    ; ----------------------------------
    ; SetSendExternalEvents 
    ; ----------------------------------
    ; Register for DOM events
    ;RegisterForModEvent("DOMOnEventAnimateAbductionFloor", "OnCaptureAnimation")
    ;RegisterForModEvent("DOMOnCaptured", "OnCapured") ; handled above
    ;RegisterForModEvent("DOMOnInBag", "OnInBag") 
    ;RegisterForModEvent("DOMOnOutBag", "OnOutBag") 
    RegisterForModEvent("DOMOnCallForHelp", "OnCallForHelp") 

    ; Use Notifications. It's faster.
    ;RegisterForModEvent("DOMOnOrgasm", "OnOrgasm")
    RegisterForModEvent("DOMOnKinkDiscovered", "OnKinkDiscovered")
    RegisterForModEvent("DOMOnLostVirginity", "OnLostVirginity")
    RegisterForModEvent("DOMOnRunaway", "OnRunaway")
    RegisterForModEvent("DOMOnMoodChange", "OnMoodChange")
    RegisterForModEvent("DOMOnBehaviourChange", "OnBehaviourChange")
    RegisterForModEvent("DOMOnNotificationSent", "OnNotificationSent")
    ; Injury Engine (soft): torture of a slave is a DOM pain punishment; Healing Hands or SexLab Aid on a slave
    ; is praise (care when shocked)
    RegisterForModEvent("Injury_Engine_Torture", "OnInjuryTorture")
    RegisterForModEvent("Injury_Engine_HealStart", "OnInjuryHealStart")
    RegisterForModEvent("SkyrimNet_SexLab_AidStart", "OnSexLabAidStart")
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
    ; SetSendExternalEvents2 — gated by ApplyExt2Events / dom.events.ext2
    ; ----------------------------------
    ; DOMOnSex is handled by SkyrimNet_SexLab; do not register it here.

    ; Ext3 required for DOMOnNotificationSent (melt/orgasm text → Handler_DOM).
    ; Prefer notifications over DOMOnOrgasm (faster in testing); keep OnOrgasm unregistered to avoid double-fire.
    ; Toggles live on DOM_API (same quest as DOM_Core); calling them on d_core is a compile-only stub and a runtime no-op.
    main.d_api.SetSendExternalEventsExt3(true)
    Trace("Register_Events", "ext/ext1/ext3 enabled via d_api")
    ; ----------------------------------
    ; Set SexLab events
    ; ----------------------------------
    RegisterForModEvent("HookAnimationStart", "SexLab_AnimationStart")
    RegisterForModEvent("HookAnimationEnd", "SexLab_AnimationEnd")

    SeedCaptureNarrated()
    UnregisterForUpdate()
    RegisterForUpdate(2.0)
    Trace("Register_Events", "capture alias scan every 2s")

EndFunction

Function SeedCaptureNarrated()
    int n = ScanCaptureAliases(false)
    Trace("SeedCaptureNarrated", "seeded existing aliases n="+n)
EndFunction

int Function ScanCaptureAliases(bool narrate)
    if !main || !main.d_core
        return 0
    endif
    DOM_SlaveManager slaveManager = main.d_core.DOM02
    if slaveManager == None || capture_narrated == 0
        return 0
    endif
    ; Walk actorAliases (filled at ForceRefTo). GetActorCount/actorArray update only after Mind AfterAssign.
    int n = slaveManager.GetMaxActorCount()
    int i = 0
    int filled = 0
    while i < n
        DOM_Actor domActor = slaveManager.actorAliases[i] as DOM_Actor
        if domActor && domActor.GetActorRef()
            filled += 1
            MarkCaptureNarrated(domActor, narrate)
        endif
        i += 1
    endwhile
    return filled
EndFunction

Function MarkCaptureNarrated(DOM_Actor domActor, bool narrate)
    if domActor == None
        return
    endif
    Actor slave = domActor.GetActorRef()
    if slave == None || slave == player
        return
    endif
    DOM_Mind mind = domActor.mind
    if mind && !mind.is_player_slave
        return
    endif
    String uuid = slave.GetFormID() as String
    if JMap.getInt(capture_narrated, uuid, 0) != 0
        return
    endif
    JMap.setInt(capture_narrated, uuid, 1)
    if narrate
        String slave_name = slave.GetDisplayName()
        String msg = player_name+" grabs "+slave_name+" by the throat, throws "+slave_name+" to the ground, and enslaves "+slave_name+"."
        Trace("OnCaptureAssigned", slave_name)
        DirectNarration(msg, slave)
    endif
EndFunction

Event OnUpdate()
    ScanCaptureAliases(true)
EndEvent

Function ApplyExt2Events()
    UnregisterForModEvent("DOMOnPriceInspection")
    UnregisterForModEvent("DOMOnBodyInspection")
    UnregisterForModEvent("DOMOnKissed")
    UnregisterForModEvent("DOMOnPraised")
    UnregisterForModEvent("DOMOnPunished")
    UnregisterForModEvent("DOMOnFlattered")
    UnregisterForModEvent("DOMOnInsulted")
    UnregisterForModEvent("DOMOnComforted")
    UnregisterForModEvent("DOMOnPromised")
    UnregisterForModEvent("DOMOnThreatened")
    UnregisterForModEvent("DOMOnUndress")
    UnregisterForModEvent("DOMOnWashSelf")
    UnregisterForModEvent("DOMOnBranded")
    UnregisterForModEvent("DOMOnSalute")
    UnregisterForModEvent("DOMOnRecruited")
    UnregisterForModEvent("DOMOnReleased")

    if !main || !main.d_api
        Trace("ApplyExt2Events", "main or d_api is None, skipping")
        return
    endif

    if !main.ext2_enabled
        main.d_api.SetSendExternalEventsExt2(false)
        Trace("ApplyExt2Events", "ext2 off")
        return
    endif

    main.d_api.SetSendExternalEventsExt2(true)
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
    RegisterForModEvent("DOMOnRecruited", "OnRecruited")
    RegisterForModEvent("DOMOnReleased", "OnReleased")
    Trace("ApplyExt2Events", "ext2 on")
EndFunction 

;------------------------------------
; Util Functions 
;------------------------------------

Bool Function GetLastOrderRefused_Reset()
    bool current = last_order_refused
    last_order_refused = False 
    return current
EndFunction

Function RegisterShortLivedEvent(String eventId, String eventType, String description, String data, int ttlMs, Actor sourceActor, Actor targetActor=None)
    SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, description, data, ttlMs, sourceActor, targetActor)
EndFunction 

Function RegisterEvent(String eventType, String description, Actor originatorActor, Actor targetActor=None)
    SkyrimNetApi.RegisterEvent(eventType, description, originatorActor, targetActor)
EndFunction 

Function RegisterShort_AddName(String eventId, String eventType, Form akRef, String description, int ttl=-1)
    Actor slave = akRef as Actor 
    if slave == None
        Trace("RegisterShort_AddName","akRef is not an Actor, skipping")
        return
    endif
    if ttl < 0
        if main
            ttl = main.short_lived_ttl
        else
            ttl = 100000
        endif
    endif
    description = slave.GetDisplayName()+" "+description 
    RegisterShortLivedEvent(eventId, eventType, description, "", ttl, slave, None)
EndFunction 

; ----------------------------------
; SetSendExternalEvents 
; ----------------------------------

; Appears to be deprecated, but leaving it here for now. 
;Event OnCaptureAnimation(Form akTarget, string capture_msg, bool is_from_behind, bool is_unconscious)
;Event OnCaptureAnimation(Form akTarget, string capture_msg, string type, bool flag)
;    Actor slave = akTarget as Actor 
;    String name = GetDisplayname(slave)
;    Trace("OnCaptureAnimation","akTarget:"+slave+" capture_msg:"+capture_msg+" type:"+type+" flag:"+flag)
;    String msg = player.GetDisplayName()
;    ;if is_from_behind
;        ;msg += " comes from behind, "
;    ;endif 
;    msg += " grabs "name+" by the throat, throws "+name+" to the ground, and enslaves "
;    ;if  is_unconscious
;        ;msg += " an unconscious "
;    ;endif 
;    msg += slave.GetDisplayName()+" "+name+"'s body, but not yet "+name+"'s mind."
;    DirectNarration(msg, slave)
;EndEvent

;Event OnCapture(Form akTarget, string mood, bool is_player_slave)
;    Actor slave = akTarget as Actor 
;    String name = GetDisplayname(slave) 
;    String msg = player.GetDisplayName()+" has captured "+name+" and enslaved "+name+"'s body, but not yet "+name+"'s mind."
;    DirectNarration(msg, slave)
;EndEvent

Event OnLostVirginity(Form akRef, String type )
    Actor slave = akRef as Actor 
    if slave == None
        Trace("OnLostVirginity","akRef is not an Actor, skipping")
        return
    endif
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
    RegisterEvent("lost virginity",msg, slave) 
EndEvent 

; ----------------------------------
; SetSendExternalEvents 
; ----------------------------------
Event OnNotificationSent(Form akRef, String notificationType, bool is_player_slave, String description)

    String desc_original = description
    Actor slave = akRef as Actor
    String slave_name = Actor_name(slave)

    ; Melt/climax only — do not match bare "orgasm" (player-orgasm tease, orgasm-control HUD).
    ; Runs before the DomObedience skip window so a gated order cannot swallow melt.
    if IsDomMeltOrgasm(description)
        Trace("OnNotificationSent", slave_name+" melt orgasm: "+description)
        if handler
            handler.DOMSlave_Orgasmed(slave, description)
        endif
        return
    endif

    if OnNotifcationSkip(description, slave)
        Trace("OnNotificationSent", "skipping notification: "+description)
        return
    endif

    ;if slave == player
        ;;Trace("OnNotificationSent", "player notification, skipping: "+description)
        ;return
    ;endif
    ;if slave == None
        ;Trace("OnNotificationSent","akRef is not an Actor, skipping: "+description)
        ;return
    ;endif
    ;if !SkyrimNet_DOM_API.IsDOMSlave(slave)
        ;Trace("OnNotificationSent", GetDisplayName(slave)+" is not a DOM actor, skipping: "+description)
        ;return
    ;endif

    ; replace you and your
    description = ReplaceWord(description, "your", player_name+"'s")
    description = ReplaceWord(description, "you", player_name)

    DirectNarration_Optional("notification", description, slave, optional=true)
    Trace("OnNotificationSent", slave_name+" notificationType: '" + notificationType + "'' is_player_slave: " + is_player_slave + " description: '" + desc_original + " -> " + description)
EndEvent

; Real Dom climax HUD: brain/mind melts. Not the "squirms as your orgasm" player-climax tease.
bool Function IsDomMeltOrgasm(String description)
    if StringUtil.Find(description, "your orgasm") >= 0
        return false
    endif
    if StringUtil.Find(description, "brain melts") >= 0
        return true
    endif
    if StringUtil.Find(description, "mind melts") >= 0
        return true
    endif
    if StringUtil.Find(description, "overwhelmed by orgasm") >= 0
        return true
    endif
    if StringUtil.Find(description, "submerged by orgasm") >= 0
        return true
    endif
    return false
EndFunction

Function AddNotification(String description, Actor Subject)
    AddNotificationActor(description, Subject)

    if main == None || main.d_core == None
        return
    endif
    DOM_SlaveManager slaveManager = main.d_core.DOM02
    if slaveManager == None
        return
    endif

    int n = slaveManager.GetActorCount()
    int i = 0
    while i < n
        DOM_Actor domActor = slaveManager.GetActorByIndex(i)
        if domActor != None
            Actor other = domActor.GetActorRef()
            if other != None && other != Subject
                String otherName = other.GetDisplayName()
                if otherName != "" && StringUtil.Find(description, otherName) >= 0
                    AddNotificationActor(description, other)
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

Function AddNotificationActor(String description, Actor akActor)
    String uuid = akActor.GetFormID() as String
    int notifications = JMap.getObj(actor_to_notifications, uuid)
    int i = 0
    int ring_size = notifications_size
    if notifications == 0
        notifications = JArray.objectWithSize(ring_size)
        JValue.retain(notifications)
        JMap.setObj(actor_to_notifications, uuid, notifications)
        JMap.setInt(actor_to_notifications_next, uuid, 0)
        i = 0
        while i < ring_size
            int noteInit = JMap.object()
            JMap.setStr(noteInit, "message", "")
            JMap.setFlt(noteInit, "timestamp", 0.0)
            JMap.setInt(noteInit, "minutes", 0)
            JMap.setInt(noteInit, "hours", 0)
            JMap.setInt(noteInit, "days", 0)
            JValue.retain(noteInit)
            JArray.setObj(notifications, i, noteInit)
            i += 1
        endwhile
    else
        ring_size = JArray.count(notifications)
    endif

    int next = JMap.getInt(actor_to_notifications_next, uuid, 0)
    int last = next - 1
    if last < 0
        last = ring_size - 1
    endif

    Float rawDaysPassed = Utility.GetCurrentGameTime()
    int found = -1
    i = 0
    while i < ring_size
        int noteScan = JArray.getObj(notifications, i)
        Float ts = JMap.getFlt(noteScan, "timestamp", 0.0)
        if ts != 0.0 && JMap.getStr(noteScan, "message", "") == description
            found = i
            i = ring_size
        else
            i += 1
        endif
    endwhile

    if found >= 0
        int noteFound = JArray.getObj(notifications, found)
        JMap.setFlt(noteFound, "timestamp", rawDaysPassed)
        if found != last
            ; Rotate object refs along the live arc from found toward last
            int dst = found
            while dst != last
                int src = dst + 1
                if src >= ring_size
                    src = 0
                endif
                JArray.setObj(notifications, dst, JArray.getObj(notifications, src))
                dst = src
            endwhile
            JArray.setObj(notifications, last, noteFound)
        endif
    else
        int note = JArray.getObj(notifications, next)
        JMap.setStr(note, "message", description)
        JMap.setFlt(note, "timestamp", rawDaysPassed)

        next += 1
        if next >= ring_size
            next = 0
        endif
        JMap.setInt(actor_to_notifications_next, uuid, next)
    endif

    Trace("AddNotification", GetDisplayName(akActor)+" description: '" + description)
EndFunction

bool Function OnNotifcationSkip(String description, Actor slave=None)
    ; DomObedience skip window: drop vanilla SendNotificationOrder / Ext2 order DN for this command.
    ; SexLab StageStart DN is not on this path.
    if SkyrimNet_DOM_Obedience.ShouldSkipEventNarration(slave)
        return true
    endif
    ; Player-orgasm tease (DOM_Mind handleSexOrgasm / handleSeparateOrgasmEvent).
    ; Not a slave climax — do not DN, ring, or feed Handler_DOM.
    if StringUtil.Find(description, "squirms under your grasp") >= 0
        return true
    endif
    if StringUtil.Find(description, "your orgasm submerges you") >= 0
        return true
    endif
    ; Less-specific status lines that duplicate named DOM action notifications.
    if StringUtil.Find(description, "was just captured") >= 0
        return true
    endif
    if StringUtil.Find(description, "will train slaves in the sexual arts") >= 0
        return true
    endif
    if StringUtil.Find(description, "will train slaves in orgies") >= 0
        return true
    endif
    if StringUtil.Find(description, "will punish trainees") >= 0
        return true
    endif
    if StringUtil.Find(description, "undergoing sex training.") >= 0
        return true
    endif
    if StringUtil.Find(description, "training another slave.") >= 0
        return true
    endif
    if StringUtil.Find(description, "participating in orgy training.") >= 0
        return true
    endif
    if StringUtil.Find(description, "following a slave trainer.") >= 0
        return true
    endif
    if StringUtil.Find(description, "is following.") >= 0
        return true
    endif
    if StringUtil.Find(description, "obediently following.") >= 0
        return true
    endif
    if StringUtil.Find(description, "fetching a slave for sexual training.") >= 0
        return true
    endif
    if StringUtil.Find(description, "fetching another slave trainee.") >= 0
        return true
    endif
    if StringUtil.Find(description, "fetching trainees for an orgy.") >= 0
        return true
    endif
    if StringUtil.Find(description, "punishing another slave trainee.") >= 0
        return true
    endif
    if StringUtil.Find(description, "punished another slave.") >= 0
        return true
    endif
    return false
EndFunction

Function UpdateNotificationAge(int note, Float timestamp)
    Float deltaDays = Utility.GetCurrentGameTime() - timestamp
    if deltaDays < 0.0
        deltaDays = 0.0
    endif
    Int minutes = (deltaDays * 1440.0) as Int
    JMap.setInt(note, "minutes", minutes)
    JMap.setInt(note, "hours", minutes / 60)
    JMap.setInt(note, "days", minutes / 1440)
EndFunction

int Function GetNotifications(Actor akActor)
    String uuid = akActor.GetFormID() as String 
    int notifications = JMap.getObj(actor_to_notifications, uuid)
    if notifications == 0
        return 0
    endif
    int ring_size = JArray.count(notifications)
    Float currentDaysPassed = Utility.GetCurrentGameTime()
    int i = 0 
    int num_notes = 0
    while i < ring_size
        int note = JArray.getObj(notifications, i)
        Float timestamp = JMap.getFlt(note, "timestamp", 0.0)
        if timestamp != 0.0 && timestamp <= currentDaysPassed
            UpdateNotificationAge(note, timestamp)
            num_notes += 1
        else 
            JMap.setStr(note, "message", "")
            JMap.setFlt(note, "timestamp", 0.0)
            JMap.setInt(note, "minutes", 0)
            JMap.setInt(note, "hours", 0)
            JMap.setInt(note, "days", 0)
        endif 
        i += 1 
    endwhile
    if num_notes == 0
        return 0
    endif
    if num_notes == ring_size
        ; Full ring: return chronological order starting at write cursor (oldest)
        int full_notes = JArray.objectWithSize(ring_size)
        int next_full = JMap.getInt(actor_to_notifications_next, uuid, 0)
        int k = 0
        while k < ring_size
            int idx = next_full + k
            if idx >= ring_size
                idx -= ring_size
            endif
            JArray.setObj(full_notes, k, JArray.getObj(notifications, idx))
            k += 1
        endwhile
        return full_notes
    endif 

    ; Partial: walk from write cursor (oldest live slot after wrap) around the ring
    int notes = JArray.objectWithSize(num_notes)
    int j = 0
    int next = JMap.getInt(actor_to_notifications_next, uuid, 0)
    i = 0 
    while i < ring_size
        int idx = next + i
        if idx >= ring_size
            idx -= ring_size
        endif
        int note = JArray.getObj(notifications, idx)
        Float timestamp = JMap.getFlt(note, "timestamp", 0.0)
        if timestamp != 0.0 && timestamp <= currentDaysPassed
            JArray.setObj(notes, j, note)
            j += 1
        endif 
        i += 1
    endwhile
    return notes
EndFunction 

; ------------------------ 

Event OnRunaway(Form akRef)
    Actor runaway = akRef as Actor
    if runaway == None
        Trace("OnRunaway","akRef is not an Actor, skipping")
        return
    endif
    Trace("OnRunaway",runaway.GetDisplayName()+" is running away!")
    StorageUtil.SetStringValue(akRef, behaviour_current_key, "running_away")
    RegisterShort_AddName("runaway","running", akRef, "is running away. To afraid to turn back!")
EndEvent 

Event OnBehaviourChange(Form akRef, String type)
    Actor slave = akRef as Actor
    if slave == None
        Trace("OnBehaviourChange","akRef is not an Actor, skipping")
        return
    endif
    String current = StorageUtil.GetStringValue(akRef, behaviour_current_key, "")
    String msg = ""
    if current == "running_away"
        msg = "has been rundown and captured."
        last_order_refused = True
    elseif type == "running_away"
        ;msg = "tries to run away, too afraid to turn back!"
        msg = ""
        last_order_refused = True
    elseif type == "masturbate"
        msg = "obeys and starts masturbating."
        last_order_refused = False
    elseif current == "masturbate"
        msg = "stops masturbating."
    else 
        msg = "is "+SkyrimNet_DOM_Decorators.BehaviourToString(type)
    endif 
    String name_msg = Actor_name(slave)+" "+msg
    Trace("OnBehaviourChange",current+"->"+type+" "+name_msg)
    if msg != "" && !OnNotifcationSkip(name_msg, slave)
        DirectNarration_Optional(type, name_msg, slave, true)
    endif
    StorageUtil.SetStringValue(akRef, behaviour_current_key, type)
EndEvent 

Event OnMoodChange(Form akRef, String type)
    Actor slave = akRef as Actor
    if slave == None
        Trace("OnMoodChange","akRef is not an Actor, skipping")
        return
    endif
    String msg = mood_to_Sentence(slave.GetDisplayName(), type) 
    DirectNarration_Optional("mood", msg, slave, true)
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
    if akActor == None
        Trace("OnCallForHelp","akRef is not an Actor, skipping")
        return
    endif
    DOM_Actor slave = main.d_api.GetDOMActor(akActor) 
    String msg = akActor.GetDisplayName() 
    bool has_gag = false
    if slave
        has_gag = slave.has_mouth_gag
    endif
    if type == "inbag"
        msg = "called for help from within a bag, only muffled sounds escape."
    elseif type == "leashed"
        msg = "tried to call for help, but it was magically suppressed."
    elseif type == "mumbles" || has_gag
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
    if slave == None
        Trace("OnOrgasm","akRef is not an Actor, skipping")
        return
    endif
    String msg = "An orgasm overwhelms and melts "+slave.GetDisplayName()+"'s mind"
    if type == "rape"
        msg += " despite being raped."
    elseif type == "kink"
        msg += " from "+slave.GetDisplayName()+"'s sexual kink."
    elseif type == "magic"
        msg += ", because of a magical effect."
    else
        msg += "."
    endif 
    if handler
        handler.DOMSlave_Orgasmed(slave, msg)
    endif
EndEvent

Event OnKinkDiscovered(Form akRef, String type)
    Actor slave = akRef as Actor 
    if slave == None
        Trace("OnKinkDiscovered","akRef is not an Actor, skipping")
        return
    endif
    String msg = player.GetDisplayName()+" discovers "+slave.GetDisplayName()+" has a fetish for "+type+"."
    DirectNarration_Optional("kink discovered", msg, slave)
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
    DirectNarration_Optional("price inspection", msg, slave)
EndEvent 

Event OnBodyInspection(Form sender, string inspectionMethod, string inspectionResults, bool isObedient)
    last_order_refused = !isObedient
    Actor slave = sender as Actor 
    String msg = player.GetDisplayName()+"'s hands inspect every inch of "+slave.GetDisplayName()+", With special attention on their genitals, ass, and mouth."
    if !isObedient 
        msg = msg + slave.GetDisplayName()+" disobediently didn't cooperate with the inspection. "
    endif 
    DirectNarration_Optional("body inspection", msg, slave)
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
    DirectNarration_Optional("kissed", msg, slave)
EndEvent 

; --------------------------
; Injury Engine
; --------------------------
int Property HEAL_SOURCE_SPELL = 1 AutoReadOnly ; Injury_Engine_Main.HealSyncSourceMethod: spell
int Property HEALING_HANDS = 0x04D3F2 AutoReadOnly ; Skyrim.esm

; Every torture batch Injury Engine lands. Starts DOM's pain punishment unless DOM already did (a weapon whip's OnHit
; starts it before this event arrives); the first batch of each punishment picks its reason (TortureReasonNamed).
; Every batch counts as a punishment hit (hand / spell torture fires no OnHit, so DOM would end it at once).
; DOM ends the punishment after a tick without hits and trains (EndPunishing -> TrainAfterPunished).
Event OnInjuryTorture(Form akAttacker, Form akVictim, String source, Int hits, String cause)
    Actor attacker = akAttacker as Actor
    Actor victim = akVictim as Actor
    if attacker == None || victim == None || attacker == victim || !main || !main.d_core
        return
    endif
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Events", "OnInjuryTorture", victim)
    if !slave || !slave.mind
        return
    endif
    if attacker != player && !main.d_core.IsAllowedToPunish(attacker)
        return
    endif
    if main.d_core.IsFleeing(victim)
        return
    endif
    DOM_Mind mind = slave.mind
    if !mind.whipping_active
        mind.StartPunishingByIndex(attacker, 0, "pain")
    endif
    Bool fresh = !SkyrimNet_DOM_API.TortureReasonNamed(victim, mind)
    Trace("OnInjuryTorture", attacker.GetDisplayName() + " -> " + victim.GetDisplayName() + " " + source + " hits:" + hits \
        + " active:" + mind.whipping_active + " reason:" + mind.whipping_reason + " fresh:" + fresh)
    if fresh
        StartTortureReason(attacker, victim, mind)
    endif
    mind.HandlePunishmentOnHit(attacker, None)
    SkyrimNet_DOM_API.MarkTortureDamage(victim, mind)
EndEvent

; Panel reason (SkyrimNet_SexLab Punish), else the player's list (dom.punish.torture_choose_reason; always offers
; custom / no reason), else a random open reason ("being a bad slave" when none). While the list is up the punishment
; carries that random reason (no event), so later batches don't reopen it and Esc / Close still trains on a real reason.
Function StartTortureReason(Actor attacker, Actor victim, DOM_Mind mind)
    String reason = SkyrimNet_DOM_API.TakePanelReason(victim)
    if reason == ""
        reason = SkyrimNet_DOM_API.RandomOpenReason(victim)
        if attacker == player && main.torture_choose_reason
            SkyrimNet_DOM_Menu menu = (self as Quest) as SkyrimNet_DOM_Menu
            if menu
                SkyrimNet_DOM_API.NameRunningPunishment(victim, mind, reason)
                menu.OpenTortureReasonList(attacker, victim, SkyrimNet_DOM_API.OpenPunishReasons(victim))
                return
            endif
        endif
    endif
    SkyrimNet_DOM_API.ApplyTortureReason(attacker, victim, reason)
EndFunction

; A healing source opened a heal session. Healing Hands cast on a slave goes to HealSlave.
Event OnInjuryHealStart(Form akCaster, Form akTarget, Int source)
    Actor caster = akCaster as Actor
    Actor target = akTarget as Actor
    if source != HEAL_SOURCE_SPELL || caster == None || target == None || caster == target || !main || !main.d_core
        return
    endif
    Spell hands = Game.GetFormFromFile(HEALING_HANDS, "Skyrim.esm") as Spell
    if hands == None || (caster.GetEquippedSpell(0) != hands && caster.GetEquippedSpell(1) != hands)
        return
    endif
    HealSlave(caster, target, "OnInjuryHealStart")
EndEvent

; SkyrimNet_SexLab Aid (HUD, Aid panel, potion, SexLab_Aid action) restored health: Aid casts nothing, so Injury Engine
; sends no HealStart. sender = target; strArg "<spell|potion>|<caster FormID>"; numArg = health.
Event OnSexLabAidStart(String eventName, String strArg, Float numArg, Form sender)
    Actor target = sender as Actor
    String[] parts = StringUtil.Split(strArg, "|")
    if target == None || parts.Length < 2 || !main || !main.d_core
        return
    endif
    Actor caster = Game.GetFormEx(parts[1] as Int) as Actor
    if caster == None || caster == target
        return
    endif
    Trace("OnSexLabAidStart", caster.GetDisplayName() + " " + parts[0] + " -> " + target.GetDisplayName() + " health:" + numArg)
    HealSlave(caster, target, "OnSexLabAidStart")
EndEvent

; A shocked slave gets DOM "care" comfort, otherwise praise ("tell"). The player picks the reason when
; dom.praise.heal_choose_reason is on (Close: no praise); otherwise, or with no reason picked, "being a good slave" /
; "being a good slaver".
Function HealSlave(Actor caster, Actor target, String fn)
    DOM_Actor slave = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Events", fn, target)
    if !slave || !slave.mind
        return
    endif
    if slave.mind.mood == "shocked"
        ComfortCareNoHug(caster, slave, target)
        return
    endif
    if caster == player && main.heal_choose_reason
        SkyrimNet_DOM_Menu menu = (self as Quest) as SkyrimNet_DOM_Menu
        if menu
            menu.OpenHealPraiseList(caster, target)
            return
        endif
    endif
    slave.StartPraising(caster, SkyrimNet_DOM_Menu.DefaultPraiseReason(slave.mind), "tell")
    Trace(fn, caster.GetDisplayName() + " heals and praises " + target.GetDisplayName())
EndFunction

; DOM_Mind.StartComfortingWith(caster, "care") without its Anim_GetPlayerHug (DOM's abuse_type is private and
; stays as it was).
Function ComfortCareNoHug(Actor caster, DOM_Actor slave, Actor target)
    DOM_Core core = main.d_core
    DOM_Mind mind = slave.mind
    String name = target.GetDisplayName()
    int broken = 0
    float mod = core.GetPredatorModifier(caster)
    if !mind.IsComforted()
        mind.SetNextPunishmentReasonForceMessage(17, "doesn't want to be comforted") ; "didnt listen"
    endif
    if !mind.StartGuilt()
        mind.SetNextPunishmentReasonForceMessage(17, "doesn't care about being healed") ; "didnt listen"
    else
        float amount = core.train_speed_tell * 0.1 * mind.MOD_Ease * mod
        mind.TrainRespect(amount)
        mind.TrainAnger(amount)
        mind.number_of_comfort += 1
        mind.SendNotificationAbuse("Comforting " + name + " with care")
        if core.DOMPlayerAlias
            core.DOMPlayerAlias.HasChatWith(slave)
        endif
        broken = 2
    endif
    if broken > 0
        float now = Utility.GetCurrentGameTime()
        mind.time_last_abused = now
        mind.time_last_resilience = now
    endif
    DOM_Mind casterMind = core.GetActorMind(caster)
    if casterMind != None
        casterMind.TrainSkillPredator(0.5)
        casterMind.SetNextPraiseReasonSilent(47) ; "being a perverted trainer"
        casterMind.CheckAndRegisterKink(100, 1.0) ; "taking advantage of slaves"
    else
        if caster == player
            core.DOM04.NotifyEndComforted(slave, "care", broken > 0)
            slave.SendExternalEventSSB("Comforted", "care", broken > 0)
        endif
        core.TrainSkillPredator(caster, 0.5)
    endif
    Trace("ComfortCareNoHug", caster.GetDisplayName() + " heals " + name + " broken:" + broken)
EndFunction

Event OnPunished(Form akRef, string punish_method, string punish_reason, bool is_obedient)
    Actor slave = akRef as Actor 
    String slave_name = slave.GetDisplayName()

    String msg = player.GetDisplayName()+" punished " \
        + slave_name+" with "+punish_method+" for "+punish_reason+"."

    if punish_method == "whip" 
        msg += " Leaving red angry welts across "+slave_name+"'s body and speckles of her blood on the floor."
    elseif punish_method == "slapping"
        msg += " Leaving "+slave_name+"'s cheek bright red and stinging."
    elseif punish_method == "spanking"
        msg += " Leaving "+slave_name+"'s ass bright red and stinging."
    elseif punish_method == "choking"
        msg += slave_name+" struggles to breath. "
    endif 
    if !is_obedient
        msg += slave_name+" refuses to submit."
    endif 
    DirectNarration_Optional("punished", msg, slave)  
    Trace("OnPunishment",msg) 
EndEvent 

; guilt, rape, insult, threat, sex, care, 
Event OnComforted(Form akRef, String type, Bool isObedient)
    last_order_refused = !isObedient
    Actor slave = akRef as Actor 
    if slave == None
        Trace("OnComforted","akRef is not an Actor, skipping")
        return
    endif
    String name = slave.GetDisplayName()
    String msg = player.GetDisplayName()
    Bool pretending = False
    if type == "sex" 
        msg += " tries to comfort "+name+" with loving sex"
    elseif type == "care"
        msg += " tries to comfort "+name+" with a warm hug"
    elseif type == "insult" || type == "threat"
        msg += " pretends to comfort "+name+" with an "+type
        pretending = True
    else ; guilt, rape
        msg += " pretends to comfort "+name+" with "+type
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
    DirectNarration_Optional("comforted "+type+":"+accepted, msg, slave)
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

    DirectNarration_Optional("praised", msg, slave)  
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

    DirectNarration_Optional("flattered", msg, slave)  
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

    DirectNarration_Optional("insult", msg, slave)  
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

    DirectNarration_Optional("promised", msg, slave)  
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

    DirectNarration_Optional("threatened", msg, slave)  
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

    DirectNarration_Optional("undress", msg, slave)  
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

    DirectNarration_Optional("washSelf", msg, slave)  
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

    DirectNarration_Optional("brand", msg, slave)  
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

    DirectNarration_Optional("onsalute", msg, slave)  
EndEvent 

Event OnRecruited(Form sender, string mood, bool isNewActor) ; If not new actor, slaver was previously in DOM
    Actor slave = sender as Actor 
    String name = slave.GetDisplayName()
    String ower = player.GetDisplayName()

    String msg = ower+" recruits a "+mood+" "+name+" as a slave trainer."

    DirectNarration_Optional("rectuit", msg, slave)  
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
    DirectNarration_Optional("released", msg, slave)  
EndEvent 

;---------------------------------------------------
; Events 3 
;---------------------------------------------------
;Event OnNotificationSent(Form sender, string actorStatus, bool isPlayersSlave, string fullText)
;    Actor slave = sender as Actor 
;    if isPlayersSlave 
;        RegisterShortLivedEvent("slave", "misc", fullText, "", 120000, slave)
;    endif 
;EndEvent

;---------------------------------------------------
; SexLab Events
;---------------------------------------------------

Event SexLab_AnimationStart(int ThreadID, bool HasPlayer)
    if sexlab_main == None || sexlab_main.sexlab == None
        Trace("SexLab_AnimationStart", "sexlab_main or sexlab is None")
        return
    endif
    ; Get the thread that triggered this event via the thread id
    sslThreadController Thread = sexlab_main.sexlab.GetController(ThreadID)
    if Thread == None
        Trace("SexLab_AnimationStart", "Thread is None for ThreadID: "+ThreadID)
        return
    endif
    Actor[] actors = Thread.Positions
    if !actors
        Trace("SexLab_AnimationStart", "actors is None for ThreadID: "+ThreadID)
        return
    endif
    int i = actors.length - 1   
    while  0 <= i
        DOM_Actor domActor = main.d_api.GetDomActor(actors[i])
        if domActor != None 
            actors[i].SetFactionRank(main.d_sexlab.DOMAnimatingFaction, 2)
            bool isACtive = sexlab_main.sexlab.IsActorActive(actors[i])
            bool canIdle = domActor.canIdle
            thread.DisableOrgasm(actors[i])
            Trace("SexLab_AnimationStart","ThreadID: "+ThreadID+" Actor: "+actors[i].GetDisplayName()+" IsActorActive: "+isACtive+" canIdle: "+canIdle)
        endif 
        i -= 1
    endwhile 
EndEvent 

Event SexLab_AnimationEnd(int ThreadID, bool HasPlayer)
    if sexlab_main == None || sexlab_main.sexlab == None
        Trace("SexLab_AnimationEnd", "sexlab_main or sexlab is None")
        return
    endif
	; Get the thread that triggered this event via the thread id
	sslThreadController Thread = sexlab_main.sexlab.GetController(ThreadID)
    if Thread == None
        Trace("SexLab_AnimationEnd", "Thread is None for ThreadID: "+ThreadID)
        return
    endif
    Actor[] actors = Thread.Positions
    if !actors
        Trace("SexLab_AnimationEnd", "actors is None for ThreadID: "+ThreadID)
        return
    endif
    GetActorsFinishedWithScene(Thread)
    int i = actors.length - 1
    while 0 <= i
        Thread.DisableOrgasm(actors[i], false)
        i -= 1
    endwhile
EndEvent

Function GetActorsReadyForScene(sslThreadModel thread)
    if thread == None
        Trace("GetActorsReadyForScene", "thread is None")
        return
    endif
    Actor[] actors = thread.Positions 
    if !actors
        Trace("GetActorsReadyForScene", "actors is None")
        return
    endif
    int i = actors.length - 1
    while 0 <= i
        main.d_sexlab.GetReadyForScene(actors[i], main.d_api.GetDomActor(actors[i]))
        actors[i].SetFactionRank(main.d_sexlab.DOMAnimatingFaction, 2)
        i -= 1
    endwhile
EndFunction 

Function GetActorsFinishedWithScene(sslThreadController thread)
	; Get our list of actors that were in this animation thread.
    if thread == None
        Trace("GetActorsFinishedWithScene", "thread is None")
        return
    endif
	Actor[] actors = Thread.Positions
    if !actors
        Trace("GetActorsFinishedWithScene", "actors is None")
        return
    endif

    int i = actors.length - 1
    while 0 <= i
        if main.d_api.IsDOMSlave(actors[i])
            DOM_Actor domActor = main.d_api.GetDomActor(actors[i])
            if domActor != None
                domActor.OnSexEnd()
            endif
            actors[i].RemoveFromFaction(main.d_sexlab.DOMAnimatingFaction)
            main.d_sexlab.ClearAnimatingFaction(actors[i])
        endif 
        i -= 1 
    endwhile 
EndFunction