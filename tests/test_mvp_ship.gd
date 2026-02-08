extends GutTest

var Ship = preload("res://scripts/ships/mvp_ship.gd")
var ship: Ship

func before_each():	
	ship = Ship.new()
	add_child_autofree(ship)

func test_ship_exists():
	assert_not_null(ship, "Ship should exist")

func test_ship_initializes_with_hp():
	# Arrange
	ship.base_hp = 100
	
	# Act
	ship.initialize()
	
	# Assert
	assert_eq(ship.current_hp, 100, "Ship should start with full HP")
