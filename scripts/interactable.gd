extends Node3D
class_name Interactable

## Classe base para objetos interativos no Escape Room
## Herdar desta classe para criar novos tipos de interação

signal interacted

@export var action_name: String = "Interact"
@export var interaction_distance: float = 3.0
@export var highlight_on_hover: bool = true

var _is_highlighted: bool = false
var _original_material: Material

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")


func _ready() -> void:
	add_to_group("interactive")
	
	if mesh and highlight_on_hover:
		if mesh.get_surface_override_material(0):
			_original_material = mesh.get_surface_override_material(0)
		elif mesh.get_material():
			_original_material = mesh.get_material()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not mesh:
		warnings.append("MeshInstance3D não encontrado para highlight visual")
	return warnings


func can_interact(player: Node3D) -> bool:
	## Verifica se o jogador está dentro da distância de interação
	if player == null:
		return false
	
	var player_pos = player.global_position
	var my_pos = global_position
	return player_pos.distance_to(my_pos) <= interaction_distance


func interact(player: Node3D) -> void:
	## Método chamado quando o jogador interage com o objeto
	## Subclasses devem sobrescrever este método
	interacted.emit()
	print("Interactable: %s interacted" % name)


func set_highlight(enabled: bool) -> void:
	## Destaca o objeto quando o jogador olha para ele
	if not highlight_on_hover or not mesh:
		return
	
	if enabled and not _is_highlighted:
		_is_highlighted = true
		_apply_highlight()
	elif not enabled and _is_highlighted:
		_is_highlighted = false
		_remove_highlight()


func _apply_highlight() -> void:
	## Aplica efeito visual de destaque (outline amarelo/brilho)
	if mesh:
		var highlight_mat = StandardMaterial3D.new()
		highlight_mat.albedo_color = Color(1.0, 0.9, 0.3, 1.0)
		highlight_mat.emission_enabled = true
		highlight_mat.emission = Color(1.0, 0.8, 0.2)
		highlight_mat.emission_energy_multiplier = 0.5
		highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		highlight_mat.albedo_color.a = 0.8
		mesh.set_surface_override_material(0, highlight_mat)


func _remove_highlight() -> void:
	## Remove o efeito de destaque
	if mesh and _original_material:
		mesh.set_surface_override_material(0, _original_material)
	elif mesh:
		mesh.set_surface_override_material(0, null)
