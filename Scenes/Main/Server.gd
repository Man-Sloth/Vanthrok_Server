extends Node

var network = ENetMultiplayerPeer.new()
const port = 4830
const max_players = 100
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var players = {}
var player_info = {"name": "Name"}
var players_loaded = 0

func _ready():
	StartServer()
	
func StartServer():
	#multiplayer.multiplayer_peer = null  #Terminates network
	#get_tree().set_network_peer(network)
	network.create_server(port, max_players)
	multiplayer.multiplayer_peer = network
	print("Server started")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	print("User: " + str(id) + " Connected")
	
func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)
	print("User: " + str(id) + " Disconnected")
	
@rpc("any_peer", "reliable")
func ReturnPlayerStats(stats, requester):
	pass
	
@rpc("any_peer", "reliable")	
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

@rpc("any_peer", "reliable")
func S_FetchPlayerStats(player_stats, requester):
	var player_id = multiplayer.get_remote_sender_id()
	var stats = get_node("PlayerStats").S_FetchPlayerStats(player_stats)
	rpc_id(player_id, "ReturnPlayerStats", stats, requester)


