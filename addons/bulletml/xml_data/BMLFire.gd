class_name BMLFire extends BMLBaseType
var direction: float = 0
var dir_type: BMLBaseType.EDirectionType
var speed: float = 1
var bullet: BMLBullet
# According to BulletML Spec, Fires don't have actions
# var action: BMLAction