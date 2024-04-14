class_name BulletMLParser

## Parses a BulletML File, needs the res://url to the BulletML file, and will return a BulletMLObject
static func ParseBML(file: String, host: GBML_Emitter,showDebugDetails=false) -> BulletMLObject:
	var document: XMLDocument = XML.parse_file(file)
	var data: XMLNode = document.root
	var bml: BulletMLObject = BulletMLObject.new()
	var type = TryGetAttribute(data, "type")
	bml.params = host.params
	bml.data_xml = data
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
	
	# debug data
	if showDebugDetails:
		print("BulletML: %s" % file)
		print("Actions: %d" % bml.action.size())
		for action in bml.action:
			action.debug_print() 
		print("Fires: %d" % bml.fire.size())
		print("Bullets: %d" % bml.bullet.size())
		print("Params: %d" % bml.params.size())
		print("IsHorizontal: %s" % bml.IsHorizontal) 
		print("Host Params: %s" % host.params)


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
	node: XMLNode, bml: BulletMLObject, host:GBML_Emitter, refable: bool = false, parent_bullet: BMLBullet = null
) -> BMLAction:
	var action = BMLAction.new()
	var name = (
		node.attributes.get("label") if node.attributes.has("label") else str(bml.fire.size())
	)
	action.host = host
	if BMLBaseType.ENodeName[node.name] == BMLBaseType.ENodeName.actionRef:
		action.ref = name
		action.type = BMLBaseType.ENodeName.action 
		action.label = name
		# get Action from bml
		var aActions = bml.action.filter(func(x:BMLAction): 
				return x.label == node.attributes.get("label"))
		if aActions.size()>0:						
			action = aActions[0].clone()

		var params =  TryGetChildNode(node, BMLBaseType.ENodeName.param)
		if params!=null:
			for param in params.children:
				action.params.append(ParseEquation(param.content,node.get_params())) 
	else:
		action.label = name
		# TODO: Reorganize as Child of Node in question
		# 		The Current Method is currently overwriting the current action
		# 		Thus never really adding the actions, except the last one
		for child in node.children:
			var childAction = BMLAction.new()
			childAction.host = host
			# Used to understand the action hirearchy
			childAction.label = child.name
			match BMLBaseType.ENodeName[child.name]:
				# This one i tricky, but is a good example or replicating what needs to be done here
				# The action itself is a repeat, but
				BMLBaseType.ENodeName.repeat:  
					# TODO: Rewrite as a Nested Action
					childAction.type = BMLBaseType.ENodeName.repeat
					var times = TryGetChildValue(child, BMLBaseType.ENodeName.times)
					if times!=null: childAction.ammount = ParseEquation(times,childAction.get_params())
					var actions =  TryGetChildNode(child, BMLBaseType.ENodeName.action)
					if actions==null: 
						 # look for action ref 
						actions = TryGetChildNode(child, BMLBaseType.ENodeName.actionRef)
						# look in root for action with label of action ref
						if actions!=null:
							var aActions = bml.action.filter(func(x:BMLAction): 
									return x.label == actions.attributes.get("label"))
							if aActions.size()>0:
								childAction.actions = aActions
					else:
					# TODO: actions.child[0] IS action
						var repeatedActions = ParseAction(actions, bml, host, false, parent_bullet)
						childAction.actions = repeatedActions.actions
					# childAction.actions.append(ParseAction(actions, bml, host, false, action))
					# if actions!=null:
					# 	for act in actions.children:
					# 		if BMLBaseType.ENodeName[act.name]==BMLBaseType.ENodeName.fire or BMLBaseType.ENodeName[act.name]==BMLBaseType.ENodeName.fireRef:
					# 			action.fire = ParseFire(act, bml, host)
					# 		else:
					# 			action.actions.append(ParseAction(act, bml, host, false, action))
				BMLBaseType.ENodeName.fireRef:
					childAction.type = BMLBaseType.ENodeName.fire
					childAction.label = child.attributes.get("label")
					action.label = name
					# get Action from bml
					var aFires = bml.fire.filter(func(x:BMLFire): 
							return x.label == child.attributes.get("label"))
					if aFires.size()>0:						
						childAction.fire = aFires[0].clone()

					var params =  TryGetChildNode(child, BMLBaseType.ENodeName.param)
					if params!=null:
						for param in params.children:
							childAction.params.append(ParseEquation(param.content,childAction.get_params()))
				BMLBaseType.ENodeName.fire:
					childAction.type = BMLBaseType.ENodeName.fire
					childAction.fire = ParseFire(child, bml, host)
				BMLBaseType.ENodeName.changeSpeed:
					childAction.type = BMLBaseType.ENodeName.changeSpeed
					childAction.ammount = TryGetChildValue(child, BMLBaseType.ENodeName.speed)
					var term = TryGetChildValue(child, BMLBaseType.ENodeName.term)
					if term!=null: childAction.term = ParseEquation(term,childAction.get_params())
				BMLBaseType.ENodeName.changeDirection:
					childAction.type = BMLBaseType.ENodeName.changeDirection
					var dir = TryGetChildNode(child, BMLBaseType.ENodeName.direction)
					if dir != null:
						var type = TryGetAttribute(dir, "type")
						childAction.dir_type = (
							BMLBaseType.EDirectionType[type]
							if type != null
							else BMLBaseType.EDirectionType.absolute
						)
						childAction.direction = ParseEquation(dir.content,childAction.get_params())
						childAction.term = ParseEquation(TryGetChildValue(child, BMLBaseType.ENodeName.term),childAction.get_params())
				BMLBaseType.ENodeName.accel:
					childAction.type = BMLBaseType.ENodeName.accel
					# I honestly don't understand this bit just yet Isn't this what .direction is for?
					var dir = Vector2(0,0)
					var x = TryGetChildValue(child, BMLBaseType.ENodeName.horizontal)
					if x!=null: dir.x = ParseEquation(x,childAction.get_params())
					var y = TryGetChildValue(child, BMLBaseType.ENodeName.vertical)
					if y!=null: dir.y = ParseEquation(y,childAction.get_params())
					childAction.velocity = dir
					var term = TryGetChildValue(child, BMLBaseType.ENodeName.term)
					if term!=null: childAction.term = ParseEquation(term,childAction.get_params())
				BMLBaseType.ENodeName.wait:
					childAction.type = BMLBaseType.ENodeName.wait
					childAction.ammount = ParseEquation(child.content,childAction.get_params())
				BMLBaseType.ENodeName.vanish:
					childAction.type = BMLBaseType.ENodeName.vanish
				BMLBaseType.ENodeName.actionRef:
					childAction.type = BMLBaseType.ENodeName.action
					action.label = name
					# get Action from bml
					var aActions = bml.action.filter(func(x:BMLAction): 
							return x.label == child.attributes.get("label"))
					if aActions.size()>0:						
						childAction = aActions[0].clone()

					var params =  TryGetChildNode(child, BMLBaseType.ENodeName.param)
					if params!=null:
						for param in params.children:
							childAction.params.append(ParseEquation(param.content,childAction.get_params()))
				BMLBaseType.ENodeName.action:
					# Strange Workaround
					childAction.type = BMLBaseType.ENodeName.action
					# ParseAction(child, bml, host, false, action)
					var actions =  TryGetChildNode(node, BMLBaseType.ENodeName.action)
					if actions!=null:
						for act in actions.children: 
							childAction.actions.append(ParseAction(act, bml, host, false, parent_bullet))

					var params =  TryGetChildNode(node, BMLBaseType.ENodeName.param)
					if params!=null:
						for param in params.children:
							childAction.params.append(ParseEquation(param.content,childAction.get_params()))
			action.actions.append(childAction)
		action.label = name
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
		# get Action from bml
		var aFires = bml.fire.filter(func(x:BMLFire): 
				return x.label == node.attributes.get("label"))
		if aFires.size()>0:						
			fire = aFires[0].clone()
		 
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
			fire.direction = ParseEquation(dir.content,fire.get_params())
		var speed = TryGetChildValue(node, BMLBaseType.ENodeName.speed)
		if speed !=null: fire.speed = speed
		var bullet = TryGetChildNode(node, BMLBaseType.ENodeName.bullet)
		if bullet != null:
			fire.bullet = ParseBullet(bullet, bml, host)
		else: # What if it's a bullet Ref?
			bullet = TryGetChildNode(node, BMLBaseType.ENodeName.bulletRef)
			if bullet != null:
				var aBullets = bml.bullet.filter(func(x:BMLBullet): 
						return x.label == bullet.attributes.get("label"))
				if aBullets.size()>0:
					fire.bullet = aBullets[0].clone()
				else:
					fire.bullet = ParseBullet(bullet, bml, host)
		bml.fire.append(fire)
		# Reset and Return Reference
		fire = BMLFire.new()
		fire.ref = name
	return fire

