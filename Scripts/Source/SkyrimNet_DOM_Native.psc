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
