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