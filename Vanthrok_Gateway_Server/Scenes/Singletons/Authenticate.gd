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
	
func _OnConnectionFailed(_id):
	print("Failed to connect to authentication server")
	
func _OnConnectionSucceeded(_id):
	print("Succesfully connected to authentication server")

@rpc("any_peer", "call_remote", "reliable")
func AuthenticatePlayer(username, password, player_id):
	print("Sending out authentication request")
	rpc_id(1, "S_AuthenticatePlayer", username, password, player_id)
	
@rpc("any_peer", "call_remote", "reliable")
func AuthenticationResults(result, player_id):
	print("results received and replying to player login request")
	Gateway.S_ReturnLoginRequest(result, player_id)
	
@rpc("any_peer", "call_remote", "reliable")
func S_AuthenticatePlayer(username, password, player_id):
	pass
	
