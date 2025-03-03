extends Node2D

var enemy_spawn = preload("res://Scenes/Characters/Enemy.tscn")

func SpawnEnemy(enemy_id, location):
	var new_enemy = enemy_spawn.instantiate()
	new_enemy.position = location
	new_enemy.name = str(enemy_id)
	get_node("Chunk 1/Enemies/").add_child(new_enemy, true)
