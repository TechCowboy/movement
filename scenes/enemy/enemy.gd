extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const VECTOR_LENGTH = 50

# Range for each of the variables below is
# 0.0 to 1.0
# For example, as anim_walking reaches 1.0 
# the previous animation is blended away.

var anim_walking:float 	= 0.0
var anim_turn:float		= 0.0
var anim_pursue:float	= 0.0
var anim_search:float	= 0.0
var anim_attack:float	= 0.0
var blend_speed:float	= 15.0

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AuxScene2/AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

enum State {IDLE, WAITNG_TO_MOVE, MOVE}

var state = State.IDLE
var idle_wait_time = 10
var idle_wait_time_count = 0
var nav_map = null

func _ready() -> void:
	nav_map = navigation_agent_3d.get_navigation_map()
	idle_wait_time_count = 0

func update_animation():
	animation_tree["parameters/attack/blend_amount"]	= anim_attack
	animation_tree["parameters/pursue/blend_amount"] 	= anim_pursue
	animation_tree["parameters/search/blend_amount"] 	= anim_search
	animation_tree["parameters/turn/blend_amount"] 		= anim_turn
	animation_tree["parameters/walk/blend_amount"] 		= anim_walking

func change_state(new_state):
	if new_state != state:
		match (new_state):
			State.IDLE:
				print(name + ": IDLE")
			State.WAITNG_TO_MOVE:
				print(name + ": WAITNG_TO_MOVE")			
			State.MOVE:
				print(name + ": MOVE")
			_:
				print(name + ": Unknown")
	
		state = new_state
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
	match (state):
		State.IDLE:

			_on_idle(delta)
			
				
		State.WAITNG_TO_MOVE:
			_on_waiting_to_move(delta)
			
		State.MOVE:

			_on_move(delta)

		_:
			print("Unknown")
							

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	update_animation()
	move_and_slide()
	
# As we go into the idle state,
# stop moving and blend to the standing state
	
func _on_idle(delta):
	velocity = Vector3.ZERO
	idle_wait_time_count = idle_wait_time
	change_state(State.WAITNG_TO_MOVE)
	
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)


# As we wait to move
# continue to blend to the desired state
# Now determine a random place to go to
# This could be inside a wall, so change the position
# so it's "safe"
		
func _on_waiting_to_move(delta):
	idle_wait_time_count -= delta
	
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)
	
	if idle_wait_time_count <= 0:
	
		var raw_target = get_new_target_location()		
		var safe_target = NavigationServer3D.map_get_closest_point(nav_map, raw_target)
		navigation_agent_3d.target_position = safe_target
		change_state(State.MOVE)	


#  Let's get walking
# move to the appropriate place.
# as we move, look at the new waypoint

func _on_move(delta):
	var current_position = global_transform.origin
	var next_position = navigation_agent_3d.get_next_path_position()

	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,1.0, blend_speed*delta)

	look_at(next_position)
	var direction = (next_position - current_position).normalized()
	velocity = direction * SPEED
	
# get a random place on the map

func get_new_target_location():
	var offset_x = randf_range(0.5, VECTOR_LENGTH) * (-1.0 if randf() < 0.5 else 1.0)
	var offset_z = randf_range(0.5, VECTOR_LENGTH) * (-1.0 if randf() < 0.5 else 1.0)
	return global_transform.origin + Vector3(offset_x, 0, offset_z)

# If we reach our destination, set our state to IDLE

func _on_navigation_agent_3d_target_reached() -> void:
	
	change_state(State.IDLE)
