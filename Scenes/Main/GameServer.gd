extends Node

var network = ENetMultiplayerPeer.new()
const port = 4830
const max_players = 100

const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
@onready var player_verification_process = $PlayerVerification
@onready var combat_functions = $Combat

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var expected_tokens = []
var player_state_collection = {}

var players = {}
var player_info = {"name": "Name"}
var players_loaded = 0
var start_time = 0
var tod = 0
var tod_ratio = 12
var tod_image = 0
var last_image = 0

func _ready():
	StartServer()
	start_time = Time.get_unix_time_from_system()
	tod = (Time.get_unix_time_from_system() - start_time) / tod_ratio
	tod_image = int(tod/360)
	
func _process(_delta):
	# 360 day cycle pictures per 2 hours
	tod = (Time.get_unix_time_from_system() - start_time) * tod_ratio
	tod_image = int(tod/360)
	if tod_image>= 360:
		start_time = Time.get_unix_time_from_system()
		tod_image = 0
	
	if tod_image != last_image:
		SendTOD(tod_image, 0)
	
	last_image = tod_image
	
	
func StartServer():
	#multiplayer.multiplayer_peer = null  #Terminates network
	network.create_server(port, max_players)
	multiplayer.multiplayer_peer = network
	print("Game Server started")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _on_player_connected(player_id):
	#_register_player.rpc_id(id, player_info)
	print("User: " + str(player_id) + " Connected")
	player_verification_process.start(player_id)
	SendTOD(tod_image, player_id)
	
func _on_player_disconnected(player_id):
	print("User: " + str(player_id) + " Disconnected")
	if has_node(str(player_id)):
		get_node(str(player_id)).queue_free()
		player_state_collection.erase(player_id)
		rpc_id(0, "DespawnPlayer", player_id)
	
func _on_token_expiration_timeout():
	var current_time = (Time.get_unix_time_from_system() * 1000)
	var token_time
	if expected_tokens == []:
		pass
	else:
		for i in range(expected_tokens.size() -1, -1, -1):
			token_time = int(expected_tokens[i].right(64))
			if current_time - token_time >= 30000:
				expected_tokens.remove(i)
	print("Expected Tokens:")
	print(expected_tokens)

func S_FetchToken(player_id):
	rpc_id(player_id, "FetchToken")

func SendWorldState(world_state):
	rpc_id(0, "ReceiveWorldState", world_state)

func SendTOD(new_tod_image, player_id):
	rpc_id(player_id, "ReceiveTOD", new_tod_image)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnToken(token):
	var player_id = multiplayer.get_remote_sender_id()
	player_verification_process.Verify(player_id, token)

@rpc ("any_peer", "call_remote", "reliable")
func S_ReturnTokenVerificationResults(player_id, result):
	rpc_id(player_id, "ReturnTokenVerificationResults", result)
	if result == true:
		rpc_id(0, "SpawnNewPlayer", player_id, Vector2(50, 50))
	
@rpc("any_peer", "reliable")	
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

@rpc("any_peer", "reliable")
func S_FetchSkillDamage(skill_name, requester):
	var player_id = multiplayer.get_remote_sender_id()
	var damage = combat_functions.FetchSkillDamage(skill_name, player_id)
	rpc_id(player_id, "ReturnSkillDamage", damage, requester)
	
@rpc("any_peer", "reliable")
func S_FetchPlayerStats():
	var player_id = multiplayer.get_remote_sender_id()
	var stats = get_node(str(player_id)).player_stats
	rpc_id(player_id, "ReturnPlayerStats", stats)
	
@rpc("any_peer", "call_remote", "unreliable")
func ReceivePlayerState(player_state):
	var player_id = multiplayer.get_remote_sender_id()
	if player_state_collection.has(player_id):
		if player_state_collection[player_id]["T"] < player_state["T"]:
			player_state_collection[player_id] = player_state
	else:
		player_state_collection[player_id] = player_state
		
@rpc ("any_peer", "call_remote", "reliable")
func FetchServerTime(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(player_id, "ReturnServerTime", (Time.get_unix_time_from_system()*1000), client_time)

@rpc("any_peer", "call_remote", "reliable")
func S_DetermineLatency(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(player_id, "ReturnLatency", client_time)
	
@rpc ("any_peer", "call_remote", "reliable")
func SendNPCHit(enemy_id, damage):
	get_node("Map").NPCHit(enemy_id, damage)
	
@rpc ("any_peer", "call_remote", "reliable")
func Attack(facing, spawn_time): #spawn time for projectiles
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(0, "ReceiveAttack", facing, spawn_time, player_id)

	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveAttack(facing, spawn_time, id): #spawn time for projectiles
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnPlayerStats(stats):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnTokenVerificationResults(result):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func FetchToken():
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func SpawnNewPlayer(player_id, spawn_position):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func DespawnPlayer(player_id):
	pass

@rpc("any_peer", "call_remote", "unreliable")
@warning_ignore("unused_parameter")
func ReceiveWorldState(world_state):
	pass

@rpc("any_peer", "call_remote", "unreliable")
@warning_ignore("unused_parameter")
func SendPlayerState(player_state):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnServerTime(server_time, client_time):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnLatency(client_time):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveTOD(tod_index):
	pass
