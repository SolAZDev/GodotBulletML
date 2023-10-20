class_name BulletMLAction extends BMLBaseType
var actions:Array[BulletMLAction]
var repeat:int 
var wait: float
var speed: float
var diection: float
var velocity: Vector2
var previous_direction: float
var previous_speed: float
var params:Array
var pc: int
var finished:bool  

func vanish():
	if parent!=null: parent.vanish()
	pc=-1
	finished=true
