extends VBoxContainer
@export var path_to_xml:="res://addons/bulletml/samples/"
@onready var xml_files = $XmlFiles
signal chane_xml(fullPath)
# Called when the node enters the scene tree for the first time.
func _ready():
	getXMLFiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func getXMLFiles():
	var fileName : Array[String] =[]
	var dir = DirAccess.open(path_to_xml)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && file_name.ends_with(".xml"):
				fileName.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	fileName.sort()
	for x in fileName:			
		xml_files.add_item(x)
func _on_xml_files_item_clicked(index, at_position, mouse_button_index):
	pass


func _on_xml_files_item_activated(index):
	var info:String  = xml_files.get_item_text(index)
	emit_signal("chane_xml","%s%s" %[path_to_xml,info])
