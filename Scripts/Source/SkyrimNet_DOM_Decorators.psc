Scriptname SkyrimNet_DOM_Decorators
;------------------------------------
; DOM Decorations  
;------------------------------------
Function Trace(String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("[SkyrimNet_DOM_Decorations]", msg, Notification)
EndFunction

Function Register_Decorators() global
    int success = SkyrimNetApi.RegisterDecorator("dom_is_slave", "SkyrimNet_DOM_Decorators", "Is_Slave")
    if success != 0
        Trace("RegisterDecorator failed: dom_is_slave",true)
    endif 
    success = SkyrimNetApi.RegisterDecorator("dom_get_actor_info", "SkyrimNet_DOM_Decorators", "Get_Actor_Info")
    if success != 0
        Trace("RegisterDecorator failed: dom_get_actor_info",true)
    endif 
    success = SkyrimNetApi.RegisterDecorator("dom_is_slave_obedient", "SkyrimNet_DOM_Decorators", "Is_Slave_Obedient")
    if success != 0
        Trace("RegisterDecorator failed: dom_is_slave_obedient",true)
    endif 
EndFunction

String Function Is_Slave(Actor akActor) global
    Bool is_slave = False 

    Quest DOM01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    if DOM01 != None 
        is_slave = (DOM01 as DOM_API).IsDOMSlave(akActor)
    endif 

    return "{\"is_slave\":"+is_slave+"}"
EndFunction

String Function Is_Slave_Obedient(Actor akActor) global
    Quest DOM01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    DOM_API api = DOM01 as DOM_API
    String is_slave = ":false"
    String is_obedient = ":false"
    if api != None
        DOM_Actor slave = api.GetDOMActor(akActor)
        if slave != None 
            is_slave = ":true"
            if slave.mind.IsObedient()
                is_obedient = ":true"
            endif
        endif
    endif 
    return "{\"is_slave\""+is_slave+", \"is_obedient\""+is_obedient+"}"
EndFunction

String Function BehaviourToStr(String behavior) global
    int key_value = JValue.readFromFile("Data/DOM_SkyrimNet/slave_behaviours.json")
    if JMap.hasKey(key_value, behavior)
        return JMap.getStr(key_value, behavior) 
    endif
    return ""
EndFunction


String Function Get_Actor_Info(Actor akActor) global
    Quest DOM01 = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as Quest
    DOM_API api = DOM01 as DOM_API
    DOM_Core core = DOM01 as DOM_Core
    if api == None
        Trace("Get_DOM_Slave_INfo: DOM_API is None",true)
        return ""
    endif
    String slave_name = akActor.GetDisplayName()
    if !api.IsDOMSlave(akActor)
        Trace("Get_DOM_Slave_INfo: "+slave_name+" is not a slave")
        return "{\"is_slave\":false}"
    endif 

    DOM_Actor slave = api.GetDOMActor(akActor)
    DOM_Mind mind = slave.mind

    String is_obedient = ":false"
    if mind.IsObedient()
        is_obedient = ":true"
    endif

    String json = "{\"is_slave\":true" \
    + ",\"name\":\"" + slave_name+"\"" \
    + ",\"owner\":\"" + Game.GetPlayer().GetDisplayName()+"\"" \
    + ",\"is_obedient\"" +is_obedient \
    + ",\"mood\":\"" + core.GetMood(akActor)+"\""\
    + ",\"state\":\"" + Add_State(slave)+"\""\
    + ",\"behaviour\":\"" + slave.behaviour+"\""\
    + ",\"submission\":" + mind.submission\
    + ",\"humiliation\":" + mind.humiliation\
    + ",\"fear_training\":" + mind.fear_training\
    + ",\"resignation\":" + mind.resignation\
    + ",\"respect_training\":" + mind.respect_training\
    + ",\"vaginal_training\":" + mind.vaginal_training\
    + ",\"anal_training\":" + mind.anal_training\
    + ",\"oral_training\":" + mind.oral_training\
    + "}"

    return json
EndFunction

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
