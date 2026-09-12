extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8
@export var interaction_distance: float = 3.0

var camera_pitch: float = 0.0
var inventory: Array[String] = []
var completed_challenges: Array[String] = []
var current_focused: Node = null

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var interaction_prompt: Label = $HUD/InteractionMessage
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Cria a collision shape com dimensões corretas
	if collision_shape:
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.35
		capsule.height = 0.4  # total height = 0.4 + 2*0.35 = 1.1
		collision_shape.shape = capsule
		collision_shape.position.y = 0.65  # centro do capsule mais baixo
	
	# Posiciona a câmera no nível dos olhos
	if camera:
		camera.position.y = 1.6
	
	_configure_raycast()
	
	if interaction_prompt:
		interaction_prompt.text = ""


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera_pitch += -event.relative.y * mouse_sensitivity
			camera_pitch = clamp(camera_pitch, deg_to_rad(-90), deg_to_rad(90))
			camera.rotation.x = camera_pitch
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var direction = input_dir.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	move_and_slide()
	_configure_raycast()
	_update_focus()


func _configure_raycast() -> void:
	if not camera:
		return
	
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "RayCast3D"
		camera.add_child(raycast)
	
	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -interaction_distance)
	raycast.collision_mask = 1
	raycast.collide_with_areas = false
	raycast.collide_with_bodies = true
	raycast.exclude_parent = true
	raycast.hit_from_inside = false


func _update_focus() -> void:
	if not raycast:
		return
	
	raycast.force_raycast_update()
	
	var new_focused: Node = null
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider != null and collider != self:
			new_focused = _find_interactable(collider)
	
	if new_focused != current_focused:
		if current_focused and current_focused.has_method("set_highlight"):
			current_focused.set_highlight(false)
		
		current_focused = new_focused
		
		if current_focused:
			if current_focused.has_method("set_highlight"):
				current_focused.set_highlight(true)
			_update_prompt("[E] %s" % current_focused.action_name)
		else:
			_update_prompt("")


func _find_interactable(node: Node) -> Node:
	if node == null:
		return null
	
	if node.is_in_group("interactive"):
		return node
	
	var parent = node.get_parent()
	while parent:
		if parent.is_in_group("interactive"):
			return parent
		parent = parent.get_parent()
	
	return null


func _try_interact() -> void:
	if current_focused and current_focused.has_method("can_interact") and current_focused.has_method("interact"):
		if current_focused.can_interact(self):
			current_focused.interact(self)


func _update_prompt(text: String) -> void:
	if interaction_prompt:
		interaction_prompt.text = text


# === Inventário (para usar com portas trancadas) ===

func add_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
		print("Player: item '%s' adicionado ao inventário" % item_id)


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func remove_item(item_id: String) -> bool:
	var idx = inventory.find(item_id)
	if idx >= 0:
		inventory.remove_at(idx)
		return true
	return false


# === Desafios (para usar com portas que requerem puzzle) ===

func complete_challenge(challenge_id: String) -> void:
	if not completed_challenges.has(challenge_id):
		completed_challenges.append(challenge_id)
		print("Player: desafio '%s' completado" % challenge_id)


func is_challenge_complete(challenge_id: String) -> bool:
	return completed_challenges.has(challenge_id)
