extends KinematicBody
onready var spawner = get_node("/root/world/Boids")
# Starting velocity and acceleratin
onready var velocity = Vector3(rand_range(0,MAX_SPEED), rand_range(0,MAX_SPEED), rand_range(0,MAX_SPEED))
var acceleration 

# Finite State Machine
enum State {IDLE, FLY_TOWARDS, EATING, EATING_COOLDOWN, SCARED}
var cur_state = State.IDLE # Initial State
enum Transition {DETECT_FOOD, FLY_TIMEOUT, ON_FOOD, DONE_EATING, HUNGRY, PLAYER_NEAR, SCARE_TIMEOUT}
var cur_transition = Transition.HUNGRY
var Table = [[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0]]

# Boid Parameters
const MAX_RANGE = 80  # range relative to Boids origin
const MAX_HEIGHT = 50 # height relative to Boids origin
const MAX_DEPTH = -35  # depth relative to Boids origin
const MAX_SPEED = 30
const MIN_SPEED = 24

var separation_distance = 4
var alignment_rate = 6
var cohesion_rate = 1/12

var on_cooldown = false

# Reference
onready var ground_level = -spawner.translation.y + 0.5
onready var target = Vector3(0,0,0) - spawner.translation
onready var eat_timer = $EatTimer
onready var eat_cooldown = $EatCooldown
onready var fly_towards_timer = $FlyTowardsTimer
onready var scared_timer = $ScaredTimer


func _ready():
	# Transition table initialization
	# each state has every transition pointing to itself
	for state in State.values():
		for transition in Transition.values():
			Table[state][transition] = state
	# Now apply the more interesting connections
	Table[State.IDLE][Transition.DETECT_FOOD] = State.FLY_TOWARDS
	Table[State.FLY_TOWARDS][Transition.FLY_TIMEOUT] = State.EATING_COOLDOWN
	Table[State.FLY_TOWARDS][Transition.ON_FOOD] = State.EATING
	Table[State.EATING][Transition.DONE_EATING] = State.EATING_COOLDOWN
	Table[State.EATING][Transition.PLAYER_NEAR] = State.SCARED
	Table[State.EATING_COOLDOWN][Transition.HUNGRY] = State.IDLE
	Table[State.SCARED][Transition.SCARE_TIMEOUT] = State.IDLE
	
	# Random eating time bewtween 10 and 20 seconds
	var rand_num = (randi()%11) + 10
	eat_timer.wait_time = rand_num
	eat_cooldown.wait_time = rand_num

func state_update():
	cur_state = Table[cur_state][cur_transition]

func state_output(cur_state):
	var v1; var v2; var v3; var v4; var v5
	match cur_state:
		State.IDLE:
			v1 = separation()
			v2 = alignment()
			v3 = cohesion()
			v4 = bound_position()
			acceleration = v1 + v2 + v3 + v4
		State.FLY_TOWARDS:
			v4 = bound_position()
			v5 = go_to_target(target)
			acceleration = v4 + v5
		State.EATING:
			translation.y = ground_level + 0.3
			acceleration = Vector3(0,0,0)
			velocity = Vector3(0,0,0)
		State.EATING_COOLDOWN:
			v1 = separation()
			v2 = alignment()
			v3 = cohesion()
			v4 = bound_position()
			acceleration = v1 + v2 + v3 + v4
		State.SCARED:
			v1 = separation()
			v2 = alignment()
			v3 = cohesion()
			v4 = bound_position()
			acceleration = v1 + v2 + v3 + v4


func _physics_process(delta):
	state_update()
	state_output(cur_state)
	velocity += acceleration*delta
	
	if velocity.length()!= 0:
		limit_velocity()
		move_and_slide(velocity)

func _process(delta):
	look_at(velocity + acceleration*delta, Vector3(0,1,0))
	#print("look at")

func separation():
	var adjustment = Vector3(0,0,0)
	for boid in spawner.boidArray:
		if boid != self:
			if abs((boid.translation - self.translation).length()) < separation_distance:
				adjustment -= (boid.translation - self.translation)
	return adjustment

func alignment():
	var adjustment = Vector3(0,0,0)
	for boid in spawner.boidArray:
		if boid != self:
			adjustment += boid.velocity
	
	adjustment = adjustment / (spawner.boidArray.size() - 1)
	
	return ((adjustment - self.velocity)/alignment_rate)

func cohesion():
	var adjustment = Vector3(0,0,0)
	for boid in spawner.boidArray:
		if boid != self:
			adjustment += boid.translation
	
	adjustment = adjustment / (spawner.boidArray.size() - 1)
	
	return ((adjustment - self.translation)*cohesion_rate)

func limit_velocity():
	if velocity.length() > MAX_SPEED:
		velocity = (velocity / velocity.length()) * MAX_SPEED
	elif velocity.length() < MIN_SPEED:
		velocity = (velocity / velocity.length()) * MIN_SPEED

func bound_position():
	var coords = Vector2(translation.x,translation.y)
	if translation.y > MAX_HEIGHT || translation.y < MAX_DEPTH:
		return (Vector3(0,-translation.y/2,0))
	elif abs(translation.x) > MAX_RANGE:
		var x = -translation.normalized().x * (abs(translation.x) - MAX_RANGE)/2
		return Vector3(x,0,0)
	elif abs(translation.z) > MAX_RANGE:
		var z = -translation.normalized().z * (abs(translation.z) - MAX_RANGE)/2
		return Vector3(0,0,z)
	else: 
		return Vector3(0,0,0)

func go_to_target(target):
	return (target - translation)*3

func _on_EatTimer_timeout(): # when the boid is done eating
	cur_transition = Transition.DONE_EATING
	eat_cooldown.start()
	on_cooldown = true
	#print("Perch_timeout")

func _on_EatCooldown_timeout(): # when the boid is hungry again
	cur_transition = Transition.HUNGRY
	on_cooldown = false
	#print("COooldownnnn")

func _on_FlyTowardsTimer_timeout(): # When the boid is in the FLY_TO state for 6 seconds
	cur_transition = Transition.FLY_TIMEOUT
	eat_cooldown.start()
	on_cooldown = true

func _on_ScaredTimer_timeout(): # when the boid is not scared anymore (after 3 seconds)
	cur_transition = Transition.SCARE_TIMEOUT
