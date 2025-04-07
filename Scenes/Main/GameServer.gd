extends Node

var network = ENetMultiplayerPeer.new()
const port = 4830
const max_players = 100

const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
@onready var player_verification_process = $PlayerVerification
@onready var combat_functions = $Combat
@onready var map = $Map

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var expected_tokens = []
var token_names = {}
var names = {}
var player_state_collection = {}

var players = {}
var characters = {}
var loaded_characters = {}
var player_info = {"name": "Name"}
var players_loaded = 0
var start_time = 0
var tod = 0
var tod_ratio = 12
var tod_image = 0
var last_image = 0
var chat_log = ""

func _ready():
	StartServer()
	start_time = Time.get_unix_time_from_system()
	tod = (Time.get_unix_time_from_system() - start_time) / tod_ratio
	tod_image = int(tod/360)
	
func _process(_delta):
	pass

func _physics_process(_delta):
	# 360 day cycle pictures per 2 hours
	tod = (Time.get_unix_time_from_system() - start_time) * tod_ratio
	tod_image = int(tod/360)
	if tod_image>= 360:
		start_time = Time.get_unix_time_from_system()
		tod_image = 0
	
	if tod_image != last_image:
		SendTOD(tod_image, 0)
	
	last_image = tod_image
	
	

func StartServer():
	#multiplayer.multiplayer_peer = null  #Terminates network
	network.create_server(port, max_players)
	multiplayer.multiplayer_peer = network
	print("Game Server started")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
func _on_player_connected(player_id):
	#_register_player.rpc_id(id, player_info)
	print("User: " + str(player_id) + " Connected")
	player_verification_process.start(player_id)
	SendTOD(tod_image, player_id)
	
func _on_player_disconnected(player_id):
	print("User: " + str(player_id) + " Disconnected")
	if get_node("WorldMap/Chunk 1/Players").has_node(str(player_id)):
		get_node("WorldMap/Chunk 1/Players/" + str(player_id)).queue_free()
		player_state_collection.erase(player_id)
		loaded_characters.erase(player_id)
		characters.erase(player_id)
		names.erase(str(player_id))
		rpc_id(0, "DespawnPlayer", player_id)
		
func _on_token_expiration_timeout():
	var current_time = (Time.get_unix_time_from_system()*1000)
	var token_time
	if expected_tokens == []:
		pass
	else:
		for i in range(expected_tokens.size() -1, -1, -1):
			token_time = float(expected_tokens[i].right(-64))
			if current_time - token_time >= 30000:
				expected_tokens.remove_at(i)
	print("Expected Tokens:")
	print(expected_tokens)

func S_FetchToken(player_id):
	rpc_id(player_id, "FetchToken")

func SendWorldState(world_state):
	rpc_id(0, "ReceiveWorldState", world_state)
	
@rpc ("any_peer", "call_remote", "reliable")
func RemoveLoot(enemy_id, loot_id):	
	if map.enemy_list.has(enemy_id.to_int()):
		map.enemy_list[enemy_id.to_int()]["Lt"].erase(loot_id)
	else:
		var breakspot
	if get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy_id)) != null:
		var loot = get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy_id)).loot_object.get_child(loot_id)
		if loot != null:
			var loot_parent = get_node("/root/GameServer/WorldMap/Chunk 1/Enemies/" + str(enemy_id)).loot_object
			for enemy in map.enemy_list:
				for num in map.enemy_list[enemy]["Lt"]:
					if num > loot.info["bag_ID"]:
						map.enemy_list[enemy]["Lt"][num]["bag_ID"] -= 1
					
			loot.queue_free()
		rpc_id(0, "RemoveLootItem", enemy_id, loot_id)

@rpc ("any_peer", "call_remote", "reliable")
func ReturnChat(new_text):
	var player_id = multiplayer.get_remote_sender_id()
	var username = names[str(player_id)]
	var char_name = loaded_characters[player_id].name
	chat_log = chat_log + char_name + ": " + new_text + "\n"
	var message = char_name + ": " + new_text + "\n"
	rpc_id(0, "ReceiveChat", message )

