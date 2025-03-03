extends Node

@onready var main_interface = get_parent()
const PLAYER_CONTAINER_SCENE = preload("res://Scenes/Instances/PlayerContainer.tscn")

var awaiting_verification = {}

func start(player_id):
	awaiting_verification[player_id] = {"Timestamp": (Time.get_unix_time_from_system() * 1000)}
	main_interface.S_FetchToken(player_id)
	
func Verify(player_id, token):
	var token_verification = false
	while (Time.get_unix_time_from_system() * 1000) - int(token.right(-64)) <= 30000:
		if main_interface.expected_tokens.has(token):
			token_verification = true
			CreatePlayerContainer(player_id)
			awaiting_verification.erase(player_id)
			main_interface.expected_tokens.erase(token)
			break
		else:
			await get_tree().create_timer(2).timeout
	main_interface.S_ReturnTokenVerificationResults(player_id, token_verification)
	if token_verification == false: #Make sure people are disconnected
		awaiting_verification.erase(player_id)
		main_interface.network.disconnect_peer(player_id)

func _on_verification_expiration_timeout():
	var current_time = (Time.get_unix_time_from_system() * 1000)
	var start_time
	if awaiting_verification == {}:
		pass
	else:
		#key = player ids
		for key in awaiting_verification.keys():
			start_time = awaiting_verification[key].Timestamp
			if current_time - start_time >= 30000:
				awaiting_verification.erase(key)
				var connected_peers = Array(multiplayer.get_peers())
				if connected_peers.has(key):
					main_interface.S_ReturnTokenVerificationResults(key, false)
					main_interface.network.disconnect_peer(key)
	print("Awaiting verification:")
	print(awaiting_verification)

func CreatePlayerContainer(player_id):
	var new_player_container = PLAYER_CONTAINER_SCENE.instantiate()
	new_player_container.name = str(player_id)
	get_node("../WorldMap/Chunk 1/Players").add_child(new_player_container, true)
	var player_container = get_node("../WorldMap/Chunk 1/Players/" + str(player_id))
	FillPlayerContainer(player_container)
	
func FillPlayerContainer(player_container):
	print("Setting player stats")
	player_container.player_stats = ServerData.test_data.Stats


