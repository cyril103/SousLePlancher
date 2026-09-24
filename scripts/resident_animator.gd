class_name ResidentAnimator
extends Node3D
## Baked Blender clips. The caller owns navigation and actual translation.
const SPEEDS := {"idle": 0.0, "walk": 0.55555556, "carry_walk": 0.36796537, "work": 0.0, "climb": 0.31875}
const ONE_SHOTS := ["pick_up", "put_down", "climb_enter", "climb_exit"]
var manage_cargo_visibility := true
var player: AnimationPlayer
var skeleton: Skeleton3D
var cargo: Node3D
var tool: Node3D
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
		cargo.visible = clip == "carry_walk"
	tool.visible = clip == "work"

func sync_motion_speed(speed: float) -> void:
	var nominal: float = SPEEDS.get(current, 0.0)
	player.speed_scale = speed / nominal if nominal > 0.0 else 1.0
