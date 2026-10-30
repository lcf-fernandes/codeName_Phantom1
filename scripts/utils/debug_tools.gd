class_name DebugTools
extends Node
## Atalhos de teste de vida, dano e morte:
## K = 1 de dano na unidade selecionada; Shift+K = 10 de dano nela;
## L = 1 de dano no primeiro inimigo vivo; Shift+L = 10 de dano nele.
## J = põe em alerta os inimigos vivos do grupo 1; Shift+J = os do grupo 2.
## T = teleporta o soldado selecionado para a célula sob o mouse (sem gastar PA).

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (leitura de selected_unit).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até a câmera (raio até o mouse, para o teleporte com a tecla T).
@export var camera_path: NodePath = ^"../Camera"
## Caminho até o GridManager (célula sob o mouse e posicionamento da unidade).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Caminho até o CoverMap (células com cobertura não recebem teleporte).
@export var cover_map_path: NodePath = ^"../CoverMap"
## Caminho até o TurnManager (o teleporte só vale no turno do jogador).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Liga ou desliga os atalhos de teste.
@export var debug_keys: bool = true

var _selection: SelectionController
var _camera: Camera3D
var _grid_manager: GridManager
var _cover_map: CoverMap
var _turn_manager: TurnManager


func _ready() -> void:
	_selection = get_node(selection_controller_path) as SelectionController
	_camera = get_node(camera_path) as Camera3D
	_grid_manager = get_node(grid_manager_path) as GridManager
	_cover_map = get_node(cover_map_path) as CoverMap
	_turn_manager = get_node(turn_manager_path) as TurnManager
	assert(_selection != null, "DebugTools: selection_controller_path não aponta para um SelectionController.")
	assert(_camera != null, "DebugTools: camera_path não aponta para uma Camera3D.")
	assert(_grid_manager != null, "DebugTools: grid_manager_path não aponta para um GridManager.")
	assert(_cover_map != null, "DebugTools: cover_map_path não aponta para um CoverMap.")
	assert(_turn_manager != null, "DebugTools: turn_manager_path não aponta para um TurnManager.")


func _unhandled_input(event: InputEvent) -> void:
	if not debug_keys:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_K:
			var amount: int = 10 if key_event.shift_pressed else 1
			_damage(_selection.selected_unit, amount)
		KEY_L:
			var enemy_amount: int = 10 if key_event.shift_pressed else 1
			_damage(_first_living_enemy(), enemy_amount)
		KEY_J:
			_alert_cluster(2 if key_event.shift_pressed else 1)
		KEY_T:
			if not key_event.shift_pressed:
				_teleport_selected()


# T: teleporta o soldado selecionado para a célula sob o mouse, sem gastar PA. O fim do teleporte
# emite move_finished (o VisionSystem recalcula a visão e o DetectionController checa a detecção,
# como no fim de um movimento normal) e reseleciona o soldado, porque a ligação do UnitMover com
# move_finished só existe durante os movimentos que ele mesmo inicia.
func _teleport_selected() -> void:
	var soldier: Unit = _selection.selected_unit
	if soldier == null or not is_instance_valid(soldier):
		print("Teleporte ignorado: nenhum soldado selecionado")
		return
	if _turn_manager.side != TurnManager.TurnSide.PLAYER:
		print("Teleporte ignorado: não é o turno do jogador")
		return
	if _is_any_unit_moving():
		print("Teleporte ignorado: movimento em andamento")
		return

	# Célula sob o mouse: raio da câmera, interseção com o plano y = 0 e conversão pelo GridManager.
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = _camera.project_ray_normal(mouse_pos)
	var floor_point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if floor_point == null:
		print("Teleporte ignorado: mouse fora da grade")
		return
	var cell: Vector2i = _grid_manager.world_to_cell(floor_point as Vector3)
	if not _grid_manager.is_inside(cell):
		print("Teleporte ignorado: mouse fora da grade")
		return
	if _cover_map.is_blocked(cell):
		print("Teleporte ignorado: célula com cobertura")
		return
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var other: Unit = node as Unit
		if other != null and other != soldier and other.hp > 0 and other.cell == cell:
			print("Teleporte ignorado: célula ocupada por %s" % other.unit_name)
			return

	var from_cell: Vector2i = soldier.cell
	soldier.place_on_cell(_grid_manager, cell)
	print("Debug: %s teleportado de (%d, %d) para (%d, %d)" % [soldier.unit_name, from_cell.x, from_cell.y, cell.x, cell.y])
	soldier.move_finished.emit(soldier)
	_selection.select_unit(soldier)


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false


# Coloca em alerta todos os inimigos vivos do grupo (cluster_id) informado.
func _alert_cluster(cluster: int) -> void:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.ENEMY and unit.hp > 0 and unit.cluster_id == cluster:
			unit.set_alerted(true)
	print("Debug: grupo %d em alerta" % cluster)


func _first_living_enemy() -> Unit:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.ENEMY and unit.hp > 0:
			return unit
	return null


func _damage(unit: Unit, amount: int) -> void:
	if unit == null:
		print("Dano ignorado: nenhuma unidade alvo")
		return

	# Guarda nome e célula antes: na morte a unidade é liberada no fim do quadro.
	var unit_name: String = unit.unit_name
	var unit_cell: Vector2i = unit.cell
	unit.take_damage(amount)
	print("Dano: %s -%d -> hp %d/%d" % [unit_name, amount, unit.hp, unit.max_hp])
	if unit.hp <= 0:
		print("%s morreu em (%d, %d)" % [unit_name, unit_cell.x, unit_cell.y])
