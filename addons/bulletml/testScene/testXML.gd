extends Node2D
@export var SC_W:=657
@export var SC_H:=322
@onready var emitter:GBML_Emitter = $emitter
var speed =  3.0 # Speed of the movement
var rost_speed = 300.0
var radius =  30.0 # Radius of the circular movement
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var angle = Time.get_ticks_msec() /  1000.0 * speed # Calculate the angle based on time
	var x = cos(angle) * radius
	var y = sin(angle) * radius
	emitter.position = Vector2(x, y) + Vector2(SC_W,SC_H)# Update the position of the sprite
	emitter.rotation_degrees = wrapi(emitter.rotation_degrees+(rost_speed *delta),0,360)



func _on_v_box_container_chane_xml(fullPath):
	
	emitter.bml_file = fullPath
	emitter.reload()
	emitter.AddToRunner()
