extends Node

var PlayerIDs

func _ready():
	var player_data_text = FileAccess.get_file_as_string("user://Data/PlayerData.json")
	var player_data_json = JSON.parse_string(player_data_text)
	PlayerIDs = player_data_json["Players"]

func SavePlayerIDs():
	var save_file = FileAccess.open("user://Data/PlayerData.json", FileAccess.WRITE)
	var player_id_string = JSON.stringify(PlayerIDs, "\t")
	save_file.store_line("{\"Players\":  " + str(player_id_string) + "}")
	save_file.close()
	print("User Created")
	
	
