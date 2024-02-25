class_name BMLBaseType extends Resource
var label: String
var ref: String=''
var parent: BMLBaseType
var host: GBML_Emitter
var params:Array

func get_params()->Array:
	var aParams:Array = []
	# get params and append any more from the host
	for i in range(max(host.params.size(),params.size())):
		if i < params.size():
			aParams.append(params[i])
		else:
			if i < host.params.size():
				aParams.append(host.params[i])
 
	return aParams


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
	## Run And Continue
	Continue, 
	## Wait til task is complete.
	WaitForMe,
	## Wait til task is complete.
	WaitSleep,
	## Skip, Next can Continue
	Finished, 
}
# endregion
