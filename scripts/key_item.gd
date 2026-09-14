extends Node3D
class_name KeyItem

@export var item_id: String = "school_key"
@export var action_name: String = "Pegar chave"
@export var interaction_distance: float = 3.0

var _picked: bool = false

func _ready() -> void:
	add_to_group("interactive")


func can_interact(player: Node3D) -> bool:
	if player == null:
		return false
	if _picked:
		return false
	return player.global_position.distance_to(global_position) <= interaction_distance


func interact(player: Node3D) -> void:
	if _picked:
		return
	if player.has_method("add_item"):
		player.add_item(item_id)
		_picked = true
		visible = false
		if has_method("set_highlight"):
			set_highlight(false)
		print("Key: %s coletada" % item_id)


func set_highlight(enabled: bool) -> void:
	if not is_inside_tree():
		return
	var mesh = get_node_or_null("MeshInstance3D")
	if not mesh:
		return
	if enabled:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.2)
		mat.emission_energy_multiplier = 0.7
		mesh.set_surface_override_material(0, mat)
	else:
		mesh.set_surface_override_material(0, null)
