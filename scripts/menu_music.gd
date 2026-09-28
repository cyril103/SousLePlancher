extends Node
## One player survives the splash -> menu transition. Colony saves are untouched.
const THEME_PATH := "res://assets/audio/music/une-lumiere-sous-les-lames.ogg"
var settings_path := "user://music.cfg"
const LEVEL_DB := -8.0
var enabled := true
var player: AudioStreamPlayer
var fade: Tween
var menu_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings := ConfigFile.new()
	if settings.load(settings_path) == OK:
		var stored = settings.get_value("music", "enabled", true)
		if stored is bool: enabled = stored
	player = AudioStreamPlayer.new()
	player.stream = load(THEME_PATH)
	player.volume_db = -60.0
	add_child(player)

func _exit_tree() -> void:
	if fade: fade.kill()
	if is_instance_valid(player):
		player.stop()
		player.stream = null

func start_menu() -> void:
	menu_active = true
	if not enabled: return
	if fade: fade.kill()
	if not player.playing:
		player.volume_db = -60.0
		player.play()
	fade = create_tween()
	fade.tween_property(player, "volume_db", LEVEL_DB, 1.6)

func stop_menu() -> void:
	menu_active = false
	_fade_out()

func _fade_out() -> void:
	if fade: fade.kill()
	if not player.playing: return
	fade = create_tween()
	fade.tween_property(player, "volume_db", -60.0, 1.5)
	fade.tween_callback(player.stop)

func bind_menu(panel: Control) -> void:
	panel.visibility_changed.connect(func():
		if panel.visible: start_menu()
		else: stop_menu())
	if panel.visible: start_menu()
	else: stop_menu()

func toggle_enabled() -> void:
	enabled = not enabled
	var settings := ConfigFile.new()
	settings.set_value("music", "enabled", enabled)
	settings.save(settings_path)
	if enabled and menu_active: start_menu()
	else: _fade_out()
