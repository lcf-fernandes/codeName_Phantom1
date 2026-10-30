class_name DetectionController
extends Node
## Detecção: quando um inimigo que não está em alerta enxerga um soldado (distância e linha de
## visão pelo sight_range dele), ele e todos os inimigos do mesmo grupo (cluster_id) entram em
## alerta. Grupo 0 não é um grupo: só o próprio inimigo é alertado. A posição do soldado é a da
## visão (a célula real durante um movimento).
## Este nó deve ficar depois do VisionSystem na cena, para o vision_cell já estar atualizado
## quando o cell_reached chegar aqui.

const UNITS_GROUP: StringName = &"units"

## Caminho até o VisionSystem (vision_cell e can_see).
@export var vision_system_path: NodePath = ^"../VisionSystem"
## Caminho até o AttackController (um inimigo atacado entra em alerta).
@export var attack_controller_path: NodePath = ^"../AttackController"
## Caminho até o EnemyAI (reação dos inimigos recém-alertados, via scamper).
@export var enemy_ai_path: NodePath = ^"../EnemyAI"

var _vision: VisionSystem
var _attack_controller: AttackController
var _enemy_ai: EnemyAI
# Verdadeiro enquanto uma reação está rodando (uma de cada vez).
var _reacting: bool = false


func _ready() -> void:
	_vision = get_node(vision_system_path) as VisionSystem
	_attack_controller = get_node(attack_controller_path) as AttackController
	_enemy_ai = get_node(enemy_ai_path) as EnemyAI
	assert(_vision != null, "DetectionController: vision_system_path não aponta para um VisionSystem.")
	assert(_attack_controller != null, "DetectionController: attack_controller_path não aponta para um AttackController.")
	assert(_enemy_ai != null, "DetectionController: enemy_ai_path não aponta para um EnemyAI.")
	# Depois de as unidades existirem (os spawners as criam no _ready deles).
	_connect_soldiers.call_deferred()


func _connect_soldiers() -> void:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var soldier: Unit = node as Unit
		if soldier == null or soldier.team != Unit.Team.SQUAD:
			continue
		soldier.cell_reached.connect(_on_cell_reached)
		soldier.move_finished.connect(_on_move_finished)
	_attack_controller.attack_started.connect(_on_attack_started)
	# Na chamada inicial os eventos são ignorados: sem reação.
	_check_detection()


# Um inimigo que ainda não está em alerta e é atacado entra em alerta, com o grupo dele.
func _on_attack_started(_attacker: Unit, defender: Unit) -> void:
	if not is_instance_valid(defender) or defender.hp <= 0:
		return
	if defender.team != Unit.Team.ENEMY or defender.alerted:
		return
	print("Alerta por ataque: %s (grupo %d) foi atacado" % [defender.unit_name, defender.cluster_id])
	_alert_cluster(defender)


# Durante um movimento do soldado: se ele detectou algum grupo, o movimento fica em espera
# (hold_move, pedido de forma síncrona) e a reação roda sem bloquear este tratamento.
func _on_cell_reached(unit: Unit, _cell: Vector2i) -> void:
	var events: Array[Dictionary] = _check_detection()
	if events.is_empty():
		return
	unit.hold_move()
	_run_reactions(events, unit)


# Fim do movimento do soldado: se ele detectou algum grupo, a reação roda sem segurar ninguém.
func _on_move_finished(_unit: Unit) -> void:
	var events: Array[Dictionary] = _check_detection()
	if events.is_empty():
		return
	_run_reactions(events, null)


# Cada inimigo sem alerta que enxerga algum soldado vivo alerta o próprio grupo. Como o grupo todo
# fica em alerta de uma vez, cada grupo é alertado no máximo uma vez por chamada. Devolve um
# evento por grupo alertado: {"enemies": Array[Unit], "soldier": Unit, "cell": Vector2i}.
func _check_detection() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var soldiers: Array[Unit] = []
	var sleepers: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or not is_instance_valid(unit) or unit.hp <= 0:
			continue
		if unit.team == Unit.Team.SQUAD:
			soldiers.append(unit)
		elif not unit.alerted:
			sleepers.append(unit)

	for soldier: Unit in soldiers:
		var position: Vector2i = _vision.vision_cell(soldier)
		for enemy: Unit in sleepers:
			# Pode já ter sido alertado nesta chamada, junto com o grupo dele.
			if enemy.alerted:
				continue
			if not _vision.can_see(enemy.cell, position, enemy.detection_range):
				continue
			print("Detecção: %s visto por %s (grupo %d)" % [soldier.unit_name, enemy.unit_name, enemy.cluster_id])
			var newly_alerted: Array[Unit] = _alert_cluster(enemy)
			if not newly_alerted.is_empty():
				events.append({"enemies": newly_alerted, "soldier": soldier, "cell": position})
	return events


# Alerta todos os inimigos vivos do mesmo grupo; com cluster_id 0, só o próprio inimigo. Devolve,
# em ordem de nome, os que passaram de não alertados a alertados.
func _alert_cluster(enemy: Unit) -> Array[Unit]:
	var newly: Array[Unit] = []
	if enemy.cluster_id == 0:
		if not enemy.alerted:
			enemy.set_alerted(true)
			newly.append(enemy)
		return newly
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var other: Unit = node as Unit
		if other == null or not is_instance_valid(other) or other.hp <= 0:
			continue
		if other.team == Unit.Team.ENEMY and other.cluster_id == enemy.cluster_id and not other.alerted:
			other.set_alerted(true)
			newly.append(other)
	newly.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)
	return newly


# Reação dos inimigos recém-alertados (scamper), um de cada vez. `holder` é o soldado cujo movimento
# está em espera (hold_move já pedido) ou null; ele é solto no fim. Sem holder, os soldados dos
# eventos ficam marcados como ocupados (is_moving) durante a reação, para bloquear cliques e Enter.
func _run_reactions(events: Array[Dictionary], holder: Unit) -> void:
	if _reacting:
		if holder != null and is_instance_valid(holder):
			holder.release_move()
		return
	_reacting = true

	var marked: Array[Unit] = []
	if holder == null:
		for event: Dictionary in events:
			var soldier: Unit = event["soldier"]
			if is_instance_valid(soldier) and not marked.has(soldier):
				soldier.is_moving = true
				marked.append(soldier)

	for event: Dictionary in events:
		var enemies: Array[Unit] = event["enemies"]
		var cell: Vector2i = event["cell"]
		for enemy: Unit in enemies:
			if is_instance_valid(enemy) and enemy.hp > 0:
				await _enemy_ai.scamper(enemy, cell)

	for soldier: Unit in marked:
		if is_instance_valid(soldier):
			soldier.is_moving = false
	_reacting = false
	if holder != null and is_instance_valid(holder):
		holder.release_move()
