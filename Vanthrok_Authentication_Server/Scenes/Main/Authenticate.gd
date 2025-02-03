extends Node

var network = ENetMultiplayerPeer.new()
var port = 1911
var max_servers = 5

func _ready():
	StartServer()
	
func StartServer():
	network.create_server(port, max_servers)
	multiplayer.multiplayer_peer = network
	print("Authentication server started")
	
	multiplayer.peer_connected.connect(_Peer_Connected)
	multiplayer.peer_disconnected.connect(_Peer_Disconnected)
	
func _Peer_Connected(gateway_id):
	print("Gateway: " + str(gateway_id) + " Connected")
	
func _Peer_Disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " Disconnected")
	
@rpc("any_peer", "call_remote", "reliable")
func S_AuthenticatePlayer(username, password, player_id):
	print("Authentication request received")
	var token
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	print("Starting authentication")
	
	if !PlayerData.PlayerIDs.has(username):
		print("User not recognized")
		result = false
	elif !PlayerData.PlayerIDs[username].Password == password:
		print ("Incorrect password")
		result = false
	else:
		print("Successful authentication")
		result = true
	
	randomize()
	var random_number = randi()
	print("Random Number: " + str(random_number))
	var hashed = str(random_number).sha256_text()
	print("Hashed: " + str(hashed))
	var timestamp = str(Time.get_ticks_msec())
	print("TimeStamp: " + str(timestamp))
	token = hashed + timestamp
	print("Token: " + str(token))
	var gameserver = "GameServer1"
	GameServers.DistributeLoginToken(token, gameserver)
	
	
	print("Authentication result sent to gateway server")
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)
	

@rpc("any_peer", "call_remote", "reliable")
func AuthenticatePlayer(username, password, player_id):
	pass	
	
@rpc("any_peer", "call_remote", "reliable")
func AuthenticationResults(result, player_id, token):
	pass

