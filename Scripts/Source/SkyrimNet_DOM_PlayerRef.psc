Scriptname SkyrimNet_DOM_PlayerRef extends ReferenceAlias  

SkyrimNet_DOM_Main Property main  Auto  

Function Trace(String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("[SkyrimNet_DOM_PlayerRef]", msg, Notification)
EndFunction


Event OnPlayerLoadGame()
    Trace("OnPlayerLoadGame called with "+main)
    main.Setup()
EndEvent