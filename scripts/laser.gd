extends Area2D

signal enemy_destroyed(points: int)

@export var speed = 600
var direction := Vector2.UP
var reflected := false

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if reflected or is_queued_for_deletion():
		return

	if area.is_in_group("diver_enemy"):
		var player := get_tree().get_first_node_in_group("player") as Player
		if not is_instance_valid(player):
			queue_free()
			return
		reflected = true
		direction = global_position.direction_to(player.global_position)
		set_deferred("collision_mask", 1)
	elif area is Enemy and not area.is_queued_for_deletion():
		area.die()
		enemy_destroyed.emit(100)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if reflected and body is Player:
		body.die()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
