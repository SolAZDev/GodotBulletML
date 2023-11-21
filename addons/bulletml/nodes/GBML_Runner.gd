class_name GBML_Runner extends Node

static var instance: GBML_Runner
var bullets: Array[GBML_BulletTypeEntry]
@export var emitters: Array[GBML_Emitter]
## This is a muliplier that is applied to movement.
@export_range(0.01, 10) var space_scale = 1
## This is used in the equations, but this value is global per-session. 
var Rank = 1

func _init():
	if GBML_Runner.instance != null: queue_free()
	else: GBML_Runner.instance = self
	### Set your rank values here

func _process(delta):
	BulletProcess(delta)
	if emitters.size()>0:
		for emitter in emitters: 
			ExecuteActionList(delta, emitter.bml_data.action[0], null)

## Processes all active bullets. Moves them, Checks for collission and life span, and finally, executes their actions.
func BulletProcess(delta: float) -> void:
	for bulletSet in bullets:
		for bullet in bulletSet.bullets:
			if bullet.process_mode == PROCESS_MODE_DISABLED: continue
			var currentPosition:Vector2 = Vector2.ZERO
			if bullet.host.Use3D:
				if bullet.host.UseXZ: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.z)
				else: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.y)
			else: currentPosition = Vector2(bullet.global_position.x, bullet.global_position.y)

			#TODO: Verify done correctly
			var angle = (Vector2.RIGHT if bullet.host.bml_data.IsHorizontal else Vector2.DOWN).rotated(bullet.direction)
			currentPosition += angle + (bullet.velocity * bullet.speed) * space_scale
			
			if bullet.host.Use3D:
				if bullet.host.UseXZ: bullet.global_position = Vector3(currentPosition.x, bullet.global_position.y, currentPosition.y)
				else: bullet.global_position = Vector3(currentPosition.x, currentPosition.y, bullet.global_position.z)
			else: bullet.global_position = currentPosition

			BulletCollissionCheck(bullet)
			bullet.lifetime-=delta
			if bullet.lifetime<=0: ToggleBullet(bullet, false)
			
			if bullet.bullet_data.action != null: ExecuteActionList(delta, bullet.bullet_data.action, bullet)

## Exectutes an action, used for iteration. To execute a list, look at ExecuteActionList
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
		BMLBaseType.ENodeName.action: # Premature Attempt, this is what ExecuteActionList is for though.
			ExecuteActionList(delta, action, bullet)
			action.status = BMLBaseType.ERunStatus.Finished
		BMLBaseType.ENodeName.changeDirection:
			var dirAlteration = 0 
			match action.dir_type:
				BMLBaseType.EDirectionType.aim:		 dirAlteration = (action.direction+GetObjectAim(bullet, bullet.terget, bullet.host.Use3D, bullet.host.UseXZ)) - bullet.direction
				BMLBaseType.EDirectionType.sequence: dirAlteration = action.direction
				BMLBaseType.EDirectionType.absolute: dirAlteration = action.direction - bullet.direction
				BMLBaseType.EDirectionType.relative: dirAlteration = action.direction
				_: dirAlteration = action.direction
			bullet.direction += dirAlteration
			action.status = BMLBaseType.ERunStatus.Finished if action.frames_passed>=action.term else BMLBaseType.ERunStatus.Continue
		BMLBaseType.ENodeName.changeSpeed: 
			var speedAlteration = 0
			match action.dir_type:
				BMLBaseType.EDirectionType.sequence: speedAlteration = bullet.bullet_data.speed
				BMLBaseType.EDirectionType.relative: speedAlteration = bullet.bullet_data.speed/action.term
				_: speedAlteration = (action.ammount - bullet.bullet_data.speed) / (action.term - action.frames_passed)
			bullet.speed += speedAlteration
			action.status = BMLBaseType.ERunStatus.Finished if action.frames_passed>=action.term else BMLBaseType.ERunStatus.Continue
		BMLBaseType.ENodeName.fire: 
			action.status = FireProcess(action, action.fire, bullet)
		BMLBaseType.ENodeName.repeat:
			if action.term >= action.ammount: return BMLBaseType.ERunStatus.Finished
			else:
				action.term +=1 
				# Force Reset; needs testing.
				for child_action in action.actions: child_action.status = BMLBaseType.ERunStatus.NotStarted
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

