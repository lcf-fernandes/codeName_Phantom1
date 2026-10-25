class_name OverwatchController
extends Node
## Reação da Vigilância: quando um inimigo termina de andar até uma célula (sinal cell_reached) ao
## alcance de soldados em vigilância, o movimento dele fica em espera (hold_move) e cada soldado
## atira nele, em ordem de nome, com uma penalidade na chance. Depois o movimento é solto.

const UNITS_GROUP: StringName = &"units"

## Penalidade, em pontos percentuais, na chance dos tiros de vigilância.
@export var overwatch_penalty: int = 15
## Caminho até o AttackController (resolve os tiros).
@export var attack_controller_path: NodePath = ^"../AttackController"
## Caminho até o CombatCalc (distância entre células).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Caminho até o VisionSystem (linha de visão do soldado em vigilância).
@export var vision_system_path: NodePath = ^"../VisionSystem"

var _attack_controller: AttackController
var _combat_calc: CombatCalc
var _vision: VisionSystem


func _ready() -> void:
	_attack_controller = get_node(attack_controller_path) as AttackController
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	_vision = get_node(vision_system_path) as VisionSystem
	assert(_attack_controller != null, "OverwatchController: attack_controller_path não aponta para um AttackController.")
	assert(_combat_calc != null, "OverwatchController: combat_calc_path não aponta para um CombatCalc.")
	assert(_vision != null, "OverwatchController: vision_system_path não aponta para um VisionSystem.")
	# Depois de os inimigos existirem (os spawners criam as unidades no _ready deles).
	_connect_enemies.call_deferred()


func _connect_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.ENEMY:
			unit.cell_reached.connect(_on_cell_reached)


# O inimigo acabou de chegar a `cell` (a célula lógica dele só muda no fim do movimento).
func _on_cell_reached(enemy: Unit, cell: Vector2i) -> void:
	if not is_instance_valid(enemy) or enemy.hp <= 0:
		return

	var watchers: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var soldier: Unit = node as Unit
		if soldier == null or soldier.team != Unit.Team.SQUAD:
			continue
		if soldier.hp <= 0 or not soldier.is_overwatching:
			continue
		# Ao alcance e com linha de visão até a célula do sinal.
		if _combat_calc.get_distance(soldier.cell, cell) <= soldier.attack_range \
				and _vision.can_see(soldier.cell, cell, soldier.sight_range):
			watchers.append(soldier)
	if watchers.is_empty():
		return
	watchers.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)

	# A espera precisa ser pedida de forma síncrona, antes de qualquer await.
	enemy.hold_move()
	_resolve_reactions(enemy, cell, watchers)


# Coroutine: cada soldado em vigilância atira, um de cada vez; no fim o movimento do inimigo é solto.
func _resolve_reactions(enemy: Unit, cell: Vector2i, watchers: Array[Unit]) -> void:
	for soldier: Unit in watchers:
		# Se o inimigo morreu, os soldados restantes continuam em vigilância.
		if not is_instance_valid(enemy) or enemy.hp <= 0:
			break
		if not is_instance_valid(soldier) or soldier.hp <= 0 or not soldier.is_overwatching:
			continue

		# Nomes guardados antes de qualquer espera: as unidades podem deixar de existir.
		var soldier_name: String = soldier.unit_name
		var enemy_name: String = enemy.unit_name
		soldier.consume_overwatch()
		print("Vigilância: %s reage a %s em (%d, %d)" % [soldier_name, enemy_name, cell.x, cell.y])
		await _attack_controller.perform_attack(soldier, enemy, overwatch_penalty, cell)

	if is_instance_valid(enemy):
		enemy.release_move()
