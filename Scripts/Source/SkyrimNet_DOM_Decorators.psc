Scriptname SkyrimNet_DOM_Decorators
;------------------------------------
; DOM Decorations  
;------------------------------------
Function Trace(String func, String msg, Bool notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_Decorations", func, msg, notification)
EndFunction
DOM_Actor Function GetSlave(String func, Actor akActor) global
    return SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Decorations",func+".GetSlave", akActor,false,false)
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
    SkyrimNet_DOM_Events events = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Events
    if events == None
        Trace("Get_DOM_Slave_INfo","events is None")
        return ""
    endif

    Quest DOM = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    DOM_API api = DOM as DOM_API
    DOM_Core DOM01 = DOM as DOM_Core
    if api == None
        Trace("Get_DOM_Slave_INfo","DOM_API is None")
        return ""
    endif
    if !api.IsDOMSlave(akActor)
        Trace("Get_DOM_Slave_Info",akActor.GetDisplayName()+" is not a slave")
        return "{\"loaded\":true,\"source\":\"Get_Actor_Info\",\"is_slave\":false}"
    endif 

    DOM_Actor slave = api.GetDOMActor(akActor)
    DOM_Mind mind = slave.mind

    String owner = Game.GetPlayer().GetDisplayName()
    if mind.actor_owner != None 
        owner = mind.actor_owner.GetDisplayName() 
    endif 

    String behaviour = BehaviourToString(slave.behaviour)
    String is_masturbating = ":false"
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if main.sexLab.IsActorActive(akActor) || SkyrimNet_DOM_Utils.Ostim_IsInOstim(akActor) 
        behaviour = "having a sexual experience." 
    elseif slave.behaviour == "masturbate"
        if !main.sexLab.IsActorActive(akActor) && !SkyrimNet_DOM_Utils.Ostim_IsInOstim(akActor) 
            is_masturbating = ":true"
        endif 
    endif 

    Trace("Get_Actor_Info", "factor: "+mind.arousal_factor+" aroused: "+mind.is_aroused_for+" enraptured:"+mind.is_enraptured_for)
    int next_punishment_reason = slave.mind.GetNextPunishmentReasonByIndex()
    String next_punishment_reason_name = DOM01.GetJSONPunishmentReasonNameByIndex(next_punishment_reason,slave.actorSex)

    String actor_json = "{\"loaded\":true,\"source\":\"Get_Actor_Info\",\"is_slave\":true" \
        + ",\"name\":\"" + akActor.GetDisplayName()+"\"" \
        + ",\"owner\":\"" +owner+"\"" \
        \
        + ",\"is_obedient\"" + Bool_String(mind.IsObedient()) \
        +", \"last_order_refused\""+Bool_String(events.GetLastOrderRefused_Reset()) \
        \
        + ",\"mood_sentence\":\"" + events.Mood_to_Sentence(akActor.GetDisplayName(), DOM01.GetMood(akActor))+"\""\
        + ",\"has_tears\"" + Bool_String(slave.hasTears()) \
        + ",\"behaviour\":\"" + behaviour+"\""\
        \
        + ",\"training_mind\":{"\
        +   "\"submission\":" + mind.submission\
        +   ",\"resignation\":" + mind.resignation\
        +   ",\"humiliation\":" + mind.humiliation\
        +   ",\"fear\":" + mind.fear_training\
        +   ",\"respect\":" + mind.respect_training\
        +  "}"\
        \
        + ",\"training_sex\":{"\
        +    "\"vaginal\":" + mind.vaginal_training\
        +    ",\"anal\":" + mind.anal_training\
        +    ",\"oral\":" + mind.oral_training\
        +  "}"\
        \
        + ",\"arousal_factor\":" + mind.arousal_factor\
        + ",\"is_aroused_for\":" + mind.is_aroused_for\
        + ",\"is_enraptured_for\":" + mind.is_enraptured_for\
        \
        + ",\"known_fetishes\":\"" + mind.GetListOfKnownKinks()+"\""\
        + ",\"hidden_fetishes\":\"" + mind.GetListOfHiddenKinks()+"\""\
        \
        + ",\"dirty_level\":" + slave.dirty_level \
        + ",\"wet_level\":" + slave.wet_level \
        \
        + ",\"is_naked\"" + Bool_String(slave.is_naked) \
        + ",\"has_mouth_gag\"" + Bool_String(slave.has_mouth_gag) \
        + ",\"has_collar\"" + Bool_String(slave.has_collar) \
        + ",\"has_cuffs_crossed\"" + Bool_String(slave.has_cuffs_crossed) \
        + ",\"has_cuffs_front\"" + Bool_String(slave.has_cuffs_front) \
        + ",\"has_cuffs_boxtied\"" + Bool_String(slave.has_cuffs_boxtied) \
        + ",\"has_cuffs_back\"" + Bool_String(slave.has_cuffs_back) \
        + ",\"has_arms_device\"" + Bool_String(slave.has_arms_device) \
        + ",\"has_dwarven_device\"" + Bool_String(slave.has_dwarven_device) \
        + ",\"has_dd_suit\"" + Bool_String(slave.has_dd_suit) \
        + ",\"has_petsuit\"" + Bool_String(slave.has_petsuit) \
        + ",\"has_straitjacket\"" + Bool_String(slave.has_straitjacket) \
        + ",\"has_cuffs\"" + Bool_String(slave.has_cuffs) \
        + ",\"has_armbinder\"" + Bool_String(slave.has_armbinder) \
        + ",\"has_yoke\"" + Bool_String(slave.has_yoke) \
        + ",\"has_disablekick\"" + Bool_String(slave.has_disablekick) \
        + ",\"has_device\"" + Bool_String(slave.has_device) \
        + ",\"has_blindfold\"" + Bool_String(slave.has_blindfold) \
        + ",\"has_leash\"" + Bool_String(slave.has_leash) \
        + ",\"has_plug_anal\"" + Bool_String(slave.has_plug_anal) \
        + ",\"has_plug_vaginal\"" + Bool_String(slave.has_plug_vaginal) \
        + ",\"has_weapon_in_inventory\"" + Bool_String(slave.has_weapon_in_inventory) \
        + ",\"has_weapon\"" + Bool_String(slave.has_weapon > 0) \
        + ",\"has_shame_clothes\"" + Bool_String(slave.has_shame_clothes) \
        + ",\"has_lingerie\"" + Bool_String(slave.has_lingerie) \
        + ",\"has_heels\"" + Bool_String(slave.has_heels) \
        + ",\"has_brand\"" + Bool_String(slave.HasMark()) \
        \
        + ",\"is_masturbating\"" + is_masturbating \
        + ",\"is_restrained\"" + Bool_String(slave.is_restrained) \
        + ",\"is_bounded\"" + Bool_String(slave.is_bounded) \
        + ",\"is_jailed\"" + Bool_String(slave.is_jailed) \
        + ",\"punishment\":{"\
        +    "\"next_reason\":\""+next_punishment_reason_name+"\"" \
        +    ",\"whipping_active\":\""+Bool_String(slave.mind.whipping_active)+"\"" \
        +    ",\"whipping_reason_name\":\""+slave.mind.whipping_reason_name+"\"" \
        +    ",\"current_reason_name\":\""+slave.mind.current_punishment_reason_name+"\"" \
        +  "}"\
        + "}"
    events.SaveActorInfo(akActor, actor_json)
    return TraceReturn("Get_Actor_Info", actor_json) 
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
