Scriptname SkyrimNet_DOM_Bath Hidden

; Stage-aware bath with another actor. DOM has no per-stage event and keeps its animation state private, so:
;  Drive           runs the bath itself (TargetMenu); each stage holds until SkyrimNet has finished speaking.
;  FollowDomBath   only narrates a bath DOM is running (spell/wheel); DOM controls the pace, so stages are timed.
; Faction DOMBathingMode rank: 3 = washer, 4 = washed.

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Bath", func, msg, Notification)
EndFunction

Bool Function IsDriven(Actor akActor) global
    return StorageUtil.GetIntValue(akActor, "DOM_bath_driven", 0) > 0
EndFunction

String Function StageText(Int stage, Actor washer, Actor washed) global
    String washerName = washer.GetDisplayName()
    String washedName = washed.GetDisplayName()
    if stage == 1
        return washedName+" sits, while "+washerName+" kneels behind washing "+washedName+"'s back with a rag."
    elseif stage == 2
        String part = "chest"
        if washer.GetLeveledActorBase().GetSex() == 1
            part = "breasts"
        endif
        return washerName+" puts away the rag, and washes "+washedName+"'s back with their "+part+"."
    endif
    return washerName+" rinses "+washedName+" off, pouring clean water over "+washedName+"'s shoulders."
EndFunction

; Source is the non-player participant so an NPC is the one who reacts.
Actor Function NarrationSource(Actor washer, Actor washed) global
    if washer == Game.GetPlayer()
        return washed
    endif
    return washer
EndFunction

Actor Function NarrationTarget(Actor washer, Actor washed) global
    if washer == Game.GetPlayer()
        return washer
    endif
    return washed
EndFunction

Function Narrate(Int stage, Actor washer, Actor washed, Bool optional) global
    String msg = StageText(stage, washer, washed)
    Actor source = NarrationSource(washer, washed)
    Actor target = NarrationTarget(washer, washed)
    Trace("Narrate", "stage="+stage+" optional="+optional+" "+msg)
    if optional
        SkyrimNet_SexLab_Utilities.DirectNarration_Optional("bath", msg, source, target, false)
    else
        SkyrimNet_SexLab_Utilities.DirectNarration(msg, source, target)
    endif
EndFunction

Bool Function StillBathing(Faction mode, Actor washer, Actor washed) global
    if washer.IsDead() || washed.IsDead()
        return false
    endif
    return washer.IsInFaction(mode) && washed.IsInFaction(mode)
EndFunction

; Holds the current stage until at least minHold has passed and SkyrimNet's speech queue is empty.
; The queue is still empty while the LLM generates, so an empty queue counts only once speech was seen or
; noSpeechGrace has passed. False = the bath was interrupted.
Bool Function WaitForQuiet(Faction mode, Actor washer, Actor washed, Float minHold) global
    Float noSpeechGrace = 12.0
    Float maxWait = 60.0
    Float elapsed = 0.0
    Bool heard = false
    Int queue = 0
    while elapsed < maxWait
        Utility.Wait(0.5)
        elapsed += 0.5
        if !StillBathing(mode, washer, washed)
            Trace("WaitForQuiet", "interrupted after "+elapsed+"s")
            return false
        endif
        queue = SkyrimNetApi.GetSpeechQueueSize()
        if queue > 0
            heard = true
        endif
        if elapsed >= minHold && queue == 0 && (heard || elapsed >= noSpeechGrace)
            Trace("WaitForQuiet", "advance after "+elapsed+"s minHold="+minHold+" heard="+heard)
            return true
        endif
    endwhile
    Trace("WaitForQuiet", "cap reached, advancing queue="+queue+" heard="+heard)
    return true
EndFunction

; Same notifications as DOM. True = bath in water, False = tub.
Bool Function AnnounceWater(DOM_Interactor interact, DOM_Bathing bath, Actor target, DOM_Actor sl_alias) global
    String name = interact.GetActorName(target, sl_alias)
    if bath.isInWaterfall(target)
        interact.SendNotificationOrder(target, sl_alias, name+" will bath under the waterfall")
        return true
    elseif bath.isInShower(target)
        interact.SendNotificationOrder(target, sl_alias, name+" will bath under the shower")
        return true
    elseif bath.isInWater(target)
        interact.SendNotificationOrder(target, sl_alias, name+" will bath in water")
        return true
    elseif !PO3_SKSEFunctions.IsActorInWater(target)
        interact.SendNotificationOrder(target, sl_alias, name+" will bath in a tub")
        return false
    elseif PO3_SKSEFunctions.IsActorUnderwater(target)
        interact.SendNotificationOrder(target, sl_alias, name+" will bath under water")
        return true
    endif
    interact.SendNotificationOrder(target, sl_alias, name+" will bath in the water")
    return true
EndFunction

