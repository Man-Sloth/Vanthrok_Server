extends Node

var network = ENetMultiplayerPeer.new()
var gateway_api = MultiplayerAPI.create_default_interface()
var port = 1910
var max_players = 100

func _ready():
	StartServer()
	
func _process(delta):
	if !multiplayer.has_multiplayer_peer():
		return
	multiplayer.poll()
	
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_multiplayer(gateway_api)
	multiplayer.set_root_node(self)
	multiplayer.multiplayer_peer = network
	print("Gateway server started")
	
	multiplayer.peer_connected.connect(_Peer_Connected)
	multiplayer.peer_disconnected.connect(_Peer_Disconnected)
	
func _Peer_Connected(player_id):
	print("User " + str( player_id) + " Connected")
	
func _Peer_Disconnected(player_id):
	print("User " + str(player_id) + " Disconnected")
	
@rpc ("any_peer", "call_remote", "reliable")
func LoginRequest(username, password):
	pass
	
func ReturnLoginRequest(result, player_id):
	pass
