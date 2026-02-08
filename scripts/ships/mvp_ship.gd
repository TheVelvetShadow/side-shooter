extends CharacterBody2D

class_name Ship

var base_hp: float = 100
var current_hp: float

func initialize():
	current_hp = base_hp