; DOM_Interactor.Interact_BathClient (washTarget=false: target washes speaker) and
; Interact_BathActor (washTarget=true: speaker washes target), with each stage held for narration.
Function Drive(DOM_Core core, Actor target, Actor speaker, Bool washTarget) global
    if !core || !target
        Trace("Drive", "missing core or target")
        return
    endif
    if !speaker
        speaker = Game.GetPlayer()
    endif
    DOM_Interactor interact = core.DOMInteract
    DOM_Bathing bath = interact.DOMBath
    Faction mode = core.DOMBathingMode
    DOM_Actor sl_alias = core.GetActor(target)
    DOM_Actor ab_alias = core.GetActor(speaker)

    interact.CheckRunningAway(target, sl_alias)
    if sl_alias == None && ab_alias == None
        Trace("Drive", "neither actor is a DOM_Actor", true)
        return
    endif
    if bath.IsBathing(target) || bath.IsBathing(speaker)
        Trace("Drive", "already bathing")
        return
    endif

    Actor washer = target
    Actor washed = speaker
    if washTarget
        washer = speaker
        washed = target
    endif

    String sl_beh = interact.GetBehaviour(target, sl_alias)
    String ab_beh = interact.GetBehaviour(speaker, ab_alias)
    Bool sl_should_wait = interact.SetFollowerPose(target)
    Bool ab_should_wait = interact.SetFollowerPose(speaker)
    if sl_beh == "bathing"
        sl_beh = "wait"
    endif
    if ab_beh == "bathing"
        ab_beh = "wait"
    endif

    interact.SetIsBathing(target, sl_alias, true)
    interact.SetIsBathing(speaker, ab_alias, true)
    DOM_EquipUtil.UnequipHandheld(target)
    DOM_EquipUtil.UnequipHandheld(speaker)
    interact.CheckRestrained(target, sl_alias, speaker, false)
    interact.CheckRestrained(speaker, ab_alias, None, false)
    if !washTarget
        interact.UnDressBeforeBathing(speaker, ab_alias)
    endif

    String anim_key = "DOMBathTub"
    if AnnounceWater(interact, bath, target, sl_alias)
        anim_key = "DOMBathWater"
    endif

    DOM_Actor center_actor = sl_alias
    if sl_alias != None
        sl_alias.StartJSONAnimation(speaker, anim_key, false, washTarget)
    else
        center_actor = ab_alias
        ab_alias.StartJSONAnimation(target, anim_key, false, !washTarget)
    endif

    Float perfection
    if washTarget
        perfection = interact.GetPerfectionismModifier(target, ab_alias)
    else
        perfection = interact.GetPerfectionismModifier(speaker, ab_alias)
    endif
    Float timer = 8.0 + perfection
    String wash_type = "bath"

    ; DOM's names are crossed: bathing the client rolls WillObeyForBathActor and vice versa.
    Bool obeyed
    if washTarget
        obeyed = interact.WillObeyForBathClient(target, sl_alias, speaker, wash_type)
    else
        obeyed = interact.WillObeyForBathActor(target, sl_alias, speaker, wash_type)
    endif
    if !obeyed
        center_actor.PlayJSONAnimation(1)
        center_actor.EndJSONAnimation()
        interact.AnswerNo(target, sl_alias, speaker)
        interact.SetIsBathing(target, sl_alias, false)
        interact.SetIsBathing(speaker, ab_alias, false)
        interact.SetBehaviour(target, sl_alias, speaker, sl_beh, None)
        interact.SetBehaviour(speaker, ab_alias, None, ab_beh, None)
        Trace("Drive", target.GetDisplayName()+" refused the bath")
        return
    endif

    StorageUtil.SetIntValue(target, "DOM_bath_driven", 1)
    StorageUtil.SetIntValue(speaker, "DOM_bath_driven", 1)
    washer.SetFactionRank(mode, 3)
    washed.SetFactionRank(mode, 4)
    interact.SetBehaviour(target, sl_alias, speaker, "bathing", None)
    interact.SetBehaviour(speaker, ab_alias, None, "bathing", None)
    interact.AnswerStrip(target, sl_alias, speaker)

    MiscObject the_soap = bath.TryFindWashProp(target)
    if the_soap == None
        the_soap = bath.TryFindWashProp(speaker)
    endif
    Bool has_soap = the_soap != None
    Int nscenes = center_actor.GetNbAnimScenes()

    Narrate(1, washer, washed, false)
    Bool active = WaitForQuiet(mode, washer, washed, timer)

    bath.SetDrip(target)
    bath.SetDrip(speaker)
    if has_soap
        bath.SetSoapy(target)
        bath.ApplySoapBonus(target, the_soap)
    endif
    if active
        center_actor.PlayJSONAnimations(1, nscenes - 3)
    endif
    bath.SetDrip(speaker)
    bath.SetDrip(target)
    bath.CleanDirt(target, has_soap)
    if sl_alias != None
        sl_alias.TryRemoveMascaraTears()
    endif
    if active
        center_actor.PlayJSONAnimation(nscenes - 2)
    endif
    if has_soap
        bath.SetSoapy(speaker)
        bath.ApplySoapBonus(speaker, the_soap)
    endif
    Float dirty_level = interact.GetDirtLevel(target, sl_alias)
    dirty_level -= 15.0 + perfection
    if active
        Narrate(2, washer, washed, false)
        active = WaitForQuiet(mode, washer, washed, timer)
    endif

    if active
        center_actor.PlayJSONAnimation(nscenes - 1)
    endif
    if has_soap
        bath.SetUnsoapy(speaker)
    endif
    bath.SetDrip(speaker)
    bath.SetDrip(target)
    dirty_level -= 25.0 + perfection
    if active
        Narrate(3, washer, washed, false)
        WaitForQuiet(mode, washer, washed, timer)
    endif
    center_actor.EndJSONAnimation()

    interact.SetDirtLevel(target, sl_alias, dirty_level)
    if washTarget
        interact.CheckBathClientEnd(target, sl_alias, speaker, ab_alias)
    else
        interact.CheckBathActorEnd(target, sl_alias, speaker, ab_alias)
    endif
    Float speaker_dirt = interact.GetDirtLevel(speaker, ab_alias) - (15.0 + perfection)
    interact.SetDirtLevel(speaker, ab_alias, speaker_dirt)

    interact.SetBehaviour(target, sl_alias, speaker, sl_beh, None)
    interact.SetBehaviour(speaker, ab_alias, None, ab_beh, None)
    target.RemoveFromFaction(mode)
    speaker.RemoveFromFaction(mode)
    StorageUtil.UnsetIntValue(target, "DOM_bath_driven")
    StorageUtil.UnsetIntValue(speaker, "DOM_bath_driven")
    interact.UnsetFollowerPose(target, sl_should_wait)
    interact.UnsetFollowerPose(speaker, ab_should_wait) ; DOM passes the target here by mistake

    bath.SetUnsoapy(target)
    bath.SetUnsoapy(speaker)
    bath.SetDrip(target)
    bath.SetDrip(speaker)
    interact.SetWetLevel(target, sl_alias, 1.0)
    interact.SetWetLevel(speaker, ab_alias, 0.7)
    interact.SetIsBathing(target, sl_alias, false)
    interact.SetIsBathing(speaker, ab_alias, false)
    interact.ReDressAfterBathing(target, sl_alias)
    if !washTarget
        interact.ReDressAfterBathing(speaker, ab_alias)
    endif
    Utility.Wait(timer)
    bath.UnsetDrip(speaker)
    bath.UnsetDrip(target)
