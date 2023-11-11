class_name GBML_Runner extends Node

static var instance: GBML_Runner
var bullets: Array[GBML_BulletTypeEntry]
@export var emitters: Array[GBML_Emitter]
## This is a muliplier that is applied to movement.
@export_range(0.01, 10) var space_scale = 1

func _init():
	if GBML_Runner.instance != null: queue_free()
	else: GBML_Runner.instance = self

func _process(delta):
	BulletProcess(delta)
	for emitter in emitters: ActionProcess(delta, emitter.actions[0], null)


func BulletProcess(delta: float):
	for bulletSet in bullets:
		for bullet in bulletSet.bullets:
			var currentPosition:Vector2 = Vector2.ZERO
			if bullet.parent.Use3D:
				if bullet.parent.UseXZ: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.z)
				else: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.y)
			else: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.y)

			#TODO: Verify done correctly
			var angle = (Vector2.RIGHT if bullet.parent.bml_data.IsHorizontal else Vector2.DOWN).rotated(bullet.direction)
			currentPosition += angle + (bullet.velocity * bullet.speed_modifier) * space_scale
			
			if bullet.parent.Use3D:
				if bullet.parent.UseXZ: bullet.global_position = Vector3(currentPosition.x, bullet.global_position.y, currentPosition.y)
				else: bullet.global_position = Vector3(currentPosition.x, currentPosition.y, bullet.global_position.z)
			else: bullet.global_position = currentPosition

			# TODO: Call Physics Server.
			BulletCollissionCheck(bullet)
			

			if bullet.action != null: ExecuteActionList(delta, bullet.action, bullet)
			pass

func ActionProcess(delta: float, action:BMLAction, bullet: GBML_Bullet = null) -> BMLBaseType.ERunStatus:
	if action.status == BMLBaseType.ERunStatus.Finished: return BMLBaseType.ERunStatus.Finished
	match action.type:
		BMLBaseType.ENodeName.accel: 
			var acceleration = Vector2.ZERO
			match action.dir_type:
				BMLBaseType.EDirectionType.sequence: acceleration.x = action.velocity.x
				BMLBaseType.EDirectionType.relative: acceleration.x = action.velocity.x / action.term
				_: acceleration.x = (bullet.velocity.x - action.velocity.x) / action.term
			match action.alt_dir_type:
				BMLBaseType.EDirectionType.sequence: acceleration.y = action.velocity.y
				BMLBaseType.EDirectionType.relative: acceleration.y = action.velocity.y / action.term
				_: acceleration.x = (bullet.velocity.y - action.velocity.y) / action.term
			bullet.velocity += acceleration
			action.frames_passed += 1
			action.status = BMLBaseType.ERunStatus.Finished if action.frames_passed>=action.term else BMLBaseType.ERunStatus.Continue
			# bullet.speed_modifier = 0
		BMLBaseType.ENodeName.action: # Premature Attempt
			for act in action.actions:
				var result = ActionProcess(delta, act, bullet)
				match result:
					BMLBaseType.ERunStatus.Continue: pass
		BMLBaseType.ENodeName.changeDirection:
			var dirAlteration = 0 
			match action.dir_type:
				BMLBaseType.EDirectionType.aim:		 dirAlteration = (action.direction+bullet.GetTargetAim()) - bullet.direction
				BMLBaseType.EDirectionType.sequence: dirAlteration = action.direction
				BMLBaseType.EDirectionType.absolute: dirAlteration = action.direction - bullet.direction
				BMLBaseType.EDirectionType.relative: dirAlteration = action.direction
				_: dirAlteration = action.direction
			bullet.diection += dirAlteration
			action.status = BMLBaseType.ERunStatus.Finished if action.frames_passed>=action.term else BMLBaseType.ERunStatus.Continue
			# action.status = BMLBaseType.ERunStatus.Finished
		BMLBaseType.ENodeName.changeSpeed: 
			var speedAlteration = 0
			match action.dir_type:
				BMLBaseType.EDirectionType.sequence: speedAlteration = bullet.bullet_data.speed
				BMLBaseType.EDirectionType.relative: speedAlteration = bullet.bullet_data.speed/action.term
				_: speedAlteration = (action.ammount - bullet.bullet_data.speed) / (action.term - action.frames_passed)
			bullet.bullet_data += speedAlteration
			action.status = BMLBaseType.ERunStatus.Finished if action.frames_passed>=action.term else BMLBaseType.ERunStatus.Continue
			# action.status = BMLBaseType.ERunStatus.Finished
		BMLBaseType.ENodeName.fire: pass # TODO
		BMLBaseType.ENodeName.repeat:
			if action.term >= action.ammount: return BMLBaseType.ERunStatus.Finished
			else:
				action.term +=1
				ExecuteActionList(delta, action, bullet)
				action.status = BMLBaseType.ERunStatus.WaitForMe
		BMLBaseType.ENodeName.wait:
			if action.frames_passed >= action.ammount: action.status = BMLBaseType.ERunStatus.Finished
			else:
				action.status = BMLBaseType.ERunStatus.WaitForMe
				action.frames_passed+=delta
		# BMLBaseType.ENodeName.vanish: EraseBulletFromList(bullet.listParent, bullet)
		BMLBaseType.ENodeName.vanish: ToggleBullet(bullet, false)
	if action.parent is BMLAction: (action.parent as BMLAction).action_in_process+=1
	return action.status

