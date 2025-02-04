extends Node

var network = ENetMultiplayerPeer.new()
var gateway_api = SceneMultiplayer.new()
var port = 1910
var max_players = 100

var cert = load("res://Certificate/X509_Certificate.crt")
var key = load("res://Certificate/x509_Key.key")

func _ready():
	StartServer()
	
func _process(_delta):
	if !multiplayer.has_multiplayer_peer():
		return
	multiplayer.poll()
	
func StartServer():
	network.create_server(port, max_players)
	network.host.dtls_server_setup(TLSOptions.server(key, cert))
	get_tree().set_multiplayer(gateway_api, get_path())
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
	#network.disconnect_peer(player_id) #Call after Result is successfully returned
	
@rpc ("any_peer", "call_remote", "reliable")
func CreateAccount(username, password):
	var player_id = multiplayer.get_remote_sender_id()
	var valid_request = true
	if username == "":
		valid_request = false
	if password == "":
		valid_request = false
	if password.length() <= 6:
		valid_request = false
	
	if valid_request == false:
		S_ReturnCreateAccount(valid_request,player_id, 1)
	else:
		Authenticate.CreateAccount(username, password, player_id)

@rpc ("any_peer", "call_remote", "reliable")
func S_ReturnCreateAccount(result, player_id, message):
	rpc_id(player_id, "ReturnCreateAccount", result, message)
	#1 = failed to create, 2 = existing username, 3 = welcome
	#network.disconnect_peer(player_id) #Call after Result is successfully returned

@rpc("any_peer", "call_remote", "reliable")
func SafeDisconnect():
	var player_id = multiplayer.get_remote_sender_id()
	network.disconnect_peer(player_id)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnLoginRequest(result, token):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func RequestLogin():
	pass

@rpc("any_peer", "call_remote", "reliable")
func ReturnCreateAccount(result, message):
	pass

@rpc("any_peer", "call_remote", "reliable")
func RequestCreateAccount():
	pass
