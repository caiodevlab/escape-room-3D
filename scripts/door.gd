extends Node3D
class_name Door
const Interactable = preload("res://scripts/interactable.gd")

signal interacted

## Script de porta com estados: trancada, destrancada, aberta, fechada
## Suporta sistema de chave e sistema de desafio

enum DoorState { CLOSED, OPEN, LOCKED, UNLOCKED }
enum InteractionType { NONE, KEY, CHALLENGE, BOTH }

@export var action_name: String = "Abrir"
@export var interaction_distance: float = 3.0
@export var state: DoorState = DoorState.CLOSED
@export var interaction_type: InteractionType = InteractionType.NONE
@export var required_key_id: String = ""
@export var required_challenge_id: String = ""
@export var challenge_question: String = "Qual é a resposta correta?"
@export var challenge_answer: String = "123"

@export var open_angle_degrees: float = 90.0
@export var open_speed: float = 2.0
@export var closed_rotation: Vector3 = Vector3.ZERO
@export var open_rotation: Vector3 = Vector3.ZERO

@export var lock_color: Color = Color(0.8, 0.1, 0.1)
@export var unlocked_color: Color = Color(0.1, 0.8, 0.2)

var _target_rotation: Vector3
var _is_animating: bool = false
var pivot: Node3D
var door_mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("interactive")
	
	if has_node("DoorPivot"):
		pivot = $DoorPivot
	else:
		pivot = self
	
	if pivot.has_node("MeshInstance3D"):
		door_mesh = pivot.get_node("MeshInstance3D")
	
	if pivot != self:
		closed_rotation = pivot.rotation_degrees
	
	open_rotation = closed_rotation + Vector3(0, open_angle_degrees, 0)
	
	if state == DoorState.OPEN:
		pivot.rotation_degrees = open_rotation
	elif state == DoorState.CLOSED or state == DoorState.LOCKED or state == DoorState.UNLOCKED:
		pivot.rotation_degrees = closed_rotation
	
	_update_visual_state()


func can_interact(player: Node3D) -> bool:
	if player == null:
		return false
	return player.global_position.distance_to(global_position) <= interaction_distance


func set_highlight(enabled: bool) -> void:
	if not door_mesh:
		return
	
	if enabled:
		var highlight_mat = StandardMaterial3D.new()
		highlight_mat.albedo_color = Color(1.0, 0.9, 0.3)
		highlight_mat.emission_enabled = true
		highlight_mat.emission = Color(1.0, 0.8, 0.2)
		highlight_mat.emission_energy_multiplier = 0.7
		door_mesh.set_surface_override_material(0, highlight_mat)
	else:
		_update_visual_state()


func _update_visual_state() -> void:
	## Atualiza a aparência visual conforme o estado
	if not door_mesh:
		return
	
	var mat = StandardMaterial3D.new()
	
	match state:
		DoorState.LOCKED:
			mat.albedo_color = lock_color
			mat.emission_enabled = true
			mat.emission = lock_color * 0.3
		DoorState.UNLOCKED:
			mat.albedo_color = unlocked_color
			mat.emission_enabled = true
			mat.emission = unlocked_color * 0.3
		DoorState.OPEN:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
		_:
			mat.albedo_color = Color(0.7, 0.5, 0.3)
	
	door_mesh.set_surface_override_material(0, mat)


func _process(delta: float) -> void:
	## Anima a abertura/fechamento da porta
	if _is_animating:
		pivot.rotation_degrees = pivot.rotation_degrees.lerp(_target_rotation, open_speed * delta)
		
		if pivot.rotation_degrees.distance_to(_target_rotation) < 0.5:
			pivot.rotation_degrees = _target_rotation
			_is_animating = false
			
			if state == DoorState.OPEN:
				_update_visual_state()


func interact(player: Node3D) -> void:
	## Chamado quando jogador interage com a porta
	match state:
		DoorState.LOCKED:
			_try_unlock(player)
		DoorState.UNLOCKED, DoorState.CLOSED:
			if interaction_type == InteractionType.NONE:
				_open()
			else:
				_try_unlock(player)
		DoorState.OPEN:
			_close()
	
	interacted.emit()
	print("Door: %s interacted" % name)