@rpc ("any_peer", "call_remote", "reliable")
func ReturnLog():
	pass
	#var player_id = multiplayer.get_remote_sender_id()
	#rpc_id(player_id, "ReceiveChat", chat_log )
	
@rpc ("any_peer", "call_remote", "reliable")
func CreateCharacter(char_name, slot, str, dex, intel, con, remaining):
	var total = int(str) + int(dex) + int(intel) + int(con) + int(remaining)
	if int(str) > 12 or int(dex) > 12 or int(intel) > 12 or int(con) > 12 or int(remaining) > 2 or total > 42:
		return
	else:
		var character = {}
		character["name"] = char_name
		character["Level"] = 1
		character["slot"] = slot
		character["Head"] = "Field_Hat"
		character["Chest"] = "Field_Shirt"
		character["Gauntlets"] = "Field_Gloves"
		character["Leggings"] = "Field_Pants"
		character["Weapon"] = ""
		character["Shield"] = ""
		character["Strength"] = str
		character["Dexterity"] = dex
		character["Intelligence"] = intel
		character["Constitution"] = con
		character["RemainingStats"] = remaining
		character["Bag"] = {}
		character["Bank"] = {}
		character["Health"] = 20 + ((int(con)-10) * 5)
		character["MaxHealth"] = character["Health"]
		character["Mana"] = 10 + ((int(intel)-10) * 5)
		character["MaxMana"] = character["Mana"]
		character["Food"] = 100
		character["MaxFood"] = 100
		character["Weight"] = 0
		character["MaxWeight"] = 250 + ((int(str)-10) * 5)
		character["Experience"] = 0
		character["Alignment"] = 500
		
		var player_id = multiplayer.get_remote_sender_id()
		S_Save_Character(character, player_id)

@rpc ("any_peer", "call_remote", "reliable")
func S_LoadCharacter(char_slot):
	var peer_id = multiplayer.get_remote_sender_id()
	var username = names[str(peer_id)]
	
	loaded_characters[peer_id] = characters[peer_id][str(char_slot)]

@rpc ("any_peer", "call_remote", "reliable")
func S_Save_Character(character,player_id):
	if character["slot"] > 3:
		return
	var username = names[str(player_id)]
	var names = {}
	var players ={"Players": names}
	
	var path = "user://Data/PlayerData.json"
	
	if FileAccess.file_exists(path):
		print("File exists. Writing to it.")
	else:
		print("File does not exist. Creating file.")
		
	var file = FileAccess.open(path, FileAccess.ModeFlags.READ_WRITE)
	if file:
		var json_text = file.get_as_text()
		var json_object = JSON.new()
		json_object.parse(json_text)
		var player_stats = json_object.data
		
		if !player_stats:
			player_stats = {}
		if !player_stats.has("Players"):
			player_stats["Players"] = {}
		if player_stats["Players"].has(username):
			player_stats["Players"][username][str(character["slot"])] = character
		else:
			player_stats["Players"][username] = {}
			player_stats["Players"][username][str(character["slot"])] = {}
			player_stats["Players"][username][str(character["slot"])] = character
		
		json_text = JSON.stringify(player_stats, "\t")
		file.store_string(json_text)
		print("Data written to file.")
		SendCharacters(player_id, player_stats)
	else:
		print("Failed to open or create the file.")

@rpc ("any_peer", "call_remote", "reliable")
func SendCharacters(id, player_stats):
	var player_id = id
	if names == {}:
		return
	var username = names[str(player_id)]
	var path = "user://Data/PlayerData.json"
	var file = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if file:
		var json_text = file.get_as_text()
		var json_object = JSON.new()
		json_object.parse(json_text)
		
		if !player_stats:
			player_stats = json_object.data
		
		if !player_stats:
			rpc_id(player_id, "ReceiveCharacters", {})
			return
		if player_stats["Players"].has(username):
			var p_characters = player_stats["Players"][username]
			rpc_id(player_id, "ReceiveCharacters", p_characters)
			characters[player_id] = p_characters
		else:
			rpc_id(player_id, "ReceiveCharacters", {})
			
