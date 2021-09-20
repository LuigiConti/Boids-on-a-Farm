extends Spatial
class_name Spawner

export var population:int = 75
const MAX_RANGE = 30

var boidArray = []
var boidNodes = []


onready var BoidScene = load("res://Boid.tscn")

func _ready():
	initialize_boids()

func initialize_boids():
	for i in population:
		var magnitude = rand_range(-MAX_RANGE, MAX_RANGE)
		var spawn_vector = magnitude * Vector3(rand_range(-1,1), rand_range(-1,1), rand_range(-1,1)).normalized()
		var boid = BoidScene.instance()
		boid.translation = spawn_vector
		boidArray.append(boid)
		add_child(boid)
		#print("SPAWNED BOID", i)
