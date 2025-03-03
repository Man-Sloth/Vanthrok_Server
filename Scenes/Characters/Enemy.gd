extends CharacterBody2D

const SPEED = 8000.0
@onready var nav_agent= $NavigationAgent2D
@export var target: Node2D = null

func _ready():
	call_deferred("seeker_setup")

func seeker_setup():
	await get_tree().physics_frame
	if target:
		nav_agent.target_position = target.global_position

func _physics_process(delta):

	if target != null:

		if (target.global_position - position).length() >= nav_agent.target_desired_distance:
			makepath()
		
		var is_at_target_desired_distance : bool = (position.distance_to(nav_agent.target_position) - nav_agent.target_desired_distance) <= 0.0
		if is_at_target_desired_distance:
			return
		
		makepath()
		var current_agent_position = position
		var next_path_position = nav_agent.get_next_path_position()
		var new_velocity = current_agent_position.direction_to(next_path_position) * SPEED * delta

		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(new_velocity)
		move_and_slide()
	

func makepath() -> void:
	nav_agent.target_position = target.global_position

func MoveEnemy(new_position):
	set_position(new_position)

func _on_aggro_body_body_entered(body):
	if body.is_in_group("Players"):
		target = body
		nav_agent.target_position = target.global_position

func _on_aggro_body_body_exited(body):
	if body.is_in_group("Players"):
		target = body
		nav_agent.target_position = target.global_position


func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity


