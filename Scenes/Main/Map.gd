extends Node

var enemy_id_counter = 1
var enemy_maximum = 10
var enemy_types = ["SK", "RA"] # List of enemies that can spawn on the map
@export var enemy_spawn_points = [Vector2(-350,0), Vector2(-250, -500), Vector2(500, 500), Vector2(500, 600), Vector2(500, 700), Vector2(500, 800), Vector2(500, 900), Vector2(500, 1000), Vector2(500, 400), Vector2(500, 300)]#List of positions an enemy can spawn at
var open_locations = [0,1,2,3,4,5,6,7,8,9]
var occupied_locations = {}
var enemy_list = {}


func _ready():
	var timer = Timer.new()
	timer.wait_time = 3
	timer.autostart = true
	timer.timeout.connect(SpawnEnemy)
	self.add_child(timer)
	
	
func _physics_process(delta):
	for enemy in enemy_list:
		#if get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy)):
		if enemy_list[enemy]["S"] != "D":
			var physical_enemy = get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy))
			if physical_enemy:
				enemy_list[enemy]["L"].x = physical_enemy.position.x
				enemy_list[enemy]["L"].y = physical_enemy.position.y
				enemy_list[enemy]["A"] = physical_enemy.facing
				
		
func SpawnEnemy():
	if enemy_list.size() >= enemy_maximum:
		pass # Maximum enemies already on map
	else:
		randomize()
		var type = enemy_types[randi() % enemy_types.size()]
		var rng_location_index = randi() % open_locations.size()
		var location = enemy_spawn_points[open_locations[rng_location_index]]
		occupied_locations[enemy_id_counter] = open_locations[rng_location_index]
		open_locations.remove_at(rng_location_index)
		#								Type,		location,	health,	max health, state: idle, time out, animation/facing
		enemy_list[enemy_id_counter] = {"T": type, "L": location, "H": 100, "MH": 100, "S": "I", "TO": 1, "A": 3}
		get_parent().get_node("WorldMap").SpawnEnemy(enemy_id_counter, location)
		enemy_id_counter += 1
	
	for enemy in enemy_list.keys():
		if enemy_list[enemy]["S"] == "D":
			if enemy_list[enemy]["TO"] == 0:
				enemy_list.erase(enemy)
			else:
				enemy_list[enemy]["TO"] = enemy_list[enemy]["TO"] - 1
		
func NPCHit(enemy_id, damage_type, player_id):
	if enemy_list[enemy_id]["H"] <= 0:
		pass
	else:
		if damage_type == "P":
			enemy_list[enemy_id]["H"] = enemy_list[enemy_id]["H"] - 20
			if enemy_list[enemy_id]["H"] <= 0:
				get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy_id)).queue_free()
				enemy_list[enemy_id]["S"] = "D"
				open_locations.append(occupied_locations[enemy_id])
				occupied_locations.erase(enemy_id)
				var xp_amount = 100
				get_parent().Return_XP(player_id, xp_amount)
