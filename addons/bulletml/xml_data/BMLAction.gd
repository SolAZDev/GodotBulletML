class_name BMLAction extends BMLBaseType
var type:BMLBaseType.ENodeName
var actions: Array[BMLAction] 
var action_in_process: int = 0

## Used for Repeats, Waits, Speed
var ammount:int 
## Used for iterations
var term: int
## Direction in Degrees
var direction: float 
var dir_type: BMLBaseType.EDirectionType
var alt_dir_type: BMLBaseType.EDirectionType
var velocity: Vector2
var fire: BMLFire


var frames_passed: float
var status: BMLBaseType.ERunStatus = BMLBaseType.ERunStatus.NotStarted
var current_action: BMLAction
var current_action_index: int=-1



func move_back():	 
	current_action_index -=1 # wrapi(current_action_index - 1, 0, actions.size())
	if current_action_index<0:
		current_action_index=0
	current_action = actions[current_action_index]
	return current_action

func next_action():
	current_action_index+=1
	if current_action_index>=actions.size():
		action_in_process = 0
		current_action_index = -1
		return null
	current_action = actions[current_action_index]
	#if current_action_index == 0: 
		#action_in_process = 0

	return current_action
	
func restart():
	for action in actions:
		action.restart()
		
	action_in_process=0
	status = BMLBaseType.ERunStatus.NotStarted
	frames_passed=0
	current_action_index=-1


func debug_print(numTabs = 0):
	var spacing = ""
	for x in numTabs:
		spacing+="\t"
	print(spacing, "type: ",type," label: ", label + (' ' + ref if ref!='' else ''), " Status: ", status)
	for action in actions:
		action.debug_print(numTabs+1)

	#for p in get_params():
		#print(spacing, "Param: ", p)
	print(spacing,"==========================================================")

#duplicate(true) not working need to manula implement
func clone():
	var new_action = BMLAction.new()
	new_action.type = type
	new_action.label = label
	new_action.ref = ref
	new_action.ammount = ammount
	new_action.term = term
	new_action.direction = direction
	new_action.dir_type = dir_type
	new_action.alt_dir_type = alt_dir_type
	new_action.velocity = velocity
	new_action.fire = fire
	new_action.frames_passed = frames_passed
	new_action.status = status
	new_action.current_action_index = current_action_index
	new_action.action_in_process = action_in_process
	for action in actions:
		new_action.actions.append(action.clone())
	return new_action
