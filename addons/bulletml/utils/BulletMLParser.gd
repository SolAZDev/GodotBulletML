class_name BulletMLParser 
var xml: XMLParser
static var instance: BulletMLParser

func _init():
	if BulletMLParser.instance != null: free()
	BulletMLParser.instance = self
	xml = XMLParser.new()

func ParseBML(file: String):
	print("Aja?")
	print(file)
	var file_error = xml.open(file)
	if file_error != OK: 
		push_error("Could not open BulletML file "+file)
		return null
	
	var current_bnode_type: BMLBaseType.ENodeName
	var current_bml: BMLBulletML = BMLBulletML.new()
	var current_bullet: BMLBullet
	var current_fire: BMLFire
	var current_action: BulletMLAction
	
	var read_error = xml.read()
	if read_error != OK: 
		push_error("Could not read BulletML file "+file)
		return null
	var current_node_name: String = xml.get_node_name()
	var current_node_type = xml.get_node_type()
	xml.skip_section() # xml
	xml.skip_section() # !doctype
	while xml.get_node_type() != XMLParser.NODE_NONE: #plsdont
		current_node_name = xml.get_node_name()
		current_node_type = xml.get_node_type()
		if current_node_name.contains("?xml") or current_node_name.contains("!doctype") or current_node_name.contains("!DOCTYPE") or current_node_name.contains("bulletml"):
			xml.skip_section()
			continue
			
		var current_node_data: String = xml.get_node_data()
		print("type "+str(xml.get_node_type()))
		print("name "+xml.get_node_name())
		print("data "+xml.get_node_data())
		if xml.get_node_type() == XMLParser.NODE_ELEMENT:
			print(xml.get_node_data())
			# match xml.get_node_name():
		
		xml.skip_section()
		continue
