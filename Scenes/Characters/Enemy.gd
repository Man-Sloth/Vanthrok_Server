extends CharacterBody2D

const SPEED = 8000.0
@onready var nav_agent= $NavigationAgent2D
const DYNAMIC_BAKE = preload("res://Scenes/Chunks/dynamic_bake.tscn")
@onready var nav_region = $"../../NavigationRegion2D"
@export var target: Node2D = null
enum dir {N, E, W, S, NE, SE, SW, NW}
enum {SURROUND, ATTACK, HIT}
var facing = dir.S

var state = SURROUND
var rand_num
var circle_target
var target_set = false
var swarm = false
var bake_timer = 0.0
var facing_timer: float = 0.0
var next_facing: int = 3
var idle = false

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
		if !nav_agent.is_target_reachable():
			nav_agent.target_position = position

		var is_at_target_desired_distance : bool = (position.distance_to(nav_agent.target_position) - nav_agent.target_desired_distance) <= 0.0
		if is_at_target_desired_distance:
			if !idle:
				bake_timer += delta
				if bake_timer >= 1.0:
					idle = true
					var bake = DYNAMIC_BAKE.instantiate()
					add_child(bake)
					nav_region.bake = true
					bake_timer = 0
					nav_agent.target_desired_distance = 250
			return
		else:
			if idle:
				get_node("DynamicBake").queue_free()
				nav_region.bake = true
				nav_agent.target_desired_distance = 100
				idle = false
			bake_timer = 0

		var current_agent_position = position
		var next_path_position = nav_agent.get_next_path_position()
		var new_velocity = current_agent_position.direction_to(next_path_position) * SPEED * delta
		
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(new_velocity)
		
		find_facing(delta)
		move_and_slide()
	else:
		nav_agent.target_position = position

func find_facing(delta):
	var dirX = velocity.normalized().x
	var dirY = velocity.normalized().y
	
	if dirX > 0:
		if abs(abs(dirY) - dirX) < 0.5:
			if dirY > 0:
				next_facing = dir.SE
			else:
				next_facing = dir.NE
		elif dirX > abs(dirY):
			next_facing= dir.E	
		else:
			if dirY > 0:
				next_facing = dir.S
			else:
				next_facing = dir.N
	else:
		if abs(abs(dirY) - abs(dirX)) < 0.5:
			if dirY > 0:
				next_facing = dir.SW
			else:
				next_facing = dir.NW
		elif abs(dirX) > abs(dirY):
			next_facing = dir.W
		else:
			if dirY > 0:
				next_facing= dir.S
			else:
				next_facing = dir.N
	if facing != next_facing:
		facing_timer += delta
		if facing_timer >= 0.2:
			facing = next_facing
			facing_timer = 0
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


func _on_enemy_body_body_entered(body):
	if target:
		if body == target.get_node("PlayerBody"):
			swarm = true


func _on_enemy_body_body_exited(body):
	if target:
		if body == target.get_node("PlayerBody"):
			swarm = false


func _on_enemy_body_area_entered(area):
	if target:
		if area == target.get_node("PlayerBody"):
			swarm = true


func _on_enemy_body_area_exited(area):
	if target:
		if area == target.get_node("PlayerBody"):
			swarm = false
			target_set = false
