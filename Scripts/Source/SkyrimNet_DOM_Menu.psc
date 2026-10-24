Scriptname SkyrimNet_DOM_Menu extends Quest

SkyrimNet_DOM_Actions Property actions Auto

int Property SLAVES_ROW_CAP = 43 AutoReadOnly

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Menu", func, msg, Notification)
EndFunction

SkyrimNet_DOM_Main Function GetMain()
    SkyrimNet_DOM_Main main = (self as Quest) as SkyrimNet_DOM_Main
    if main
        return main
    endif
    return Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
EndFunction

SkyrimNet_DOM_Actions Function GetActions()
    if actions
        return actions
    endif
    actions = (self as Quest) as SkyrimNet_DOM_Actions
    if actions
        return actions
    endif
    actions = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    return actions
EndFunction

DOM_Keys Function GetKeys()
    SkyrimNet_DOM_Main main = GetMain()
    if main
        return main.d_keys
    endif
    return None
EndFunction

DOM_Core Function GetCore()
    SkyrimNet_DOM_Main main = GetMain()
    if main
        return main.d_core
    endif
    return None
EndFunction

DOM_API Function GetApi()
    SkyrimNet_DOM_Main main = GetMain()
    if main
        return main.d_api
    endif
    return None
EndFunction

DOM_SlaveManager Function GetSlaveManager()
    DOM_Core core = GetCore()
    if core
        return core.DOM02
    endif
    return None
EndFunction

Actor Function FocusActor()
    return SkyrimNet_SexLab_WebUI.WebUI_GetFocusActor()
EndFunction

String Function FocusKind()
    return SkyrimNet_SexLab_WebUI.WebUI_GetFocusKind()
EndFunction

Bool Function IsAllSlaves()
    return FocusKind() == "all_slaves"
EndFunction

Function PushJson(String json)
    if json == ""
        Trace("PushJson", "empty json")
        return
    endif
    SkyrimNet_SexLab_WebUI.WebUI_PushMainPanelData(json)
EndFunction

Function Obey(Actor speaker, Actor target, String desc)
    SkyrimNet_DOM_Actions act = GetActions()
    if act && target
        act.RegisterObeyCommand(target, speaker, desc)
    endif
EndFunction

Function OrderNarration(Actor speaker, Actor target, String orderDesc)
    if !speaker
        speaker = Game.GetPlayer()
    endif
    String who = "the slaves"
    if target
        who = target.GetDisplayName()
    endif
    String msg = speaker.GetDisplayName()+" orders "+who+" to "+orderDesc+"."
    ; source=superior, target=slave — slave-as-source makes SkyrimNet attribute the order to the focus actor
    SkyrimNet_SexLab_Utilities.DirectNarration(msg, speaker, target)
    if target
        Obey(speaker, target, orderDesc)
    endif
EndFunction

; -1 ungated/no dll (caller OrderNarration), 0 refuse, 1/2 already narrated
Int Function GateOrder(Actor speaker, Actor target, String kind, String actionDesc)
    return SkyrimNet_DOM_Obedience.TryOrder(speaker, target, kind, actionDesc)
EndFunction

Function FinishOrder(Actor speaker, Actor target, String actionDesc, Int gateResult)
    if gateResult < 0
        OrderNarration(speaker, target, actionDesc)
    endif
EndFunction

String Function NamedOrderKind(String fn)
    if fn == "stand" || fn == "wait" || fn == "favor" || fn == "bag" || fn == "display"
        return fn
    endif
    if fn == "kneel" || fn == "salute" || fn == "attention" || fn == "naked" || fn == "drink"
        return fn
    endif
    if fn == "shower" || fn == "bath_me" || fn == "bath_you" || fn == "look" || fn == "turn" || fn == "come"
        return fn
    endif
    if fn == "follow_actor" || fn == "noweapons" || fn == "weapons" || fn == "noarmor" || fn == "armor"
        return fn
    endif
    return ""
EndFunction

String Function OrderEventKind(String eventName)
    if eventName == "Follow"
        return "follow"
    elseif eventName == "StandStill" || eventName == "WaitHere"
        return "stand"
    elseif eventName == "Display"
        return "display"
    elseif eventName == "Kneel"
        return "kneel"
    elseif eventName == "Salute"
        return "salute"
    elseif eventName == "Attention"
        return "attention"
    elseif eventName == "Masturbate"
        return "masturbate"
    elseif eventName == "BeNaked" || eventName == "DontBeNaked"
        return "naked"
    elseif eventName == "BeRespectful"
        return "respectful"
    elseif eventName == "BeSilent"
        return "silent"
    elseif eventName == "FightForMe" || eventName == "DontFightForMe"
        return "fight"
    elseif eventName == "WalkOnFour"
        return "walk4"
    elseif eventName == "ComeHere"
        return "come"
    elseif eventName == "LookAtMe"
        return "look"
    elseif eventName == "DrinkThis"
        return "drink"
    elseif eventName == "InBag"
        return "bag"
    elseif eventName == "Work"
        return "work"
    elseif eventName == "NoOrgasm" || eventName == "FreeOrgasm"
        return "orgasm"
    endif
    return ""
EndFunction

Function GateOrderGroup(Actor speaker, DOM_Keys keys, String kind, String actionDesc, String eventName, String type, Bool slavers)
    if !keys
        return
    endif
    if kind == "" || !SkyrimNet_DOM_Obedience.NativeReady()
        if slavers
            keys.DOMAllOrderSlavesAndSlavers(eventName, type, false)
        else
            keys.DOMAllOrderSlaves(eventName, type, false)
        endif
        OrderNarration(speaker, None, actionDesc)
        return
    endif
    DOM_SlaveManager mgr = GetSlaveManager()
    Actor player = Game.GetPlayer()
    if !mgr || !mgr.actorAliases
        return
    endif
    int n = mgr.GetMaxActorCount()
    int i = 0
    while i < n
        DOM_Actor slave = mgr.actorAliases[i] as DOM_Actor
        Actor akRef = None
        if slave
            akRef = slave.GetActorRef()
        endif
        if akRef && akRef != player && !IsFleeingActor(akRef)
            Int r = GateOrder(speaker, akRef, kind, actionDesc)
            if r != 0
                keys.DOMDoActionActor(akRef, eventName, type, false)
                FinishOrder(speaker, akRef, actionDesc, r)
            endif
        endif
        i += 1
    endwhile
EndFunction

Function SpeakAsPlayer(Actor speaker, Actor target, String line)
    if line != ""
        SkyrimNetApi.TransformDialogue(line)
    endif
    if target
        Obey(speaker, target, line)
    endif
EndFunction

String Function TargetName(Actor target)
    if target
        return target.GetDisplayName()
    endif
    return "them"
EndFunction

String Function SpeakerName(Actor speaker)
    if !speaker
        speaker = Game.GetPlayer()
    endif
    if speaker
        return speaker.GetDisplayName()
    endif
    return "I"
EndFunction

Actor Function ActorFromId(String otherId)
    if otherId == ""
        return None
    endif
    int fid = otherId as Int
    return Game.GetFormEx(fid) as Actor
EndFunction

Function PushCascade(int root)
    ; Lowercase keys — Skyrim string pool remaps name/label/options casing.
    String json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(root)
    JValue.release(root)
    if json == "" || json == "null" || json == "{}"
        Trace("PushCascade", "empty json")
        return
    endif
    Trace("PushCascade", "json length="+StringUtil.GetLength(json))
    SkyrimNet_SexLab_WebUI.WebUI_PushCascadeChoices(json)
EndFunction

int Function ChoicePapyrus(String label, String execFn, Bool closeLeaves)
    int opt = JMap.object()
    JMap.setStr(opt, "type", "papyrus")
    JMap.setStr(opt, "label", label)
    JMap.setStr(opt, "plugin", "SkyrimNet_DOM.esp")
    JMap.setStr(opt, "questFormId", "0x800")
    JMap.setStr(opt, "scriptName", "SkyrimNet_DOM_Menu")
    JMap.setStr(opt, "executionFunctionName", execFn)
    JMap.setInt(opt, "closeWebUI", closeLeaves as Int)
    int maps = JArray.object()
    JMap.setObj(opt, "parameterMapping", maps)
    int m1 = JMap.object()
    JMap.setStr(m1, "type", "speaker")
    JMap.setStr(m1, "name", "speaker")
    JArray.addObj(maps, m1)
    int m2 = JMap.object()
    JMap.setStr(m2, "type", "target")
    JMap.setStr(m2, "name", "target")
    JArray.addObj(maps, m2)
    return opt
EndFunction

Function ChoiceStatic(int opt, String name, String value)
    int maps = JMap.getObj(opt, "parameterMapping")
    int m = JMap.object()
    JMap.setStr(m, "type", "static")
    JMap.setStr(m, "name", name)
    JMap.setStr(m, "value", value)
    JArray.addObj(maps, m)
EndFunction

Function ChoiceDynamic(int opt, String name)
    int maps = JMap.getObj(opt, "parameterMapping")
    int m = JMap.object()
    JMap.setStr(m, "type", "dynamic")
    JMap.setStr(m, "name", name)
    JArray.addObj(maps, m)
EndFunction

; Choice entry for panel: fields (pool-safe keys; avoid name/label/value/options).
int Function FieldOption(String value, String label)
    int o = JMap.object()
    JMap.setStr(o, "val", value)
    JMap.setStr(o, "caption", label)
    return o
EndFunction

int Function MappingST()
    int maps = JArray.object()
    int m1 = JMap.object()
    JMap.setStr(m1, "type", "speaker")
    JMap.setStr(m1, "name", "speaker")
    JArray.addObj(maps, m1)
    int m2 = JMap.object()
    JMap.setStr(m2, "type", "target")
    JMap.setStr(m2, "name", "target")
    JArray.addObj(maps, m2)
    return maps
EndFunction

String Function YesNo(Bool v)
    if v
        return "yes"
    endif
    return "no"
EndFunction

String Function OnOff(Bool v)
    if v
        return "on"
    endif
    return "off"
EndFunction

Function AddField(int fields, String id, String label, String value)
    int f = JMap.object()
    JMap.setStr(f, "id", id)
    JMap.setStr(f, "label", label)
    JMap.setStr(f, "value", value)
    JArray.addObj(fields, f)
EndFunction

Function AddToggle(int controls, String id, String label, Bool on)
    int c = JMap.object()
    JMap.setStr(c, "id", id)
    JMap.setStr(c, "label", label)
    JMap.setStr(c, "widget", "toggle")
    JMap.setInt(c, "value", on as Int)
    JArray.addObj(controls, c)
EndFunction

Function AddSelect(int controls, String id, String label, String value, int options)
    int c = JMap.object()
    JMap.setStr(c, "id", id)
    JMap.setStr(c, "label", label)
    JMap.setStr(c, "widget", "select")
    JMap.setStr(c, "value", value)
    JMap.setObj(c, "options", options)
    JArray.addObj(controls, c)
EndFunction

Function AddButton(int controls, String id, String label, String value)
    int c = JMap.object()
    JMap.setStr(c, "id", id)
    JMap.setStr(c, "label", label)
    JMap.setStr(c, "widget", "button")
    JMap.setStr(c, "value", value)
    JArray.addObj(controls, c)
EndFunction

