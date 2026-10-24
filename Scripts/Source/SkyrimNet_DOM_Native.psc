Scriptname SkyrimNet_DOM_Native Hidden

;/
Native helpers implemented by SkyrimNet_DOM.dll (DomObedience).
Mode: 0 ungated, 1 order DirectNarration, 2 sex RegisterEvent only.
/;

Int Function KindMode(String kind) Global Native
Int Function KindReason(String kind) Global Native
Int Function KindFacet(String kind) Global Native
Int Function KindTraining(String kind) Global Native

Function ArmSkip(Actor slave, Int ms) Global Native
Bool Function ShouldSkipEventNarration(Actor slave) Global Native

String Function MakeRefuseNarration(String superiorName, String slaveName, String actionDesc) Global Native
String Function MakeObeyNarration(String superiorName, String slaveName, String actionDesc) Global Native
String Function MakeSexOrderEvent(String superiorName, String slaveName, String actionDesc) Global Native

; Gesture watch (Character::NotifyAnimationGraph hook). Matches send ModEvent
; "SkyrimNet_DOM_Gesture" (strArg = key, sender = actor) for actors in the faction.
Function GestureRegisterEvent(String animEvent, String key) Global Native
Function GestureRegisterIdle(Idle idle, String key) Global Native
Function GestureClear() Global Native
Function GestureSetFaction(Faction watched) Global Native
Function GestureSetEnabled(Bool enabled, Int cooldownMs) Global Native
Function GestureSetDebug(Bool enabled) Global Native
