extends Node2D

@export var scroll_speed: float = 150.0

@onready var sprite_a: Sprite2D = $SpriteA
@onready var sprite_b: Sprite2D = $SpriteB

var _segment_width: float

func _ready() -> void:
	var vp := get_viewport_rect().size
	if sprite_a.texture == null:
		return

	var tex_size := sprite_a.texture.get_size()
	# "Cover" mode: scale so the sprite fills the viewport in both dimensions,
	# cropping the overflow. Prevents any grey gaps.
	var scale_factor := maxf(vp.x / tex_size.x, vp.y / tex_size.y)
	var scaled_width := tex_size.x * scale_factor

	sprite_a.scale = Vector2(scale_factor, scale_factor)
	sprite_b.scale = Vector2(scale_factor, scale_factor)

	# Sprite2D origin is center, so offset by half width to start flush left
	sprite_a.position = Vector2(scaled_width * 0.5, vp.y * 0.5)
	sprite_b.position = Vector2(scaled_width * 1.5, vp.y * 0.5)

	_segment_width = scaled_width

func _process(delta: float) -> void:
	sprite_a.position.x -= scroll_speed * delta
	sprite_b.position.x -= scroll_speed * delta

	_wrap(sprite_a, sprite_b)
	_wrap(sprite_b, sprite_a)

func _wrap(sprite: Sprite2D, other: Sprite2D) -> void:
	if sprite.position.x + _segment_width * 0.5 < 0.0:
		sprite.position.x = other.position.x + _segment_width
