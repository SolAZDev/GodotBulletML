class_name GBML_Bullet extends Node
var bullet_data: BMLBullet
var velocity: Vector2 = Vector2.ZERO
var diection: float = 0
var vanished:bool   = false
var finished:bool   = false
var target:Node     = null
var rank:float      = 0
var tags:Array[String] = []
var actions:Array   = []

# Extended 
var damage: int     = 1
var lifetime:float  = 10

# TODO: Add XZ Check and return positin
func aim(target: Node)->void:
    if target != null:
        return atan2(0,0)

func vanish()->void:
    for action in actions: action.vanish()
    actions = []

func replace_action(old, new)->void: pass