class_name ResidentAnimator
extends Node3D
## Baked Blender clips. The caller owns navigation and actual translation.
const SPEEDS := {"eat": 0.0, "drink": 0.0, "sleep": 0.0, "floor_rest": 0.0, "idle": 0.0, "walk": 0.55555556, "carry_walk": 0.36796537, "work": 0.0, "climb": 0.31875, "climb_down": -0.28333333}
const ONE_SHOTS := ["bed_enter", "bed_exit", "pick_up", "put_down", "climb_enter", "climb_exit", "carry_turn_right", "carry_turn_left", "descend_enter", "descend_exit"]
var manage_cargo_visibility := true
var player: AnimationPlayer
var skeleton: Skeleton3D
var cargo: Node3D
var tool: Node3D
var sleeping_lids: Node3D
var ration: Node3D
var cup: Node3D
var current := "idle"

func _ready() -> void:
	var model := preload("res://assets/models/animations_03/resident_animated.glb").instantiate()
	add_child(model)
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for clip in SPEEDS:
		assert(player.has_animation(clip), "Missing resident clip: " + clip)
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for clip in ONE_SHOTS:
		assert(player.has_animation(clip))
		player.get_animation(clip).loop_mode = Animation.LOOP_NONE
	cargo = attach("socket_carry", "res://assets/models/reference_01/salvage_crate.glb")
	cargo.scale = Vector3.ONE * 0.52
	tool = attach("socket_tool", "res://assets/models/animations_03/hand_hammer.glb")
	sleeping_lids = attach("head", "res://assets/models/sleep_12/closed_eyes.glb")
	ration = attach("socket_tool", "res://assets/models/needs_13/ration.glb")
	cup = attach("socket_tool", "res://assets/models/reference_01/thimble_bucket.glb")
	cup.scale = Vector3.ONE * .32
	# The tool socket's +Z is upright; the thimble's +Y is its opening axis.
	cup.rotation.x = PI / 2 + .35
	set_action("idle", 0.0)

func attach(bone: String, path: String) -> Node3D:
	assert(skeleton.find_bone(bone) >= 0)
	var socket := BoneAttachment3D.new()
	socket.bone_name = bone
	skeleton.add_child(socket)
	var prop := (load(path) as PackedScene).instantiate() as Node3D
	socket.add_child(prop)
	return prop

func set_action(clip: String, blend: float = 0.16) -> void:
	assert(SPEEDS.has(clip) or clip in ONE_SHOTS)
	current = clip
	player.play(clip, blend)
	if manage_cargo_visibility:
		cargo.visible = clip == "carry_walk" or clip.begins_with("carry_turn_")
	tool.visible = clip == "work"
	sleeping_lids.visible = clip in ["sleep", "floor_rest"]
	ration.visible = clip == "eat"
	cup.visible = clip == "drink"

func sync_motion_speed(speed: float) -> void:
	var nominal: float = SPEEDS.get(current, 0.0)
	player.speed_scale = speed / nominal if not is_zero_approx(nominal) else 1.0
