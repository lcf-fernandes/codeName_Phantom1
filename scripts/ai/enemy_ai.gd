class_name EnemyAI
extends Node
## IA mínima dos inimigos: no turno deles, cada inimigo vivo anda em direção ao soldado
## vivo mais próximo. Sem ataque, sem revide e sem condição de vitória.

const UNITS_GROUP: StringName = &"units"

## Caminho até o MovementRange (células alcançáveis e caminho).
@export var movement_range_path: NodePath = ^"../MovementRange"
## Caminho até o CombatCalc (distância em passos de grade).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Espera entre um inimigo e o próximo, em segundos.
@export var delay_between_enemies: float = 0.3

var _movement_range: MovementRange
var _combat_calc: CombatCalc


func _ready() -> void:
	_movement_range = get_node(movement_range_path) as MovementRange
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	assert(_movement_range != null, "EnemyAI: movement_range_path não aponta para um MovementRange.")
	assert(_combat_calc != null, "EnemyAI: combat_calc_path não aponta para um CombatCalc.")


## Roda o turno dos inimigos: renova os PA de todos e move um inimigo por vez, em ordem de nome.
## Termina quando todos agiram, ou antes, se não houver soldado vivo.
func run_enemy_turn() -> void:
	var enemies: Array[Unit] = _living_units(Unit.Team.ENEMY)
	enemies.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)
	for enemy: Unit in enemies:
		enemy.reset_actions()

	for i: int in enemies.size():
		var enemy: Unit = enemies[i]
		var target: Unit = _nearest_soldier(enemy)
		if target == null:
			print("IA: sem soldados vivos")
			return

		var from_cell: Vector2i = enemy.cell
		var destination: Vector2i = _choose_destination(enemy, target)
		if destination == from_cell:
			print("IA: %s fica parado" % enemy.unit_name)
		else:
			var path: Array[Vector2i] = _movement_range.get_move_path(enemy, destination)
			enemy.spend_action(1)
			enemy.move_along_path(path)
			await enemy.move_finished
			print("IA: %s -> alvo %s | (%d, %d) -> (%d, %d) | %d passos" % [
				enemy.unit_name, target.unit_name, from_cell.x, from_cell.y,
				enemy.cell.x, enemy.cell.y, path.size()
			])

		if i < enemies.size() - 1:
			await get_tree().create_timer(delay_between_enemies).timeout


# Unidades vivas do lado informado (as mortas saem do grupo "units").
func _living_units(team: Unit.Team) -> Array[Unit]:
	var result: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == team and unit.hp > 0:
			result.append(unit)
	return result


# Soldado vivo mais próximo (distância em passos de grade); empate: menor nome.
func _nearest_soldier(enemy: Unit) -> Unit:
	var best: Unit = null
	var best_distance: int = 0
	for soldier: Unit in _living_units(Unit.Team.SQUAD):
		var distance: int = _combat_calc.get_distance(enemy.cell, soldier.cell)
		if best == null or distance < best_distance \
				or (distance == best_distance and soldier.unit_name < best.unit_name):
			best = soldier
			best_distance = distance
	return best


# Entre as células alcançáveis, a mais perto do alvo; empate: menor custo, depois menor y,
# depois menor x. Se nenhuma for melhor que a posição atual, devolve a própria célula do inimigo.
func _choose_destination(enemy: Unit, target: Unit) -> Vector2i:
	var current_distance: int = _combat_calc.get_distance(enemy.cell, target.cell)
	var reachable: Dictionary[Vector2i, int] = _movement_range.compute_reachable(enemy)

	var found: bool = false
	var best_cell: Vector2i = enemy.cell
	var best_distance: int = current_distance
	var best_cost: int = 0
	for cell: Vector2i in reachable.keys():
		var distance: int = _combat_calc.get_distance(cell, target.cell)
		if distance >= current_distance:
			continue
		var cost: int = reachable[cell]
		if not found or _is_better(distance, cost, cell, best_distance, best_cost, best_cell):
			found = true
			best_cell = cell
			best_distance = distance
			best_cost = cost
	return best_cell


func _is_better(distance: int, cost: int, cell: Vector2i, best_distance: int, best_cost: int, best_cell: Vector2i) -> bool:
	if distance != best_distance:
		return distance < best_distance
	if cost != best_cost:
		return cost < best_cost
	if cell.y != best_cell.y:
		return cell.y < best_cell.y
	return cell.x < best_cell.x
