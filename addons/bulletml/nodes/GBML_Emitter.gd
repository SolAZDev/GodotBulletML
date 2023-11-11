class_name GBML_Emitter extends Node
@export_category("Core Settings")
## BulletML File to Run
@export var bml_file: String

## Bullet Dictionary, to look up what bullets to use
@export var bullet_list: Array[GBML_BulletEntry]

@export_category("Bullet Space Settings")
## Enable 3D
@export var Use3D: bool = false

## Used for 3D Space
@export var UseXZ: bool = false

## The Parsed BML Data
var bml_data: BulletMLObject

var bml:BulletMLObject
func _ready():
	var bml_data = BulletMLParser.ParseBML(bml_file)
	if bml_data != null:
		GBML_Runner.instance.emitter.push(self)