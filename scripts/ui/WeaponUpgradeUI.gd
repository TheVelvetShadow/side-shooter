extends CanvasLayer

const STAT_BOOST_OPTIONS: Array[Dictionary] = [
	{"kind": "stat", "id": "hp",     "name": "Hull Plating",  "desc": "+20 Max HP\nRestores 20 HP"},
	{"kind": "stat", "id": "shield", "name": "Shield Booster","desc": "+15 Max Shield\nFull shield restore"},
	{"kind": "stat", "id": "attack", "name": "Weapons Array", "desc": "+20% Bullet Damage"},
	{"kind": "stat", "id": "speed",  "name": "Engine Boost",  "desc": "+30 Move Speed"},
]

@onready var title_label: Label = $VBox/TitleLabel
@onready var cards: HBoxContainer = $VBox/Cards

var _offered: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	EventBus.weapon_upgrade_available.connect(_on_upgrade_available)
	var card_nodes = cards.get_children()
	for i in card_nodes.size():
		card_nodes[i].get_node("VBox/ChooseBtn").pressed.connect(_on_card_chosen.bind(i))

func _on_upgrade_available(_slot: int) -> void:
	_offered = _build_upgrade_options()
	var card_nodes = cards.get_children()
	for i in 3:
		card_nodes[i].get_node("VBox/NameLabel").text = _offered[i]["name"]
		card_nodes[i].get_node("VBox/DescLabel").text = _offered[i]["desc"]
	title_label.text = "WEAPON UPGRADE"
	visible = true
	get_tree().paused = true

func _build_upgrade_options() -> Array[Dictionary]:
	var player = get_tree().get_first_node_in_group("player")
	var eligible: Array[Dictionary] = []
	if player:
		for i in player.unlocked_slots:
			var w = player.weapon_slots[i]
			if w != null and w["tier"] < 5:
				eligible.append({
					"kind": "weapon",
					"slot": i,
					"name": "Tier Up: %s" % w["name"],
					"desc": "Upgrade %s to Tier %d\n+Damage  +Fire Rate" % [w["name"], w["tier"] + 1],
				})
	eligible.shuffle()
	var options: Array[Dictionary] = eligible.slice(0, 3)
	if options.size() < 3:
		var stats = STAT_BOOST_OPTIONS.duplicate()
		stats.shuffle()
		for s in stats:
			if options.size() >= 3:
				break
			options.append(s)
	return options

func _on_card_chosen(index: int) -> void:
	var choice = _offered[index]
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if choice["kind"] == "weapon":
			player.upgrade_weapon_choice(choice["slot"])
		elif choice["kind"] == "stat" and player.has_method("apply_upgrade"):
			player.apply_upgrade(choice["id"])
	visible = false
	get_tree().paused = false
