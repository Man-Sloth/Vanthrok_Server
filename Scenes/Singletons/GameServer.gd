extends Node

var network = ENetMultiplayerPeer.new()
const ip = "76.181.30.56"
const port = 4830
var connected = false
var token 

var decimal_collector : float = 0
var latency_array = []
var latency = 0
var client_clock = 0
var delta_latency = 0

func _ready():
	pass
	#ConnectToServer()

func _physics_process(delta):
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00

func ConnectToServer():
	network.create_client(ip, port)
	multiplayer.multiplayer_peer = network
	
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
		
func _on_connected_ok():
	connected = true
	print("Succesfully connected")
	rpc_id(1,"FetchServerTime", (Time.get_unix_time_from_system()*1000))
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(DetermineLatency)
	self.add_child(timer)
	
func _on_connected_fail():
	print("Failed to connect")
	
func server_connected():
	return connected

func FetchPlayerStats():
	if(connected):
		pass
		#rpc_id(1,"S_FetchPlayerStats")

func NPCHit(enemy_id, damage):
	rpc_id(1, "SendNPCHit", enemy_id, damage)	
		
func DetermineLatency():
	rpc_id(1, "S_DetermineLatency", (Time.get_unix_time_from_system()*1000))
	
func SendAttack(facing):
	rpc_id(1, "Attack", facing, client_clock)

@rpc("any_peer", "call_remote", "reliable")
func ReceiveTOD(tod_index):
	pass

@rpc ("any_peer", "call_remote", "reliable")
func ReceiveAttack(facing, spawn_time, id): #spawn time for projectiles
	var player_id = multiplayer.get_unique_id()
	if player_id == id:
		pass # this is us, don't update
	else:
		get_node("/root/OmegaScene/Map/OtherPlayers/" + str(id)).is_attacking = true
		get_node("/root/OmegaScene/Map/OtherPlayers/" + str(id)).facing = facing
		get_node("/root/OmegaScene/Map/OtherPlayers/" + str(id)).attack_time = spawn_time
		## attack_dict for projectiles
		#get_node("/root/OmegaScene/Map/OtherPlayers/" + str(id)).attack_dict[spawn_time] = {"Position": position, "Facing": facing}

@rpc("any_peer", "call_remote", "reliable")
func ReturnLatency(client_time):
	latency_array.append(((Time.get_unix_time_from_system()*1000) - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range(latency_array.size() -1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
				latency_array.remove_at(i)
			else:
				total_latency += latency_array[i]
		delta_latency = (total_latency / latency_array.size()) - latency
		latency = total_latency / latency_array.size()
		print("Latency: ", int(latency))
		latency_array.clear()
		
		
@rpc("any_peer", "call_remote", "reliable")
func ReturnServerTime(server_time, client_time):
	latency = ((Time.get_unix_time_from_system()*1000) - client_time) / 2
	client_clock = server_time + latency
	
@rpc("any_peer", "call_remote", "reliable")
func SpawnNewPlayer(player_id, spawn_position):
	get_node("../OmegaScene/Map").SpawnNewPlayer(player_id, spawn_position)
	
@rpc("any_peer", "call_remote", "reliable")
func DespawnPlayer(player_id):
	get_node("../OmegaScene/Map").DespawnPlayer(player_id)

@rpc("any_peer", "call_remote", "reliable")
func FetchToken():
	rpc_id(1, "ReturnToken", token)
	
@rpc("any_peer", "call_remote", "reliable")
func ReturnPlayerStats(stats):
	get_node("/root/OmegaScene/Map/CanvasLayer/Status Bars").LoadPlayerStats(stats)
	
@rpc ("any_peer", "call_remote", "reliable")
func ReturnTokenVerificationResults(result):
	if result == true:
		get_node("../OmegaScene/CanvasLayer").queue_free()
		get_node("../OmegaScene/Map").visible = true
		get_node("../OmegaScene/Map/CanvasLayer").visible = true
		print("Successful token verification")
		#get_node("../OmegaScene/Map/Player").set_physics_process(true)
		rpc_id(1,"S_FetchPlayerStats")
		get_node("../OmegaScene/Map/Player").set_physics_process(true)
	else:
		print("Login failed, please try again")
		get_node("../OmegaScene/CanvasLayer/Control/LoginWindow").login_button.disabled = false
		get_node("../OmegaScene/CanvasLayer/Control/LoginWindow").create_account_button.disabled = false

@rpc("any_peer", "call_remote", "unreliable")
func SendPlayerState(player_state):
	rpc_id(1, "ReceivePlayerState", player_state)
	
@rpc("any_peer", "call_remote", "unreliable")
func ReceiveWorldState(world_state):
	get_node("../OmegaScene/Map").UpdateWorldState(world_state)
	#print("Worldstate: ", world_state["T"], " && client_clock: ", client_clock)


@rpc("any_peer", "reliable")	
@warning_ignore("unused_parameter")
func _register_player(new_player_info):
	pass

@rpc("any_peer", "reliable")
@warning_ignore("unused_parameter")
func S_FetchSkillDamage(skill_name, requester):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter", "shadowed_variable")
func ReturnToken(token):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func S_ReturnTokenVerificationResults(player_id, result):
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func S_FetchPlayerStats():
	pass
	
@rpc("any_peer", "call_remote", "unreliable")
@warning_ignore("unused_parameter")
func ReceivePlayerState(player_state):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func FetchServerTime(client_time):
	pass

@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func S_DetermineLatency(client_time):
	pass

@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func SendNPCHit(enemy_id, damage):
	pass
	
@rpc ("any_peer", "call_remote", "reliable")
@warning_ignore("unused_parameter")
func Attack(facing, spawn_time):
	pass
