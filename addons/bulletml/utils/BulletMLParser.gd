class_name BulletMLParser extends RefCounted

## Parses a BulletML File, needs the res://url to the BulletML file, and will return a BulletMLObject
static func ParseBML(file: String, host: GBML_Emitter) -> BulletMLObject:
	var document: XMLDocument = XML.parse_file(file)
	var data: XMLNode = document.root
	var bml: BulletMLObject = BulletMLObject.new()
	var type = TryGetAttribute(data, "type")
	# Check if null or just not horizontal
	if type != "horizontal" : bml.IsHorizontal=false
	else: bml.IsHorizontal=true
	for child in data.children:
		match BMLBaseType.ENodeName[child.name]:
			BMLBaseType.ENodeName.action:
				bml.action.append(ParseAction(child, bml, host))
			BMLBaseType.ENodeName.fire:
				bml.fire.append(ParseFire(child, bml, host))
			BMLBaseType.ENodeName.bullet:
				bml.bullet.append(ParseBullet(child, bml, host))
	return bml

## Lists children of a node. Used for debugging
static func ListChildren(node: XMLNode, parent: XMLNode = null):
	for child in node.children:
		print(
			(
				"Parsing: "
				+ (parent.name + "->" if parent != null else "")
				+ node.name
				+ "."
				+ child.name
			)
		)
		if child.children: ListChildren(child, node)

## Parses a action & actionRef node. it will add the action to the Root's action collection, but returns a reference to it.
static func ParseAction(
	node: XMLNode, bml: BulletMLObject, host:GBML_Emitter, refable: bool = false, parent_action: BMLAction = null
) -> BMLAction:
	var action = BMLAction.new()
	var name = (
		node.attributes.get("label") if node.attributes.has("label") else str(bml.fire.size())
	)
	if BMLBaseType.ENodeName[node.name] == BMLBaseType.ENodeName.actionRef:
		action.ref = name
		action.host = host
		action.type = BMLBaseType.ENodeName.actionRef
	else:
		for child in node.children:
			match BMLBaseType.ENodeName[child.name]:
				BMLBaseType.ENodeName.repeat:
					action.type = BMLBaseType.ENodeName.repeat
					var times = TryGetChildValue(child, BMLBaseType.ENodeName.times)
					if times!=null: action.ammount = ParseEquation(times)
				BMLBaseType.ENodeName.fire, BMLBaseType.ENodeName.fireRef:
					action.type = BMLBaseType.ENodeName.fire
					action.fire = ParseFire(child, bml, host)
				BMLBaseType.ENodeName.changeSpeed:
					action.type = BMLBaseType.ENodeName.changeSpeed
					action.ammount = TryGetChildValue(child, BMLBaseType.ENodeName.speed)
					var term = TryGetChildValue(child, BMLBaseType.ENodeName.term)
					if term!=null: action.term = ParseEquation(term)
				BMLBaseType.ENodeName.changeDirection:
					action.type = BMLBaseType.ENodeName.changeDirection
					var dir = TryGetChildNode(child, BMLBaseType.ENodeName.direction)
					if dir != null:
						var type = TryGetAttribute(dir, "type")
						action.dir_type = (
							BMLBaseType.EDirectionType[type]
							if type != null
							else BMLBaseType.EDirectionType.absolute
						)
						action.direction = ParseEquation(dir.content)
						action.term = ParseEquation(TryGetChildValue(child, BMLBaseType.ENodeName.term))
				BMLBaseType.ENodeName.accel:
					action.type = BMLBaseType.ENodeName.accel
					# I honestly don't understand this bit just yet Isn't this what .direction is for?
					var dir = Vector2(0,0)
					var x = TryGetChildValue(child, BMLBaseType.ENodeName.horizontal)
					if x!=null: dir.x = ParseEquation(x)
					var y = TryGetChildValue(child, BMLBaseType.ENodeName.vertical)
					if y!=null: dir.y = ParseEquation(y)
					action.velocity = dir
					var term = TryGetChildValue(child, BMLBaseType.ENodeName.term)
					if term!=null: action.term = ParseEquation(term)
				BMLBaseType.ENodeName.wait:
					action.type = BMLBaseType.ENodeName.wait
					action.ammount = ParseEquation(node.content)
				BMLBaseType.ENodeName.vanish:
					action.type = BMLBaseType.ENodeName.vanish
				BMLBaseType.ENodeName.action, BMLBaseType.ENodeName.actionRef:
					action.type = BMLBaseType.ENodeName.action
					ParseAction(child, bml, host, false, action)
		action.label = name
		if parent_action != null:
			parent_action.actions.append(action)
		if refable:
			# Reset and Return Reference
			bml.action.append(action)
			action = BMLAction.new()
			action.ref = name
			action.type = BMLBaseType.ENodeName.actionRef
	return action