func _try_unlock(player: Node3D) -> void:
	## Tenta destrancar a porta com chave ou desafio
	var can_unlock = false
	var has_key = false
	var challenge_done = false
	
	if interaction_type == InteractionType.KEY or interaction_type == InteractionType.BOTH:
		has_key = _has_required_key(player)
	
	if interaction_type == InteractionType.CHALLENGE or interaction_type == InteractionType.BOTH:
		challenge_done = _has_completed_challenge(player)
		if not challenge_done:
			_request_challenge(player)
			return
	
	match interaction_type:
		InteractionType.KEY:
			can_unlock = has_key
		InteractionType.CHALLENGE:
			can_unlock = challenge_done
		InteractionType.BOTH:
			if has_key and challenge_done:
				can_unlock = true
			elif not has_key:
				print("Door: %s precisa da chave %s" % [name, required_key_id])
				_play_locked_feedback()
				return
			else:
				print("Door: %s precisa concluir o desafio %s" % [name, required_challenge_id])
				_play_locked_feedback()
				return
		_:
			can_unlock = false
	
	if can_unlock:
		state = DoorState.UNLOCKED
		_update_visual_state()
		_open()
		print("Door: %s destrancada e aberta" % name)
	else:
		print("Door: %s trancada. Necessário: %s" % [name, _get_required_text()])
		_play_locked_feedback()


func _request_challenge(player: Node3D) -> void:
	var manager = get_node_or_null("/root/ChallengeManager")
	if manager and manager.has_method("show_question"):
		var prompt_text = challenge_question
		if prompt_text.is_empty():
			prompt_text = "Resolva o desafio para abrir a porta."
		manager.show_question(
			required_challenge_id,
			prompt_text,
			challenge_answer,
			func() -> void:
				if player.has_method("complete_challenge"):
					player.complete_challenge(required_challenge_id)
				if interaction_type == InteractionType.BOTH and not _has_required_key(player):
					print("Door: %s concluído, mas a chave ainda é necessária" % name)
					_play_locked_feedback()
					return
				state = DoorState.UNLOCKED
				_update_visual_state()
				_open()
				print("Door: %s liberada após desafio" % name)
		)
		print("Door: %s solicitando desafio %s" % [name, required_challenge_id])
		return
	
	print("Door: %s sem framework de desafio disponível" % name)
	_play_locked_feedback()


func _has_required_key(player: Node3D) -> bool:
	## Verifica se o jogador possui a chave necessária
	if not required_key_id.is_empty():
		if player.has_method("has_item"):
			return player.has_item(required_key_id)
		if "inventory" in player:
			return required_key_id in player.inventory
	return false


func _has_completed_challenge(player: Node3D) -> bool:
	## Verifica se o desafio necessário foi completado
	if not required_challenge_id.is_empty():
		if player.has_method("is_challenge_complete"):
			return player.is_challenge_complete(required_challenge_id)
		if "completed_challenges" in player:
			return required_challenge_id in player.completed_challenges
	return false


func _get_required_text() -> String:
	## Retorna texto descritivo do que é necessário
	var reqs = []
	if interaction_type == InteractionType.KEY or interaction_type == InteractionType.BOTH:
		if not required_key_id.is_empty():
			reqs.append("Chave: %s" % required_key_id)
	if interaction_type == InteractionType.CHALLENGE or interaction_type == InteractionType.BOTH:
		if not required_challenge_id.is_empty():
			reqs.append("Desafio: %s" % required_challenge_id)
	return ", ".join(reqs) if reqs else "Nada"


func _open() -> void:
	## Abre a porta
	state = DoorState.OPEN
	_target_rotation = open_rotation
	_is_animating = true


func _close() -> void:
	## Fecha a porta
	state = DoorState.CLOSED
	_target_rotation = closed_rotation
	_is_animating = true
	_update_visual_state()


func _play_locked_feedback() -> void:
	## Feedback visual/som ao tentar abrir porta trancada
	pass


func unlock() -> void:
	## Força destrancar a porta (útil para puzzles)
	state = DoorState.UNLOCKED
	_update_visual_state()


func lock() -> void:
	## Força trancar a porta
	state = DoorState.LOCKED
	_update_visual_state()
