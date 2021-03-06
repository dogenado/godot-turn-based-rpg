extends Node

var experience_earned : int = 0
var party : Array = []
var drops : Array = []

func initialize(battlers : Array):
	"""
	We rely on signals to only add experience of enemies that have been defeated.
	This allows us to support enemies running away and not receiving exp for them,
	as well as allowing the party to run away and only earn partial exp
	"""
	$Panel.visible = false
	party = []
	experience_earned = 0
	randomize()
	for battler in battlers:
		if not battler.party_member:
			battler.stats.connect("health_depleted", self, "_add_reward", [battler])
		else:
			party.append(battler)
	
func _add_reward(battler : Battler):
	"""
	Appends dictionaries with the form { 'item': Item.tres, 'amount': amount } of dropped items to the drops array.
	"""
	experience_earned += battler.stats.experience
	for drop in battler.drops:
		if drop.chance - randf() > drop.chance:
			continue
		var amount : int = 1 if drop.max_amount == 1 else round(rand_range(drop.min_amount, drop.max_amount))
		drops.append({
			'item': drop.item,
			'amount': amount
		})

func _reward_to_battlers() -> Array:
	"""
	Rewards the surviving party members with experience points
	
	@returns Array of Battlers who have leveled up
	"""
	var survived = []
	for member in party:
		if member.stats.is_alive:
			survived.append(member)
		
	var exp_per_survivor = int(ceil(float(experience_earned) / float(len(survived))))
	var leveled_up = []
	for member in survived:
		var level = member.stats.level
		member.stats.experience += exp_per_survivor
		if level < member.stats.level:
			leveled_up.append(member)
	return leveled_up

func on_battle_completed():
	"""
	On victory be sure to grant the battlers their earned exp
	and show the interface
	"""
	var leveled_up = _reward_to_battlers()
	$Panel.visible = true
	$Panel/Label.text = "EXP Earned %d" % experience_earned
	yield(get_tree().create_timer(2.0), "timeout")
	for battler in leveled_up:
		$Panel/Label.text = "%s Leveled Up to %d" % [battler.name, battler.stats.level]
		yield(get_tree().create_timer(2.0), "timeout")
	for drop in drops:
		$Panel/Label.text = "Found %s %s(s)" % [drop.amount, drop.item.name]
		yield(get_tree().create_timer(2.0), "timeout")
	$Panel.visible = false
	
func on_flee():
	"""
	End combat condition when the party flees
	"""
	experience_earned /= 2
	on_battle_completed()
