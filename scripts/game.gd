extends Node2D

const SCORE_FILE := "user://scores.cfg"

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos = $PlayerSpawnPosition
@onready var laser_container = $LaserContainer
@onready var timer = $EnemySpawnTimer
@onready var enemy_container = $EnemyContainer
@onready var score_label: Label = $HUD/ScoreLabel
@onready var game_over_screen: CenterContainer = $HUD/GameOver
@onready var final_score_label: Label = $HUD/GameOver/VBox/FinalScore
@onready var high_score_label: Label = $HUD/GameOver/VBox/HighScore

var player: Player
var score := 0
var high_score := 0
var game_over := false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.tree_exiting.connect(_on_player_exiting, CONNECT_DEFERRED)

	var scores := ConfigFile.new()
	if scores.load(SCORE_FILE) == OK:
		high_score = int(scores.get_value("scores", "high_score", 0))

	score_label.position = Vector2(20, 16)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.text = "Score: 0"
	game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$HUD/GameOver/VBox/Title.text = "GAME OVER"
	$HUD/GameOver/VBox/Title.add_theme_font_size_override("font_size", 36)
	$HUD/GameOver/VBox/RestartHint.text = "Press R to restart"
	for label: Label in $HUD/GameOver/VBox.get_children():
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_screen.hide()
	if restarting:
		restarting = false
	else:
		_show_start_menu()

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		restarting = true
		get_tree().reload_current_scene()

func _on_player_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.enemy_destroyed.connect(add_score)
	laser_container.add_child(laser)
	laser.global_position = location
	laser_sound.play()

func _on_enemy_spawn_timer_timeout() -> void:
	var e = enemy_scenes.pick_random().instantiate()
	e.global_position = Vector2(randf_range(50, 500), -50)
	enemy_container.add_child(e)

func add_score(points: int) -> void:
	if game_over:
		return
	score += points
	score_label.text = "Score: %d" % score
	if score > high_score:
		high_score = score
		var scores := ConfigFile.new()
		scores.set_value("scores", "high_score", high_score)
		if scores.save(SCORE_FILE) != OK:
			push_warning("Could not save the high score.")

func _on_player_exiting() -> void:
	if not is_inside_tree():
		return
	game_over = true
	timer.stop()
	score_label.hide()
	final_score_label.text = "Final score: %d" % score
	high_score_label.text = "High score: %d" % high_score
	game_over_screen.show()


var laser_sound: AudioStreamPlayer

func _enter_tree() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)

	var backdrop := TextureRect.new()
	backdrop.name = "SpaceBackground"
	backdrop.texture = preload("res://assets/Backgrounds/black.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_TILE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	laser_sound = AudioStreamPlayer.new()
	laser_sound.name = "LaserSound"
	laser_sound.stream = preload("res://assets/Bonus/sfx_laser1.ogg")
	laser_sound.volume_db = -12.0
	laser_sound.max_polyphony = 4
	add_child(laser_sound)


static var restarting := false

func _show_start_menu() -> void:
	var menu := CanvasLayer.new()
	menu.name = "StartMenu"
	menu.layer = 2
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)

	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://assets/Backgrounds/black.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_TILE
	menu.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	center.add_child(content)

	var title := Label.new()
	title.text = "STARSHIP SURVIVAL 🚀 "
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	content.add_child(title)

	var rules := Label.new()
	rules.text = "WASD to move. Space to fire.\nDestroy regular enemies for 100 points.\nDodge enemy ships and reflected shots.\nDiver enemies bounce your lasers back!"
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.add_theme_font_size_override("font_size", 20)
	content.add_child(rules)

	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(150, 48)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 22)
	content.add_child(play)
	play.pressed.connect(func():
		menu.hide()
		menu.queue_free()
		get_tree().paused = false
	)
	get_tree().paused = true
	play.grab_focus()
