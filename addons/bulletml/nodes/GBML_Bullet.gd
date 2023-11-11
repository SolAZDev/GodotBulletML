class_name GBML_Bullet extends Node

@export_category("Physics Settngs")
@export var shape_3d: Shape3D
@export var shape_2d: Shape2D

var bullet_data: BMLBullet
var listParent: GBML_BulletTypeEntry
var parent: GBML_Emitter
var velocity: Vector2 = Vector2.ZERO
var speed_modifier: float = 1
var diection: float = 0
var vanished:bool   = false
var finished:bool   = false
var target:Node     = null
var rank:float      = 0
var tags:Array[String] = []
var action:BMLAction
var damage: int     = 1
var lifetime:float  = 10

func replace_action(old, new)->void: pass

func GetTargetAim() -> float: 
	var angle = 0
	if parent.Use3D:
		var pos = self.global_position
		var tar = (target as Node3D).global_position
		if parent.UseXZ: angle = Vector2(pos.x, pos.z).angle_to_point(Vector2(tar.x, tar.z))
		else: angle = Vector2(pos.x, pos.y).angle_to_point(Vector2(tar.x, tar.y))
	else: angle = self.global_position.angle_to_point((target as Node2D).global_position)
	return angle