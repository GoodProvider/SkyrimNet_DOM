Scriptname SkyrimNet_DOM_Obedience Hidden
import SkyrimNet_SexLab_Utilities

; Returns:
;  -1 ungated / native missing (caller executes and may OrderNarration)
;   0 refused (do not execute; refuse DN already emitted)
;   1 obeyed, unified DN already emitted
;   2 obeyed sex, order RegisterEvent already emitted (SexLab DN owns the scene)

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Obedience", func, msg, Notification)
EndFunction

Bool Function NativeReady() global
    return SKSE.GetPluginVersion("SkyrimNet_DOM") > 0
EndFunction

Bool Function ShouldSkipEventNarration(Actor slave) global
    if !slave
        return false
    endif
    if !NativeReady()
        return false
    endif
    return SkyrimNet_DOM_Native.ShouldSkipEventNarration(slave)
EndFunction

Int Function TryOrder(Actor superior, Actor slave, String kind, String actionDesc) global
    if !slave
        return -1
    endif
    if !NativeReady()
        return -1
    endif
    int mode = SkyrimNet_DOM_Native.KindMode(kind)
    if mode <= 0
        return -1
    endif
    if !superior
        superior = Game.GetPlayer()
    endif
    if actionDesc == ""
        actionDesc = kind
    endif

    SkyrimNet_DOM_Native.ArmSkip(slave, 4000)

    DOM_Actor da = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Obedience", "TryOrder", slave, false)
    Bool obeyed = true
    if da && da.mind
        int reason = SkyrimNet_DOM_Native.KindReason(kind)
        int facet = SkyrimNet_DOM_Native.KindFacet(kind)
        int training = SkyrimNet_DOM_Native.KindTraining(kind)
        obeyed = da.mind.WillObey(reason, facet, training, 1.0, false)
        if !obeyed
            da.ChooseAnswerNo(superior)
        endif
    endif

    String superiorName = GetDisplayName(superior)
    String slaveName = GetDisplayName(slave)
    if !obeyed
        String refuseMsg = SkyrimNet_DOM_Native.MakeRefuseNarration(superiorName, slaveName, actionDesc)
        DirectNarration(refuseMsg, slave, superior)
        RegisterRefusePunishment(superior, slave, actionDesc)
        Trace("TryOrder", slaveName+" refused kind="+kind+" "+actionDesc)
        return 0
    endif

    SkyrimNet_DOM_Actions act = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if mode == 2
        String sexMsg = SkyrimNet_DOM_Native.MakeSexOrderEvent(superiorName, slaveName, actionDesc)
        SkyrimNetApi.RegisterEvent("Order", sexMsg, superior, slave)
        if act
            act.RegisterObeyCommand(slave, superior, actionDesc)
        endif
        Trace("TryOrder", slaveName+" sex order kind="+kind+" "+actionDesc)
        return 2
    endif

    String obeyMsg = SkyrimNet_DOM_Native.MakeObeyNarration(superiorName, slaveName, actionDesc)
    ; source=superior so DN attribution matches "{superior} orders {slave}…"
    DirectNarration(obeyMsg, superior, slave)
    if act
        act.RegisterObeyCommand(slave, superior, actionDesc)
    endif
    Trace("TryOrder", slaveName+" obeyed kind="+kind+" "+actionDesc)
    return 1
EndFunction

Function RegisterRefusePunishment(Actor superior, Actor slave, String actionDesc) global
    if !slave
        return
    endif
    String slaveName = GetDisplayName(slave)
    String superiorName = GetDisplayName(superior)
    String msg = slaveName+" refused to obey "+superiorName+"'s command to "+actionDesc+", this will be punished."
    SkyrimNetApi.RegisterEvent("Reason to Punish", msg, slave, superior)
EndFunction

