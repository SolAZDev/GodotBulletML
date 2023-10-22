class_name BulletMLAction extends BMLBaseType
var type:BMLBaseType.ENodeName
var actions: Array[BulletMLAction] 

## Used for Repeats, Waits, Speed
var ammount:int 
var term: int
var direction: float
var direction_type: BMLBaseType.EDirectionType
var velocity: Vector2
var fire: BulletMLFire
var params:Array

var frames_passed: int
var finished:bool = false

func vanish():
	if parent!=null: parent.vanish()
	frames_passed=-1
	finished=true

