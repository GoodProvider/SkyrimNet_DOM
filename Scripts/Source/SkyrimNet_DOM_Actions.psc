Scriptname SkyrimNet_DOM_Actions

;------------------------------------
; DOM Actions  
;------------------------------------
Function Trace(String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("[SkyrimNet_DOM_Actions]", msg, Notification)
EndFunction

Function Register_Actions() global 

    SkyrimNetApi.RegisterAction("SlaveOrder_No_Sex", \
        "Disobeys a <superior>'s order to have sex", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "Disobey_Execute",  \
        "", "PAPYRUS", \
        10, "{\"superior\": \"Actor\", \"type\":\"no sex\"")

    ;--------------------------------------
    ; SlaveOrder handled by Disobey
    ;--------------------------------------
    int slave_orders = JValue.readFromFile("Data/SkyrimNet_DOM/slave_orders.json")
    i = 0 
    count = JArray.count(slave_orders)
    while i < count
        int order = JArray.getObj(slave_orders,i)
        String actionName = JArray.getStr(order,0)
        String description = JArray.getStr(order,1)
        String schemaJson = JArray.getStr(order,2)
        SkyrimNetApi.RegisterAction("SlaveOrder_"+actionName, description, \
            "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
            "SkyrimNet_DOM_Actions", "Disobey_Execute",  \
            "", "PAPYRUS", 1, schemaJson)
        i += 1
    endwhile

    SkyrimNetApi.RegisterAction("SlaveOrder_Strip", \
        "'{{ decnpc(npc.UUID).name }} was ordered to <strip> clothes by <superior>, they have choosen to <choice>.", \
        "SkyrimNet_DOM_Actions", "SlaveStrip_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_StripDress_Execute",  \
        "", "PAPYRUS", \
        10, "{\"superior\": \"Actor\", \"choice\":\"obey|disobey\", \"type\":\"strip|dress\"}")
    SkyrimNetApi.RegisterAction("SlaveOrder_Dress", \
        "'{{ decnpc(npc.UUID).name }} was ordered to dress by <superior>, they have choosen to <choice>.", \
        "SkyrimNet_DOM_Actions", "SlaveDress_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_StripDress_Execute",  \
        "", "PAPYRUS", \
        10, "{\"superior\": \"Actor\", \"choice\":\"obey|disobey\", \"type\":\"dress\"}")
    return 

    SkyrimNetApi.RegisterAction("SlaveOrder_TypeTarget", \
        "'{{ decnpc(npc.UUID).name }} was ordered to <type> <target> by <superior>, they have choosen to <choice>.", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_Target_Execute",  \
        "", "PAPYRUS", \
        10, "{\"superior\": \"Actor\", \"target\":\"Actor\", \"type\":\"follow|wait\", \"choice\":\"obey|disobey\"}")
    SkyrimNetApi.RegisterAction("SlaveOrder_SexTarget", \
        "'{{ decnpc(npc.UUID).name }} was ordered to have <type> sex with <target> by <superior>, they have choosen to <choice>.", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_SexTarget_Execute",  \
        "", "PAPYRUS", \
        15, "{\"superior\": \"Actor\", \"target\":\"Actor\", \"type\":\"anal|vaginal|oral\", \"choice\":\"obey|disobey\", \"aggressive\":false}")
    SkyrimNetApi.RegisterAction("SlaveOrder_Sex", \
        "'{{ decnpc(npc.UUID).name }} was ordered to masturbate by <superior>, they have choosen to <choice>.", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_SexTarget_Execute",  \
        "", "PAPYRUS", \
        10, "{\"superior\": \"Actor\",  \"type\":\"mastrubate\", \"choice\":\"obey|disobey\"}")


    ;--------------------------------------
    ; Praise Reasons
    ;--------------------------------------
    String praise_reasons = "other" 
    int reasons = JValue.readFromFile("Data/SkyrimNet_DOM/praise_reasons.json")
    int i = 0 
    int count = JArray.count(reasons)
    while i < count
        praise_reasons += "|"
        praise_reasons += JArray.getStr(reasons,i)
        i += 1
    endwhile

    SkyrimNetApi.RegisterAction("SlaveOrder_Praise", \
        "'{{ decnpc(npc.UUID).name }} has been praised by <superior> for <reason>,  {{ decnpc(npc.UUID).name }} has choosen to <choice> the praise.", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_Words_Execute",  \
        "", "PAPYRUS", \
        2, "{\"speaker\": \"Actor\", \"choice\":\"accept|reject\",\"type\":\"praise\",\"reason\":\""+praise_reasons+"\"}")

    SkyrimNetApi.RegisterAction("SlaveOrder_Insulting", \
        "'<superior> said hurtful words to {{ decnpc(npc.UUID).name }} by <kind> words,  {{ decnpc(npc.UUID).name }} has choosen to <choice> the those words.", \
        "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
        "SkyrimNet_DOM_Actions", "SlaveOrder_Words_Execute",  \
        "", "PAPYRUS", \
        2, "{\"superior\": \"Actor\", \"choice\":\"accept|reject\",\"type\":\"insulting\",\"kind\":\"try to dominating|calling them useless|degrading|demeaning|disgraceful|calling them worthless|hurtful\"}")


EndFunction

Bool Function IsSlave_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    if !SkyrimNet_SexLab_Actions.SexTarget_IsEligible(akActor, contextJson, paramsJson)
        return False
    endif

    DOM_API api = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API
    if api == None
        Trace("DOMSlave_Disobey_IsElibible: DOM_API is None",true)
        return False
    endif
    Bool value = api.IsDOMSlave(akActor)
    Trace(akActor.GetLeveledActorBase().GetName()+" "+contextJson+" "+paramsJson+" "+value)
    return value 
EndFunction 

Function Disobey_Execute(Actor akActor, string contextJson, string paramsJson) global
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "didnt obey")
    AddPunishmentReason(akActor, type) 
EndFunction

Function SlaveOrder_SexTarget_Execute(Actor akActor, string contextJson, string paramsJson) global
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    Trace(akActor.GetLeveledActorBase().GetName()+" choice: "+choice+" sextarget: "+contextJson+":"+paramsJson)
    if choice == "obey"
        Actor akTarget = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
        String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "vaginal")
        Bool rape = SkyrimNetApi.GetJsonBool(paramsJson, "rape", false)
        Actor player = Game.GetPlayer() 
        Debug.Trace("SexTarget target:"+akTarget+" type:"+type+" rape:"+rape)
        if akTarget == player 
            type = SkyrimNet_SexLab_Actions.YesNoDialog(rape, akTarget, akActor, player)
        endif 
        if type != "No"
            DOM_API api = ( Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API)
            if api == None
                Trace("SlaveOrder_SexTarget_Execute: DOM_API is None",true)
                return
            endif
            String slave_name = akActor.GetLeveledActorBase().GetName()
            if !api.IsDOMSlave(akActor)
                Trace("SlaveOrder_SexTarget_Execute: "+slave_name+" is not a slave")
                return
            endif 
            DOM_Actor slave = api.GetDOMActor(akActor)
            slave.StartSexWithNPC(akTarget, type, rape)
        endif 
    Else
        Debug.Trace("SexTarget no sex!!")
        AddPunishmentReason(akActor, "no sex") 
    endif 
EndFunction

; ----------------------------------------------
; Strip 
; ----------------------------------------------

Bool Function SlaveStrip_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    return SlaveStripDress_IsEligible(akActor, contextJson, paramsJson, false)
EndFunction

Bool Function SlaveDress_IsEligible(Actor akActor, string contextJson, string paramsJson) global
    return SlaveStripDress_IsEligible(akActor, contextJson, paramsJson, true)
EndFunction

Bool Function SlaveStripDress_IsEligible(Actor akActor, string contextJson, string paramsJson, Bool is_naked) global
    DOM_API api = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API
    if api == None
        Trace("SlaveStrip_IsEligible: DOM_API is None", true)
        return false
    endif
    DOM_Actor slave = api.GetDOMActor(akActor)
    if slave == None 
        Trace("SlaveStrip_IsEligible: slave is None")
        return false
    endif 
    return slave.is_naked == is_naked
EndFunction 

Function SlaveOrder_StripDress_Execute(Actor akActor, string contextJson, string paramsJson) global
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "strip")
    Trace(akActor.GetLeveledActorBase().GetName()+" "+type+":"+contextJson+":"+paramsJson)
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    if choice == "obey"
        DOM_API api = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API
        if api == None
            Trace("[SkyrimNet_DOM] DOMSlave_Srip_Execute: DOM_API is None", true)
            return 
        endif
        DOM_Actor slave = api.GetDOMActor(akActor)
        if slave == None 
            Trace("[SkyrimNet_DOM] DOMSlave_Srip_Execute: slave is None")
            return 
        endif 
        if type == "strip"
            slave.StripMore() 
        else
            slave.UnsetShouldBeNaked(Game.GetPlayer())
            slave.Anim_DressUp(true)
        endif 
    Else
        AddPunishmentReason(akActor, "refusing to strip") 
    endif 
EndFunction

Function SlaveOrder_Words_Execute(Actor akActor, string contextJson, string paramsJson) global
    Debug.Notification(akActor.GetLeveledActorBase().GetName()+" words :"+contextJson+":"+paramsJson)
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "accept")
    if choice == "accept"
        DOM_API api = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API
        if api == None
            Trace("[SkyrimNet_DOM] DOMSlave_words_Execute: DOM_API is None",true)
            return 
        endif
        DOM_Actor slave = api.GetDOMActor(akActor)
        if slave == None 
            Trace("[SkyrimNet_DOM] DOMSlave_Words_Execute: slave is None",true)
            return 
        endif 
        String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "being disrespectful")
        if type == "praise"
            String reason = SkyrimNetApi.GetJsonString(paramsJson, "reason", "good slave")
            slave.StartPraising(Game.GetPlayer(),reason,"tell")
        else
            String kind = SkyrimNetApi.GetJsonString(paramsJson, "kind", "useless")
            if kind == "calling them useless"
                kind = "useless"
            elseif kind == "calling them worthless"
                kind = "worthless"
            elseif kind == "disgraceful"
                kind = "disgrace"
            endif
            slave.StartInsultingWith(Game.GetPlayer(),kind)
        endif 
    Else
        AddPunishmentReason(akActor, "didnt listen") 
    endif 
EndFunction

Function AddPunishmentReason(Actor akActor, String reason_name) global
    DOM_API api = Game.GetFormFromFile(0x00000D61, "DiaryOfMine.esm") as DOM_API
    if api == None
        Trace("[SkyrimNet_DOM] Get_DOM_Slave_INfo: DOM_API is None",true)
    endif
    String slave_name = akActor.GetLeveledActorBase().GetName()
    if !api.IsDOMSlave(akActor)
        Debug.TraceAndBox("[SkyrimNet_DOM] Get_DOM_Slave_INfo: "+slave_name+" is not a slave")
    endif 
    DOM_Mind mind = api.GetDOM_MindFromActor(akActor)
    int reason = DOM_Util.GetPunishmentReasonIndexByName(reason_name)
    mind.AddNextPunishmentReason(reason)
    Debug.Notification(slave_name+" "+reason_name)
EndFunction