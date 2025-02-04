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
func AuthenticationResults(result, player_id, token):
	print("results received and replying to player login request")
	Gateway.S_ReturnLoginRequest(result, player_id, token)
	
@rpc("any_peer", "call_remote", "reliable")
func CreateAccount(username, password, player_id):
	print("Sending out create account request")
	rpc_id(1, "S_CreateAccount", username, password, player_id)
	
@rpc("any_peer", "call_remote", "reliable")
func CreateAccountResults(result, player_id, message):
	print("Results received and replying to player create account request")
	Gateway.S_ReturnCreateAccount(result, player_id, message)
	
@rpc("any_peer", "call_remote", "reliable")
func S_AuthenticatePlayer(username, password, player_id):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func S_CreateAccount(username, password, player_id):
	pass
