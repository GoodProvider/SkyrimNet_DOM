Scriptname SkyrimNet_DOM_Decorators
;------------------------------------
; DOM Decorations  
;------------------------------------
Function Trace(String func, String msg, Bool notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Decorators", func, msg, notification)
EndFunction
DOM_Actor Function GetSlave(String func, Actor akActor) global
    return SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Decorators",func+".GetSlave", akActor,false,false)
EndFunction
string Function TraceReturn(String func, String msg, Bool Notification = false) global 
    Trace(func, msg, Notification) 
    return msg 
EndFunction 

Function Register_Decorators() global
    int success = SkyrimNetApi.RegisterDecorator("dom_get_actor_info", "SkyrimNet_DOM_Decorators", "Get_Actor_Info")
    if success != 0
        Trace("RegisterDecorator", "failed to register dom_get_actor_info")
    endif 
EndFunction

String Function BehaviourToString(String behavior) global
    int key_value = JValue.readFromFile("Data/SKSE/Plugins/SkyrimNet_DOM/slave_behaviours.json")
    if JMap.hasKey(key_value, behavior)
        return JMap.getStr(key_value, behavior) 
    endif
    return ""
EndFunction

int Function PromiseOathToRank(String oath) global
    if oath == "freedom"
        return 1
    elseif oath == "money"
        return 2
    elseif oath == "to be gentle" || oath == "gentle"
        return 3
    elseif oath == "pain"
        return 4
    elseif oath == "rapture"
        return 5
    elseif oath == "to be sacrificed" || oath == "sacrificed"
        return 6
    endif
    if oath == "" || oath == "nothing"
        return 0
    endif
    return 0
EndFunction

Function FillGearFields(Int actor_obj, DOM_Actor slave) global
    JMap.setInt(actor_obj, "has_tears", slave.hasTears() as Int)
    JMap.setInt(actor_obj, "has_mark", slave.HasMark() as Int)
    JMap.setFlt(actor_obj, "dirty_level", slave.dirty_level)
    JMap.setFlt(actor_obj, "wet_level", slave.wet_level)
    JMap.setInt(actor_obj, "is_naked", slave.is_naked as Int)
    JMap.setInt(actor_obj, "has_mouth_gag", slave.has_mouth_gag as Int)
    JMap.setInt(actor_obj, "has_collar", slave.has_collar as Int)
    JMap.setInt(actor_obj, "has_cuffs_crossed", slave.has_cuffs_crossed as Int)
    JMap.setInt(actor_obj, "has_cuffs_front", slave.has_cuffs_front as Int)
    JMap.setInt(actor_obj, "has_cuffs_boxtied", slave.has_cuffs_boxtied as Int)
    JMap.setInt(actor_obj, "has_cuffs_back", slave.has_cuffs_back as Int)
    JMap.setInt(actor_obj, "has_lingerie", slave.has_lingerie as Int)
    JMap.setInt(actor_obj, "has_cuffs", slave.has_cuffs as Int)
    JMap.setInt(actor_obj, "has_arms_device", slave.has_arms_device as Int)
    JMap.setInt(actor_obj, "has_dwarven_device", slave.has_dwarven_device as Int)
    JMap.setInt(actor_obj, "has_dd_suit", slave.has_dd_suit as Int)
    JMap.setInt(actor_obj, "has_petsuit", slave.has_petsuit as Int)
    JMap.setInt(actor_obj, "has_straitjacket", slave.has_straitjacket as Int)
    JMap.setInt(actor_obj, "has_armbinder", slave.has_armbinder as Int)
    JMap.setInt(actor_obj, "has_yoke", slave.has_yoke as Int)
    JMap.setInt(actor_obj, "has_disablekick", slave.has_disablekick as Int)
    JMap.setInt(actor_obj, "has_plug_anal", slave.has_plug_anal as Int)
    JMap.setInt(actor_obj, "has_plug_vaginal", slave.has_plug_vaginal as Int)
    JMap.setInt(actor_obj, "has_blindfold", slave.has_blindfold as Int)
    JMap.setInt(actor_obj, "has_leash", slave.has_leash as Int)
    JMap.setInt(actor_obj, "has_shame_clothes", slave.has_shame_clothes as Int)
    JMap.setInt(actor_obj, "has_heels", slave.has_heels as Int)
EndFunction

Function FillVirginFields(Int actor_obj, DOM_Mind mind) global
    Int virgin = JMap.object()
    JMap.setObj(actor_obj, "virgin", virgin)
    JMap.setInt(virgin, "vaginal", mind.virgin_status_vaginal)
    JMap.setInt(virgin, "oral", mind.virgin_status_oral)
    JMap.setInt(virgin, "anal", mind.virgin_status_anal)
    JMap.setInt(virgin, "same", mind.virgin_status_same)
    JMap.setInt(virgin, "gangbang", mind.virgin_status_gang)
EndFunction

Function FillSlaverFields(Int actor_obj, DOM_Actor slave, DOM_Mind mind) global
    JMap.setStr(actor_obj, "title", slave.getTitle())
    JMap.setInt(actor_obj, "is_love_interest", mind.is_love_interest as Int)

    String camp = ""
    if slave.CampMarker != None
        camp = slave.CampMarker.GetDisplayName()
    endif
    JMap.setStr(actor_obj, "camp_name", camp)

    int trainee_count = slave.GetTraineeCount()
    JMap.setInt(actor_obj, "trainee_count", trainee_count)
    Int trainee_names = JArray.object()
    JMap.setObj(actor_obj, "trainee_names", trainee_names)
    int i = 0
    while i < trainee_count
        DOM_Actor trainee = slave.GetTrainee(i)
        if trainee != None
            JArray.addStr(trainee_names, trainee.getName())
        endif
        i += 1
    endwhile

    Int skills = JMap.object()
    JMap.setObj(actor_obj, "skills", skills)
    JMap.setFlt(skills, "enforcer", mind.skill_enforcer)
    JMap.setFlt(skills, "persuader", mind.skill_persuader)
    JMap.setFlt(skills, "depraver", mind.skill_depraver)
    JMap.setFlt(skills, "predator", mind.skill_predator)
    JMap.setFlt(skills, "slaver", mind.skill_slaver)
    JMap.setFlt(skills, "deceiver", mind.skill_deceiver)

    Int career = JMap.object()
    JMap.setObj(actor_obj, "career", career)
    JMap.setInt(career, "captured", mind.number_of_capturedslaves)
    JMap.setInt(career, "sold", mind.number_of_soldslaves)
    JMap.setInt(career, "whored", mind.number_of_whoredslaves)
    JMap.setInt(career, "ransomed", mind.number_of_ransomedslaves)
    JMap.setInt(career, "broken", mind.number_of_brokenslaves)
    JMap.setInt(career, "recruited_slavers", mind.number_of_recruitedslavers)
EndFunction

Function FillSlaveFields(Int actor_obj, Actor akActor, DOM_Actor slave, DOM_Mind mind, DOM_Core DOM01) global
    String owner = Game.GetPlayer().GetDisplayName()
    if mind.actor_owner != None
        owner = mind.actor_owner.GetDisplayName()
    endif
    JMap.setStr(actor_obj, "owner", owner)
    JMap.setInt(actor_obj, "is_obedient", mind.isObedient() as Int)
    JMap.setInt(actor_obj, "is_trainer", slave.is_trainer as Int)
    String title = slave.getTitle()
    if title != ""
        JMap.setStr(actor_obj, "title", title)
    endif

    Int training_mind = JMap.object()
    JMap.setObj(actor_obj, "training_mind", training_mind)
    JMap.setInt(training_mind, "submission", mind.submission as Int)
    JMap.setInt(training_mind, "resignation", mind.resignation as Int)
    JMap.setInt(training_mind, "humiliation", mind.humiliation as Int)
    JMap.setInt(training_mind, "fear", mind.fear_training as Int)
    JMap.setInt(training_mind, "respect", mind.respect_training as Int)

    Int training_sex = JMap.object()
    JMap.setObj(actor_obj, "training_sex", training_sex)
    JMap.setFlt(training_sex, "vaginal", mind.vaginal_training)
    JMap.setFlt(training_sex, "anal", mind.anal_training)
    JMap.setFlt(training_sex, "oral", mind.oral_training)

    int next_punishment_reason = mind.GetNextPunishmentReasonByIndex()
    String next_punishment_reason_name = DOM01.GetJSONPunishmentReasonNameByIndex(next_punishment_reason, slave.actorSex)
    Int punishment = JMap.object()
    JMap.setObj(actor_obj, "punishment", punishment)
    JMap.setStr(punishment, "next_reason", next_punishment_reason_name)
    JMap.setInt(punishment, "whipping_active", mind.whipping_active as Int)
    JMap.setStr(punishment, "whipping_reason_name", mind.whipping_reason_name)
    JMap.setStr(punishment, "current_reason_name", mind.current_punishment_reason_name)

    JMap.setInt(actor_obj, "is_in_love", mind.IsInLove() as Int)
    JMap.setInt(actor_obj, "is_devoted", mind.IsDevoted() as Int)
    JMap.setInt(actor_obj, "is_ashamed", mind.IsAshamed() as Int)
    JMap.setInt(actor_obj, "is_restrained", slave.is_restrained as Int)
    JMap.setInt(actor_obj, "is_bound", slave.is_bounded as Int)
    JMap.setInt(actor_obj, "is_jailed", slave.is_jailed as Int)

    Int orders = JMap.object()
    JMap.setObj(actor_obj, "orders", orders)
    JMap.setInt(orders, "should_be_naked", mind.should_be_naked as Int)
    JMap.setInt(orders, "should_wear_armor", mind.should_wear_armor as Int)
    JMap.setInt(orders, "should_hold_weapons", mind.should_hold_weapons as Int)
    JMap.setInt(orders, "should_be_respectful", mind.should_be_respectful as Int)
    JMap.setInt(orders, "should_be_silent", mind.should_be_silent as Int)
    JMap.setInt(orders, "should_be_no_orgasm", mind.should_be_noorgasm as Int)
    JMap.setInt(orders, "should_walk_on_four", mind.should_walk_on_four as Int)

    JMap.setInt(actor_obj, "is_walking_on_four", mind.is_walking_on_four as Int)
    JMap.setInt(actor_obj, "is_respectful", mind.was_respectful as Int)

    int family_history_rank = 0
    if DOM01.DOMActorFamilyHistory != None && akActor.IsInFaction(DOM01.DOMActorFamilyHistory)
        family_history_rank = akActor.GetFactionRank(DOM01.DOMActorFamilyHistory)
    endif
    JMap.setInt(actor_obj, "family_history_rank", family_history_rank)

    String promise_oath = mind.promiseOath
    int promise_rank = PromiseOathToRank(promise_oath)
    if DOM01.DOMPromised != None && akActor.IsInFaction(DOM01.DOMPromised)
        int faction_rank = akActor.GetFactionRank(DOM01.DOMPromised)
        if faction_rank > 0
            promise_rank = faction_rank
        endif
    endif
    JMap.setInt(actor_obj, "promise_rank", promise_rank)
    JMap.setStr(actor_obj, "promise_oath", promise_oath)

    Int experience = JMap.object()
    JMap.setObj(actor_obj, "experience", experience)
    JMap.setInt(experience, "pain", mind.number_of_pain)
    JMap.setInt(experience, "bondage", mind.number_of_bondage)
    JMap.setInt(experience, "shame", mind.number_of_shame)
    JMap.setInt(experience, "rape", mind.number_of_rape)
    JMap.setInt(experience, "sex", mind.number_of_sex)
    JMap.setInt(experience, "sex_with_others", mind.number_of_sexwithothers)
    JMap.setInt(experience, "sex_for_money", mind.number_of_sexformoney)
    JMap.setInt(experience, "orgasm", mind.number_of_orgasm)
    JMap.setInt(experience, "broken", mind.number_of_broken)
    JMap.setInt(experience, "brainwashed", mind.number_of_brainwashed)
    JMap.setInt(experience, "shock", mind.number_of_shock)
    JMap.setInt(experience, "promise", mind.number_of_promise)
    JMap.setInt(experience, "praise", mind.number_of_praise)
    JMap.setInt(experience, "comfort", mind.number_of_comfort)
    JMap.setInt(experience, "insult", mind.number_of_insult)
    JMap.setInt(experience, "threat", mind.number_of_threat)
    JMap.setInt(experience, "toldoff", mind.number_of_toldoff)

    JMap.setInt(actor_obj, "trauma_days", mind.timer_for_broken as Int)

    Int love = JMap.object()
    JMap.setObj(actor_obj, "love", love)
    JMap.setFlt(love, "desire", mind.love_desire)
    JMap.setFlt(love, "fascination", mind.love_fascination)
    JMap.setFlt(love, "admiration", mind.love_admiration)

    Int loyal = JMap.object()
    JMap.setObj(actor_obj, "loyal", loyal)
    JMap.setFlt(loyal, "worship", mind.loyal_worship)
    JMap.setFlt(loyal, "absolution", mind.loyal_absolution)
    JMap.setFlt(loyal, "devotion", mind.loyal_devotion)
EndFunction

String Function Get_Actor_Info(Actor akActor) global
    Int not_dom_obj = JMap.object()
    JMap.setInt(not_dom_obj, "loaded", 0)
    JMap.setStr(not_dom_obj, "source", "Get_Actor_Info")
    JMap.setInt(not_dom_obj, "is_slave", 0)
    JMap.setInt(not_dom_obj, "is_slaver", 0)
    JMap.setStr(not_dom_obj, "dom_faction", "")
    JMap.setInt(not_dom_obj, "history_rank", 0)
    String not_dom_json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(not_dom_obj)
    JValue.release(not_dom_obj)

    if akActor == None
        return not_dom_json
    endif

    SkyrimNet_DOM_Events events = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Events
    if events == None
        Trace("Get_Actor_Info", "events is None")
        return not_dom_json
    endif

    Quest DOM = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    DOM_API api = DOM as DOM_API
    DOM_Core DOM01 = DOM as DOM_Core
    if api == None || DOM01 == None
        Trace("Get_Actor_Info", "DOM_API/DOM_Core is None")
        return not_dom_json
    endif

    DOM_Actor slave = api.GetDOMActor(akActor)
    if slave == None
        Trace("Get_Actor_Info", akActor.GetDisplayName()+" is not a DOMActor")
        return not_dom_json
    endif

    bool is_slave = api.IsDOMSlave(akActor)
    bool is_slaver = api.IsDOMSlaver(akActor)
    String dom_faction = "other"
    if is_slave
        dom_faction = "slave"
    elseif is_slaver
        dom_faction = "slaver"
    endif

    int history_rank = 0
    if DOM01.DOMHistoryFaction != None && akActor.IsInFaction(DOM01.DOMHistoryFaction)
        history_rank = akActor.GetFactionRank(DOM01.DOMHistoryFaction)
    endif

    Int actor_obj = JMap.object()
    JMap.setInt(actor_obj, "loaded", 1)
    JMap.setStr(actor_obj, "source", "Get_Actor_Info")
    JMap.setStr(actor_obj, "name", akActor.GetDisplayName())
    JMap.setInt(actor_obj, "is_slave", is_slave as Int)
    JMap.setInt(actor_obj, "is_slaver", is_slaver as Int)
    JMap.setStr(actor_obj, "dom_faction", dom_faction)
    JMap.setInt(actor_obj, "history_rank", history_rank)

    int notifications = events.GetNotifications(akActor)
    if notifications < 1
        notifications = JArray.object()
    endif
    JMap.setObj(actor_obj, "notifications", notifications)

    JMap.setStr(actor_obj, "mood_sentence", events.mood_to_Sentence(akActor.GetDisplayName(), DOM01.GetMood(akActor)))

    String behaviour = BehaviourToString(slave.behaviour)
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if main != None && main.sexLab != None
        if main.sexLab.IsActorActive(akActor) || SkyrimNet_DOM_API.Ostim_IsInOstim(akActor)
            behaviour = "having a sexual experience."
        endif
    endif
    JMap.setStr(actor_obj, "behaviour", behaviour)

    FillGearFields(actor_obj, slave)

    DOM_Mind mind = slave.mind
    if mind
        JMap.setFlt(actor_obj, "arousal_factor", mind.arousal_factor)
        JMap.setInt(actor_obj, "is_aroused_for", mind.is_aroused_for)
        JMap.setInt(actor_obj, "is_enraptured_for", mind.is_enraptured_for)
        JMap.setStr(actor_obj, "known_fetishes", mind.GetListOfKnownKinks())
        JMap.setStr(actor_obj, "hidden_fetishes", mind.GetListOfHiddenKinks())
        FillVirginFields(actor_obj, mind)

        if is_slaver && !is_slave
            FillSlaverFields(actor_obj, slave, mind)
        endif
        if is_slave
            FillSlaveFields(actor_obj, akActor, slave, mind, DOM01)
        endif
    else
        Trace("Get_Actor_Info", akActor.GetDisplayName()+" mind is None; thin gear/notifications only")
        Int virgin = JMap.object()
        JMap.setObj(actor_obj, "virgin", virgin)
        JMap.setInt(virgin, "vaginal", 0)
        JMap.setInt(virgin, "oral", 0)
        JMap.setInt(virgin, "anal", 0)
        JMap.setInt(virgin, "same", 0)
        JMap.setInt(virgin, "gangbang", 0)
        JMap.setStr(actor_obj, "known_fetishes", "")
        JMap.setStr(actor_obj, "hidden_fetishes", "")
        JMap.setFlt(actor_obj, "arousal_factor", 0.0)
        JMap.setInt(actor_obj, "is_aroused_for", 0)
        JMap.setInt(actor_obj, "is_enraptured_for", 0)
    endif

    String actor_json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(actor_obj)
    JValue.release(actor_obj)
    return actor_json
EndFunction

String function Bool_String(Bool val) global
    if val
        return ":true"
    else
        return ":false"
    endif
endfunction

String function Add_State(DOM_Actor slave) global
    String msg = "" 

    if slave.hasTears()
        msg += " tears from crying,"
    endif 
    if slave.has_mouth_gag
        msg += " mouth is gagged (can not speak, only 'mumble')," 
    endif
    if slave.is_naked
        msg += "  naked,"
    endif 
    if slave.has_collar
        msg += "  collared,"
    endif 
    if slave.has_cuffs_crossed
        msg += " arms in cuffs crossed,"
    endif
    if slave.has_cuffs_front
        msg += " arms in cuffs front,"
    endif
    if slave.has_cuffs_boxtied
        msg += " arms in cuffs boxtied,"
    endif
    if slave.has_cuffs_back
        msg += " arms in cuffs back,"
    endif
    if slave.has_arms_device
        msg += " arms in bondage device,"
    endif
    if slave.has_dwarven_device
        msg += " in dwarven bondge device,"
    endif
    if slave.has_dd_suit
        msg += " in bondage suit,"
    endif
    if slave.has_petsuit
        msg += " in bondage petsuit,"
    endif
    if slave.has_straitjacket
        msg += " in straitjacket,"
    endif
    if slave.has_cuffs
        msg += " arms in cuffs,"
    endif
    if slave.has_armbinder
        msg += " in armbinder,"
    endif
    if slave.has_yoke
        msg += " in prisoner yoke,"
    endif
    if slave.has_disablekick
        msg += " in bondage gear that disablekicks,"
    endif
    if slave.has_device
        msg += " in bondage device,"
    endif
    if slave.has_collar
        msg += " in a collar,"
    endif
    if slave.has_blindfold
        msg += " in a blindfold,"
    endif
    if slave.has_leash
        msg += " is leashed,"
    endif
    if slave.has_plug_anal
        msg += " plug anal in ass,"
    endif
    if slave.has_plug_vaginal
        msg += " plug vaginal in pussy,"
    endif
    if slave.has_weapon_in_inventory
        msg += " has a weapon in inventory,"
    endif
    if slave.has_weapon
        msg += " has a weapon,"
    endif
    if slave.dirty_level > 0.0
        msg += " is dirty,"
    endif
    if slave.wet_level > 0.0
        msg += " is wet,"
    endif
    if slave.has_shame_clothes
        msg += " wearing shameful clothes,"
    endif
    if slave.has_lingerie
        msg += " in lingerie,"
    endif
    if slave.has_heels
        msg += " in heels,"
    endif
    if slave.is_restrained
        msg += " is restrained,"
    endif
    if slave.is_bounded
        msg += " is bounded,"
    endif
    if slave.is_jailed
        msg += " is in jailed,"
    endif
    if slave.is_leashed
        msg += " is leashed,"
    endif
    if slave.has_jewelry > 0.0
        msg += " wearing jewelry,"
    endif
    if slave.has_gold > 0
        msg += " has "+slave.has_gold+" gold,"
    endif

    return msg
endfunction 
