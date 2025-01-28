extends Node

var network = ENetMultiplayerPeer.new()
var ip = "127.0.0.1"
var port = 1911

func _ready():
	ConnectToServer()
	
func ConnectToServer():
	network.create_client(ip, port)
	multiplayer.multiplayer_peer = network
	
	multiplayer.peer_disconnected.connect(_OnConnectionFailed)
	multiplayer.peer_connected.connect(_OnConnectionSucceeded)
	
func _OnConnectionFailed():
	print("Failed to connect to authentication server")
	
func _OnConnectionSucceeded():
	print("Succesfully connected to authentication server")
	
func AuthenticatePlayer(username, password, player_id):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func AuthenticationResults(result, player_id):
	pass
	
	
