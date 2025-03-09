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
	
func GenerateSalt():
	randomize()
	var salt = str(randi()).sha256_text()
	print ("Salt: " + salt)
	return salt

func GenerateHashedPassword(password, salt):
	print(str((Time.get_unix_time_from_system() * 1000)))
	var hashed_password = password
	var rounds = pow(2,18) #pow(2,18) = 262144 times longer to brute force
	print("hashed password as input: " + hashed_password)
	while rounds > 0:
		hashed_password = (hashed_password + salt).sha256_text()
		#print("password @ round: " + str(rounds) + " is: " + hashed_password)
		rounds -= 1
	print("final hashed password: " + hashed_password)
	print(str((Time.get_unix_time_from_system() * 1000)))
	return hashed_password
	
@rpc("any_peer", "call_remote", "reliable")
func S_AuthenticatePlayer(username, password, player_id):
	print("Authentication request received")
	var gateway_id = multiplayer.get_remote_sender_id()
	var token
	var result
	var hashed_password
	print("Starting authentication")
	
	if !PlayerData.PlayerIDs.has(username):
		print("User not recognized")
		result = false
	else:
		var retrieved_salt = PlayerData.PlayerIDs[username].Salt
		hashed_password = GenerateHashedPassword(password, retrieved_salt)
		if !PlayerData.PlayerIDs[username].Password == hashed_password:
			print ("Incorrect password")
			result = false
		else:
			print("Successful authentication")
			result = true
			
			randomize()
			token = str(randi()).sha256_text() + str((Time.get_unix_time_from_system() * 1000))
			var gameserver = "GameServer1" #This will need to be replaced with a load balancer for multiple game servers
			GameServers.DistributeLoginToken(token, gameserver,username)
	
	print("Authentication result sent to gateway server")
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)
	
@rpc("any_peer", "call_remote", "reliable")
func S_CreateAccount(username, password, player_id):
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	var message
	if PlayerData.PlayerIDs.has(username):
		result = false
		message = 2
	else:
		result = true
		message = 3
		var salt = GenerateSalt()
		var hashed_password = GenerateHashedPassword(password, salt)
		PlayerData.PlayerIDs[username] = {"Password": hashed_password, "Salt": salt}
		PlayerData.SavePlayerIDs()
		
	rpc_id(gateway_id, "CreateAccountResults", result, player_id, message)

@rpc("any_peer", "call_remote", "reliable")
func AuthenticatePlayer(username, password, player_id):
	pass	
	
@rpc("any_peer", "call_remote", "reliable")
func AuthenticationResults(result, player_id, token):
	pass

@rpc("any_peer", "call_remote", "reliable")
func CreateAccount(username, password, player_id):
	pass

@rpc("any_peer", "call_remote", "reliable")
func CreateAccountResults(result, player_id, message):
	pass
