extends Node

var network = ENetMultiplayerPeer.new()
var gateway_api = SceneMultiplayer.new()
var port = 1910
var max_players = 100

func _ready():
	StartServer()
	
func _process(_delta):
	if !multiplayer.has_multiplayer_peer():
		return
	multiplayer.poll()
	
func StartServer():
	network.create_server(port, max_players)
	var path = "/root/"
	get_tree().set_multiplayer(gateway_api, get_path())
	#multiplayer.set_root_node(self)
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
	print("Login request recieved")
	var player_id = multiplayer.get_remote_sender_id()
	Authenticate.AuthenticatePlayer(username, password, player_id)

@rpc ("any_peer", "call_remote", "reliable")
func S_ReturnLoginRequest(result, player_id, token):
	rpc_id(player_id, "ReturnLoginRequest", result, token)
	#network.disconnect_peer(player_id)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnLoginRequest(results, token):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func RequestLogin():
	pass