int Function SelectOption(String id, String label)
    int o = JMap.object()
    JMap.setStr(o, "id", id)
    JMap.setStr(o, "label", label)
    return o
EndFunction

String Function NestedStr(int obj, String mapName, String sub)
    int nested = JMap.getObj(obj, mapName)
    if nested == 0
        return ""
    endif
    return JMap.getStr(nested, sub, "")
EndFunction

String Function NestedIntStr(int obj, String mapName, String sub)
    int nested = JMap.getObj(obj, mapName)
    if nested == 0
        return ""
    endif
    return JMap.getInt(nested, sub, 0) as String
EndFunction

String Function NestedFltStr(int obj, String mapName, String sub)
    int nested = JMap.getObj(obj, mapName)
    if nested == 0
        return ""
    endif
    return JMap.getFlt(nested, sub, 0.0) as String
EndFunction

String Function TrainerLabel(DOM_Actor slave)
    if !slave
        return ""
    endif
    if slave.is_trainer
        return "trainer"
    endif
    DOM_Actor trainer = slave.GetTrainer()
    if trainer
        Actor tref = trainer.akRef
        if tref
            return tref.GetDisplayName()
        endif
        return trainer.getName()
    endif
    return ""
EndFunction

String Function DutyLabel(DOM_Actor slave)
    if !slave
        return ""
    endif
    if slave.is_jailed
        return "jailed"
    endif
    String duty = slave.GetOnDutyTitle()
    if duty != ""
        return duty
    endif
    return ""
EndFunction

String Function RestrainedLabel(DOM_Actor slave)
    if !slave
        return ""
    endif
    if slave.is_jailed
        return "jailed"
    endif
    if slave.is_restrained || slave.is_bounded
        return "restrained"
    endif
    return ""
EndFunction

String Function PunishmentLabel(DOM_Actor slave, DOM_Core core)
    if !slave || !slave.mind
        return ""
    endif
    DOM_Mind mind = slave.mind
    String current = mind.current_punishment_reason_name
    if current != "" && current != "no reason"
        return current
    endif
    if core
        int idx = mind.GetNextPunishmentReasonByIndex()
        return core.GetJSONPunishmentReasonNameByIndex(idx, slave.actorSex)
    endif
    return ""
EndFunction

DOM_Actor Function SlaveOf(Actor akActor)
    DOM_API api = GetApi()
    if api && akActor
        return api.GetDOMActor(akActor)
    endif
    return None
EndFunction

Bool Function IsFleeingActor(Actor akActor)
    DOM_Core core = GetCore()
    if core && akActor
        return core.IsFleeing(akActor)
    endif
    return false
EndFunction

int Function FurnitureIndex(String flag)
    if flag == "random" || flag == ""
        return Utility.RandomInt(0, 6)
    endif
    return flag as Int
EndFunction

Bool Function ReasonListed(DOM_Mind mind, int n, String reason)
    if !mind || reason == ""
        return false
    endif
    int i = 0
    while i < n
        if mind.GetNextPunishmentReason(i) == reason
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

Bool Function PraiseListed(DOM_Mind mind, int n, String reason)
    if !mind || reason == ""
        return false
    endif
    int i = 0
    while i < n
        if mind.GetNextPraiseReason(i) == reason
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

Function TM_ModeOpened()
    Trace("TM_ModeOpened", "--- DOM ControlPanel mode")
EndFunction

Function TM_ModeClosed()
    Trace("TM_ModeClosed", "--- left DOM ControlPanel mode")
EndFunction

Function TM_StatusPanelClose()
    Trace("TM_StatusPanelClose", "---")
EndFunction

Function TM_SlavesPanelClose()
    Trace("TM_SlavesPanelClose", "---")
EndFunction

Function TM_StatusPanelOpen()
    if IsAllSlaves()
        PushJson(TM_BuildGroupStatusJson())
        return
    endif
    Actor target = FocusActor()
    if !target
        Trace("TM_StatusPanelOpen", "no focus actor")
        return
    endif
    PushJson(TM_BuildSlaveStatusJson(target))
EndFunction

Function TM_SlavesPanelOpen()
    PushJson(TM_BuildSlavesTableJson())
EndFunction

String Function TM_BuildGroupStatusJson()
    int owned = 0
    int nearby = 0
    int on_duty = 0
    int restrained = 0
    DOM_SlaveManager mgr = GetSlaveManager()
    Actor player = Game.GetPlayer()
    if mgr && mgr.actorAliases
        int n = mgr.GetMaxActorCount()
        int i = 0
        while i < n
            DOM_Actor slave = mgr.actorAliases[i] as DOM_Actor
            Actor akRef = None
            if slave
                akRef = slave.GetActorRef()
            endif
            if akRef && akRef != player
                owned += 1
                if akRef.Is3DLoaded()
                    nearby += 1
                endif
                if slave.GetOnDutyTitle() != ""
                    on_duty += 1
                endif
                if slave.is_restrained || slave.is_jailed || slave.is_bounded
                    restrained += 1
                endif
            endif
            i += 1
        endwhile
    endif

    int root = JMap.object()
    JMap.setStr(root, "panel", "actor_detail")
    JMap.setStr(root, "id", "status")
    JMap.setStr(root, "label", "All Slaves")
    JMap.setStr(root, "plugin", "SkyrimNet_DOM.esp")
    JMap.setStr(root, "questFormId", "0x800")
    JMap.setStr(root, "scriptName", "SkyrimNet_DOM_Menu")
    JMap.setStr(root, "applyFunction", "TM_StatusApply")
    int fields = JArray.object()
    JMap.setObj(root, "fields", fields)
    AddField(fields, "owned", "Owned", owned as String)
    AddField(fields, "nearby", "Nearby", nearby as String)
    AddField(fields, "on_duty", "On duty", on_duty as String)
    AddField(fields, "restrained", "Restrained", restrained as String)
    int controls = JArray.object()
    JMap.setObj(root, "controls", controls)
    AddButton(controls, "respectful", "Respectful", "1")
    AddButton(controls, "silent", "Silent", "1")
    AddButton(controls, "fight", "Fight for me", "1")
    AddButton(controls, "orgasm", "Free orgasm", "1")
    AddButton(controls, "noorgasm", "No orgasm", "1")
    int options = JArray.object()
    JArray.addObj(options, SelectOption("maid", "maid"))
    JArray.addObj(options, SelectOption("work:1", "mine"))
    JArray.addObj(options, SelectOption("work:2", "cut wood"))
    JArray.addObj(options, SelectOption("work:3", "cook"))
    JArray.addObj(options, SelectOption("work:4", "forage"))
    JArray.addObj(options, SelectOption("work:5", "harvest"))
    JArray.addObj(options, SelectOption("work:6", "create"))
    JArray.addObj(options, SelectOption("jail:1", "jail standstill"))
    JArray.addObj(options, SelectOption("jail:2", "jail wait"))
    JArray.addObj(options, SelectOption("jail:3", "jail tied"))
    JArray.addObj(options, SelectOption("jail:4", "jail cuffs back"))
    JArray.addObj(options, SelectOption("jail:5", "jail cuffs front"))
    JArray.addObj(options, SelectOption("jail:6", "jail cuffs crossed"))
    JArray.addObj(options, SelectOption("jail:7", "jail cuffed"))
    AddSelect(controls, "task", "Task", "", options)
    String json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(root)
    JValue.release(root)
    return json
EndFunction

String Function TM_BuildSlaveStatusJson(Actor akActor)
    int root = JMap.object()
    JMap.setStr(root, "panel", "actor_detail")
    JMap.setStr(root, "id", "status")
    JMap.setStr(root, "plugin", "SkyrimNet_DOM.esp")
    JMap.setStr(root, "questFormId", "0x800")
    JMap.setStr(root, "scriptName", "SkyrimNet_DOM_Menu")
    JMap.setStr(root, "applyFunction", "TM_StatusApply")
    int fields = JArray.object()
    JMap.setObj(root, "fields", fields)
    int controls = JArray.object()
    JMap.setObj(root, "controls", controls)

    String name = ""
    if akActor
        name = akActor.GetDisplayName()
    endif
    JMap.setStr(root, "label", name)

    String info = SkyrimNet_DOM_Decorators.Get_Actor_Info(akActor)
    int src = 0
    if info != ""
        src = JValue.objectFromPrototype(info)
    endif

    AddField(fields, "name", "Name", name)
    if src != 0
        AddField(fields, "title", "Title", JMap.getStr(src, "title", ""))
        AddField(fields, "owner", "Owner", JMap.getStr(src, "owner", ""))
        AddField(fields, "faction", "Faction", JMap.getStr(src, "dom_faction", ""))
        AddField(fields, "behaviour", "Standing order", JMap.getStr(src, "behaviour", ""))
        AddField(fields, "mood", "Mood", JMap.getStr(src, "mood_sentence", ""))
        AddField(fields, "obedient", "Obedient", YesNo(JMap.getInt(src, "is_obedient", 0) != 0))
        AddField(fields, "submission", "Submission", NestedIntStr(src, "training_mind", "submission"))
        AddField(fields, "resignation", "Resignation", NestedIntStr(src, "training_mind", "resignation"))
        AddField(fields, "humiliation", "Humiliation", NestedIntStr(src, "training_mind", "humiliation"))
        AddField(fields, "fear", "Fear", NestedIntStr(src, "training_mind", "fear"))
        AddField(fields, "respect", "Respect", NestedIntStr(src, "training_mind", "respect"))
        AddField(fields, "vaginal", "Vaginal", NestedFltStr(src, "training_sex", "vaginal"))
        AddField(fields, "anal", "Anal", NestedFltStr(src, "training_sex", "anal"))
        AddField(fields, "oral", "Oral", NestedFltStr(src, "training_sex", "oral"))
        AddField(fields, "next_punishment", "Next punishment", NestedStr(src, "punishment", "next_reason"))
        AddField(fields, "current_punishment", "Current punishment", NestedStr(src, "punishment", "current_reason_name"))
        AddField(fields, "restrained", "Restrained", YesNo(JMap.getInt(src, "is_restrained", 0) != 0))
        AddField(fields, "bound", "Bound", YesNo(JMap.getInt(src, "is_bound", 0) != 0))
        AddField(fields, "jailed", "Jailed", YesNo(JMap.getInt(src, "is_jailed", 0) != 0))
        AddField(fields, "respectful_order", "Respectful order", YesNo(NestedIntStr(src, "orders", "should_be_respectful") == "1"))
        AddField(fields, "silent_order", "Silent order", YesNo(NestedIntStr(src, "orders", "should_be_silent") == "1"))
        AddField(fields, "no_orgasm", "No orgasm", YesNo(NestedIntStr(src, "orders", "should_be_no_orgasm") == "1"))
        AddField(fields, "arousal", "Arousal", JMap.getFlt(src, "arousal_factor", 0.0) as String)
        AddField(fields, "promise", "Promise", JMap.getStr(src, "promise_oath", ""))
        AddField(fields, "love_desire", "Desire", NestedFltStr(src, "love", "desire"))
        AddField(fields, "loyal_devotion", "Devotion", NestedFltStr(src, "loyal", "devotion"))
    endif

    DOM_API api = GetApi()
    DOM_Actor slave = None
    if api && akActor
        slave = api.GetDOMActor(akActor)
    endif
    AddField(fields, "trainer", "Trainer", TrainerLabel(slave))
    AddField(fields, "duty", "Duty", DutyLabel(slave))

    DOM_Core core = GetCore()
    if core && akActor
        AddField(fields, "stats", "Stats", core.NPCStatsMessage(akActor))
        AddField(fields, "mood_long", "Mood text", core.NPCMoodMessage(akActor))
        AddField(fields, "traits", "Traits", core.DOMTraitsMessage(akActor))
        AddField(fields, "feelings", "Feelings", core.NPCFeelingsMessage(akActor))
    endif

    DOM_Mind mind = None
    if slave
        mind = slave.mind
    endif
    Bool isSlave = false
    if src != 0
        isSlave = JMap.getInt(src, "is_slave", 0) != 0
    endif
    if isSlave && mind
        AddToggle(controls, "respectful", "Respectful", mind.should_be_respectful)
        AddToggle(controls, "silent", "Silent", mind.should_be_silent)
        AddToggle(controls, "fight", "Fight for me", mind.should_fight_for_player)
        AddToggle(controls, "orgasm", "Orgasm allowed", !mind.should_be_noorgasm)

        int options = JArray.object()
        JArray.addObj(options, SelectOption("maid", "maid"))
        JArray.addObj(options, SelectOption("work:1", "mine"))
        JArray.addObj(options, SelectOption("work:2", "cut wood"))
        JArray.addObj(options, SelectOption("work:3", "cook"))
        JArray.addObj(options, SelectOption("work:4", "forage"))
        JArray.addObj(options, SelectOption("work:5", "harvest"))
        JArray.addObj(options, SelectOption("work:6", "create"))
        JArray.addObj(options, SelectOption("jail:1", "jail standstill"))
        JArray.addObj(options, SelectOption("jail:2", "jail wait"))
        JArray.addObj(options, SelectOption("jail:3", "jail tied"))
        JArray.addObj(options, SelectOption("jail:4", "jail cuffs back"))
        JArray.addObj(options, SelectOption("jail:5", "jail cuffs front"))
        JArray.addObj(options, SelectOption("jail:6", "jail cuffs crossed"))
        JArray.addObj(options, SelectOption("jail:7", "jail cuffed"))
        AddSelect(controls, "task", "Task", "", options)
    endif

    String json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(root)
    JValue.release(root)
    if src != 0
        JValue.release(src)
    endif
    return json