func ExecuteActionList(delta:float, actionParent: BMLAction, bullet:GBML_Bullet):
	for action in actionParent.actions:
		var status = ActionProcess(delta, action, bullet)
		if status == BMLBaseType.ERunStatus.WaitForMe: break

func EraseBulletFromList(bulletList: GBML_BulletTypeEntry, bullet:GBML_Bullet):
	if bulletList != null:
		bulletList.bullets.erase(bullet)
		if bulletList.bullets.size()<=0: bullets.erase(bulletList)
	bullet.queue_free()

func SpawnBullet(bullet: BMLBullet, parent: GBML_Emitter) -> Node:
	var bulletsFound = parent.bullet_list.filter(func(be:GBML_BulletEntry): return be.label.to_lower()==bullet.label.to_lower())
	var bulletEntry = bulletsFound[0] if bulletsFound.size()>0 else parent.bullet_list[0]
	# Check if the bullet entry exists
	var entriesFound = bullets.filter(func(be: GBML_BulletTypeEntry):return be.label.to_lower() == bulletEntry.label.to_lower())
	if entriesFound.size()>0: 
		var bulletAvailable:int = entriesFound[0].bullets.find(func(bul):return bul.process_mode == Node.PROCESS_MODE_DISABLED)
		if bulletAvailable > -1: return entriesFound[0].bullets[bulletAvailable]
		else: #Spawn Bullet
			var spawn = bulletEntry.bullet.instantiate()
			parent.add_child(spawn)
			entriesFound[0].bullets.append(spawn)
			return spawn
	else: # Spawn bullet and append to bullet dictionary
		var spawn = bulletEntry.bullet.instantiate()
		parent.add_child(spawn)
		var entry:GBML_BulletTypeEntry
		entry.label = bulletEntry.label
		entry.bullets = []
		entry.bullets.append(spawn)
		bullets.append(entry)
		return spawn

func BulletCollissionCheck(bullet:GBML_Bullet) -> void:
	var result: Array[Dictionary] = []
	if bullet.parent.Use3D:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = bullet.shape_3d
		query.collide_with_bodies = true
		query.transform = bullet.global_transform
		result = get_node(".").get_world_3d().direct_space_state.intersect_shape(query)
	else:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = bullet.shape_2d
		query.collide_with_bodies = true
		query.transform = bullet.global_transform
		result = get_node(".").get_world_2d().direct_space_state.intersect_shape(query)
	if result.size()>0:
		for other_node in result:
			## This expects your nodes to have a reciever for the bullet_hit, and you can grab the info from the bullet.
			other_node.collider.emit_signal('bullet_hit', bullet)
		ToggleBullet(bullet, false)

func ToggleBullet(bullet:GBML_Bullet, toggle:bool = true) -> void:
	if toggle: bullet.show()
	else: bullet.hide()
	bullet.set_process(toggle)