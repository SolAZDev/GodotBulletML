class_name GBML_Emitter extends Node
@export var bml_file: String
@export var bullet_list: Array[GBML_BulletEntry]
var bml:BulletMLObject
func _ready():
	bml = BulletMLParser.ParseBML(bml_file)
	var test = JSON.stringify(bml)
	print(test)