## Parses a fire & fireRef node. it will add the fire Action to the Root's fire collection, but returns a reference to it.
static func ParseFire(node: XMLNode, bml: BulletMLObject, host:GBML_Emitter) -> BMLFire:
	var fire = BMLFire.new()
	fire.host = host
	if BMLBaseType.ENodeName[node.name] == BMLBaseType.ENodeName.fireRef:
		fire.ref = node.attributes.get("label")
	else:
		var name = (
			node.attributes.get("label") if node.attributes.has("label") else str(bml.fire.size())
		)
		fire.label = name
		var dir = TryGetChildNode(node, BMLBaseType.ENodeName.direction)
		if dir != null:
			var type = TryGetAttribute(dir, "type")
			fire.dir_type = (
				BMLBaseType.EDirectionType[type]
				if type != null
				else BMLBaseType.EDirectionType.absolute
			)
			fire.direction = ParseEquation(dir.content)
		var speed = TryGetChildValue(node, BMLBaseType.ENodeName.speed)
		if speed !=null: fire.speed = speed
		var bullet = TryGetChildNode(node, BMLBaseType.ENodeName.bullet)
		if bullet != null:
			fire.bullet = ParseBullet(bullet, bml, host)
		# Fires don't have actions. At least, according to BulletML spec.
		# var action = TryGetChildNode(node, BMLBaseType.ENodeName.action)
		# if action != null:
		# 	fire.action = ParseAction(action, bml, host, false)

		bml.fire.append(fire)
		# Reset and Return Reference
		fire = BMLFire.new()
		fire.ref = name
	return fire

## Parses a bullet & bulletRef node. it will add the bullet to the Root's bullet collection, but returns a reference to it.
static func ParseBullet(node: XMLNode, bml: BulletMLObject, host:GBML_Emitter) -> BMLBullet:
	var bullet: BMLBullet = BMLBullet.new()
	if BMLBaseType.ENodeName[node.name] == BMLBaseType.ENodeName.bulletRef:
		bullet.ref = node.attributes.get("label")
	else:  #Make a new entry and return ref.
		bullet.label = (
			node.attributes.get("label") if node.attributes.has("label") else str(bml.bullet.size())
		)
		var speed = TryGetChildValue(node, BMLBaseType.ENodeName.speed)
		if speed!=null: bullet.speed = speed
		var damage = TryGetAttribute(node, "damage")
		if damage!=null: bullet.damage = damage
		var lifetime = TryGetAttribute(node, "lifetime")
		if lifetime!=null: bullet.lifetime = lifetime
		var action = TryGetChildNode(node, BMLBaseType.ENodeName.action)
		if action != null:
			# Bullets should contain their own actions as they can be executed in their own time
			bullet.action = ParseAction(action, bml, host, false)
		bml.bullet.append(bullet)
		var ref_name = bullet.label
		# Reset and Return Reference
		bullet = BMLBullet.new()
		bullet.ref = ref_name
	return bullet

## Will attempt to return an attribute's value by the key name, within a node, if it exists
static func TryGetAttribute(node: XMLNode, key: String) -> Variant:
	if node.attributes.has(key):
		return node.attributes.get(key)
	else:
		return null

## Will attempt to return a value of type within a node, if it exists
static func TryGetChildValue(node: XMLNode, type: BMLBaseType.ENodeName) -> Variant:
	var possible_children = node.children.filter(
		func(x: XMLNode):
			var atype = BMLBaseType.ENodeName[x.name] 
			return atype == type
	)
	if possible_children.size() > 0:
		return possible_children[0].content
	else:
		return null

## Will attempt to return a child of type, within a node, if it exists
static func TryGetChildNode(node: XMLNode, type: BMLBaseType.ENodeName) -> XMLNode:
	var possible_children = (
		node.children.filter(
			 func (x:XMLNode): return BMLBaseType.ENodeName[x.name] == type
		)
	)
	if possible_children.size() > 0:
		return possible_children[0]
	else:
		return null

## Parses Equations based on string literals
static func ParseEquation(equation: String) -> float:
	var exp = Expression.new()
	var result = 0
	var rank = GBML_Runner.instance.Rank if GBML_Runner.instance != null else 1
	var finalString = equation.replace("$rank", str(rank)).replace("$rand", str(randf_range(0,1)))
	# TODO: Parse params 
	var err = exp.parse(finalString)
	if err == OK: result = exp.execute()
	return result

## Tries to find the relevant type based on a name
static func NameToType(name:String) -> BMLBaseType.ENodeName:
	var type =  BMLBaseType.ENodeName.keys()[BMLBaseType.ENodeName[name]]
	return type
