extends Node

var player_data
var test_data = {
	"Stats": {
		"MaxHealth": 2150,
		"Health": 1009,
		"MaxMana": 935,
		"Mana": 420,
		"MaxFood": 100,
		"Food": 69,
		"MaxExp": 42000,
		"Exp": 2001,
		"MaxEncumbrance": 250,
		"Encumbrance": 42,
		"MaxAlignment": 1000,
		"Alignment": 250
	}
}

func _ready():
	var player_data_text = FileAccess.get_file_as_string("res://Data/PlayerData.json")
	var player_data_json = JSON.parse_string(player_data_text)
	
	if player_data_json:
		player_data = player_data_json["Player Stats"]
	
