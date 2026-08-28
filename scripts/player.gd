extends CharacterBody3D

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
@export var gravity = 9.8

var camera_pitch = 0.0

@onready var camera = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Rotação horizontal do corpo do jogador
			rotate_y(-event.relative.x * mouse_sensitivity)

			# Rotação vertical da câmera
			camera_pitch += -event.relative.y * mouse_sensitivity
			camera_pitch = clamp(camera_pitch, deg_to_rad(-90), deg_to_rad(90))
			camera.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var input_dir = Vector3.ZERO

	# Movimento WASD e setas
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	# Aplicar gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Mover o jogador
	var direction = input_dir.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
