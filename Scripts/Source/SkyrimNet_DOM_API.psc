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
    if main == None
        Trace("AddPunishmentReason", "SkyrimNet_DOM_Main is None, aborting")
        return
    endif
    if !slave || !slave.mind || !slaveActor
        Trace("AddPunishmentReason", "slave, slave.mind, or slaveActor is None, aborting")
        return
    endif

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

; ------------------------------------------------------------
; Injury Engine torture as DOM punishment
; ------------------------------------------------------------
String Function REASON_BAD_SLAVE() global
    return "being a bad slave"
EndFunction

String Function REASON_DISOBEY() global
    return "didnt obey"
EndFunction

; StorageUtil on the slave: panel-picked reason (PanelPunished) and when (real time)
String Function KEY_PANEL_REASON() global
    return "skyrimnet_dom.panel_reason"
EndFunction

String Function KEY_PANEL_REASON_TIME() global
    return "skyrimnet_dom.panel_reason_time"
EndFunction

; StorageUtil string lists on the slave: Punish panel text -> DOM reason (PanelPunishReasons)
String Function KEY_PANEL_TEXT() global
    return "skyrimnet_dom.panel_reason_text"
EndFunction

String Function KEY_PANEL_NAME() global
    return "skyrimnet_dom.panel_reason_name"
EndFunction

; StorageUtil on the slave: the whipping_reason the bridge named the running pain punishment with, and
; whipping_pain_damage after its last batch (TortureReasonNamed)
String Function KEY_TORTURE_REASON_INDEX() global
    return "skyrimnet_dom.torture_reason_index"
EndFunction

String Function KEY_TORTURE_DAMAGE() global
    return "skyrimnet_dom.torture_damage"
EndFunction

