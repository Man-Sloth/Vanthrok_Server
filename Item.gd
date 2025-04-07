extends Node2D

@export_group("Item Properties")
enum ITEM_TYPE {Helm, Chest, Leggings, Gauntlets, Weapon, Shield, Stackable, Gold, Non_Stackable = -1}
@export_group("Item Properties")
enum STACK_TYPE {Potion}

var close_to_player = false
var inventory_slot = -1

var info = {"visible": false, 
			"item_type": 0,
			"armor_type": 0,
			"stack_size": 1,
			"max_stack": 1,
			"weight": 0,
			"sell_value": 0.0,
			"buy_value": 0.0,
			"tag": "",
			"bag_ID": 0,
			"slot_num": 0}
			

# Called when the node enters the scene tree for the first time.
func _ready():
	var random = RandomNumberGenerator.new()
	random.randomize()
	info["item_type"] = randi_range(1, 7)
	var breakpnt
	if info["item_type"] == 7 or info["item_type"] == 6:
		info["armor_type"] = -1
	
	if info["item_type"] == ITEM_TYPE.Gold:
		info["tag"] = "Gold"
		info["weight"] = 0.0
		info["sell_value"] = 0
		info["stack_size"] = randi_range(1, 20)
	
	elif info["item_type"] == ITEM_TYPE.Stackable:
		random.randomize()
		var stackable = randi_range(0, STACK_TYPE.size() - 1)
		random.randomize()
		if stackable == STACK_TYPE.Potion:
			info["tag"] = "Potion"
			info["weight"] = 0.25 * info["stack_size"]
			info["sell_value"] = 2 * info["stack_size"]
			info["buy_value"] = 10 * info["stack_size"]
			info["stack_size"] = randi_range(1, 3)
			
	elif info["armor_type"] == 0: #cloth
		if info["item_type"] == ITEM_TYPE.Chest:
			info["tag"] = "Field Shirt"
			info["weight"] = 0.5
			info["sell_value"] = 0
		elif info["item_type"] == ITEM_TYPE.Helm:
			info["tag"] = "Field Hat"
			info["weight"] = 0.5
			info["sell_value"] = 0
		elif info["item_type"] == ITEM_TYPE.Gauntlets:
			info["tag"] = "Field Gloves"
			info["weight"] = 0.5
			info["sell_value"] = 0
		elif info["item_type"] == ITEM_TYPE.Leggings:
			info["tag"] = "Field Pants"
			info["weight"] = 0.5
			info["sell_value"] = 0
		elif info["item_type"] == ITEM_TYPE.Weapon:
			info["tag"] = "Rusty Sword"
			info["weight"] = 0.5
			info["sell_value"] = 5
		elif info["item_type"] == ITEM_TYPE.Shield:
			info["tag"] = "Buckler"
			info["weight"] = 0.5
			info["sell_value"] = 10
	
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