func SendTOD(new_tod_image, player_id):
	rpc_id(player_id, "ReceiveTOD", new_tod_image)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnToken(token):
	var player_id = multiplayer.get_remote_sender_id()
	player_verification_process.Verify(player_id, token)

@rpc ("any_peer", "call_remote", "reliable")
func S_ReturnTokenVerificationResults(player_id, result):
	rpc_id(player_id, "ReturnTokenVerificationResults", result)
	if result == true:
		rpc_id(0, "SpawnNewPlayer", player_id, Vector2(50, 50))
	
@rpc("any_peer", "reliable")	
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

@rpc("any_peer", "reliable")
func S_FetchSkillDamage(skill_name, requester):
	var player_id = multiplayer.get_remote_sender_id()
	var damage = combat_functions.FetchSkillDamage(skill_name, player_id)
	rpc_id(player_id, "ReturnSkillDamage", damage, requester)
	
@rpc("any_peer", "reliable")
func S_FetchPlayerStats():
	var player_id = multiplayer.get_remote_sender_id()
	#var player = get_node("WorldMap/Chunk 1/Players/"+ str(player_id))
	var stats = get_node("WorldMap/Chunk 1/Players/"+ str(player_id)).player_stats
	rpc_id(player_id, "ReturnPlayerStats", stats)
	
@rpc("any_peer", "call_remote", "unreliable")
func ReceivePlayerState(player_state):
	var player_id = multiplayer.get_remote_sender_id()
	if player_state_collection.has(player_id):
		if player_state_collection[player_id]["T"] < player_state["T"]:
			var player = get_node("WorldMap/Chunk 1/Players/" +str(player_id)+"/Player")
			if player:
				player.position = player_state_collection[player_id]["P"]
				player_state_collection[player_id] = player_state
	else:
		player_state_collection[player_id] = player_state
		
@rpc ("any_peer", "call_remote", "reliable")
func FetchServerTime(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(player_id, "ReturnServerTime", (Time.get_unix_time_from_system()*1000), client_time)

@rpc("any_peer", "call_remote", "reliable")
func S_DetermineLatency(client_time):
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(player_id, "ReturnLatency", client_time)
	
@rpc ("any_peer", "call_remote", "reliable")
func SendNPCHit(enemy_id, damage_type):
	var player_id = multiplayer.get_remote_sender_id()
	get_node("Map").NPCHit(enemy_id, damage_type, player_id)
	
@rpc ("any_peer", "call_remote", "reliable")
func Attack(facing, spawn_time): #spawn time for projectiles
	var player_id = multiplayer.get_remote_sender_id()
	rpc_id(0, "ReceiveAttack", facing, spawn_time, player_id)

@rpc ("any_peer", "call_remote", "reliable")
func Return_XP(player_id, xp_amount):
	#player_id.add_xp(xp_amount)
	rpc_id(player_id, "Receive_XP", xp_amount)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnLoot(enemy_id):
	var player_id = multiplayer.get_remote_sender_id()
	var loot = map.get_loot(enemy_id)
	rpc_id(player_id, "ReceiveLoot" , enemy_id, loot)
	
@rpc ("any_peer", "call_remote", "reliable")
func Receive_XP(xp_amount):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveAttack(facing, spawn_time, id): #spawn time for projectiles
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
func ReceiveCharacters(characters):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnPlayerStats(stats):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnTokenVerificationResults(result):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func FetchToken():
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func SpawnNewPlayer(player_id, spawn_position):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func DespawnPlayer(player_id):
	pass

@rpc("any_peer", "call_remote", "unreliable")
@warning_ignore("unused_parameter")
func ReceiveWorldState(world_state):
	pass

@rpc("any_peer", "call_remote", "unreliable")
@warning_ignore("unused_parameter")
func SendPlayerState(player_state):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnServerTime(server_time, client_time):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReturnLatency(client_time):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveTOD(tod_index):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func LoadCharacter(char_slot):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveLoot(enemy_id, loot):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func ReceiveChat(chat_log):
	pass

@rpc("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func RemoveLootItem(enemy_id, loot_id):
	pass
