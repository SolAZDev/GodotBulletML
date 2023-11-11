class_name BMLBaseType extends RefCounted
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
	## Y or Z Axis
	vertical,
	## X Axis
	horizontal,
	none
}

## These are used for tasks during runtime
enum ERunStatus{
	## To Run
	NotStarted, 
	## Run Afnd Continue
	Continue, 
	## Wait til task is complete.
	WaitForMe, 
	## Skip, Next can Continue
	Finished, 
}
# endregion

func vanish(): pass
