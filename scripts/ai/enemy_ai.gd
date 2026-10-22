class_name EnemyAI
extends Node
## IA mínima dos inimigos: no turno deles, cada inimigo vivo escolhe o soldado vivo mais próximo
## e, se puder atacar de onde chega, prefere a célula com melhor cobertura; senão, anda em
## direção ao alvo. Depois ataca se estiver ao alcance. Sem condição de vitória ou derrota.

const UNITS_GROUP: StringName = &"units"

## Caminho até o MovementRange (células alcançáveis e caminho).
@export var movement_range_path: NodePath = ^"../MovementRange"
## Caminho até o CombatCalc (distância em passos de grade).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Espera entre um inimigo e o próximo, em segundos.
@export var delay_between_enemies: float = 0.3
## Caminho até o AttackController (resolve o ataque).
@export var attack_controller_path: NodePath = ^"../AttackController"
## Caminho até o CoverMap (cobertura das células candidatas contra o alvo).
@export var cover_map_path: NodePath = ^"../CoverMap"

var _movement_range: MovementRange
var _combat_calc: CombatCalc
var _attack_controller: AttackController
var _cover_map: CoverMap


func _ready() -> void:
	_movement_range = get_node(movement_range_path) as MovementRange
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	_attack_controller = get_node(attack_controller_path) as AttackController
	_cover_map = get_node(cover_map_path) as CoverMap
	assert(_movement_range != null, "EnemyAI: movement_range_path não aponta para um MovementRange.")
	assert(_combat_calc != null, "EnemyAI: combat_calc_path não aponta para um CombatCalc.")
	assert(_attack_controller != null, "EnemyAI: attack_controller_path não aponta para um AttackController.")
	assert(_cover_map != null, "EnemyAI: cover_map_path não aponta para um CoverMap.")


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
		var cover_label: String = _cover_label(_cover_map.get_cover_against(destination, target.cell))
		if destination == from_cell:
			print("IA: %s fica parado em (%d, %d) | cobertura %s" % [
				enemy.unit_name, from_cell.x, from_cell.y, cover_label
			])
		else:
			var path: Array[Vector2i] = _movement_range.get_move_path(enemy, destination)
			enemy.spend_action(1)
			enemy.move_along_path(path)
			await enemy.move_finished
			print("IA: %s -> alvo %s | (%d, %d) -> (%d, %d) | %d passos | cobertura %s" % [
				enemy.unit_name, target.unit_name, from_cell.x, from_cell.y,
				enemy.cell.x, enemy.cell.y, path.size(), cover_label
			])

		await _try_attack(enemy, target)

		if i < enemies.size() - 1:
			await get_tree().create_timer(delay_between_enemies).timeout


# Depois do movimento (ou de ficar parado): ataca o alvo se ainda houver PA, o alvo estiver vivo
# e a distância for <= attack_range do próprio inimigo. No máximo um ataque por inimigo por turno.
func _try_attack(enemy: Unit, target: Unit) -> void:
	var distance: int = _combat_calc.get_distance(enemy.cell, target.cell)
	var can_attack: bool = enemy.action_points >= _attack_controller.attack_cost \
			and is_instance_valid(target) and target.hp > 0 and distance <= enemy.attack_range
	if can_attack:
		await _attack_controller.perform_attack(enemy, target)
	else:
		print("IA: %s fora de alcance (distância %d)" % [enemy.unit_name, distance])


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


# Escolhe o destino. Candidatos: as células alcançáveis e a célula atual (custo 0), só os que ficam ao
# alcance de ataque do alvo. Se houver algum, vale o de melhor cobertura contra o alvo (HIGH > LOW >
# NONE); empate: menor distância ao alvo, menor custo, menor y, menor x. Se não houver, vale a regra
# de sempre (_choose_closest_destination). Se o escolhido for a célula atual, o inimigo não anda.
func _choose_destination(enemy: Unit, target: Unit) -> Vector2i:
	var costs: Dictionary[Vector2i, int] = {enemy.cell: 0}
	var reachable: Dictionary[Vector2i, int] = _movement_range.compute_reachable(enemy)
	for cell: Vector2i in reachable.keys():
		costs[cell] = reachable[cell]

	var options: Array[Dictionary] = []
	for cell: Vector2i in costs.keys():
		var distance: int = _combat_calc.get_distance(cell, target.cell)
		if distance > enemy.attack_range:
			continue
		options.append({
			"cell": cell,
			"cover": _cover_map.get_cover_against(cell, target.cell),
			"distance": distance,
			"cost": costs[cell],
		})

	if options.is_empty():
		return _choose_closest_destination(enemy, target)

	options.sort_custom(_option_is_better)
	var best_cell: Vector2i = options[0]["cell"]
	return best_cell


# Ordem das opções: melhor cobertura primeiro (NONE < LOW < HIGH na ordem do enum), depois menor
# distância, menor custo, menor y e menor x.
func _option_is_better(a: Dictionary, b: Dictionary) -> bool:
	var cover_a: int = a["cover"]
	var cover_b: int = b["cover"]
	if cover_a != cover_b:
		return cover_a > cover_b
	var distance_a: int = a["distance"]
	var distance_b: int = b["distance"]
	if distance_a != distance_b:
		return distance_a < distance_b
	var cost_a: int = a["cost"]
	var cost_b: int = b["cost"]
	if cost_a != cost_b:
		return cost_a < cost_b
	var cell_a: Vector2i = a["cell"]
	var cell_b: Vector2i = b["cell"]
	if cell_a.y != cell_b.y:
		return cell_a.y < cell_b.y
	return cell_a.x < cell_b.x


func _cover_label(cover: CoverMap.CoverType) -> String:
	match cover:
		CoverMap.CoverType.LOW:
			return "Baixa"
		CoverMap.CoverType.HIGH:
			return "Alta"
		_:
			return "Nenhuma"


# Entre as células alcançáveis, a mais perto do alvo; empate: menor custo, depois menor y,
# depois menor x. Se nenhuma for melhor que a posição atual, devolve a própria célula do inimigo.
func _choose_closest_destination(enemy: Unit, target: Unit) -> Vector2i:
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
