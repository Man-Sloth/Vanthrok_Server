extends Node

var world_state = {}

func _physics_process(_delta):
	if !get_parent().player_state_collection.is_empty():
		world_state = get_parent().player_state_collection.duplicate(true)
		for player in world_state.keys():
			world_state[player].erase("T")
		world_state["T"] = (Time.get_unix_time_from_system() * 1000)
		world_state["Enemies"] = get_node("../Map").enemy_list
		# Verifications
		# Anti-Cheat
		# cuts (chunking / maps)
		# physics checks
		# Anything else
		get_parent().SendWorldState(world_state)
