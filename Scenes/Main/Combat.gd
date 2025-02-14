extends Node

func FetchSkillDamage(skill_name, player_id):
	var damage = ServerData.skill_data[skill_name].Damage
	return damage
