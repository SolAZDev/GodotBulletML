class_name BMLAction extends BMLBaseType
var type:BMLBaseType.ENodeName
var actions: Array[BMLAction] 
var action_in_process: int = -1

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
var params:Array

var frames_passed: float
var status: BMLBaseType.ERunStatus = BMLBaseType.ERunStatus.NotStarted
