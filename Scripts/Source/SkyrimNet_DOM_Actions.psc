Scriptname SkyrimNet_DOM_Actions
import SkyrimNet_DOM_Utils

;------------------------------------
; Shared Functions 
;------------------------------------
Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_Actions",func, msg, Notification)
EndFunction
DOM_ACtor Function Get_Slave(String func, Actor slaveActor,bool error_non_dom_actor=False) global
    return SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Actions",func, slaveActor, error_non_dom_actor, false)
EndFunction

;------------------------------------
; Register ACtions 
;------------------------------------
Function Register_Actions() global 
    Trace("Register_Actions","Registering Actions")
    ;--------------------------------------
    ; SlaveOrder handled by Disobey
    ;--------------------------------------
    int slave_orders = JValue.readFromFile("Data/SKSE/Plugins/SkyrimNet_DOM/slave_orders.json")
    int i = 0 
    int count = JArray.count(slave_orders)
    while i < count
        int order = JArray.getObj(slave_orders,i)
        String actionName = JArray.getStr(order,0)
        String description = JArray.getStr(order,1)
        String schemaJson = JArray.getStr(order,2)
        SkyrimNetApi.RegisterAction("DOMSLAVE_"+actionName, description, \
            "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
            "SkyrimNet_DOM_Actions", "Disobey_Execute",  \
            "", "PAPYRUS", 1, schemaJson)
        i += 1
    endwhile

    String actions_fname = "Data/SKSE/Plugins/SkyrimNet_DOM/actions.json"
    Trace("RegisterActions","loading "+actions_fname)

    int actions = JValue.readFromFile(actions_fname) 
    count = JArray.count(actions) 
    i = 0 
    while i < count 
        int a = JArray.getObj(actions, i) 
        Trace("RigsterActions", "i: "+i+" a: "+a)
         if a > 0
            String name = JMap.getStr(a, "name")
            Trace("RegisterActions",\
                i+" name: "+JMap.getStr(a, "name")\
                +" description: "+JMap.getStr(a, "description")\
                +" scriptFileName: "+JMap.getStr(a, "scriptFileName")\ 
                +" execute: "+JMap.getStr(a, "execute")\
                +" isEligible: "+JMap.getStr(a, "isEligible")\
                +" priority: "+JMap.getInt(a, "priority")\
                +" parameters: "+JMap.getStr(a, "parameters")\
                +" tags: "+JMap.getStr(a, "tags"))
            SkyrimNetApi.RegisterAction(\ 
                JMap.getStr(a, "name"),\
                JMap.getStr(a, "description"),\
                JMap.getStr(a, "scriptFileName"), JMap.getStr(a, "isEligible"),\
                JMap.getStr(a, "scriptFileName"), JMap.getStr(a, "execute"),\
                "", "PAPYRUS", JMap.getInt(a, "priority"),\
                JMap.getStr(a, "parameters"),\
                "", JMap.getStr(a, "tags"))
        else 
            Trace("RegisterActions","Failed to get object from i: "+i)
        endif 
        i += 1 
    endwhile 

    ;--------------------------------------
    ; Praise Reasons
    ;--------------------------------------
    Trace("Register_Actions","Praise Reasons")
    String praise_reasons = "other" 
    String fname = "Data/SKSE/Plugins/StorageUtilData/PAH Diary Of Mine/PraisingReasons.json"
    int reasons = JValue.readFromFile(fname) 
    Trace("Register_Actions","reasons:"+reasons+" fname:"+fname)
    if reasons > 0
        i = 0 
        count = JArray.count(reasons)
        count = 1
        while i < count
            String id = ""+i
            if i < 10 
                id = "00"+id
            elseif i < 100
                id = "0"+id
            endif 
            String undefined = "undefined"+id
            String path = "praisesList.Praise"+id+".reason"
            String reason = JValue.solveStr(reasons,path,"")
            if reason != "" && reason != undefined
                praise_reasons += "|"
                praise_reasons += reason
            endif 
            Trace("Register_Actions",i+" | "+undefined+" | "+path+" | "+reason)
            i += 1
        endwhile

        SkyrimNetApi.RegisterAction("Praise", \
            "'{{ decnpc(npc.UUID).name }} has been praised by <superior> for <reason>,  {{ decnpc(npc.UUID).name }} has choosen to <choice> the praise.", \
            "SkyrimNet_DOM_Actions", "IsSlave_IsEligible",  \
            "SkyrimNet_DOM_Actions", "Words_Execute",  \
            "", "PAPYRUS", \
            2, "{\"superior\": \"Actor\", \"choice\":\"accept|reject\",\"type\":\"praise\",\"reason\":\""+praise_reasons+"\"}")
        Trace("Register_Actions","praise_reasons: "+praise_reasons)
    else
        Trace("Register_Actions","Fail to load "+fname) 
    endif 