EndFunction

Actor Function FindPartner(Faction mode, Actor slave, Int partnerRank) global
    Actor player = Game.GetPlayer()
    if slave != player && player.GetFactionRank(mode) == partnerRank
        return player
    endif
    Actor[] found = MiscUtil.ScanCellNPCsByFaction(mode, slave, 500.0, partnerRank, partnerRank)
    if !found
        return None
    endif
    Int i = 0
    while i < found.length
        if found[i] != slave
            return found[i]
        endif
        i += 1
    endwhile
    return None
EndFunction

; Waits seconds of game-running time. False = the bath ended first.
Bool Function HoldWhileBathing(Faction mode, Actor washer, Actor washed, Float seconds) global
    Float elapsed = 0.0
    while elapsed < seconds
        Utility.Wait(0.5)
        elapsed += 0.5
        if !StillBathing(mode, washer, washed)
            return false
        endif
    endwhile
    return true
EndFunction

; A bath DOM is running. Called from DOMOnBehaviourChange, which DOM only sends for the slave.
Function FollowDomBath(DOM_Core core, Actor slave) global
    if !core || !slave
        return
    endif
    Faction mode = core.DOMBathingMode
    Int rank = slave.GetFactionRank(mode)
    Int partnerRank = 7 - rank
    Actor partner = FindPartner(mode, slave, partnerRank)
    if !partner
        Trace("FollowDomBath", "no partner found for "+slave.GetDisplayName())
        return
    endif
    Actor washer = slave
    Actor washed = partner
    if rank == 4
        washer = partner
        washed = slave
    elseif partner != Game.GetPlayer() && core.GetActor(partner) != None
        ; Two DOM slaves each send the event; only the washed one narrates.
        return
    endif

    Float timer = 8.0 + core.DOMInteract.GetPerfectionismModifier(washed, core.GetActor(washed))
    Narrate(1, washer, washed, false)
    if HoldWhileBathing(mode, washer, washed, timer)
        Narrate(2, washer, washed, true)
        if HoldWhileBathing(mode, washer, washed, timer)
            Narrate(3, washer, washed, true)
        endif
    endif
EndFunction
