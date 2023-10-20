class_name BMLBaseType
var label: String
var ref: String
var parent: BMLBaseType

# region Enums
## These are the different type of nodes that can exist in a bulletML file
enum ENodeName{
	bulletml,
	action,
	fire, 
	bullet, 
	changeDirection, 
	changeSpeed, 
	accel,
	wait, 
	repeat, 
	bulletRef, 
	actionRef, 
	fireRef, 
	vanish,
	horizontal, 
	vertical, 
	term, 
	times, 
	direction, 
	speed, 
	param,
}

enum EDirectionType{
	none,
	aim,
	absolute,
	relative,
	sequence
}

## Different types of bullet patterns
enum EPatternType{
	vertical,
	horizontal,
	none
}

## Theese are used for tasks during runtime
enum ERunStatus{
	Continue, 
	End, 
	Stop 
}
# endregion

func vanish(): pass
