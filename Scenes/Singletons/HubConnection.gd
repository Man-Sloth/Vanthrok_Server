extends Node

var network = ENetMultiplayerPeer.new()
var gateway_api = SceneMultiplayer.new()
var ip = "127.0.0.1"
var port = 1912

@onready var gameserver = get_node("/root/GameServer")

func _ready():
	ConnectToServer()
	
func _process(delta):
	if multiplayer == null:
		return
	if !multiplayer.has_multiplayer_peer():
		return
	multiplayer.poll()
	
func ConnectToServer():
	network.create_client(ip, port)
	get_tree().set_multiplayer(gateway_api, get_path())
	multiplayer.multiplayer_peer = network
	
	multiplayer.peer_disconnected.connect(_OnConnectionFailed)
	multiplayer.peer_connected.connect(_OnConnectionSucceeded)
	
func _OnConnectionFailed():
	print("Failed to connect to Game Server Hub")
	
func _OnConnectionSucceeded(id):
	print("Successfully connected to Game Server Hub")
	
@rpc ("any_peer", "call_remote", "reliable")
func ReceiveLoginToken(token):
	gameserver.expected_tokens.append(token)
