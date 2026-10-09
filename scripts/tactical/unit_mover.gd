class_name UnitMover
extends Node3D
## Move o soldado selecionado, célula por célula e pelo caminho mais curto, até a célula alcançável clicada.
## Clique em qualquer outra célula (ou fora da grade) limpa a seleção.
## Enquanto alguma unidade se move, todos os cliques são ignorados.

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (sinal cell_clicked e soldado selecionado).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o MovementRange (cálculo de alcance e de caminhos).
@export var movement_range_path: NodePath = ^"../MovementRange"
## Caminho até o TurnManager (de quem é a vez).
@export var turn_manager_path: NodePath = ^"../TurnManager"

var _selection: SelectionController
var _movement_range: MovementRange
var _turn_manager: TurnManager


func _ready() -> void:
	_selection = get_node(selection_controller_path) as SelectionController
	_movement_range = get_node(movement_range_path) as MovementRange
	_turn_manager = get_node(turn_manager_path) as TurnManager
	assert(_selection != null, "UnitMover: selection_controller_path não aponta para um SelectionController.")
	assert(_movement_range != null, "UnitMover: movement_range_path não aponta para um MovementRange.")
	assert(_turn_manager != null, "UnitMover: turn_manager_path não aponta para um TurnManager.")
	_selection.cell_clicked.connect(_on_cell_clicked)
	_turn_manager.turn_started.connect(_on_turn_started)


# _input roda antes de qualquer _unhandled_input, então este bloqueio vale
# para a seleção, o movimento e a limpeza, independentemente da ordem dos nós.
func _input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if _turn_manager.side == TurnManager.TurnSide.ENEMY:
		print("Clique ignorado: turno dos inimigos")
		get_viewport().set_input_as_handled()
		return
	if _is_any_unit_moving():
		print("Clique ignorado: movimento em andamento")
		get_viewport().set_input_as_handled()


func _on_cell_clicked(cell: Vector2i) -> void:
	var unit: Unit = _selection.selected_unit
	if unit == null:
		_selection.clear_selection()
		return

	# Sem PA: o clique no chão é ignorado e a seleção continua.
	if unit.action_points <= 0:
		print("%s sem PA" % unit.unit_name)
		return

	var path: Array[Vector2i] = _movement_range.get_move_path(unit, cell)
	if path.is_empty():
		_selection.clear_selection()
		return

	var parts: PackedStringArray = PackedStringArray()
	parts.append("(%d, %d)" % [unit.cell.x, unit.cell.y])
	for step: Vector2i in path:
		parts.append("(%d, %d)" % [step.x, step.y])
	print("Caminho: %s" % " -> ".join(parts))

	# Cada movimento gasta 1 PA, descontado no início.
	unit.spend_action(1)
	# Durante o movimento, esconde o marcador amarelo e os quadrados azuis.
	_selection.hide_marker()
	_movement_range.hide_range()
	unit.move_finished.connect(_on_move_finished, CONNECT_ONE_SHOT)
	unit.move_along_path(path)


func _on_move_finished(unit: Unit) -> void:
	# Reseleciona o mesmo soldado: o marcador vai para a nova célula e o
	# MovementRange recalcula e mostra o alcance a partir dela.
	_selection.select_unit(unit)
	print("Movimento concluído: %s em (%d, %d)" % [unit.unit_name, unit.cell.x, unit.cell.y])


# Turno dos inimigos: esconde o alcance. Volta ao jogador: reseleciona o soldado
# para mostrar o marcador e o alcance com os PA renovados.
func _on_turn_started(_turn_number: int, side: TurnManager.TurnSide) -> void:
	var unit: Unit = _selection.selected_unit
	if unit == null:
		return
	if side == TurnManager.TurnSide.ENEMY:
		_movement_range.hide_range()
	else:
		_selection.select_unit(unit)


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false