EndFunction

; -------------------------------
Bool Function is_masturbating_isEligible(Actor slaveActor, string contextJson, string paramsJson) global
    if !SkyrimNet_DOM_Utils.IsDOMSlave(slaveActor)
        Trace("is_masturbating_isEligible",slaveActor.GetDisplayName()+" isn't a slave")
        return False
    endif 
    DOM_Actor slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Actions","is_masturbating",slaveActor) 
    Trace("is_masturbating_isEligible",slaveActor.GetDisplayName()+" is_behaviour_masturbate:"+slave.is_behaviour_masturbate)
    return slave.is_behaviour_masturbate
EndFunction 

Bool Function is_not_masturbating_isEligible(Actor slaveActor, string contextJson, string paramsJson) global
    if !SkyrimNet_DOM_Utils.IsDOMSlave(slaveActor)
        Trace("is_not_masturbating_isEligible",slaveActor.GetDisplayName()+" isn't a slave")
        return False
    endif 
    DOM_Actor slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Actions","is_not_masturbating_isElibible",slaveActor) 
    Trace("is_not_masturbating_isEligible",slaveActor.GetDisplayName()+" is_behaviour_masturbate:"+slave.is_behaviour_masturbate)
    return !slave.is_behaviour_masturbate
EndFunction

Function masturbate_Start(Actor slaveActor, String contextJson, String paramsJson) global
    Trace("Masturbate_Start","Starting "+slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)

    DOM_Actor slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Start", slaveActor, True) 
    if slave == None 
        return 
    endif 

    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "start masturbating")
    Actor superior = SkyrimNetAPi.GetJsonActor(paramsJson, "superior", Game.GetPlayer())
    String position = SkyrimNetApi.GetJsonString(paramsJson, "position", "kneeling")
    Trace("Masturbate_Start","slave:"+slaveActor.GetDisplayName()+" superior:"+superior.GetDisplayName()\
        +" choice:"+choice+" position:"+position)
    if choice == "start masturbating" || choice == "obey"
        ;SkyrimNet_DOM_Utils. RegisterEvent(String event_name, String msg, Actor source=None, Actor target=None)
        if !slave.is_behaviour_masturbate
            if position == "kneeling"
                slave.EnterMasturbateKneeling(superior) 
            elseif position == "laying"
                slave.EnterMasturbateLaying(superior) 
            else
                slave.EnterMasturbateStanding(superior) 
            endif 
        else
            slave.MasturbateHarder(superior) 
        endif 
    Else
        SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions","Masturbate_Start", superior, slaveActor, slave, "didnt masturbate") 
    endif 
EndFunction 

Function masturbate_Stop(Actor slaveActor, String contextJson, String paramsJson) global
    Trace("Masturbate_Stop","Stopping "+slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)

    DOM_Actor slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Actions", "masturbate_Stop", slaveActor, True) 
    if slave == None 
        Trace("Masturbate_Stop","Failed to get slave for "+slaveActor.GetDisplayName())
        return 
    endif 
    String reason = SkyrimNetApi.GetJsonString(paramsJson, "reason", "wanted")
    if reason != "orderd"
        SkyrimNet_Dom_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions","Masturbate_Stop", None, slaveActor, slave, "didnt masturbate")
    endif 

    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x5900, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    main.d_keys.DOMDoStandStill(slaveActor)
    Trace("Masturbate_Stop","slave:"+slaveActor.GetDisplayName()+" reason:"+reason)
EndFunction 
; -------------------------------
Bool Function IsSlave_IsEligible(Actor slaveActor, string contextJson, string paramsJson) global
    SkyrimNet_SexLab_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
    if !main.sexLab.IsValidActor(slaveActor) || slaveActor.IsDead() || slaveActor.IsInCombat() || main.sexLab.IsActorActive(slaveActor) || main.IsActorLocked(slaveActor) 
        Trace("IsSlave_IsEligible",slaveActor.GetDisplayName()+" can't have sex")
        return False
    endif
    DOM_Actor slave = Get_Slave("IsSlave_IsEligible", slaveActor) 
    bool is_slave = slave != None 
    Trace("IsSlave_IsEligible",slaveActor.GetDisplayName()+" is_slave:"+is_slave)
    return is_slave
EndFunction 

Function Disobey_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    DOM_Actor slave = Get_Slave("Disobey_Execute", slaveActor,true) 
    if slave == None 
        return 
    endif 
    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "didnt obey")
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer()) 
    SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions", "Disobey_Execute", superior, slaveActor, slave, type) 
EndFunction

