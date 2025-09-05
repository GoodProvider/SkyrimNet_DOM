Scriptname DOM_Mind extends ReferenceAlias  

String Property mood Auto 
Float Property submission Auto 
Float Property fear_training Auto 
Float Property humiliation Auto 
Float Property resignation Auto 
Float Property respect_training Auto 

Float Property vaginal_training Auto 
Float Property oral_training Auto 
Float Property anal_training Auto 

Function AddNextPunishmentReason(int reason)
EndFunction

bool Function IsObedient() ; will obey
EndFunction

float __arousal_factor = 0.0
Float Property arousal_factor Hidden ; is getting more and more aroused
	float Function get()
	EndFunction
	Function set(float value)
	EndFunction
EndProperty

Int __is_aroused_for = 0 ; has reached the arousal plateau, orgasm is possible
Int Property is_aroused_for Hidden
	Int Function get()
	EndFunction
	Function set(Int value)
	EndFunction
EndProperty

Int __is_enraptured_for = 0 ; is ecstatic
Int Property is_enraptured_for Hidden
	Int Function get()
	EndFunction
	Function set(Int value)
	EndFunction
EndProperty