## Processes a Fire action, will spawn a bullet from the emitter and enable it for processing
func FireProcess(action:BMLAction, fire:BMLFire, bullet_parent: GBML_Bullet) -> BMLBaseType.ERunStatus: 
	var status = BMLBaseType.ERunStatus.Continue
	# Find the Fire in the List
	var host = action.host if action.host != null else fire.host
	var fire_label = fire.label if fire.label.length()>0 else fire.ref
	if host == null: 
		print("ERROR: Host NOT found!!")
		return BMLBaseType.ERunStatus.Finished
	
	var fires_found = host.bml_data.fire.filter(func(f:BMLFire): return f.label.to_lower() == fire_label.to_lower())
	if fires_found.size()>0:
		var main_fire: BMLFire = fires_found[0]
		var bullet_label = main_fire.bullet.label if main_fire.bullet.label.length()>0 else main_fire.bullet.ref
		var bullets_found = host.bml_data.bullet.filter(func(bul: BMLBullet): return bul.label.to_lower() == bullet_label.to_lower())
		if bullets_found.size()>0:
			print("Firing !")
			# Now actually fire the bullet.
			var bullet_node = SpawnBullet(bullets_found[0], host, bullet_parent)
			# Reset Bullet
			bullet_node.velocity = Vector2.ONE
			bullet_node.bullet_data = bullets_found[0]
			bullet_node.speed = main_fire.speed if bullets_found[0].speed==null else bullets_found[0].speed
			bullet_node.target = GetEmitterActiveTarget(host)
			bullet_node.lifetime = bullets_found[0].lifetime
			var spawn_parent = bullet_parent if bullet_parent!=null else host
			if host.Use3D:
				var pos = (spawn_parent as Node3D).global_position
				bullet_node.global_position = Vector3(pos.x, pos.y, pos.z)
			else:
				var pos = (spawn_parent as Node2D).global_position
				bullet_node.global_position = Vector2(pos.x, pos.y)
			var final_direction = 0

			match main_fire.dir_type:
				BMLBaseType.EDirectionType.absolute: final_direction = main_fire.direction
				BMLBaseType.EDirectionType.aim: final_direction = GetObjectAim(host, bullet_node.target, host.Use3D, host.UseXZ)
				BMLBaseType.EDirectionType.sequence: final_direction += main_fire.direction * action.term
				_: #Includes Relative and Null
					var parent = bullet_parent if bullet_parent!=null else host
					var parent_angle = 0
					if host.Use3D:
						if host.UseXZ: 	parent_angle = (parent as Node3D).global_rotation_degrees.y * PI/180
						else: 			parent_angle = (parent as Node3D).global_rotation_degrees.z * PI/180
					else: 				parent_angle = (parent as Node2D).global_rotation_degrees
					final_direction = parent_angle + main_fire.direction
			
			bullet_node.direction = final_direction
			ToggleBullet(bullet_node, true)
			status = BMLBaseType.ERunStatus.Finished
	return status;

## Execute a list of actions until it has to wait for one to finish
func ExecuteActionList(delta:float, actionParent: BMLAction, bullet:GBML_Bullet):
	for action in actionParent.actions:
		var status = ActionProcess(delta, action, bullet)
		if status == BMLBaseType.ERunStatus.WaitForMe: break

## Destroys every bullet from an emitter, and removes the emitter from the list to stop it from being processed 
func DeleteEvertythingFromEmitter(emitter: GBML_Emitter)->void:
	for bulletSet in emitter.bullet_list: 
		var list_label = emitter.name+"_"+bulletSet.label
		var active_bullet_entry = bullets.filter(func(bte:GBML_BulletTypeEntry): return bte.label==list_label)
		if active_bullet_entry.size()<=1: continue
		for i in range(active_bullet_entry[0].bullets,0, -1):
			active_bullet_entry[0].bullets[i].queue_free()
			active_bullet_entry[0].bullets.remove_at(i)
		bullets.erase(active_bullet_entry)
	emitters.erase(emitter)

