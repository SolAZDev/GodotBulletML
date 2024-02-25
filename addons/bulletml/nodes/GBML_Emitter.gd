class_name GBML_Emitter extends Node
@export_category("Core Settings")
## Start once the node is Ready
@export var auto_start:bool = false
## Ammount of seconds to wait before it's added to the Runne
@export var start_delay:float = 1
## BulletML File to Run
@export var bml_file: String

## Bullet Dictionary, to look up what bullets to use
@export var bullet_list: Array[GBML_BulletEntry]
@export var spawnedBulletToPath:NodePath=NodePath(".")
## Enable 3D
@export var Use3D: bool = false

## Used for 3D Space
@export var UseXZ: bool = false

## The Parsed BML Data
var bml_data: BulletMLObject

@export_category("Aiming Settings")
@export var ActiveTarget:int = 0
@export var Targets:Array[Node]
@export var params:Array : 
	set(value):
		params = value
		if bml_data:
			bml_data.params = value

signal OnEmitterAdded(emitter:GBML_Emitter)
signal OnEmitterRemoved(emitter:GBML_Emitter)


@onready var spawnedBulletTo:Node = get_node_or_null(spawnedBulletToPath)

func _ready():
	bml_data = BulletMLParser.ParseBML(bml_file, self,true)
	if auto_start == true: AddToRunner()


 

func reload():
	RemoveFromRunner()
	bml_data = BulletMLParser.ParseBML(bml_file, self,true)
	if auto_start == true: AddToRunner()


## Add this emitter to the Runner so it can be processed
func AddToRunner()->void:
	await get_tree().create_timer(start_delay).timeout
	if bml_data!=null: 
		GBML_Runner.instance.emitters.append(self)
		OnEmitterAdded.emit(self)

## Remove this emitter for being is processed
func RemoveFromRunner()->void:	
	GBML_Runner.instance.DeleteEverythingFromEmitter(self)
	OnEmitterRemoved.emit(self)