EndFunction

String Function TM_BuildSlavesTableJson()
    int root = JMap.object()
    JMap.setStr(root, "panel", "data_table")
    JMap.setStr(root, "id", "slaves")
    JMap.setStr(root, "label", "Slaves")
    int columns = JArray.object()
    JMap.setObj(root, "columns", columns)
    AddField(columns, "name", "Name", "")
    AddField(columns, "trainer", "Trainer", "")
    AddField(columns, "order", "Standing order", "")
    AddField(columns, "duty", "Duty", "")
    AddField(columns, "respectful", "Respectful", "")
    AddField(columns, "silent", "Silent", "")
    AddField(columns, "fight", "Fight", "")
    AddField(columns, "orgasm", "Orgasm", "")
    AddField(columns, "restrained", "Restrained/jailed", "")
    AddField(columns, "punishment", "Next punishment", "")

    int rows = JArray.object()
    JMap.setObj(root, "rows", rows)
    Bool truncated = false
    int added = 0
    DOM_SlaveManager mgr = GetSlaveManager()
    DOM_Core core = GetCore()
    Actor player = Game.GetPlayer()
    if mgr && mgr.actorAliases
        int n = mgr.GetMaxActorCount()
        int i = 0
        while i < n
            DOM_Actor slave = mgr.actorAliases[i] as DOM_Actor
            Actor akRef = None
            if slave
                akRef = slave.GetActorRef()
            endif
            if akRef && akRef != player
                if added >= SLAVES_ROW_CAP
                    truncated = true
                else
                    DOM_Mind mind = slave.mind
                    int row = JMap.object()
                    JMap.setInt(row, "formId", akRef.GetFormID())
                    int cells = JArray.object()
                    JMap.setObj(row, "cells", cells)
                    JArray.addStr(cells, akRef.GetDisplayName())
                    JArray.addStr(cells, TrainerLabel(slave))
                    JArray.addStr(cells, slave.GetBehaviourTitle())
                    JArray.addStr(cells, DutyLabel(slave))
                    if mind
                        JArray.addStr(cells, OnOff(mind.should_be_respectful))
                        JArray.addStr(cells, OnOff(mind.should_be_silent))
                        JArray.addStr(cells, OnOff(mind.should_fight_for_player))
                        JArray.addStr(cells, OnOff(!mind.should_be_noorgasm))
                    else
                        JArray.addStr(cells, "")
                        JArray.addStr(cells, "")
                        JArray.addStr(cells, "")
                        JArray.addStr(cells, "")
                    endif
                    JArray.addStr(cells, RestrainedLabel(slave))
                    JArray.addStr(cells, PunishmentLabel(slave, core))
                    JArray.addObj(rows, row)
                    added += 1
                endif
            endif
            i += 1
        endwhile
    endif
    JMap.setInt(root, "truncated", truncated as Int)

    String json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(root)
    JValue.release(root)
    return json
EndFunction

Function TM_StatusApply(Actor speaker, Actor target, String control, String value)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_StatusApply", "d_keys is None")
        return
    endif
    Bool group = IsAllSlaves()
    if !group && !target
        target = FocusActor()
    endif
    if group
        TM_StatusApplyGroup(speaker, keys, control, value)
        TM_StatusPanelOpen()
        return
    endif
    if !target
        Trace("TM_StatusApply", "no target")
        return
    endif
    if IsFleeingActor(target)
        Trace("TM_StatusApply", "fleeing")
        return
    endif
    Bool wantOn = value == "1" || value == "true" || value == "on"
    DOM_Actor slave = SlaveOf(target)
    DOM_Mind mind = None
    if slave
        mind = slave.mind
    endif

    String orderDesc = control
    String kind = control
    if control == "respectful"
        orderDesc = "be respectful"
    elseif control == "silent"
        orderDesc = "be silent"
    elseif control == "fight"
        orderDesc = "fight for me"
    elseif control == "orgasm"
        orderDesc = "set orgasm status"
    elseif control == "noorgasm"
        kind = "orgasm"
        orderDesc = "deny orgasm"
    elseif control == "task"
        if value == "maid"
            kind = "maid"
            orderDesc = "clean the mess"
        elseif value == "jail" || StringUtil.Find(value, "jail:") == 0
            kind = "jail"
            orderDesc = "go to jail"
        elseif StringUtil.Find(value, "work:") == 0
            kind = "work"
            orderDesc = "work"
        else
            kind = ""
        endif
    else
        Trace("TM_StatusApply", "unknown control "+control)
        TM_StatusPanelOpen()
        return
    endif
    Int gate = GateOrder(speaker, target, kind, orderDesc)
    if gate == 0
        TM_StatusPanelOpen()
        return
    endif
    if control == "respectful"
        if mind && mind.should_be_respectful != wantOn
            keys.DOMDoBeRespectful(target)
        endif
    elseif control == "silent"
        if mind && mind.should_be_silent != wantOn
            keys.DOMDoBeSilent(target)
        endif
    elseif control == "fight"
        if mind && mind.should_fight_for_player != wantOn
            keys.DOMDoFightForMe(target)
        endif
    elseif control == "orgasm"
        Bool deny = !wantOn
        if mind && mind.should_be_noorgasm != deny
            keys.DOMDoSetOrgasmStatus(target)
        endif
    elseif control == "noorgasm"
        if mind && !mind.should_be_noorgasm
            keys.DOMDoSetOrgasmStatus(target)
        endif
    elseif control == "task"
        if value == "maid"
            keys.DOMDoCleanTheMess(target)
        elseif value == "jail"
            if slave
                slave.EnterJailTravel(1)
            endif
        elseif StringUtil.Find(value, "jail:") == 0
            int mode = StringUtil.Substring(value, 5) as Int
            if slave && mode > 0
                slave.EnterJailTravel(mode)
            endif
        elseif StringUtil.Find(value, "work:") == 0
            int workType = StringUtil.Substring(value, 5) as Int
            if workType > 0
                keys.DOMDoWork(target, workType)
            endif
        endif
    endif
    FinishOrder(speaker, target, orderDesc, gate)
    TM_StatusPanelOpen()
EndFunction

Function TM_StatusApplyGroup(Actor speaker, DOM_Keys keys, String control, String value)
    String orderDesc = control
    String kind = control
    String eventName = ""
    Bool slavers = false
    String type = ""
    if control == "respectful"
        eventName = "BeRespectful"
        orderDesc = "be respectful"
    elseif control == "silent"
        eventName = "BeSilent"
        orderDesc = "be silent"
    elseif control == "fight"
        eventName = "FightForMe"
        slavers = true
        orderDesc = "fight for me"
    elseif control == "orgasm"
        eventName = "FreeOrgasm"
        orderDesc = "have free orgasm"
    elseif control == "noorgasm"
        eventName = "NoOrgasm"
        kind = "orgasm"
        orderDesc = "deny orgasm"
    elseif control == "task"
        if value == "maid"
            kind = "maid"
            orderDesc = "clean the mess"
            TM_MaidAllGated(speaker, keys)
            return
        elseif value == "jail" || StringUtil.Find(value, "jail:") == 0
            int mode = 1
            if StringUtil.Find(value, "jail:") == 0
                mode = StringUtil.Substring(value, 5) as Int
            endif
            if mode < 1
                mode = 1
            endif
            TM_JailAllGated(speaker, mode)
            return
        elseif StringUtil.Find(value, "work:") == 0
            int workType = StringUtil.Substring(value, 5) as Int
            eventName = "Work"
            type = workType as String
            kind = "work"
            orderDesc = "work"
        else
            Trace("TM_StatusApplyGroup", "unknown task "+value)
            return
        endif
    else
        Trace("TM_StatusApplyGroup", "unknown control "+control)
        return
    endif
    GateOrderGroup(speaker, keys, kind, orderDesc, eventName, type, slavers)
EndFunction

Function TM_MaidAll(DOM_Keys keys)
    TM_MaidAllGated(None, keys)
EndFunction

Function TM_MaidAllGated(Actor speaker, DOM_Keys keys)
    DOM_SlaveManager mgr = GetSlaveManager()
    Actor player = Game.GetPlayer()
    if !mgr || !mgr.actorAliases
        return
    endif
    int n = mgr.GetMaxActorCount()
    int i = 0
    while i < n
        DOM_Actor slave = mgr.actorAliases[i] as DOM_Actor
        Actor akRef = None
        if slave
            akRef = slave.GetActorRef()
        endif
        if akRef && akRef != player && !IsFleeingActor(akRef)
            Int r = -1
            if speaker
                r = GateOrder(speaker, akRef, "maid", "clean the mess")
            endif
            if r != 0
                keys.DOMDoCleanTheMess(akRef)
                if speaker
                    FinishOrder(speaker, akRef, "clean the mess", r)
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

Function TM_JailAll(int mode)
    TM_JailAllGated(None, mode)
EndFunction

