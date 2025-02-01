extends Node

var PlayerIDs

func _ready():
	var player_data_text = FileAccess.get_file_as_string("res://Data/PlayerData.json")
	var player_data_json = JSON.parse_string(player_data_text)
	
	PlayerIDs = player_data_json["Players"]