; The following paramsJson are used by hotkey functions to test thisfunction 
; by_hotkey : required to turn on the functionality 
Function Sex_Start(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("Sex_Start",slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)
    Sex_Start_Helper(slaveActor, contextJson, paramsJson, "None")
EndFunction

Function Rape_Target_Start(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("Rape_Target_Start",slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)
    Sex_Start_Helper(slaveActor, contextJson, paramsJson, "Target")
EndFunction

Function Rape_Speaker_Start(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("Rape_Speaker_Start",slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)
    Sex_Start_Helper(slaveActor, contextJson, paramsJson, "Speaker")
EndFunction

Function Sex_Start_Helper(Actor slaveActor, string contextJson, string paramsJson, String rape_victim) global
    Trace("Sex_Start_Helper", slaveActor.GetDisplayName()+" context:"+contextJson+" params:"+paramsJson)
    DOM_Actor slave = Get_Slave("Sex_Start_Helper", slaveActor,true) 
    if slave == None 
        return 
    endif 

    Actor player = Game.GetPlayer() 
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", player)
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    Bool rape = rape_victim == "Speaker" || rape_victim == "Target"

    Trace("Sex_Start_Helper", "superior:"+superior.GetDisplayName()+" choice:"+choice+" rape:"+rape)

    if choice == "obey" || rape
        Actor target = SkyrimNetApi.GetJsonActor(paramsJson, "target", player)

        String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "")
        
        int DOMO1_ID = 0x00000D61
        int DOM02Topic_ID = 0x000ED87C
        String DOM_FILE = "DiaryOfMine.esm"
        Form f = Game.GetFormFromFile(DOM02Topic_ID,DOM_FILE) 
        DOM_KEYS d_keys = f as DOM_KEYS
        DOM_sexlab d_sexlab = f as DOM_sexlab

        ;String msg = "" 
        ;float respectful_modifier = 1
        ;if rape
            ;msg = "' rape."
            ;respectful_modifier = 0.4
        ;else
            ;msg = "'s request for sex."
            ;respectful_modifier = 0.6
            ;slave.Anim_PoseByString("LooseDialogueResponsePositive")
        ;endif

        ;bool not_respectful= false 
        ;if slave.CanAnswer() 
            ;not_respectful = slave.mind.IsNotRespectful(respectful_modifier)
        ;endif 
        ;if not_respectful 
            ;msg = slaveActor.GetDisplayName()+" is being disrespectful about "+superior.GetDisplayName()+msg
        ;else 
            ;msg = slaveActor.GetDisplayName()+" respectfully submits to "+superior.GetDisplayName()+msg
        ;endif 
        ;slave.mind.sex_is_non_consensual = rape

        Actor[] actors = new Actor[2] 
        actors[0] = slaveActor 
        actors[1] = target 

        String style = SkyrimNetApi.GetJsonString(paramsJson, "style", "normal")
        String direction = SkyrimNetApi.GetJsonString(paramsJson, "direction", "")
        String tag = SkyrimNetApi.GetJsonString(paramsJson, "type", "")

        SkyrimNet_SexLab_Actions actions = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Actions
        if actions == None 
            Trace("Sex_Start_Helper", "SkyrimNet_SexLab_Actions is None, aborting")
            return 
        endif 
        Trace("Sex_Start_Helper","actions:"+actions)

        sslThreadModel thread = None 
        if rape
            Actor[] victims = PapyrusUtil.ActorArray(1) 
            Actor victim_actor = slaveActor 
            if rape_victim == "Target"
                victim_actor = target
            endif 
            victims[0] = victim_actor 

            if SkyrimNet_DOM_Utils.IsDOMSlave(victim_actor)
                DOM_Actor victim_slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM", "Sex_Start_Helper", victim_actor) 
                string reason
                int imenu = d_keys.ShowDOMPunishmentMenu(slaveActor)
                if imenu < 0
                    reason = ""
                else
                    reason = d_keys.selectPunishmentReason[imenu]
                    if reason == ""
                        Trace("Sex_Start_Helper","Wheel menu returned invalid punishment reason")
                    endif
                endif
                if reason != "" 
                    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x5900, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
                    String desc = main.Get_Punishment_To_Description(reason) 
                    if desc != "" 
                        reason = desc+" "+superior.GetDisplayName()+"."
                    endif 
                endif 
                String msg = superior.GetDisplayName()+" starts raping "+slaveActor.GetDisplayName()+" to punish them for "+reason+"."
                SkyrimNet_DOM_Utils.RegisterEvent("DOM_Obey",msg, slaveActor, target)
                slave.StartPunishingByActor(superior, reason, "rape")
            endif 

            Trace("SkyrimNet_DOM_Actions",SkyrimNet_SexLab_Utilities.JoinActors(actors)+" victims:"+SkyrimNet_SexLab_Utilities.JoinActors(victims)+" style:"+style+" direction:"+direction+" tag:"+tag)
            thread = actions.Sex_Start_Helper(actors, victims, style, direction, tag, "SkyrimNet_DOM_AnimationEnd")
        else
            Actor[] victims = PapyrusUtil.ActorArray(0) 

            String msg = slaveActor.GetDisplayName()+" respectfully submits to "+superior.GetDisplayName()+"."
            SkyrimNet_DOM_Utils.RegisterEvent("DOM_Obey",msg, slaveActor, target)
            Trace("SkyrimNet_DOM_Actions",SkyrimNet_SexLab_Utilities.JoinActors(actors)+" victims:"+SkyrimNet_SexLab_Utilities.JoinActors(victims)+" style:"+style+" direction:"+direction+" tag:"+tag)
            thread = actions.Sex_Start_Helper(actors, victims, style, direction, tag, "SkyrimNet_DOM_AnimationEnd")
        endif 
;        Trace("Sex_Start_Helper",superior.GetDisplayName()+"'s "+slaveActor.GetDisplayName()\
;            +" target: "+target.GetDisplayName()+" rape:"+rape+" choice:"+choice)

        SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
        ((main as Quest) as SkyrimNet_DOM_Events).GetActorsReadyForScene(thread) 
    Else
        SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions", "Sex_Start_Helper", superior, slaveActor, slave, "refusing to have sex") 
    endif 
EndFunction

Bool Function Comfort_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    String name = slaveActor.GetDisplayName()
    DOM_Actor slave = Get_Slave("UndressDress_IsEligible", slaveActor) 
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer())
    String method = SkyrimNetApi.GetJsonString(paramsJson, "method", "care")
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    if choice == "obey" || choice == "is comforted"
        Trace("Comfort_excute",slaveActor.GetDisplayName()+" comforted with "+method+" by "+superior.GetDisplayName())
        slave.mind.StartComfortingWith(superior, method) 
    else
        SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions", "Comfortated_Execute", superior, slaveActor, slave, "didnt listen") 
    endif 
EndFunction 


; ----------------------------------------------
; Dress/Undress
; ----------------------------------------------

Bool Function Dress_IsEligible(Actor slaveActor, string contextJson, string paramsJson) global
    return UndressDress_IsEligible(slaveActor, contextJson, paramsJson, true)
EndFunction

Bool Function Undress_IsEligible(Actor slaveActor, string contextJson, string paramsJson) global
    return UndressDress_IsEligible(slaveActor, contextJson, paramsJson, false)
EndFunction

Bool Function UndressDress_IsEligible(Actor slaveActor, string contextJson, string paramsJson, Bool is_naked) global
    String name = slaveActor.GetDisplayName()
    DOM_Actor slave = Get_Slave("UndressDress_IsEligible", slaveActor) 
    if slave == None 
        Trace("UndressDress_IsEligible",name+" is not a name.")
        return false 
    endif 
    bool value = slave.is_naked == is_naked
    if is_naked
        Trace("UndressDress_IsEligible","Slave "+name+" can dress: "+value)
    else 
        Trace("UndressDress_IsEligible","Slave "+name+" can undress: "+value)
    endif 
    return value 
EndFunction 

Function UndressDress_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("UndressDress_Execute", slaveActor.GetDisplayName()+" context:"+ contextJson+" params:"+paramsJson)
    DOM_Actor slave = Get_Slave("SripDress_Execute", slaveActor,true) 
    if slave == None 
        return 
    endif 

    String type = SkyrimNetApi.GetJsonString(paramsJson, "type", "undress")
    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "obey")
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer()) 
    if choice == "starts to undress" || choice == "starts to dress" || choice == "obey"
        if type == "dress"
            slave.UnsetShouldBeNaked(superior)
        else
            if !slave.mind.should_be_naked
                slave.mind.SetObedientTimer(1)
            endif 
            slave.SetShouldBeNaked(superior)
        endif 
    else 
        String reason = "refusing to strip"
        if choice == "dress" 
            reason = "didnt listen"
        endif 
        SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions", "UndressDress_Execute", superior, slaveActor, slave, reason)
    endif 
EndFunction

Function Words_Execute(Actor slaveActor, string contextJson, string paramsJson) global
    Trace("StripDress_Execute", slaveActor.GetDisplayName()+" context:"+ contextJson+" params:"+paramsJson)
    DOM_Actor slave = Get_Slave("Words_Execute", slaveActor) 
    if slave == None 
        return 
    endif 

    String choice = SkyrimNetApi.GetJsonString(paramsJson, "choice", "accept")
    Actor superior = SkyrimNetApi.GetJsonActor(paramsJson, "superior", Game.GetPlayer()) 
    if choice == "accept"
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
        SkyrimNEt_DOM_Utils.AddPunishmentReason("SkyrimNet_DOM_Actions", "Words_Execute", superior, slaveActor, slave, "didnt listen") 
    endif 
EndFunction
