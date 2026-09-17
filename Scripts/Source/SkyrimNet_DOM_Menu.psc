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
        JArray.addObj(options, SelectOption("jail", "jail"))
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
    if !target
        target = FocusActor()
    endif
    if !target
        Trace("TM_StatusApply", "no target")
        return
    endif
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_StatusApply", "d_keys is None")
        return
    endif
    Bool wantOn = value == "1" || value == "true" || value == "on"
    DOM_API api = GetApi()
    DOM_Actor slave = None
    if api
        slave = api.GetDOMActor(target)
    endif
    DOM_Mind mind = None
    if slave
        mind = slave.mind
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
        ; widget "Orgasm allowed"; DOM flag is should_be_noorgasm
        Bool deny = !wantOn
        if mind && mind.should_be_noorgasm != deny
            keys.DOMDoSetOrgasmStatus(target)
        endif
    elseif control == "task"
        if value == "maid"
            keys.DOMDoCleanTheMess(target)
        elseif value == "jail"
            if slave
                slave.EnterJailTravel(1)
            endif
        elseif StringUtil.Find(value, "work:") == 0
            String num = StringUtil.Substring(value, 5)
            int workType = num as Int
            if workType > 0
                keys.DOMDoWork(target, workType)
            endif
        endif
    else
        Trace("TM_StatusApply", "unknown control "+control)
    endif
    TM_StatusPanelOpen()
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
        elseif flag == "slavers"
            keys.DOMAllOrderSlavesAndSlavers(eventName, type, false)
        else
            keys.DOMAllOrderSlaves(eventName, type, false)
        endif
        return
    endif
    Bool theFlag = flag == "1" || flag == "true"
    keys.DOMDoActionActor(target, eventName, type, theFlag)
    Obey(speaker, target, eventName)
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
        if fn == "follow" || fn == "stand" || fn == "wait" || fn == "praise"
            String order = "Follow"
            if fn == "stand"
                order = "StandStill"
            elseif fn == "wait"
                order = "WaitHere"
            elseif fn == "praise"
                order = "Praise"
            endif
            keys.DOMAllOrderSlavesAndSlavers(order, "", false)
        else
            String order = fn
            if fn == "scold"
                order = "Scold"
            elseif fn == "insult"
                order = "Insult"
            elseif fn == "flatter"
                order = "Flatter"
            elseif fn == "display"
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
            elseif fn == "strip" || fn == "stripall"
                order = "Strip"
            endif
            keys.DOMAllOrderSlaves(order, "", false)
        endif
        return
    endif

    if fn == "inventory"
        keys.DOMDoOpenInventory(target)
    elseif fn == "follow"
        TM_DoFollow(speaker, target, "start", "")
        return
    elseif fn == "stand"
        keys.DOMDoStandStill(target)
    elseif fn == "wait"
        keys.DOMDoWaitSandbox(target)
    elseif fn == "favor"
        keys.DOMDoFavor(target)
    elseif fn == "bag"
        keys.DOMDoPutInBag(target)
    elseif fn == "untie"
        keys.DOMDoUntie(target)
    elseif fn == "display"
        keys.DOMDoDisplay(target)
    elseif fn == "praise"
        keys.DOMDoPraise(target)
    elseif fn == "scold"
        keys.DOMDoScold(target)
    elseif fn == "flatter"
        keys.DOMDoFlatter(target, type)
    elseif fn == "insult"
        keys.DOMDoInsult(target, type)
    elseif fn == "kneel"
        keys.DOMDoKneel(target)
    elseif fn == "salute"
        keys.DOMDoSalute(target)
    elseif fn == "attention"
        keys.DOMDoAttention(target)
    elseif fn == "strip"
        keys.DOMDoStrip(target)
    elseif fn == "stripall"
        keys.DOMDoStripAll(target)
    elseif fn == "naked"
        keys.DOMDoBeNaked(target)
    elseif fn == "inspect"
        String grabType = type
        if grabType == ""
            grabType = "Front"
        endif
        keys.DOMDoGrab(target, grabType)
    else
        Trace("TM_DoNamed", "unknown fn "+fn)
        return
    endif
    Obey(speaker, target, fn)
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
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoFollow", "d_keys is None")
        return
    endif
    DOM_Core core = GetCore()
    DOM_Actor sl_alias = None
    if core
        sl_alias = core.GetActor(target)
    endif
    if sl_alias
        if kind == "distance" || kind == "walk4" || kind == "leash"
            if sl_alias.behaviour != "follow_player"
                sl_alias.EnterFollowPlayer()
            endif
        endif
    elseif kind == "distance" || kind == "walk4" || kind == "leash"
        keys.DOMDoFollowMe(target)
    endif
    if kind == "start"
        ; unused by Follow catalog
    elseif kind == "distance"
        if sl_alias
            sl_alias.SetFollowMode(type as Int)
        endif
    elseif kind == "cuff"
        keys.DOMDoWearCuffs(target, type as Int)
    elseif kind == "uncuff"
        keys.DOMDoUnCuff(target)
    elseif kind == "walk4"
        Bool wantFour = type == "1" || type == "on"
        if sl_alias && sl_alias.mind
            if wantFour
                if !sl_alias.mind.should_walk_on_four
                    sl_alias.SetShouldWalkOnFour(speaker)
                endif
            else
                if sl_alias.mind.should_walk_on_four
                    sl_alias.UnsetShouldWalkOnFour(speaker)
                endif
            endif
        endif
    elseif kind == "leash"
        keys.DOMDoLeash(target, type as Int)
    elseif kind == "unleash"
        keys.DOMDoUnleash(target)
    else
        Trace("TM_DoFollow", "unknown kind "+kind)
        return
    endif
    Obey(speaker, target, kind)
EndFunction

Function TM_DoRestrain(Actor speaker, Actor target, String kind, String flag)
    DOM_Keys keys = GetKeys()
    if !keys
        Trace("TM_DoRestrain", "d_keys is None")
        return
    endif
    Bool group = flag == "all" || IsAllSlaves() || !target
    if group
        keys.DOMAllOrderSlaves("TieUp", "", false)
        return
    endif
    if kind == "untie"
        keys.DOMDoUntie(target)
    elseif kind == "chains"
        keys.DOMChainsByIndex(target, 0, false, false)
    elseif kind == "post"
        keys.DOMPostByIndex(target, 0, false, false)
    elseif kind == "cage"
        keys.DOMCageByIndex(target, 0, false, false)
    else
        keys.DOMTiedUpByIndex(target, 0, false, false)
    endif
    Obey(speaker, target, kind)
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

Function TM_DoMasturbate(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoMasturbate", "missing actions or target")
        return
    endif
    act.StartScene_masturbate("", target, speaker, "")
EndFunction

Function TM_DoPunish(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoPunish", "missing actions or target")
        return
    endif
    act.AddPunishmentReason("didnt obey", target, speaker)
    act.StartScene_Nonconsensual_Two("punish", target, speaker, speaker, target, "", "", "punish_spanking")
EndFunction

Function TM_DoDress(Actor speaker, Actor target)
    SkyrimNet_DOM_Actions act = GetActions()
    if !act || !target
        Trace("TM_DoDress", "missing actions or target")
        return
    endif
    act.Dress_Execute(target, speaker)
EndFunction
