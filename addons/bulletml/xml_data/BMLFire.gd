class_name BMLFire extends BMLBaseType
var direction: float = 0
var dir_type: BMLBaseType.EDirectionType
var speed: float
var bullet: BMLBullet
# According to BulletML Spec, Fires don't have actions
# var action: BMLAction
#duplicate(true) not working need to manula implement
func clone():
	var new_fire = BMLFire.new()
	new_fire.label = label
	new_fire.ref = ref
	new_fire.parent = parent
	new_fire.host = host 
	new_fire.direction = direction
	new_fire.dir_type = dir_type
	new_fire.speed = speed
	new_fire.bullet = bullet
	return new_fire