## Spawns a bullet, either pooled or makes a new entry in the bullet list with its emitter to pool future bullets
func SpawnBullet(bullet: BMLBullet, host:GBML_Emitter, parent_bullet: GBML_Bullet) -> GBML_Bullet:
	var list_label:String = host.name+"_"+bullet.label
	var bulletsFound = host.bullet_list.filter(func(be:GBML_BulletEntry): return be.label.to_lower()==list_label.to_lower())
	var bulletEntry = bulletsFound[0] if bulletsFound.size()>0 else host.bullet_list[0]
	# Check if the bullet entry exists
	var entriesFound = bullets.filter(func(be: GBML_BulletTypeEntry):return be.label.to_lower() == bulletEntry.label.to_lower())
	if entriesFound.size()>0: 
		var bulletAvailable = (entriesFound[0] as GBML_BulletTypeEntry).bullets.filter(
			func(bul):
				return bul.process_mode == Node.PROCESS_MODE_DISABLED
		)
		if bulletAvailable.size() > 0: return entriesFound[0].bullets[bulletAvailable[0]]
		else: #Spawn Bullet
			var spawn = bulletEntry.bullet.instantiate()
			spawn.host = host
			host.add_child(spawn)
			entriesFound[0].bullets.append(spawn)
			return spawn
	else: # Spawn bullet and append to bullet dictionary
		var spawn = (bulletEntry.bullet.instantiate() as GBML_Bullet)
		spawn.host = host
		host.add_child(spawn)
		var entry:GBML_BulletTypeEntry = GBML_BulletTypeEntry.new()
		entry.label = bulletEntry.label
		entry.bullets = []
		entry.bullets.append(spawn)
		bullets.append(entry)
		return spawn

## Checks if a bullet has a colission
func BulletCollissionCheck(bullet:GBML_Bullet) -> void:
	var result: Array[Dictionary] = []
	if bullet.host.Use3D:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = bullet.shape_3d
		query.collide_with_bodies = true
		query.transform = bullet.global_transform
		var world = bullet.get_world_3d()
		if world==null: return # Skip this bullet
		result = world.direct_space_state.intersect_shape(query)
	else:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = bullet.shape_2d
		query.collide_with_bodies = true
		query.transform = bullet.global_transform
		# Look at 3D Comment above.
		var world = bullet.get_world_2d()
		if world==null: return # Skip this bullet
		result = world.direct_space_state.intersect_shape(query)
	if result.size()>0:
		for other_node in result:
			## This expects your nodes to have a reciever for the bullet_hit, and you can grab the info from the bullet.
			other_node.collider.emit_signal('bullet_hit', bullet)
		ToggleBullet(bullet, false)

## Enables or Disables a Bullet from being processed and 
func ToggleBullet(bullet:GBML_Bullet, toggle:bool = true) -> void:
	if toggle: bullet.show()
	else: bullet.hide()
	bullet.set_process(toggle)

## Gets the Emitter's Active target
func GetEmitterActiveTarget(emitter: GBML_Emitter) -> Node:
	var target = null
	if emitter.Targets.size()>0: target = emitter.Targets[emitter.ActiveTarget]
	return target

## Get the Aim Angle from an object to a target
func GetObjectAim(from: Node, to:Node, Use3D:bool=false, UseXZ:bool=false) -> float:
	var angle = 0
	if Use3D:
		var pos = from.global_position
		var tar = (to as Node3D).global_position
		if UseXZ: angle = Vector2(pos.x, pos.z).angle_to_point(Vector2(tar.x, tar.z))
		else: angle = Vector2(pos.x, pos.y).angle_to_point(Vector2(tar.x, tar.y))
	else: angle = from.global_position.angle_to_point((to as Node2D).global_position)
	return angle
