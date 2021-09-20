extends RigidBody

onready var spawner = get_node("/root/world/Boids")

func _on_Detection_Area_body_entered(body):
	if body.is_in_group("Boid"):
		body.cur_transition = body.Transition.DETECT_FOOD
		body.fly_towards_timer.start()

func _on_Perch_Area_body_entered(body):
	if body.is_in_group("Boid"):
		body.cur_transition = body.Transition.ON_FOOD
		body.eat_timer.start()
