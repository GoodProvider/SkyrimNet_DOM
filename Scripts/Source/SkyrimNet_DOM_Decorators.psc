Scriptname SkyrimNet_DOM_Decorators
;------------------------------------
; DOM Decorations  
;------------------------------------
Function Trace(String func, String msg, Bool notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Decorations", func, msg, notification)
EndFunction
DOM_Actor Function GetSlave(String func, Actor akActor) global
    return SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Decorations",func+".GetSlave", akActor,false,false)
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

String Function Get_Actor_Info(Actor akActor) global
    ; Create a new JMap object
    Int not_slave_obj = JMap.object()

    ; Populate the base values
    JMap.setInt(not_slave_obj, "loaded", 1) ; 1 represents True
    JMap.setStr(not_slave_obj, "source", "Get_Actor_Info")
    JMap.setInt(not_slave_obj, "is_slave", 0) ; 0 represents False

    ; If you need this as a string representation later:
    String not_slave_json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(not_slave_obj)

    ; Release memory if you aren't retaining this object in a long-term property
    JValue.release(not_slave_obj)

    SkyrimNet_DOM_Events events = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Events
    if events == None
        Trace("Get_DOM_Slave_INfo","events is None")
        return not_slave_json
    endif

    Quest DOM = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    DOM_API api = DOM as DOM_API
    DOM_Core DOM01 = DOM as DOM_Core
    if api == None
        Trace("Get_DOM_Slave_INfo","DOM_API is None")
        return not_slave_json
    endif
    if !api.IsDOMSlave(akActor)
        Trace("Get_Actor_Info", akActor.GetDisplayName()+" is not a slave")
        return not_slave_json
    endif
    DOM_Actor slave = api.GetDOMActor(akActor)
    if slave == None 
        return not_slave_json
    endif 

    DOM_Mind mind = slave.mind
    if !mind
        Trace("Get_Actor_Info", akActor.GetDisplayName()+" mind is None")
        return not_slave_json
    endif

    String owner = Game.GetPlayer().GetDisplayName()
    if mind.actor_owner != None 
        owner = mind.actor_owner.GetDisplayName() 
    endif 

    String behaviour = BehaviourToString(slave.behaviour)
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if main == None
        Trace("Get_Actor_Info", "SkyrimNet_SexLab_Main is None, aborting sexlab checks")
    elseif main.sexLab == None
        Trace("Get_Actor_Info", "sexLab is None, aborting sexlab checks")
    elseif main.sexLab.IsActorActive(akActor) || SkyrimNet_DOM_API.Ostim_IsInOstim(akActor) 
        behaviour = "having a sexual experience." 
    endif 

    Trace("Get_Actor_Info", "factor: "+mind.arousal_factor+" aroused: "+mind.is_aroused_for+" enraptured:"+mind.is_enraptured_for)
    int next_punishment_reason = slave.mind.GetNextPunishmentReasonByIndex()
    String next_punishment_reason_name = DOM01.GetJSONPunishmentReasonNameByIndex(next_punishment_reason,slave.actorSex)

    ; 1. Create the main Actor JSON object
    Int actor_obj = JMap.object()

    ; 2. Add top-level primitive values
    JMap.setInt(actor_obj, "loaded", 1)
    JMap.setStr(actor_obj, "source", "Get_Actor_Info")
    JMap.setInt(actor_obj, "is_slave", 1)
    JMap.setStr(actor_obj, "name", akActor.GetDisplayName()) ; Assuming akActor is your DOM_Actor
    JMap.setStr(actor_obj, "owner", owner) ; Replace with your variable
    JMap.setInt(actor_obj, "is_obedient", mind.isObedient()as Int)
    JMap.setStr(actor_obj, "mood_sentence", events.Mood_to_Sentence(akActor.GetDisplayName(), DOM01.GetMood(akActor)))
    JMap.setInt(actor_obj, "has_tears", slave.hasTears() as Int)
    JMap.setStr(actor_obj, "behaviour", behaviour)

    ; 3. Build and nest the "training_mind" sub-object
    Int training_mind = JMap.object()
    JMap.setObj(actor_obj, "training_mind", training_mind)
        JMap.setInt(training_mind, "submission", mind.submission as Int)
        JMap.setInt(training_mind, "resignation", mind.resignation as Int)
        JMap.setInt(training_mind, "humiliation", mind.humiliation as Int)
        JMap.setInt(training_mind, "fear", mind.fear_training as Int)
        JMap.setInt(training_mind, "respect", mind.respect_training as Int)


    ; 4. Build and nest the "training_sex" sub-object
    Int training_sex = JMap.object()
    JMap.setObj(actor_obj, "training_sex", training_sex)
        JMap.setFlt(training_sex, "vaginal", mind.vaginal_training)
        JMap.setFlt(training_sex, "anal", mind.anal_training)
        JMap.setFlt(training_sex, "oral", mind.oral_training)

    ; 5. Sexual Kinks
    JMap.setStr(actor_obj, "known_fetishes", mind.GetListOfKnownKinks())
    JMap.setStr(actor_obj, "hidden_fetishes", mind.GetListOfHiddenKinks())
    

    ; 6. Arousal 
    JMap.setFlt(actor_obj, "arousal_factor", mind.arousal_factor)
    JMap.setInt(actor_obj, "is_aroused_for", mind.is_aroused_for)
    JMap.setInt(actor_obj, "is_enraptured_for", mind.is_enraptured_for)

    ; 7. Body
    JMap.setFlt(actor_obj, "dirty_level", slave.dirty_level)
    JMap.setFlt(actor_obj, "wet_level", slave.wet_level)
    JMap.setInt(actor_obj, "is_naked", slave.is_naked as Int)

    ; 8. Bondage
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
    JMap.setInt(actor_obj, "has_mark", slave.HasMark() as Int)

    JMap.setInt(actor_obj, "is_in_love", mind.IsInLove() as Int)
    JMap.setInt(actor_obj, "is_devoted", mind.IsDevoted() as Int)
    JMap.setInt(actor_obj, "is_ashamed", mind.IsAshamed() as Int)

    JMap.setInt(actor_obj, "is_restrained", slave.is_restrained as Int)
    JMap.setInt(actor_obj, "is_bound", slave.is_bounded as Int)
    JMap.setInt(actor_obj, "is_jailed", slave.is_jailed as Int)

    int notifications = events.GetNotifications(akActor)
    if notifications < 1 
        notifications = JArray.object()
    endif 
    JMap.setObj(actor_obj, "notifications", notifications) 

    ; 6. Build and nest the "punishment" sub-object
    Int punishment = JMap.object()
    JMap.setObj(actor_obj, "punishment", punishment)
        JMap.setStr(punishment, "next_reason", next_punishment_reason_name)
        JMap.setInt(punishment, "whipping_active", mind.whipping_active as Int)
        JMap.setStr(punishment, "whipping_reason_name", mind.whipping_reason_name)
        JMap.setStr(punishment, "current_reason_name", mind.current_punishment_reason_name)

    ; If passing the data to the UI or SKSE API, you can stringify it:
    String actor_json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(actor_obj)

    ; Important: Clean up the main object (which recursively cleans up nested objects) 
    ; to prevent memory leaks if you aren't saving it to a JContainer file/form.
    JValue.release(actor_obj)

    ;return TraceReturn("Get_Actor_Info", actor_json) 
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
    if slave.has_weapon ; Float, check for nonzero
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
