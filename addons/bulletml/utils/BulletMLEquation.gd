class_name BulletMLEquation

var gRandom: RandomNumberGenerator

func _init():
	gRandom = RandomNumberGenerator.new()
	gRandom.randomize()

func RandomValue() -> float:
	return gRandom.randf()
	