Function TM_JailAllGated(Actor speaker, int mode)
    DOM_SlaveManager mgr = GetSlaveManager()
    Actor player = Game.GetPlayer()
    if !mgr || !mgr.actorAliases
        return
    endif
    int n = mgr.GetMaxActorCount()
    int i = 0
    while i < n
        DOM_Actor slave = mgr.actorAliases[i] as DOM_Actor
        Actor akRef = None
        if slave
            akRef = slave.GetActorRef()
        endif
        if slave && akRef && akRef != player && !IsFleeingActor(akRef)
            Int r = -1
            if speaker
                r = GateOrder(speaker, akRef, "jail", "go to jail")
            endif
            if r != 0
                slave.EnterJailTravel(mode)
                if speaker
                    FinishOrder(speaker, akRef, "go to jail", r)
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

Function TM_DoOrder(Actor speaker, Actor target, String eventName, String type, String flag)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoOrder", "d_keys is None")
        return
    endif
    Bool group = IsAllSlaves() || !target || flag == "slaves" || flag == "slavers" || flag == "bags" || flag == "all"
    if group
        if flag == "bags"
            keys.DOMAllOrderBags(eventName, type, false)
            OrderNarration(speaker, None, eventName)
            return
        endif
        Bool slavers = flag == "slavers"
        String kind = OrderEventKind(eventName)
        String actionDesc = eventName
        GateOrderGroup(speaker, keys, kind, actionDesc, eventName, type, slavers)
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    Bool theFlag = flag == "1" || flag == "true"
    if eventName == "Promise"
        SpeakAsPlayer(speaker, target, SpeakerName(speaker)+" promises "+TargetName(target)+" "+type+".")
        keys.DOMDoActionActor(target, eventName, type, theFlag)
        return
    endif
    String kind = OrderEventKind(eventName)
    Int gate = -1
    if kind != ""
        gate = GateOrder(speaker, target, kind, eventName)
        if gate == 0
            return
        endif
    endif
    keys.DOMDoActionActor(target, eventName, type, theFlag)
    if kind != ""
        FinishOrder(speaker, target, eventName, gate)
    else
        OrderNarration(speaker, target, eventName)
    endif
EndFunction

Function TM_DoNamed(Actor speaker, Actor target, String fn, String type)
    String tgt = "None"
    if target
        tgt = target.GetDisplayName()
    endif
    Trace("TM_DoNamed", "fn="+fn+" type="+type+" target="+tgt)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoNamed", "d_keys is None")
        return
    endif
    Bool group = type == "all" || IsAllSlaves() || !target
    if group
        TM_DoNamedGroup(speaker, keys, fn)
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Actor slave = SlaveOf(target)
    String kind = NamedOrderKind(fn)
    String orderDesc = fn
    if fn == "inventory"
        orderDesc = "open inventory"
    elseif fn == "follow"
        TM_DoFollow(speaker, target, "start", "")
        return
    elseif fn == "stand"
        orderDesc = "stand still"
    elseif fn == "wait"
        orderDesc = "wait here"
    elseif fn == "favor"
        orderDesc = "do a favor"
    elseif fn == "bag"
        orderDesc = "get in the bag"
    elseif fn == "display"
        orderDesc = "display"
    elseif fn == "kneel"
        orderDesc = "kneel"
    elseif fn == "salute"
        orderDesc = "salute"
    elseif fn == "attention"
        orderDesc = "stand at attention"
    elseif fn == "naked"
        orderDesc = "be naked"
    elseif fn == "drink"
        orderDesc = "drink"
    elseif fn == "shower"
        orderDesc = "shower"
    elseif fn == "bath_me"
        orderDesc = "bathe me"
    elseif fn == "bath_you"
        orderDesc = "bathe"
    elseif fn == "look"
        orderDesc = "look at me"
    elseif fn == "turn"
        orderDesc = "turn around"
    elseif fn == "come"
        orderDesc = "come here"
    elseif fn == "follow_actor"
        orderDesc = "follow someone"
    elseif fn == "noweapons"
        orderDesc = "hold no weapons"
    elseif fn == "weapons"
        orderDesc = "hold weapons"
    elseif fn == "noarmor"
        orderDesc = "wear no armor"
    elseif fn == "armor"
        orderDesc = "wear armor"
    endif

    Int gate = -1
    if kind != ""
        gate = GateOrder(speaker, target, kind, orderDesc)
        if gate == 0
            return
        endif
    endif

    if fn == "inventory"
        keys.DOMDoOpenInventory(target)
        orderDesc = "open inventory"
    elseif fn == "stand"
        keys.DOMDoStandStill(target)
    elseif fn == "wait"
        keys.DOMDoWaitSandbox(target)
    elseif fn == "favor"
        keys.DOMDoFavor(target)
    elseif fn == "bag"
        keys.DOMDoPutInBag(target)
    elseif fn == "display"
        keys.DOMDoDisplay(target)
    elseif fn == "praise"
        keys.DOMDoPraise(target)
        orderDesc = "accept praise"
    elseif fn == "scold"
        keys.DOMDoScold(target)
        orderDesc = "be scolded"
    elseif fn == "flatter"
        SpeakAsPlayer(speaker, target, SpeakerName(speaker)+" flatters "+TargetName(target)+": "+type+".")
        keys.DOMDoFlatter(target, type)
        return
    elseif fn == "insult"
        SpeakAsPlayer(speaker, target, SpeakerName(speaker)+" insults "+TargetName(target)+": "+type+".")
        keys.DOMDoInsult(target, type)
        return
    elseif fn == "kneel"
        keys.DOMDoKneel(target)
    elseif fn == "salute"
        keys.DOMDoSalute(target)
    elseif fn == "attention"
        keys.DOMDoAttention(target)
    elseif fn == "strip"
        keys.DOMDoStrip(target)
        orderDesc = "strip"
    elseif fn == "stripall"
        keys.DOMDoStripAll(target)
        orderDesc = "strip everything"
    elseif fn == "naked"
        keys.DOMDoBeNaked(target)
    elseif fn == "inspect"
        String grabType = type
        if grabType == ""
            grabType = "Front"
        endif
        keys.DOMDoGrab(target, grabType)
        orderDesc = "be inspected"
    elseif fn == "pose"
        TM_DoPose(speaker, target, slave, type)
        return
    elseif fn == "threaten"
        SpeakAsPlayer(speaker, target, SpeakerName(speaker)+" threatens "+TargetName(target)+" about "+type+".")
        if slave
            slave.StartThreatening(speaker, type)
        endif
        return
    elseif fn == "comfort"
        SpeakAsPlayer(speaker, target, SpeakerName(speaker)+" comforts "+TargetName(target)+" about "+type+".")
        if slave
            slave.StartComfortingWith(speaker, type)
        else
            keys.DOMDoNPCPlayerHug(target)
        endif
        return
    elseif fn == "kiss"
        if type == "Vampire"
            keys.DOMDoVampireKiss(target)
            orderDesc = "receive a vampire kiss"
        else
            keys.DOMDoKiss(target, type)
            orderDesc = "be kissed"
        endif
    elseif fn == "drink"
        keys.DOMDoDrink(target, type)
    elseif fn == "shower"
        if slave
            slave.DoShower(speaker)
        else
            keys.DOMDoNPCShower(target)
        endif
    elseif fn == "bath_me"
        if slave
            slave.DoBathMaster(speaker)
        else
            keys.DOMDoNPCBathMe(target, speaker)
        endif
    elseif fn == "bath_you"
        if slave
            slave.DoBathMe(speaker)
        else
            keys.DOMDoNPCBathMe(speaker, target)
        endif
    elseif fn == "look"
        if slave
            slave.Interact_LookAtMe(speaker)
        endif
    elseif fn == "turn"
        if slave
            slave.Interact_TurnAround(speaker)
        endif
    elseif fn == "come"
        if slave
            slave.Interact_ComeHere(speaker)
        endif
    elseif fn == "follow_actor"
        Actor other = ActorFromId(type)
        if slave && other
            slave.EnterFollowTarget(other)
        endif
    elseif fn == "mark"
        if slave
            if slave.HasMark()
                slave.Interact_Unmark()
                orderDesc = "remove mark"
            else
                slave.Interact_Mark(speaker)
                orderDesc = "be marked"
            endif
        endif
    elseif fn == "brand"
        if slave
            if slave.HasBrand()
                slave.Interact_unbrand()
                orderDesc = "remove brand"
            else
                slave.Interact_Brand(speaker)
                orderDesc = "be branded"
            endif
        endif
    elseif fn == "rip"
        keys.DOMDoRipOff(target)
        orderDesc = "have clothes ripped off"
    elseif fn == "ripall"
        if slave
            slave.Interact_UndressAll(speaker)
        else
            keys.DOMDoRipOff(target)
        endif
        orderDesc = "have everything ripped off"
    elseif fn == "equip"
        if slave
            slave.SendOrderEquipInventory(true)
        endif
        orderDesc = "re-equip inventory"
    elseif fn == "noweapons"
        if slave
            slave.HoldNoWeapons()
        endif
    elseif fn == "weapons"
        if slave
            slave.HoldWeapons(speaker)
        endif
    elseif fn == "noarmor"
        if slave
            slave.WearNoArmor()
        endif
    elseif fn == "armor"
        if slave
            slave.WearArmor(speaker)
        endif
    elseif fn == "feed"
        keys.DOMDoVampireKiss(target)
        orderDesc = "feed"
    else
        Trace("TM_DoNamed", "unknown fn "+fn)
        return
    endif
    if kind != ""
        FinishOrder(speaker, target, orderDesc, gate)
    else
        OrderNarration(speaker, target, orderDesc)
    endif
EndFunction

Function TM_DoNamedGroup(Actor speaker, DOM_Keys keys, String fn)
    String order = fn
    Bool slavers = false
    if fn == "follow"
        order = "Follow"
        slavers = true
    elseif fn == "stand"
        order = "StandStill"
        slavers = true
    elseif fn == "wait"
        order = "WaitHere"
        slavers = true
    elseif fn == "praise"
        order = "Praise"
        slavers = true
    elseif fn == "scold"
        order = "Scold"
    elseif fn == "insult"
        order = "Insult"
    elseif fn == "flatter"
        order = "Flatter"
    elseif fn == "threaten"
        order = "Threaten"
    elseif fn == "display" || fn == "pose"
        order = "Display"
    elseif fn == "attention"
        order = "Attention"
    elseif fn == "kneel"
        order = "Kneel"
    elseif fn == "salute"
        order = "Salute"
    elseif fn == "masturbate"
        order = "Masturbate"
    elseif fn == "naked"
        order = "BeNaked"
    elseif fn == "clothed"
        order = "DontBeNaked"
    elseif fn == "strip"
        order = "Strip"
    elseif fn == "stripall"
        order = "StripAll"
    elseif fn == "equip"
        order = "EquipInventoryForced"
        slavers = true
    elseif fn == "noweapons"
        order = "StripWeapons"
    elseif fn == "noarmor"
        order = "StripArmor"
    endif
    if slavers
        String slaverKind = OrderEventKind(order)
        if fn == "praise" || fn == "equip"
            slaverKind = ""
        endif
        GateOrderGroup(speaker, keys, slaverKind, order, order, "", true)
        return
    endif
    String kind = NamedOrderKind(fn)
    if kind == ""
        if fn == "display" || fn == "pose"
            kind = "display"
        elseif fn == "attention"
            kind = "attention"
        elseif fn == "kneel"
            kind = "kneel"
        elseif fn == "salute"
            kind = "salute"
        elseif fn == "masturbate"
            kind = "masturbate"
        elseif fn == "naked" || fn == "clothed"
            kind = "naked"
        endif
    endif
    if fn == "strip" || fn == "stripall" || fn == "equip" || fn == "praise" || fn == "scold" || fn == "insult" || fn == "flatter" || fn == "threaten" || fn == "noweapons" || fn == "noarmor"
        kind = ""
    endif
    GateOrderGroup(speaker, keys, kind, order, order, "", false)
