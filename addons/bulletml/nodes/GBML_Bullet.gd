class_name GBML_Bullet extends Node

@export_category("Physics Settngs")
## Used for collisions in the PhysicsServer3D
@export var shape_3d: Shape3D
## Used for collisions in the PhysicsServer2D
@export var shape_2d: Shape2D

var bullet_data: BMLBullet
var listParent: GBML_BulletTypeEntry
var host: GBML_Emitter
var velocity: Vector2 = Vector2.ZERO
var speed: float
var direction: float = 0
var target:Node     = null
var rank:float      = 0
var tags:Array[String] = []
var damage: int     = 1
var lifetime:float  = 10
