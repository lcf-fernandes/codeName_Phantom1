class_name DebugTools
extends Node
## Atalhos de teste de vida, dano e morte:
## K = 1 de dano na unidade selecionada; Shift+K = 10 de dano nela;
## L = 1 de dano no primeiro inimigo vivo; Shift+L = 10 de dano nele.
## J = põe em alerta os inimigos vivos do grupo 1; Shift+J = os do grupo 2.

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (leitura de selected_unit).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Liga ou desliga os atalhos de teste.
@export var debug_keys: bool = true

var _selection: SelectionController


func _ready() -> void:
	_selection = get_node(selection_controller_path) as SelectionController
	assert(_selection != null, "DebugTools: selection_controller_path não aponta para um SelectionController.")


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