EndFunction

Function TM_DoPose(Actor speaker, Actor target, DOM_Actor slave, String typ)
    if !slave
        return
    endif
    String orderDesc = typ
    String kind = typ
    if typ == "chair"
        orderDesc = "pose on a chair"
    elseif typ == "light"
        orderDesc = "hold a light"
    elseif typ == "flowers"
        orderDesc = "hold flowers"
    elseif typ == "drinks"
        orderDesc = "serve drinks"
    elseif typ == "cute"
        orderDesc = "pose cute"
    elseif typ == "dance"
        orderDesc = "dance"
    elseif typ == "music"
        orderDesc = "play music"
    elseif typ == "submissive"
        orderDesc = "pose submissive"
    elseif typ == "ass"
        orderDesc = "present ass"
    elseif typ == "breasts"
        orderDesc = "present breasts"
    elseif typ == "pussy"
        orderDesc = "present pussy"
    else
        kind = "display"
        orderDesc = "display"
    endif
    Int gate = GateOrder(speaker, target, kind, orderDesc)
    if gate == 0
        return
    endif
    if typ == "chair"
        slave.DoChair(speaker)
    elseif typ == "light"
        slave.DoLight(speaker)
    elseif typ == "flowers"
        slave.DoFlowers(speaker)
    elseif typ == "drinks"
        slave.DoDrinks(speaker)
    elseif typ == "cute"
        slave.DoCute(speaker)
    elseif typ == "dance"
        slave.DoDance(speaker)
    elseif typ == "music"
        slave.DoMusic(speaker)
    elseif typ == "submissive"
        slave.DoSubmissive(speaker)
    elseif typ == "ass"
        slave.DoAssPresentation(speaker)
    elseif typ == "breasts"
        slave.DoBreastsPresentation(speaker)
    elseif typ == "pussy"
        slave.DoPussyPresentation(speaker)
    else
        DOM_Keys keys = GetKeys()
        if keys
            keys.DOMDoDisplay(target)
        endif
    endif
    FinishOrder(speaker, target, orderDesc, gate)
EndFunction

Function ApplyWalkFour(Actor speaker, DOM_Actor sl_alias, String walk4)
    if !sl_alias || !sl_alias.mind
        return
    endif
    Bool wantFour = walk4 == "1" || walk4 == "on"
    if wantFour
        if !sl_alias.mind.should_walk_on_four
            sl_alias.SetShouldWalkOnFour(speaker)
        endif
    else
        if sl_alias.mind.should_walk_on_four
            sl_alias.UnsetShouldWalkOnFour(speaker)
        endif
    endif
EndFunction

Int Function FollowDistanceMode(String distance)
    if distance == "0" || distance == "tight"
        return 0
    elseif distance == "1" || distance == "close"
        return 1
    elseif distance == "2" || distance == "short" || distance == "near"
        return 2
    elseif distance == "3" || distance == "long"
        return 3
    elseif distance == "4" || distance == "far"
        return 3
    elseif distance == "5" || distance == "very far"
        return 3
    endif
    Int n = distance as Int
    if n < 0
        return 2
    elseif n > 3
        return 3
    endif
    return n
EndFunction

String Function FollowDistanceOrderDesc(Int mode)
    if mode == 0
        return "follow tightly"
    elseif mode == 1
        return "follow closely"
    elseif mode == 2
        return "follow from a short distance"
    endif
    return "follow from afar"
EndFunction

