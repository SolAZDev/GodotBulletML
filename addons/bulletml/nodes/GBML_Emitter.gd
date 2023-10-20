class_name GBML_Emitter extends Node
@export var bml_file: String
@export var bullet_list: Array[GBML_BulletEntry]

@onready var parser: BulletMLParser = BulletMLParser.new()

func _ready():
	parser.ParseBML(bml_file)
