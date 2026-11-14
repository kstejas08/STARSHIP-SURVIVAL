class_name Player extends CharacterBody2D

@export var speed = 300
@onready var muzzle = $Muzzle
signal laser_shot(laser_scene, location)
var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd := false
func _process(_delta):
	if Input.is_action_pressed("shoot"):
		if !shoot_cd:
			shoot_cd = true
			shoot()
			await get_tree().create_timer(0.25).timeout
			shoot_cd = false 

func _physics_process(_delta):
	var direction = Vector2(Input.get_axis("move_left","move_right"), Input.get_axis("move_up","move_down"))
	velocity = direction * speed
	move_and_slide()
	
	global_position = global_position.clamp(Vector2.ZERO,get_viewport_rect().size)
func _ready():
	add_to_group("player")
	
func shoot():
	laser_shot.emit(laser_scene, muzzle.global_position )
	
func die():
	queue_free()
