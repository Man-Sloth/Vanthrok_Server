extends Node

var network = ENetMultiplayerPeer.new()
var gateway_api = SceneMultiplayer.new()
var port = 1912
var max_players = 100

var gameserverlist = {}

func _ready():
	StartServer()

func _process(delta):
	if !multiplayer.has_multiplayer_peer():
		return
	multiplayer.poll()
	
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_multiplayer(gateway_api, get_path())
	multiplayer.multiplayer_peer = network
	print("GameServerHub started")
	
	multiplayer.peer_connected.connect(_Peer_Connected)
	multiplayer.peer_disconnected.connect(_Peer_Disconnected)
	
func _Peer_Connected(gameserver_id):
	print("Game Server " + str(gameserver_id) + " Connected")
	
	gameserverlist["GameServer1"] = gameserver_id
	print("GSList: " + str(gameserverlist))
	
func _Peer_Disconnected(gameserver_id):
	print("Game Server " + str(gameserver_id) + " Disconnected")
	
func DistributeLoginToken(token, gameserver):
	var gameserver_peer_id = gameserverlist[gameserver]
	rpc_id(gameserver_peer_id, "ReceiveLoginToken", token)

@rpc ("any_peer", "call_remote", "reliable")
func ReceiveLoginToken(token):
	pass
	
