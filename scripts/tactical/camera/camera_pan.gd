class_name CameraPan
extends Camera3D
## Câmera que se move no plano do chão (WASD ou setas) e centraliza no soldado selecionado (Espaço).
## A rotação, o fov e o v_offset não mudam: o que se move é um ponto-alvo no chão, o que está no
## centro da tela, e a câmera fica sempre a um deslocamento fixo dele.

## Velocidade do movimento da câmera, em metros por segundo.
@export var pan_speed: float = 24.0
## Caminho até o GridManager (limites do mapa).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Caminho até o SelectionController (soldado selecionado).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Duração da centralização suave no soldado (Espaço), em segundos.
@export var recenter_time: float = 0.25
## Célula em que a câmera começa centralizada; (-1, -1) mantém o enquadramento da cena.
@export var start_cell: Vector2i = Vector2i(-1, -1)

var _grid_manager: GridManager
var _selection: SelectionController
# Ponto do chão (y = 0) que está no centro da tela.
var _target: Vector3 = Vector3.ZERO
# Posição da câmera menos o ponto-alvo: constante durante o jogo.
var _offset: Vector3 = Vector3.ZERO
var _recenter_tween: Tween


func _ready() -> void:
	_grid_manager = get_node(grid_manager_path) as GridManager
	_selection = get_node(selection_controller_path) as SelectionController
	assert(_grid_manager != null, "CameraPan: grid_manager_path não aponta para um GridManager.")
	assert(_selection != null, "CameraPan: selection_controller_path não aponta para um SelectionController.")

	# O raio do centro da tela leva em conta o v_offset; a interseção com y = 0 é o ponto-alvo.
	var screen_center: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var origin: Vector3 = project_ray_origin(screen_center)
	var direction: Vector3 = project_ray_normal(screen_center)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	assert(hit != null, "CameraPan: o centro da tela não encontra o plano do chão.")
	_target = hit as Vector3
	_offset = global_position - _target
	# Adiado: o GridManager ainda não achou o chão quando este _ready roda (a câmera vem antes dele).
	_apply_start_cell.call_deferred()


# Move o ponto-alvo para a célula inicial (se definida), dentro dos limites, e posiciona a câmera.
func _apply_start_cell() -> void:
	if start_cell == Vector2i(-1, -1):
		return
	var world: Vector3 = _grid_manager.cell_to_world(start_cell)
	_target = _clamped(Vector3(world.x, 0.0, world.z))
	global_position = _target + _offset


func _process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0

	if input != Vector2.ZERO:
		# Mover à mão interrompe a centralização suave.
		if _recenter_tween != null and _recenter_tween.is_valid():
			_recenter_tween.kill()
		input = input.normalized()
		_target.x += input.x * pan_speed * delta
		_target.z += input.y * pan_speed * delta

	_target = _clamped(_target)
	global_position = _target + _offset


# Espaço: centraliza suavemente no soldado selecionado (sem seleção, não faz nada).
func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo or key_event.keycode != KEY_SPACE:
		return
	var unit: Unit = _selection.selected_unit
	if unit == null or not is_instance_valid(unit):
		return

	var destination: Vector3 = _clamped(Vector3(unit.global_position.x, 0.0, unit.global_position.z))
	if _recenter_tween != null and _recenter_tween.is_valid():
		_recenter_tween.kill()
	_recenter_tween = create_tween()
	_recenter_tween.tween_property(self, "_target", destination, recenter_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	get_viewport().set_input_as_handled()


# Limita o ponto-alvo à metade da largura e da profundidade da grade (centrada na origem).
func _clamped(point: Vector3) -> Vector3:
	var floor_ref: GridFloor = _grid_manager.grid_floor
	if floor_ref == null:
		return point
	var half_width: float = floor_ref.grid_width * floor_ref.cell_size * 0.5
	var half_depth: float = floor_ref.grid_depth * floor_ref.cell_size * 0.5
	return Vector3(clampf(point.x, -half_width, half_width), 0.0, clampf(point.z, -half_depth, half_depth))