; Order → Follow distance pick (0–3). Does not change walk-on-four.
Function TM_DoFollowDistance(Actor speaker, Actor target, String distance)
    if !target
        Trace("TM_DoFollowDistance", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoFollowDistance", "d_keys is None")
        return
    endif
    Int mode = FollowDistanceMode(distance)
    String orderDesc = FollowDistanceOrderDesc(mode)
    Int gate = GateOrder(speaker, target, "follow", orderDesc)
    if gate == 0
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    if sl_alias
        if sl_alias.behaviour != "follow_player"
            sl_alias.EnterFollowPlayer()
        endif
        sl_alias.SetFollowMode(mode)
    else
        keys.DOMDoFollowMe(target)
    endif
    FinishOrder(speaker, target, orderDesc, gate)
EndFunction

Function TM_DoFollowApply(Actor speaker, Actor target, String distance, String walk4)
    if !target
        Trace("TM_DoFollowApply", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoFollowApply", "d_keys is None")
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    String orderDesc = "follow"
    if walk4 == "1" || walk4 == "on"
        orderDesc = "follow on four"
    endif
    Int gate = GateOrder(speaker, target, "follow", orderDesc)
    if gate == 0
        return
    endif
    if sl_alias
        if sl_alias.behaviour != "follow_player"
            sl_alias.EnterFollowPlayer()
        endif
        sl_alias.SetFollowMode(FollowDistanceMode(distance))
    else
        keys.DOMDoFollowMe(target)
    endif
    ApplyWalkFour(speaker, sl_alias, walk4)
    FinishOrder(speaker, target, orderDesc, gate)
EndFunction

Function TM_DoWalkingApply(Actor speaker, Actor target, String walkType)
    if !target
        Trace("TM_DoWalkingApply", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    Bool crawl = walkType == "four" || walkType == "knees" || walkType == "1" || walkType == "on"
    String orderDesc = "walk"
    if walkType == "four"
        orderDesc = "follow on four"
    elseif walkType == "knees"
        orderDesc = "follow on hands and knees"
    endif
    Int gate = GateOrder(speaker, target, "walk4", orderDesc)
    if gate == 0
        return
    endif
    if crawl
        ApplyWalkFour(speaker, sl_alias, "1")
    else
        ApplyWalkFour(speaker, sl_alias, "0")
    endif
    FinishOrder(speaker, target, orderDesc, gate)
EndFunction

Function TM_DoStandApply(Actor speaker, Actor target, String walk4)
    if !target
        Trace("TM_DoStandApply", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoStandApply", "d_keys is None")
        return
    endif
    String orderDesc = "stand still"
    if walk4 == "1" || walk4 == "on"
        orderDesc = "stand still on four"
    endif
    Int gate = GateOrder(speaker, target, "stand", orderDesc)
    if gate == 0
        return
    endif
    keys.DOMDoStandStill(target)
    ApplyWalkFour(speaker, SlaveOf(target), walk4)
    FinishOrder(speaker, target, orderDesc, gate)
EndFunction

Function TM_DoFollow(Actor speaker, Actor target, String kind, String type)
    String tgt = "None"
    if target
        tgt = target.GetDisplayName()
    endif
    Trace("TM_DoFollow", "kind="+kind+" type="+type+" target="+tgt)
    if !target
        Trace("TM_DoFollow", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoFollow", "d_keys is None")
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    String orderDesc = kind
    String gateKind = "follow"
    if kind == "start"
        orderDesc = "follow"
    elseif kind == "distance"
        orderDesc = "follow at distance"
    elseif kind == "wait_distance"
        orderDesc = "wait at distance"
        gateKind = "wait"
    elseif kind == "cuff" || kind == "uncuff"
        gateKind = ""
        if kind == "cuff"
            orderDesc = "wear cuffs"
        else
            orderDesc = "remove cuffs"
        endif
    elseif kind == "walk4" || kind == "follow_walk4"
        gateKind = "walk4"
        if type == "1" || type == "on"
            orderDesc = "walk on four"
        else
            orderDesc = "walk standing"
        endif
    else
        Trace("TM_DoFollow", "unknown kind "+kind)
        return
    endif
    Int gate = -1
    if gateKind != ""
        gate = GateOrder(speaker, target, gateKind, orderDesc)
        if gate == 0
            return
        endif
    endif
    Bool startFollow = kind == "distance" || kind == "follow_walk4" || kind == "start"
    if startFollow
        if sl_alias
            if sl_alias.behaviour != "follow_player"
                sl_alias.EnterFollowPlayer()
            endif
        else
            keys.DOMDoFollowMe(target)
        endif
    endif
    if kind == "distance"
        if sl_alias
            sl_alias.SetFollowMode(type as Int)
        endif
    elseif kind == "wait_distance"
        keys.DOMDoWaitSandbox(target)
        if sl_alias
            sl_alias.SetWaitMode(type as Int)
        endif
    elseif kind == "cuff"
        keys.DOMDoWearCuffs(target, type as Int)
    elseif kind == "uncuff"
        keys.DOMDoUnCuff(target)
    elseif kind == "walk4" || kind == "follow_walk4"
        ApplyWalkFour(speaker, sl_alias, type)
    endif
    if gateKind != ""
        FinishOrder(speaker, target, orderDesc, gate)
    else
        OrderNarration(speaker, target, orderDesc)
    endif
EndFunction

Function TM_DoRestrain(Actor speaker, Actor target, String kind, String flag)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoRestrain", "d_keys is None")
        return
    endif
    Bool group = flag == "all" || IsAllSlaves() || !target
    if group
        String ev = "TieUp"
        if kind == "chains"
            ev = "Chain"
        elseif kind == "post"
            ev = "Post"
        elseif kind == "cage"
            ev = "Cage"
        elseif kind == "cross"
            ev = "Cross"
        elseif kind == "pillory"
            ev = "Pillory"
        elseif kind == "wheel"
            ev = "Wheel"
        elseif kind == "untie"
            ev = "Untie"
        endif
        keys.DOMAllOrderSlaves(ev, "", false)
        OrderNarration(speaker, None, ev)
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    int idx = FurnitureIndex(flag)
    String orderDesc = kind
    if kind == "untie"
        keys.DOMDoUntie(target)
        orderDesc = "be untied"
    elseif kind == "tie"
        keys.DOMTiedUpByIndex(target, idx, false, false)
        orderDesc = "be tied"
    elseif kind == "chains"
        keys.DOMChainsByIndex(target, idx, false, false)
        orderDesc = "be chained"
    elseif kind == "post"
        keys.DOMPostByIndex(target, idx, false, false)
        orderDesc = "be put on a post"
    elseif kind == "cage"
        keys.DOMCageByIndex(target, idx, false, false)
        orderDesc = "enter a cage"
    elseif kind == "cross"
        keys.DOMCrossByIndex(target, idx, false, false)
        orderDesc = "be put on a cross"
    elseif kind == "pillory"
        keys.DOMPilloryByIndex(target, idx, false, false)
        orderDesc = "be put in a pillory"
    elseif kind == "wheel"
        keys.DOMWheelByIndex(target, idx, false, false)
        orderDesc = "be put on a wheel"
    elseif kind == "gag"
        Form gag = None
        if keys.DOMZaz
            if flag == "ball"
                gag = keys.DOMZaz.GetGagBall()
            elseif flag == "ring"
                gag = keys.DOMZaz.GetGagRing()
            elseif flag == "log"
                gag = keys.DOMZaz.GetGagLog()
            else
                gag = keys.DOMZaz.GetGagCloth()
            endif
        endif
        keys.DOMDoGag(target, gag)
        orderDesc = "be gagged"
    elseif kind == "plug"
        keys.DOMDoPlug(target, flag == "vaginal")
        orderDesc = "be plugged"
    elseif kind == "blindfold"
        if flag == "remove"
            keys.DOMDoRemoveBlindfold(target)
            orderDesc = "remove blindfold"
        else
            Form bf = None
            int bidx = 1
            if flag == "random"
                bidx = Utility.RandomInt(1, 6)
            else
                bidx = (flag as Int) + 1
            endif
            if keys.DOMZaz
                bf = keys.DOMZaz.GetBlindfold(bidx)
            endif
            keys.DOMDoEquipBlindfold(target, bf)
            orderDesc = "be blindfolded"
        endif
    elseif kind == "cuff"
        keys.DOMDoWearCuffs(target, flag as Int)
        orderDesc = "wear cuffs"
    elseif kind == "uncuff"
        keys.DOMDoUnCuff(target)
        orderDesc = "remove cuffs"
    else
        keys.DOMTiedUpByIndex(target, idx, false, false)
        orderDesc = "be restrained"
    endif
    OrderNarration(speaker, target, orderDesc)
EndFunction

Function TM_DoSex(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoSex", "missing actions or target")
        return
    endif
    act.StartScene_Consensual_Two("have sex", target, speaker, speaker, "", "fucking", "", "")
EndFunction

Function TM_DoRape(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoRape", "missing actions or target")
        return
    endif
    act.StartScene_Nonconsensual_Two("punish", target, speaker, speaker, target, "", "", "punish_pleasure_pain_rape")
EndFunction

Function TM_DoMasturbate(Actor speaker, Actor target, String kind)
    if !target
        Trace("TM_DoMasturbate", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    SkyrimNet_DOM_Actions act = GetActions()
    if !act
        Trace("TM_DoMasturbate", "missing actions")
        return
    endif
    if kind == "stop"
        act.StopScene_Masturbate("", target, speaker, true)
        return
    elseif kind == "harder"
        String orderDesc = "masturbate harder"
        Int gate = GateOrder(speaker, target, "masturbate_harder", orderDesc)
        if gate == 0
            return
        endif
        DOM_Actor slave = SlaveOf(target)
        if slave
            slave.MasturbateHarder(speaker)
        endif
        FinishOrder(speaker, target, orderDesc, gate)
        return
    endif
    act.StartScene_masturbate("", target, speaker, kind)
EndFunction

Function TM_DoPunish(Actor speaker, Actor target, String reason, String type)
    if !target
        Trace("TM_DoPunish", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Actor slave = SlaveOf(target)
    if !slave
        Trace("TM_DoPunish", "no DOM actor")
        return
    endif
    if type == ""
        type = "pain"
    endif
    ; Rape uses TM_PunishRapeRecord + SexLab scene_start (JS); never Anim_Sexlab here.
    if type == "rape"
        Trace("TM_DoPunish", "rape must use TM_PunishRapeRecord path")
        return
    endif
    ; Bare sentinel must never reach StartPunishing (JS opens text panel).
    if reason == "custom" || reason == ""
        reason = "being a bad slave"
    endif
    DOM_Mind mind = slave.mind
    if reason == "no reason"
        ; GetAnyPunishmentReason("no reason") remaps index 0; force index 0.
        if type == "pain" && mind
            mind.StartPunishingByIndex(speaker, 0, type)
        else
            slave.StartPunishing(speaker, reason, type)
            if mind
                mind.whipping_reason = 0
                mind.whipping_reason_name = "no reason"
                mind.current_punishment_reason = 0
                mind.current_punishment_reason_name = "no reason"
            endif
        endif
        OrderNarration(speaker, target, "be punished for no reason")
        return
    endif
    slave.StartPunishing(speaker, reason, type)
    ; Custom free-text: DOM may remap the index; keep the player string on the name fields.
    if mind && reason != "no reason" && reason != "being a bad slave"
        DOM_Core core = GetCore()
        int known = 0
        if core
            known = core.GetJSONPunishmentReasonIndexByName(reason)
        endif
        if known <= 0
            mind.whipping_reason_name = reason
            mind.current_punishment_reason_name = reason
        endif
    endif
    OrderNarration(speaker, target, "be punished for "+reason)
EndFunction

; Mind-only rape punish record (no Interact_Punish / Anim_Sexlab). JS then starts SexLab scene.
Function TM_PunishRapeRecord(Actor speaker, Actor target, String reason)
    if !target
        Trace("TM_PunishRapeRecord", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Actor slave = SlaveOf(target)
    if !slave
        Trace("TM_PunishRapeRecord", "no DOM actor")
        return
    endif
    DOM_Mind mind = slave.mind
    if !mind
        Trace("TM_PunishRapeRecord", "no DOM mind")
        return
    endif
    if reason == "custom" || reason == ""
        reason = "being a bad slave"
    endif
    if reason == "no reason"
        mind.StartPunishingByIndex(speaker, 0, "rape")
        mind.current_punishment_reason = 0
        mind.current_punishment_reason_name = "no reason"
        OrderNarration(speaker, target, "be punished for no reason")
        return
    endif
    mind.StartPunishing(speaker, reason, "rape")
    if reason != "being a bad slave"
        DOM_Core core = GetCore()
        int known = 0
        if core
            known = core.GetJSONPunishmentReasonIndexByName(reason)
        endif
        if known <= 0
            mind.current_punishment_reason_name = reason
            mind.whipping_reason_name = reason
        endif
    endif
    OrderNarration(speaker, target, "be punished for "+reason)
EndFunction

Function TM_DoPraise(Actor speaker, Actor target, String reason, String type)
    if !target
        Trace("TM_DoPraise", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Actor slave = SlaveOf(target)
    if !slave
        Trace("TM_DoPraise", "no DOM actor")
        return
    endif
    if type == ""
        type = "tell"
    endif
    slave.StartPraising(speaker, reason, type)
    OrderNarration(speaker, target, "accept praise for "+reason)
EndFunction

Function AddReasonChoice(int opts, String reason)
    if reason == ""
        return
    endif
    JArray.addObj(opts, FieldOption(reason, reason))
EndFunction

Function TM_PunishPanelOpen(Actor speaker, Actor target)
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_PunishPanelOpen", "no target")
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    DOM_Mind sl_mind = None
    if sl_alias
        sl_mind = sl_alias.mind
    endif
    int reasonOpts = JArray.object()
    int n = 0
    if sl_mind
        n = sl_mind.GetNumberOfNextPunishmentReasons()
    endif
    int i = 0
    while i < n
        AddReasonChoice(reasonOpts, sl_mind.GetNextPunishmentReason(i))
        i += 1
    endwhile
    DOM_Core core = GetCore()
    if core && sl_mind
        if core.cryingPunishmentToggle && sl_mind.IsCrying()
            if !ReasonListed(sl_mind, n, "crying")
                AddReasonChoice(reasonOpts, "crying")
            endif
        endif
        if sl_mind.IsAngry()
            if !ReasonListed(sl_mind, n, "being angry")
                AddReasonChoice(reasonOpts, "being angry")
            endif
        endif
        if (sl_alias.is_behaviour_pose && sl_mind.pose_training < 100.0) || (sl_alias.IsTied() && sl_mind.IsDevoted() && sl_mind.pose_training < 100.0)
            AddReasonChoice(reasonOpts, "posture correction")
        endif
    endif
    if JArray.count(reasonOpts) <= 0
        AddReasonChoice(reasonOpts, "being a bad slave")
    endif
    ; Always available: custom (opens text panel) + no reason (DOM index 0).
    int customOpt = FieldOption("custom", "custom")
    JMap.setInt(customOpt, "opensText", 1)
    JArray.addObj(reasonOpts, customOpt)
    AddReasonChoice(reasonOpts, "no reason")
    int methodOpts = JArray.object()
    int mn = 0
    if core
        mn = core.GetJSONNumberOfPunishmentTypes()
    endif
    i = 0
    while i < mn
        String typ = core.GetJSONPunishmentTypeNameByIndex(i)
        if typ != ""
            JArray.addObj(methodOpts, FieldOption(typ, typ))
        endif
        i += 1
    endwhile
    if JArray.count(methodOpts) <= 0
        JArray.addObj(methodOpts, FieldOption("pain", "pain"))
    endif
    String defReason = JMap.getStr(JArray.getObj(reasonOpts, 0), "val")
    if defReason == "custom"
        defReason = "no reason"
    endif
    String defType = JMap.getStr(JArray.getObj(methodOpts, 0), "val")
    int reasonField = JMap.object()
    JMap.setStr(reasonField, "fieldId", "reason")
    JMap.setStr(reasonField, "caption", "reason")
    JMap.setStr(reasonField, "widget", "select")
    JMap.setObj(reasonField, "choices", reasonOpts)
    int methodField = JMap.object()
    JMap.setStr(methodField, "fieldId", "type")
    JMap.setStr(methodField, "caption", "method")
    JMap.setStr(methodField, "widget", "select")
    JMap.setObj(methodField, "choices", methodOpts)
    int fields = JArray.object()
    JArray.addObj(fields, reasonField)
    JArray.addObj(fields, methodField)
    int defaults = JMap.object()
    JMap.setStr(defaults, "reason", defReason)
    JMap.setStr(defaults, "type", defType)
    int maps = MappingST()
    int md1 = JMap.object()
    JMap.setStr(md1, "type", "dynamic")
    JMap.setStr(md1, "name", "reason")
    JArray.addObj(maps, md1)
    int md2 = JMap.object()
    JMap.setStr(md2, "type", "dynamic")
    JMap.setStr(md2, "name", "type")
    JArray.addObj(maps, md2)
    int root = JMap.object()
    JMap.setStr(root, "panel", "fields")
    JMap.setStr(root, "label", "punish")
    JMap.setStr(root, "source", "dom")
    JMap.setStr(root, "plugin", "SkyrimNet_DOM.esp")
    JMap.setStr(root, "questFormId", "0x800")
    JMap.setStr(root, "scriptName", "SkyrimNet_DOM_Menu")
    JMap.setStr(root, "executionFunctionName", "TM_DoPunish")
    JMap.setInt(root, "closeWebUI", 1)
    JMap.setObj(root, "parameterMapping", maps)
    JMap.setObj(root, "panelFields", fields)
    JMap.setObj(root, "panelDefaults", defaults)
    Trace("TM_PunishPanelOpen", "reasons="+JArray.count(reasonOpts)+" methods="+JArray.count(methodOpts))
    PushCascade(root)
EndFunction

Function TM_ListPunishReasons(Actor speaker, Actor target)
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_ListPunishReasons", "no target")
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    DOM_Mind sl_mind = None
    if sl_alias
        sl_mind = sl_alias.mind
    endif
    int root = JMap.object()
    JMap.setStr(root, "title", "punish reason")
    int options = JArray.object()
    JMap.setObj(root, "options", options)
    int n = 0
    if sl_mind
        n = sl_mind.GetNumberOfNextPunishmentReasons()
    endif
    int i = 0
    while i < n
        String reason = sl_mind.GetNextPunishmentReason(i)
        int opt = ChoicePapyrus(reason, "TM_DoPunish", true)
        ChoiceStatic(opt, "reason", reason)
        JArray.addObj(options, opt)
        i += 1
    endwhile
    DOM_Core core = GetCore()
    if core && sl_mind
        if core.cryingPunishmentToggle && sl_mind.IsCrying()
            if !ReasonListed(sl_mind, n, "crying")
                int opt = ChoicePapyrus("crying", "TM_DoPunish", true)
                ChoiceStatic(opt, "reason", "crying")
                JArray.addObj(options, opt)
            endif
        endif
        if sl_mind.IsAngry()
            if !ReasonListed(sl_mind, n, "being angry")
                int opt = ChoicePapyrus("being angry", "TM_DoPunish", true)
                ChoiceStatic(opt, "reason", "being angry")
                JArray.addObj(options, opt)
            endif
        endif
        if (sl_alias.is_behaviour_pose && sl_mind.pose_training < 100.0) || (sl_alias.IsTied() && sl_mind.IsDevoted() && sl_mind.pose_training < 100.0)
            int opt = ChoicePapyrus("posture correction", "TM_DoPunish", true)
            ChoiceStatic(opt, "reason", "posture correction")
            JArray.addObj(options, opt)
        endif
    endif
    if JArray.count(options) <= 0
        int opt = ChoicePapyrus("being a bad slave", "TM_DoPunish", true)
        ChoiceStatic(opt, "reason", "being a bad slave")
        JArray.addObj(options, opt)
    endif
    PushCascade(root)
EndFunction

Function TM_ListPraiseReasons(Actor speaker, Actor target)
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_ListPraiseReasons", "no target")
        return
    endif
    DOM_Actor sl_alias = SlaveOf(target)
    DOM_Mind sl_mind = None
    if sl_alias
        sl_mind = sl_alias.mind
    endif
    int root = JMap.object()
    JMap.setStr(root, "title", "praise reason")
    int options = JArray.object()
    JMap.setObj(root, "options", options)
    int reasons = PraiseReasonList(sl_mind)
    int i = 0
    while i < JArray.count(reasons)
        String reason = JArray.getStr(reasons, i)
        int opt = ChoicePapyrus(reason, "TM_ListPraiseTypes", false)
        ChoiceStatic(opt, "reason", reason)
        JArray.addObj(options, opt)
        i += 1
    endwhile
    JValue.release(reasons)
    PushCascade(root)
EndFunction

; The praise reason used when none is picked: "being a good slave" (or "being a good slaver").
String Function DefaultPraiseReason(DOM_Mind sl_mind) global
    if sl_mind && !sl_mind.is_slave
        return "being a good slaver"
    endif
    return "being a good slave"
EndFunction

; Praise reasons for a mind (JArray of strings, caller releases): the default (DefaultPraiseReason) first, then
; DOM's queued reasons, then crying (DOM toggle).
int Function PraiseReasonList(DOM_Mind sl_mind)
    int reasons = JValue.retain(JArray.object())
    String fallback = DefaultPraiseReason(sl_mind)
    JArray.addStr(reasons, fallback)
    int n = 0
    if sl_mind
        n = sl_mind.GetNumberOfNextPraiseReasons()
    endif
    int i = 0
    while i < n
        String reason = sl_mind.GetNextPraiseReason(i)
        if reason != fallback
            JArray.addStr(reasons, reason)
        endif
        i += 1
    endwhile
    DOM_Core core = GetCore()
    if core && sl_mind && core.cryingPraiseToggle && sl_mind.IsCrying()
        if !PraiseListed(sl_mind, n, "crying")
            JArray.addStr(reasons, "crying")
        endif
    endif
    return reasons
EndFunction

Function TM_ListPraiseTypes(Actor speaker, Actor target, String reason)
    DOM_Core core = GetCore()
    int n = 0
    if core
        n = core.GetJSONNumberOfPraisingTypes()
    endif
    int root = JMap.object()
    JMap.setStr(root, "title", "praise type")
    int options = JArray.object()
    JMap.setObj(root, "options", options)
    if n <= 1
        int opt = ChoicePapyrus("tell", "TM_DoPraise", true)
        ChoiceStatic(opt, "reason", reason)
        ChoiceStatic(opt, "type", "tell")
        JArray.addObj(options, opt)
        PushCascade(root)
        return
    endif
    int i = 0
    while i < n
        String typ = core.GetJSONPraisingTypeNameByIndex(i)
        if typ == ""
            typ = "tell"
        endif
        int opt = ChoicePapyrus(typ, "TM_DoPraise", true)
        ChoiceStatic(opt, "reason", reason)
        ChoiceStatic(opt, "type", typ)
        JArray.addObj(options, opt)
        i += 1
    endwhile
    PushCascade(root)
EndFunction

; Scene abuse → comfort → pain: mid-scene gesture list (*narrative* TransformDialogue).
Function TM_ListComfortPainActions(Actor speaker, Actor target)
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_ListComfortPainActions", "no target")
        return
    endif
    int root = JMap.object()
    JMap.setStr(root, "title", "comfort by")
    int options = JArray.object()
    JMap.setObj(root, "options", options)
    int     opt = ChoicePapyrus("slap face", "TM_DoComfortByPain", true)
    ChoiceStatic(opt, "painAction", "slap face")
    JArray.addObj(options, opt)
    opt = ChoicePapyrus("slap ass", "TM_DoComfortByPain", true)
    ChoiceStatic(opt, "painAction", "slap ass")
    JArray.addObj(options, opt)
    opt = ChoicePapyrus("twist nipple", "TM_DoComfortByPain", true)
    ChoiceStatic(opt, "painAction", "twist nipple")
    JArray.addObj(options, opt)
    opt = ChoicePapyrus("slap breasts", "TM_DoComfortByPain", true)
    ChoiceStatic(opt, "painAction", "slap breasts")
    JArray.addObj(options, opt)
    int customOpt = ChoicePapyrus("custom", "TM_DoComfortByPain", true)
    ChoiceDynamic(customOpt, "painAction")
    JMap.setInt(customOpt, "opensText", 1)
    JArray.addObj(options, customOpt)
    PushCascade(root)
EndFunction

; Injury Engine torture by the player (SkyrimNet_DOM_Events.StartTortureReason): random, "being a bad slave" and
; "didnt obey" (always: they cover what the LLM missed), the slave's other open reasons, custom, no reason, as a
; scrollable solo list (SkyrimNet_SexLab Choice_Open). The pick names the running punishment (TM_DoTortureReason).
; JSON is built as a string: the JContainers serializer dropped the options array when called from this hit event
; (Choice_Open options=0).
Function OpenTortureReasonList(Actor torturer, Actor slave, String[] reasons)
    String slaveId = slave.GetFormID() as String
    String badSlave = SkyrimNet_DOM_API.REASON_BAD_SLAVE()
    String disobey = SkyrimNet_DOM_API.REASON_DISOBEY()
    String opts = TortureReasonChoice("random", slaveId)
    opts += "," + TortureReasonChoice(badSlave, slaveId)
    opts += "," + TortureReasonChoice(disobey, slaveId)
    int i = 0
    while i < reasons.Length
        if reasons[i] != badSlave && reasons[i] != disobey
            opts += "," + TortureReasonChoice(reasons[i], slaveId)
        endif
        i += 1
    endwhile
    opts += "," + TortureReasonChoice("custom", slaveId)
    opts += "," + TortureReasonChoice("no reason", slaveId)
    String json = "{\"title\":" + SkyrimNet_SexLab_Utilities.JsonQuote("punish " + TargetName(slave) + " for") \
        + ",\"options\":[" + opts + "]}"
    Trace("OpenTortureReasonList", TargetName(slave) + " reasons=" + reasons.Length + " json(" \
        + StringUtil.GetLength(json) + ")=" + StringUtil.Substring(json, 0, 200))
    SkyrimNet_SexLab_WebUI.Choice_Open(json)
EndFunction

; One papyrus option as JSON: speaker (the player) + static reason / slaveId; the list has no focus target.
String Function TortureReasonChoice(String reason, String slaveId)
    return "{\"type\":\"papyrus\",\"label\":" + SkyrimNet_SexLab_Utilities.JsonQuote(reason) \
        + ",\"plugin\":\"SkyrimNet_DOM.esp\",\"questFormId\":\"0x800\",\"scriptName\":\"SkyrimNet_DOM_Menu\"" \
        + ",\"executionFunctionName\":\"TM_DoTortureReason\",\"closeWebUI\":1,\"parameterMapping\":[" \
        + "{\"type\":\"speaker\",\"name\":\"speaker\"}" \
        + ",{\"type\":\"static\",\"name\":\"reason\",\"value\":" + SkyrimNet_SexLab_Utilities.JsonQuote(reason) + "}" \
        + ",{\"type\":\"static\",\"name\":\"slaveId\",\"value\":" + SkyrimNet_SexLab_Utilities.JsonQuote(slaveId) + "}]}"
EndFunction

; custom: UIExtensions text box; empty / cancelled keeps the provisional reason (no event, like Esc).
Function TM_DoTortureReason(Actor speaker, String reason, String slaveId)
    Actor slave = Game.GetFormEx(slaveId as Int) as Actor
    if !slave
        Trace("TM_DoTortureReason", "no slave for id " + slaveId)
        return
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    if reason == "custom"
        UIExtensions.OpenMenu("UITextEntryMenu")
        reason = UIExtensions.GetMenuResultString("UITextEntryMenu")
        Trace("TM_DoTortureReason", "custom: '" + reason + "'")
        if reason == ""
            return
        endif
    elseif reason == "random" || reason == ""
        reason = SkyrimNet_DOM_API.RandomOpenReason(slave)
    endif
    SkyrimNet_DOM_API.ApplyTortureReason(speaker, slave, reason)
EndFunction

; Healing Hands / SexLab Aid by the player (SkyrimNet_DOM_Events.HealSlave, dom.praise.heal_choose_reason): "being a
; good slave" (always), the slave's other praise reasons, custom, as a solo list (SkyrimNet_SexLab Choice_Open). Close
; sends nothing: no praise. JSON is built as a string, like OpenTortureReasonList: the JContainers serializer dropped
; the options array when called from the Aid / heal event (empty list).
Function OpenHealPraiseList(Actor healer, Actor slave)
    DOM_Actor sl_alias = SlaveOf(slave)
    DOM_Mind sl_mind = None
    if sl_alias
        sl_mind = sl_alias.mind
    endif
    String slaveId = slave.GetFormID() as String
    String opts = HealPraiseChoice(DefaultPraiseReason(sl_mind), slaveId, false)
    int count = 0
    if sl_mind
        int reasons = PraiseReasonList(sl_mind)
        count = JArray.count(reasons)
        int i = 1 ; 0 is the default, already listed
        while i < count
            opts += "," + HealPraiseChoice(JArray.getStr(reasons, i), slaveId, false)
            i += 1
        endwhile
        JValue.release(reasons)
    endif
    opts += "," + HealPraiseChoice("custom", slaveId, true)
    String json = "{\"title\":" + SkyrimNet_SexLab_Utilities.JsonQuote("praise " + TargetName(slave) + " for") \
        + ",\"options\":[" + opts + "]}"
    Trace("OpenHealPraiseList", TargetName(slave) + " reasons=" + count + " json(" \
        + StringUtil.GetLength(json) + ")=" + StringUtil.Substring(json, 0, 200))
    SkyrimNet_SexLab_WebUI.Choice_Open(json)
EndFunction

; One papyrus option as JSON: speaker (the player) + static slaveId + reason (static; custom: dynamic text box).
; Mapping order matches TM_DoHealPraise(speaker, slaveId, reason).
String Function HealPraiseChoice(String reason, String slaveId, bool isCustom)
    String reasonMap = "{\"type\":\"static\",\"name\":\"reason\",\"value\":" + SkyrimNet_SexLab_Utilities.JsonQuote(reason) + "}"
    String extra = ""
    if isCustom
        reasonMap = "{\"type\":\"dynamic\",\"name\":\"reason\"}"
        extra = ",\"opensText\":1"
    endif
    return "{\"type\":\"papyrus\",\"label\":" + SkyrimNet_SexLab_Utilities.JsonQuote(reason) + extra \
        + ",\"plugin\":\"SkyrimNet_DOM.esp\",\"questFormId\":\"0x800\",\"scriptName\":\"SkyrimNet_DOM_Menu\"" \
        + ",\"executionFunctionName\":\"TM_DoHealPraise\",\"closeWebUI\":1,\"parameterMapping\":[" \
        + "{\"type\":\"speaker\",\"name\":\"speaker\"}" \
        + ",{\"type\":\"static\",\"name\":\"slaveId\",\"value\":" + SkyrimNet_SexLab_Utilities.JsonQuote(slaveId) + "}" \
        + "," + reasonMap + "]}"
EndFunction

Function TM_DoHealPraise(Actor speaker, String slaveId, String reason)
    Actor slave = Game.GetFormEx(slaveId as Int) as Actor
    DOM_Actor sl_alias = None
    if slave
        sl_alias = SlaveOf(slave)
    endif
    if !sl_alias
        Trace("TM_DoHealPraise", "no slave for id " + slaveId)
        return
    endif
    if reason == "" || reason == "custom"
        reason = DefaultPraiseReason(sl_alias.mind)
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    sl_alias.StartPraising(speaker, reason, "tell")
    Trace("TM_DoHealPraise", TargetName(slave) + " praised for " + reason)
EndFunction

Function TM_DoComfortByPain(Actor speaker, Actor target, String painAction)
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_DoComfortByPain", "missing target")
        return
    endif
    if painAction == ""
        Trace("TM_DoComfortByPain", "empty painAction")
        return
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    String line = "*" + SpeakerName(speaker) + " comforts " + TargetName(target) + " by " + painAction + "*"
    SkyrimNetApi.TransformDialogue(line)
    Obey(speaker, target, line)
    DOM_Actor slave = SlaveOf(target)
    if slave
        slave.StartComfortingWith(speaker, "pain")
    endif
EndFunction

Function TM_DoDress(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoDress", "missing actions or target")
        return
    endif
    act.Dress_Execute(target, speaker)
EndFunction

Function TM_DoTrainer(Actor speaker, Actor target, String kind, String otherId)
    if !target
        Trace("TM_DoTrainer", "missing target")
        return
    endif
    if IsFleeingActor(target)
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoTrainer", "d_keys is None")
        return
    endif
    DOM_Actor trainer = SlaveOf(target)
    Actor other = ActorFromId(otherId)
    DOM_Actor trainee = SlaveOf(other)
    String orderDesc = kind
    if kind == "list"
        keys.DOMDoListTrainees(target)
        orderDesc = "list trainees"
    elseif kind == "camp"
        keys.DOMDoSetCamp(target)
        orderDesc = "set camp"
    elseif kind == "travel"
        keys.DOMDoGoToCamp(target)
        orderDesc = "go to camp"
    elseif kind == "guard"
        keys.DOMDoGuard(target)
        orderDesc = "guard here"
    elseif kind == "gather"
        keys.DOMDoGatherTrainees(target)
        orderDesc = "gather trainees"
    elseif kind == "add"
        if trainee && trainer
            trainee.SetTrainer(trainer)
        endif
        orderDesc = "add a trainee"
    elseif kind == "unload_one"
        if trainee
            trainee.SeparateFromTrainer()
        endif
        orderDesc = "unload a trainee"
    elseif kind == "unload_all"
        keys.DOMDoUnloadTrainees(target)
        orderDesc = "unload all trainees"
    elseif kind == "display"
        keys.DOMDoDisplayTrainees(target)
        orderDesc = "display trainees"
    elseif kind == "tie"
        keys.DOMDoTieupTrainees(target)
        orderDesc = "tie up trainees"
    elseif kind == "chain"
        keys.DOMDoChainTrainees(target)
        orderDesc = "chain trainees"
    elseif kind == "restrain"
        keys.DOMDoRestrainTrainees(target)
        orderDesc = "restrain trainees"
    elseif kind == "masturbate"
        keys.DOMDoMasturbateTrainees(target)
        orderDesc = "have trainees masturbate"
    elseif kind == "punish"
        keys.DOMDoPunishTrainees(target)
        orderDesc = "punish trainees"
    elseif kind == "rape"
        keys.DOMDoRapeTrainees(target)
        orderDesc = "rape trainees"
    elseif kind == "orgy"
        keys.DOMDoOrgyTrainees(target)
        orderDesc = "start an orgy"
    else
        Trace("TM_DoTrainer", "unknown kind "+kind)
        return
    endif
    OrderNarration(speaker, target, orderDesc)
EndFunction

Function TM_ListRestrainVariants(Actor speaker, Actor target, String kind)
    int variantOpts = JArray.object()
    int arr = JValue.readFromFile("Data/SKSE/Plugins/SkyrimNet_DOM/restrains/"+kind+".json")
    int n = 0
    if arr
        n = JArray.count(arr)
    endif
    int i = 0
    if n > 0
        while i < n
            String lab = JArray.getStr(arr, i)
            if lab == ""
                lab = "variant "+(i as String)
            endif
            JArray.addObj(variantOpts, FieldOption(i as String, lab))
            i += 1
        endwhile
    else
        while i < 7
            String lab = "variant "+(i as String)
            JArray.addObj(variantOpts, FieldOption(i as String, lab))
            i += 1
        endwhile
    endif
    JArray.addObj(variantOpts, FieldOption("random", "random"))
    String defFlag = JMap.getStr(JArray.getObj(variantOpts, 0), "val")
    int flagField = JMap.object()
    JMap.setStr(flagField, "fieldId", "flag")
    JMap.setStr(flagField, "caption", kind)
    JMap.setStr(flagField, "widget", "select")
    JMap.setObj(flagField, "choices", variantOpts)
    int fields = JArray.object()
    JArray.addObj(fields, flagField)
    int defaults = JMap.object()
    JMap.setStr(defaults, "flag", defFlag)
    int maps = MappingST()
    int mk = JMap.object()
    JMap.setStr(mk, "type", "static")
    JMap.setStr(mk, "name", "kind")
    JMap.setStr(mk, "value", kind)
    JArray.addObj(maps, mk)
    int md = JMap.object()
    JMap.setStr(md, "type", "dynamic")
    JMap.setStr(md, "name", "flag")
    JArray.addObj(maps, md)
    int root = JMap.object()
    JMap.setStr(root, "panel", "fields")
    JMap.setStr(root, "label", kind)
    JMap.setStr(root, "source", "dom")
    JMap.setStr(root, "plugin", "SkyrimNet_DOM.esp")
    JMap.setStr(root, "questFormId", "0x800")
    JMap.setStr(root, "scriptName", "SkyrimNet_DOM_Menu")
    JMap.setStr(root, "executionFunctionName", "TM_DoRestrain")
    JMap.setInt(root, "closeWebUI", 1)
    JMap.setObj(root, "parameterMapping", maps)
    JMap.setObj(root, "panelFields", fields)
    JMap.setObj(root, "panelDefaults", defaults)
    PushCascade(root)
EndFunction

DOM_BurlapSack Function ResolveSack(Actor target)
    DOM_Actor sl = SlaveOf(target)
    if sl && sl.the_bag_iam_in
        return sl.the_bag_iam_in
    endif
    DOM_Keys keys = GetKeys()
    if keys
        return keys.GetCurrentCrosshairBurlapSack()
    endif
    return None
EndFunction

Bool Function SlaveInBag(Actor target)
    DOM_Actor sl = SlaveOf(target)
    if !sl
        return false
    endif
    if sl.behaviour == "wait_in_bag"
        return true
    endif
    if sl.the_bag_iam_in
        return true
    endif
    return false
EndFunction

Function TM_ListSackOptions(Actor speaker, Actor target)
    if !target
        target = FocusActor()
    endif
    DOM_Actor sl = SlaveOf(target)
    DOM_BurlapSack sack = ResolveSack(target)
    Actor victim = None
    if sack
        victim = sack.GetVictim()
    endif
    int root = JMap.object()
    JMap.setStr(root, "title", "sack")
    int options = JArray.object()
    JMap.setObj(root, "options", options)
    Bool bagged = SlaveInBag(target)
    if !bagged && victim && target && victim == target
        bagged = true
    endif
    if bagged || (sack && victim && !sl)
        int o1 = ChoicePapyrus("open sack", "TM_DoSack", true)
        ChoiceStatic(o1, "kind", "open")
        JArray.addObj(options, o1)
        int o2 = ChoicePapyrus("open and tie-up", "TM_DoSack", true)
        ChoiceStatic(o2, "kind", "tie")
        JArray.addObj(options, o2)
        int o3 = ChoicePapyrus("take sack", "TM_DoSack", true)
        ChoiceStatic(o3, "kind", "take")
        JArray.addObj(options, o3)
    elseif sl
        int o = ChoicePapyrus("put in bag", "TM_DoNamed", true)
        ChoiceStatic(o, "fn", "bag")
        ChoiceStatic(o, "type", "")
        JArray.addObj(options, o)
    elseif sack && victim
        int o1 = ChoicePapyrus("open sack", "TM_DoSack", true)
        ChoiceStatic(o1, "kind", "open")
        JArray.addObj(options, o1)
        int o2 = ChoicePapyrus("open and tie-up", "TM_DoSack", true)
        ChoiceStatic(o2, "kind", "tie")
        JArray.addObj(options, o2)
        int o3 = ChoicePapyrus("take sack", "TM_DoSack", true)
        ChoiceStatic(o3, "kind", "take")
        JArray.addObj(options, o3)
    endif
    if JArray.count(options) <= 0
        int o = ChoicePapyrus("no sack", "TM_DoSack", true)
        ChoiceStatic(o, "kind", "open")
        JArray.addObj(options, o)
    endif
    PushCascade(root)
EndFunction

Function TM_DoSack(Actor speaker, Actor target, String kind)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoSack", "d_keys is None")
        return
    endif
    DOM_BurlapSack sack = ResolveSack(target)
    if !sack
        Trace("TM_DoSack", "no nearby sack")
        return
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    String orderDesc = "open the sack"
    if kind == "tie"
        keys.DOMDoTakeOutOfBag(speaker, sack, true)
        orderDesc = "open the sack and tie"
    elseif kind == "take"
        keys.DOMPickUpBag(speaker, sack)
        orderDesc = "take the sack"
    else
        keys.DOMDoTakeOutOfBag(speaker, sack, false)
    endif
    OrderNarration(speaker, target, orderDesc)
EndFunction
