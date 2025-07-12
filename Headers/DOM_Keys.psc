Scriptname DOM_Keys extends Quest  

int Function ShowDOMPunishmentMenu(Actor akTarget)
EndFunction 

string[] _selectPunishmentReason
string[] Property selectPunishmentReason
	string[] Function Get()
		if !_selectPunishmentReason
			_selectPunishmentReason = new string[8] ; 8 choices max per wheel menu
		endif
		return _selectPunishmentReason
	endFunction
EndProperty