## Parses a bullet & bulletRef node. it will add the bullet to the Root's bullet collection, but returns a reference to it.
static func ParseBullet(node: XMLNode, bml: BulletMLObject, host:GBML_Emitter) -> BMLBullet:
	var bullet: BMLBullet = BMLBullet.new()
	bullet.host = host
	if BMLBaseType.ENodeName[node.name] == BMLBaseType.ENodeName.bulletRef:
		var aBullets = bml.bullet.filter(func(x:BMLBullet): 
						return x.label == bullet.attributes.get("label"))
		if aBullets.size()>0:
			bullet = aBullets[0].clone()
		#bullet.ref = node.attributes.get("label")
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
		# not sure about this line
		#bullet = BMLBullet.new()
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
			func (x:XMLNode):
				return BMLBaseType.ENodeName[x.name] == type)
	)
	if possible_children.size() > 0:
		return possible_children[0]
	else:
		return null
 
## Parses Equations based on string literals
static func ParseEquation(equation: String,params:Array) -> float:
	var exp = Expression.new()
	var result = 0
	var rank = GBML_Runner.instance.Rank if GBML_Runner.instance != null else 1
	for x in params.size():
		equation = equation.replace("$%d" % (x+1), str(params[x]))
	var finalString = equation.replace("$rank", str(rank)).replace("$rand", str(randf_range(0,1)))
	# TODO: Parse params 
	var err = exp.parse(finalString)
	if err == OK: result = exp.execute()
	return result

## Tries to find the relevant type based on a name
static func NameToType(name:String) -> BMLBaseType.ENodeName:
	var type =  BMLBaseType.ENodeName.keys()[BMLBaseType.ENodeName[name]]
	return type