; First method/tag token; skip style/direction leftovers from older concatenations.
String Function FirstSexToken(String raw) global
    if raw == ""
        return "sex"
    endif
    String s = raw
    int comma = StringUtil.Find(s, ",")
    if comma >= 0
        s = StringUtil.Substring(s, 0, comma)
    endif
    String[] parts = StringUtil.Split(s, " ")
    if !parts
        return "sex"
    endif
    int i = 0
    while i < parts.length
        String token = parts[i]
        if token != "" && token != "normally" && token != "forcefully" && token != "gently"
            if token != "forceful" && token != "normal" && token != "gentle"
                if token != "fucking" && token != "fucked" && token != "in" && token != "getting" && token != "giving"
                    if token != "with" && token != "have"
                        return token
                    endif
                endif
            endif
        endif
        i += 1
    endwhile
    return "sex"
EndFunction

String Function MapSexType(String token) global
    if token == "" || token == "sex"
        return "sex"
    endif
    if token == "vaginal" || token == "pussy"
        return "vaginal sex"
    endif
    if token == "oral" || token == "mouth" || token == "blowjob" || token == "cunnilingus"
        return "oral sex"
    endif
    if token == "anal" || token == "ass"
        return "anal sex"
    endif
    if StringUtil.Find(token, "sex") >= 0
        return token
    endif
    if token == "handjob" || token == "boobjob" || token == "thighjob" || token == "footjob"
        return token
    endif
    if token == "fingering" || token == "dildo" || token == "fisting"
        return token
    endif
    return token+" sex"
EndFunction

; "have vaginal sex with Bob" — drop style; partner is the other participant.
String Function FormatSexCommand(String methodOrTags, Actor partner) global
    if methodOrTags != "" && StringUtil.GetLength(methodOrTags) >= 5
        String prefix = StringUtil.Substring(methodOrTags, 0, 5)
        if prefix == "have "
            return methodOrTags
        endif
    endif
    String mapped = MapSexType(FirstSexToken(methodOrTags))
    String phrase = "have "+mapped
    if partner
        String partnerName = GetDisplayName(partner)
        if partnerName != ""
            phrase += " with "+partnerName
        endif
    endif
    return phrase
EndFunction

; Prefer superior when they are in the scene; else first other actor.
Actor Function SexCommandPartner(Actor ordered, Actor superior, Actor speaker, Actor target, Actor participate=None) global
    Actor partner = None
    Bool sawSuperior = false
    if target && target != ordered
        partner = target
        if target == superior
            sawSuperior = true
        endif
    endif
    if speaker && speaker != ordered
        if speaker == superior
            partner = speaker
            sawSuperior = true
        elseif !sawSuperior && !partner
            partner = speaker
        endif
    endif
    if participate && participate != ordered
        if participate == superior
            partner = participate
            sawSuperior = true
        elseif !sawSuperior && !partner
            partner = participate
        endif
    endif
    if !partner && superior && superior != ordered
        partner = superior
    endif
    return partner
EndFunction

; Scene Creator / cast gate: prefer non-player DOM slave among actors.
; Returns 0 refuse, else proceed (-1 ungated / no slave / missing DLL).
Int Function TryOrderSexCast(Actor superior, Actor[] actors, String actionDesc) global
    if !actors
        return -1
    endif
    if !superior
        superior = Game.GetPlayer()
    endif
    Actor ordered = None
    int i = 0
    while i < actors.length
        Actor ak = actors[i]
        if ak && ak != superior && SkyrimNet_DOM_API.IsDOMSlave(ak)
            ordered = ak
            i = actors.length
        endif
        i += 1
    endwhile
    if !ordered
        i = 0
        while i < actors.length
            Actor ak = actors[i]
            if ak && SkyrimNet_DOM_API.IsDOMSlave(ak)
                ordered = ak
                i = actors.length
            endif
            i += 1
        endwhile
    endif
    if !ordered
        Trace("TryOrderSexCast", "no DOM slave in cast")
        return -1
    endif
    Actor partner = None
    Bool sawSuperior = false
    i = 0
    while i < actors.length
        Actor ak = actors[i]
        if ak && ak != ordered
            if ak == superior
                partner = ak
                sawSuperior = true
            elseif !sawSuperior && !partner
                partner = ak
            endif
        endif
        i += 1
    endwhile
    if !partner && superior && superior != ordered
        partner = superior
    endif
    return TryOrder(superior, ordered, "sex", FormatSexCommand(actionDesc, partner))
EndFunction
