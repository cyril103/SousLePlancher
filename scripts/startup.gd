extends Control
## Startup artwork is independent of colony saves and gameplay randomness.
const IMAGES := [
	"res://assets/ui/splash/01-refuge-chaleureux.png",
	"res://assets/ui/splash/02-exploration-lanterne.png",
	"res://assets/ui/splash/03-pas-du-geant.png",
	"res://assets/ui/splash/04-colonie-miniature.png",
	"res://assets/ui/splash/05-boite-allumettes.png",
]
const MIN_SECONDS := 3.0
@export var history_path := "user://startup.cfg"
@export var next_scene_path := "res://scenes/main.tscn"
@export var auto_advance := true
var selected_index := -1
var artwork: TextureRect
var status: Label
var hint: Label
var next_scene: PackedScene
var elapsed := 0.0
var skip_requested := false
var transitioning := false
var loading := false
var failed := false

static func choose_index(previous: int, rng: RandomNumberGenerator) -> int:
	var choices: Array[int] = []
	for i in range(IMAGES.size()):
		if i != previous: choices.append(i)
	return choices[rng.randi_range(0, choices.size() - 1)]

func _ready() -> void:
	var history := ConfigFile.new()
	var previous := -1
	if history.load(history_path) == OK:
		var value = history.get_value("splash", "last", -1)
		if value is int: previous = value
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	selected_index = choose_index(previous, rng)
	history.set_value("splash", "last", selected_index)
	history.save(history_path)
	var background := ColorRect.new()
	background.color = Color("100e0b")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork = TextureRect.new()
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture = load(IMAGES[selected_index])
	add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.modulate.a = 0
	var appearance := create_tween()
	appearance.tween_property(artwork, "modulate:a", 1.0, .35)
	appearance.finished.connect(begin_loading)
	var footer := VBoxContainer.new()
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -65
	footer.offset_bottom = -14
	status = make_label(footer, "Chargement…", 18)
	hint = make_label(footer, "Clic · Entrée · Espace · Échap pour passer", 14)

func make_label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f3e6cd"))
	label.add_theme_color_override("font_outline_color", Color("100e0b"))
	label.add_theme_constant_override("outline_size", 5)
	parent.add_child(label)
	return label

func begin_loading() -> void:
	if loading: return
	failed = false
	loading = true
	# Present the artwork before loading scripts on the main thread. Threaded
	# loading of this game's script graph leaves RefCounted instances behind.
	await get_tree().process_frame
	await get_tree().process_frame
	next_scene = load(next_scene_path) as PackedScene
	loading = false
	if next_scene == null: show_failure()
	else:
		status.text = "Bienvenue sous le plancher"
		hint.text = "Clic · Entrée · Espace · Échap pour passer"

func _process(delta: float) -> void:
	elapsed += delta
	if auto_advance and next_scene != null and (skip_requested or elapsed >= MIN_SECONDS): advance()

func _input(event: InputEvent) -> void:
	var pressed: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	pressed = pressed or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE])
	if not pressed: return
	get_viewport().set_input_as_handled()
	if failed:
		status.text = "Nouvelle tentative…"
		begin_loading()
	else: skip_requested = true

func show_failure() -> void:
	failed = true
	status.text = "Impossible de charger l’accueil."
	hint.text = "Clic ou Entrée pour réessayer"

func advance() -> void:
	if transitioning: return
	transitioning = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, .3)
	fade.tween_callback(func():
		if get_tree().change_scene_to_packed(next_scene) != OK:
			modulate.a = 1
			transitioning = false
			next_scene = null
			show_failure())
