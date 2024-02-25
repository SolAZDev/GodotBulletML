class_name BMLBullet extends BMLBaseType
var speed: float = 1
var action: BMLAction

# Extended
## Optional Damage that a bullet can give to the player
var damage: int = 1
## Lifetime of the Bullet. Default is 60 seconds.
var lifetime: float = 10

# Methods
func clone() -> BMLBullet:
	var new_bullet = BMLBullet.new() 
	new_bullet.label = label
	new_bullet.ref = ref
	new_bullet.parent = parent
	new_bullet.host = host 
	new_bullet.speed = speed
	new_bullet.action = action
	new_bullet.damage = damage
	new_bullet.lifetime = lifetime
	return new_bullet
