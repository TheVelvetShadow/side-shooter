extends CanvasLayer

const UPGRADES: Array[Dictionary] = [
	{"id": "hp",     "name": "Hull Plating",   "desc": "+20 Max HP\nRestores 20 HP"},
	{"id": "shield", "name": "Shield Booster",  "desc": "+15 Max Shield\nFull shield restore"},
	{"id": "attack", "name": "Weapons Array",   "desc": "+20% Bullet Damage"},
	{"id": "speed",  "name": "Engine Boost",    "desc": "+30 Move Speed"},
]

@onready var title_label: Label = $VBox/TitleLabel
@onready var cards: HBoxContainer = $VBox/Cards

var _offered: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	EventBus.ship_levelled_up.connect(_on_level_up)
	var card_nodes = cards.get_children()
	for i in card_nodes.size():
		card_nodes[i].get_node("VBox/ChooseBtn").pressed.connect(_on_card_chosen.bind(i))

func _on_level_up(new_level: int) -> void:
	title_label.text = "LEVEL UP!   Level %d" % new_level
	var pool: Array[Dictionary] = []
	pool.assign(UPGRADES)
	pool.shuffle()
	_offered.assign(pool.slice(0, 3))
	var card_nodes = cards.get_children()
	for i in 3:
		card_nodes[i].get_node("VBox/NameLabel").text = _offered[i]["name"]
		card_nodes[i].get_node("VBox/DescLabel").text = _offered[i]["desc"]
	visible = true
	get_tree().paused = true

func _on_card_chosen(index: int) -> void:
	var upgrade_id = _offered[index]["id"]
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade_id)
	EventBus.upgrade_chosen.emit(upgrade_id)
	visible = false
	get_tree().paused = false