; True when the running pain punishment is the one the bridge already named. DOM may start a punishment itself
; (its OnHit, before Injury Engine's event) with its own reason; StartPunishingByIndex resets whipping_pain_damage
; and EndPunishing resets whipping_reason, so either one changing means a new punishment.
Bool Function TortureReasonNamed(Actor slaveActor, DOM_Mind mind) global
    if !mind.whipping_active
        return false
    endif
    int index = StorageUtil.GetIntValue(slaveActor, KEY_TORTURE_REASON_INDEX(), -1)
    if index < 0 || mind.whipping_reason != index
        return false
    endif
    return mind.whipping_pain_damage >= StorageUtil.GetIntValue(slaveActor, KEY_TORTURE_DAMAGE(), 0)
EndFunction

Function MarkTortureDamage(Actor slaveActor, DOM_Mind mind) global
    StorageUtil.SetIntValue(slaveActor, KEY_TORTURE_DAMAGE(), mind.whipping_pain_damage)
EndFunction

; StorageUtil float on the slave: game time (days) the bridge first saw the running pain punishment (EndStalePainPunishment)
String Function KEY_PAIN_START() global
    return "skyrimnet_dom.pain_start"
EndFunction

Float Function PAIN_PUNISH_TIMEOUT_SECONDS() global
    return 60.0
EndFunction

; Ends a pain punishment older than PAIN_PUNISH_TIMEOUT_SECONDS (real seconds, via TimeScale). DOM's tick never ends one
; started by a DOM-mind actor (whipping_by_trainer), and such a punishment survives in the save: every later lash then
; looked "already named" (TortureReasonNamed), so no reason list / dom_torture_punish ever came. EndWhipping is DOM's
; normal close (training + "Punishing ... strokes" notice). Clears the bridge markers so the next batch is fresh.
Bool Function EndStalePainPunishment(Actor slaveActor, DOM_Actor slave, Actor abuser) global
    if slaveActor == None || !slave || !slave.mind
        return false
    endif
    DOM_Mind mind = slave.mind
    if !mind.whipping_active
        StorageUtil.UnsetFloatValue(slaveActor, KEY_PAIN_START())
        return false
    endif
    Float now = Utility.GetCurrentGameTime()
    Float start = StorageUtil.GetFloatValue(slaveActor, KEY_PAIN_START(), -1.0)
    if start < 0.0 || start > now
        StorageUtil.SetFloatValue(slaveActor, KEY_PAIN_START(), now)
        return false
    endif
    Float timescale = 20.0
    GlobalVariable ts = Game.GetFormFromFile(0x3A, "Skyrim.esm") as GlobalVariable
    if ts && ts.GetValue() > 0.0
        timescale = ts.GetValue()
    endif
    Float elapsed = (now - start) * 86400.0 / timescale
    if elapsed <= PAIN_PUNISH_TIMEOUT_SECONDS()
        return false
    endif
    if abuser == None
        abuser = Game.GetPlayer()
    endif
    Trace("EndStalePainPunishment", slaveActor.GetDisplayName() + " reason:" + mind.whipping_reason + " '" \
        + mind.whipping_reason_name + "' trainer:" + mind.whipping_by_trainer + " elapsed:" + elapsed + "s by " \
        + abuser.GetDisplayName())
    slave.EndWhipping(abuser)
    StorageUtil.UnsetFloatValue(slaveActor, KEY_PAIN_START())
    StorageUtil.UnsetIntValue(slaveActor, KEY_TORTURE_REASON_INDEX())
    StorageUtil.UnsetIntValue(slaveActor, KEY_TORTURE_DAMAGE())
    return true
EndFunction

; A new pain punishment's first batch (OnInjuryTorture fresh): its timeout counts from now, not from one that ended
; between two scans.
Function MarkPainStart(Actor slaveActor) global
    StorageUtil.SetFloatValue(slaveActor, KEY_PAIN_START(), Utility.GetCurrentGameTime())
EndFunction

; Names the running pain punishment (no event) and marks it named for TortureReasonNamed.
Function NameRunningPunishment(Actor slaveActor, DOM_Mind mind, String reason) global
    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    if main == None || !mind.whipping_active
        return
    endif
    ; "no reason" is DOM index 0; free text (the list's custom) counts as "being a bad slave" and keeps its own name
    ; (the default index 0 makes DOM keep the provisional reason for the summary / training).
    if reason == "no reason"
        mind.whipping_reason = 0
    elseif main.Has_Punishment_Reason(reason)
        mind.whipping_reason = main.Get_Punishment_To_Index(reason)
    else
        mind.whipping_reason = main.Get_Punishment_To_Index(REASON_BAD_SLAVE())
    endif
    mind.whipping_reason_name = reason
    StorageUtil.SetIntValue(slaveActor, KEY_TORTURE_REASON_INDEX(), mind.whipping_reason)
    MarkTortureDamage(slaveActor, mind)
EndFunction

; The slave's open DOM punishment reasons (DOM_Mind next reasons), no duplicates / "no reason".
String[] Function OpenPunishReasons(Actor slaveActor) global
    String[] reasons = PapyrusUtil.StringArray(0)
    DOM_Actor slave = GetSlave("SkyrimNet_DOM_API", "OpenPunishReasons", slaveActor)
    if !slave || !slave.mind
        return reasons
    endif
    DOM_Mind mind = slave.mind
    int n = mind.GetNumberOfNextPunishmentReasons()
    int i = 0
    while i < n
        String reason = mind.GetNextPunishmentReason(i)
        if reason != "" && reason != "no reason" && reasons.Find(reason) < 0
            reasons = PapyrusUtil.PushString(reasons, reason)
        endif
        i += 1
    endwhile
    return reasons
EndFunction

; A random open reason; "being a bad slave" when the slave has none.
String Function RandomOpenReason(Actor slaveActor) global
    String[] reasons = OpenPunishReasons(slaveActor)
    if reasons.Length == 0
        return REASON_BAD_SLAVE()
    endif
    return reasons[Utility.RandomInt(0, reasons.Length - 1)]
EndFunction

; subject + punishment_reason.json description + superior ("she refused to comply with the sexual demands of Bob");
; "" when the reason has no description.
String Function ReasonClause(Actor superior, Actor slaveActor, String reason, String subject) global
    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    if main == None || superior == None
        return ""
    endif
    String desc = main.Get_Punishment_Description_Exact(reason)
    if desc == ""
        return ""
    endif
    return subject + desc + superior.GetDisplayName()
EndFunction

; Names the reason on the running pain punishment and tells SkyrimNet:
; "Bob is punishing Nina because she refused to comply with the sexual demands of Bob."
Function ApplyTortureReason(Actor torturer, Actor slaveActor, String reason) global
    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    DOM_Actor slave = GetSlave("SkyrimNet_DOM_API", "ApplyTortureReason", slaveActor)
    if main == None || !slave || !slave.mind || torturer == None
        Trace("ApplyTortureReason", "missing main, slave or torturer")
        return
    endif
    if reason == ""
        reason = REASON_BAD_SLAVE()
    endif
    DOM_Mind mind = slave.mind
    NameRunningPunishment(slaveActor, mind, reason)
    String pronoun = "he"
    if slaveActor.GetLeveledActorBase().GetSex() == 1
        pronoun = "she"
    endif
    String why = " for no reason"
    if reason != "no reason"
        why = ReasonClause(torturer, slaveActor, reason, pronoun)
        if why == ""
            why = "of " + reason
        endif
        why = " because " + why
    endif
    String msg = torturer.GetDisplayName() + " is punishing " + slaveActor.GetDisplayName() + why + "."
    Trace("ApplyTortureReason", "index:" + mind.whipping_reason + " active:" + mind.whipping_active + " " + msg)
    SkyrimNetApi.RegisterEvent("dom_torture_punish", msg, torturer, slaveActor)
EndFunction

; SkyrimNet_SexLab scene start (Handler_DOM.SeedPunishReasons): the slave's open DOM reasons join the
; Punish panel's reason list ("Nina refused to comply with the sexual demands of Bob").
Function PanelPunishReasons(Actor slaveActor) global
    if slaveActor == None
        return
    endif
    StorageUtil.StringListClear(slaveActor, KEY_PANEL_TEXT())
    StorageUtil.StringListClear(slaveActor, KEY_PANEL_NAME())
    DOM_Actor slave = GetSlave("SkyrimNet_DOM_API", "PanelPunishReasons", slaveActor)
    if !slave || !slave.mind
        return
    endif
    String[] reasons = OpenPunishReasons(slaveActor)
    Actor superior = slave.mind.actor_owner
    if superior == None
        superior = Game.GetPlayer()
    endif
    String slave_name = slaveActor.GetDisplayName()
    int i = 0
    while i < reasons.Length
        String text = ReasonClause(superior, slaveActor, reasons[i], slave_name)
        if text == ""
            text = slave_name + " is to be punished for " + reasons[i]
        endif
        StorageUtil.StringListAdd(slaveActor, KEY_PANEL_TEXT(), text)
        StorageUtil.StringListAdd(slaveActor, KEY_PANEL_NAME(), reasons[i])
        SkyrimNet_SexLab_OrgasmEngine.AddPunishReason(superior, slaveActor, text)
        i += 1
    endwhile
    Trace("PanelPunishReasons", slave_name + " reasons:" + reasons.Length)
EndFunction

; SkyrimNet_SexLab Punish panel (C++ OrgasmEngine::PunishNarrated, before the hit): a DOM text -> that reason,
; a SexLab strategy / request reason -> "didnt obey", anything else -> "being a bad slave".
; Kept on the slave for the torture handler (TakePanelReason).
Function PanelPunished(Actor by, Actor slaveActor, String reason, Bool isStrategy) global
    if slaveActor == None || !IsDOMSlave(slaveActor)
        return
    endif
    String name
    int i = -1
    if reason != ""
        i = StorageUtil.StringListFind(slaveActor, KEY_PANEL_TEXT(), reason)
    endif
    if i >= 0
        name = StorageUtil.StringListGet(slaveActor, KEY_PANEL_NAME(), i)
    elseif isStrategy
        name = REASON_DISOBEY()
    else
        name = REASON_BAD_SLAVE()
    endif
    StorageUtil.SetStringValue(slaveActor, KEY_PANEL_REASON(), name)
    StorageUtil.SetFloatValue(slaveActor, KEY_PANEL_REASON_TIME(), Utility.GetCurrentRealTime())
    Trace("PanelPunished", slaveActor.GetDisplayName() + " '" + reason + "' strategy:" + isStrategy + " -> " + name)
EndFunction

; The Punish panel's reason when it was picked in the last 10 real seconds ("" otherwise); cleared once taken.
String Function TakePanelReason(Actor slaveActor) global
    String name = StorageUtil.GetStringValue(slaveActor, KEY_PANEL_REASON(), "")
    float stamp = StorageUtil.GetFloatValue(slaveActor, KEY_PANEL_REASON_TIME(), -1000.0)
    StorageUtil.UnsetStringValue(slaveActor, KEY_PANEL_REASON())
    StorageUtil.UnsetFloatValue(slaveActor, KEY_PANEL_REASON_TIME())
    float now = Utility.GetCurrentRealTime()
    if name == "" || now - stamp > 10.0 || now < stamp
        return ""
    endif
    return name
EndFunction

int Function GetThreads() global
    SkyrimNet_SexLab_Scene_Manager scene_manager = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Scene_Manager
    if scene_manager == None
        Trace("GetThreads", "SkyrimNet_SexLab_Scene_Manager is None")
        return 0
    endif
    ; DOM01 (0xD61) is DOM_Core/DOM_API — SlaveManager is DOM_Core.DOM02 (DiaryOfMine property, not edited here)
    DOM_Core dom01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_Core
    if dom01 == None
        Trace("GetThreads", "DOM_Core is None")
        return 0
    endif

    DOM_SlaveManager slaveManager = dom01.DOM02
    if slaveManager == None
        Trace("GetThreads", "DOM_Core.DOM02 (SlaveManager) is None")
        return 0
    endif

    int threads = JArray.object()
    ; actorAliases is filled at ForceRefTo; GetActorCount/actorArray lag until UpdateActorArray.
    if !slaveManager.actorAliases
        Trace("GetThreads", "--- actorAliases empty")
        return threads
    endif
    int n = slaveManager.GetMaxActorCount()
    int i = 0
    int skipped_no_actor = 0
    int skipped_not_masturbating = 0
    int skipped_busy = 0
    while i < n
        DOM_Actor slave = slaveManager.actorAliases[i] as DOM_Actor
        if slave != None
            Actor akSlave = slave.GetActorRef()
            if akSlave == None
                skipped_no_actor += 1
                Trace("GetThreads", "--- skip alias index:"+i+" no actor")
            else
                bool is_masturbating = slave.is_behaviour_masturbate || slave.behaviour == "masturbate"
                if !is_masturbating && dom01.DOMActionMasturbating && akSlave.IsInFaction(dom01.DOMActionMasturbating)
                    is_masturbating = true
                endif
                if !is_masturbating
                    skipped_not_masturbating += 1
                elseif scene_manager.IsBusy(akSlave)
                    skipped_busy += 1
                    Trace("GetThreads", "--- skip "+akSlave.GetDisplayName()+" busy")
                else
                    int thread = JMap.object()

                    int actor_obj = JMap.object()
                    JMap.setStr(actor_obj, "name", akSlave.GetDisplayName())
                    JMap.setForm(actor_obj, "form", akSlave)
                    JMap.setInt(actor_obj, "is_slave", 1)
                    if slave.mind
                        JMap.setFlt(actor_obj, "arousal_factor", slave.mind.arousal_factor)
                        JMap.setInt(actor_obj, "is_aroused_for", slave.mind.is_aroused_for)
                        JMap.setInt(actor_obj, "is_enraptured_for", slave.mind.is_enraptured_for)
                    endif

                    int speaking_modifiers_obj = JArray.objectWithSize(1)
                    JArray.setStr(speaking_modifiers_obj, 0, "_pleasure_")
                    JMap.setObj(actor_obj, "speaking_modifiers", speaking_modifiers_obj)

                    int actors_obj = JArray.objectWithSize(1)
                    JArray.setObj(actors_obj, 0, actor_obj)
                    JMap.setObj(thread, "actors", actors_obj)

                    JMap.setStr(thread, "description", akSlave.GetDisplayName()+" is masturbating")
                    JArray.addObj(threads, thread)
                    Trace("GetThreads", "--- add "+akSlave.GetDisplayName()+" is masturbating")
                endif
            endif
        endif
        i += 1
    endwhile
    Trace("GetThreads", "--- scanned:"+n+" threads:"+JArray.count(threads)+" skipped_no_actor:"+skipped_no_actor+" skipped_not_masturbating:"+skipped_not_masturbating+" skipped_busy:"+skipped_busy)
    return threads
EndFunction

; -------------------------------------------------------------
Function Start_Masturbate(String intent, Actor speaker, Actor superior, String position="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("Start_Masturbate","SkyrimNet_DOM_Actions is None")
        return
    endif
    actions.StartScene_masturbate(intent, speaker, superior, position=position)
EndFunction

Function StartScene_Consensual_Two(String intent, Actor speaker, Actor Superior, Actor target, string style="", string method="", String direction="", String setting_name="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Consensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif
    actions.StartScene_Consensual_Two(intent, speaker, superior, target, style=style, method=method, direction=direction, setting_name=setting_name)
EndFunction

Function StartScene_Nonconsensual_Two(String intent, Actor speaker, Actor superior, Actor target=None, Actor victim, string method="", String direction="", String setting_name="") global
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Nonconsensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif   
    actions.StartScene_Nonconsensual_Two(intent, speaker, superior, target, victim, method=method, direction=direction, setting_name=setting_name)
EndFunction


Function StartScene_Nonconsensual_Two_SpeakerVictim(String intent, Actor speaker, Actor superior, Actor target, string method="", String direction="", String setting_name="") global
    Actor victim = speaker
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Nonconsensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif   
    actions.StartScene_Nonconsensual_Two(intent, speaker, superior, target, victim, method=method, direction=direction, setting_name=setting_name)
EndFunction

Function StartScene_Nonconsensual_Two_TargetVictim(String intent, Actor speaker, Actor superior, Actor target, string method="", String direction="", String setting_name="") global
    Actor victim = target
    SkyrimNet_DOM_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if actions == None
        Trace("StartScene_Nonconsensual_Two","SkyrimNet_DOM_Actions is None")
        return
    endif   
    actions.StartScene_Nonconsensual_Two(intent, speaker, superior, target, victim, method=method, direction=direction, setting_name=setting_name)
EndFunction