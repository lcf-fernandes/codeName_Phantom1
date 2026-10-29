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

var _vision: VisionSystem
var _attack_controller: AttackController


func _ready() -> void:
	_vision = get_node(vision_system_path) as VisionSystem
	_attack_controller = get_node(attack_controller_path) as AttackController
	assert(_vision != null, "DetectionController: vision_system_path não aponta para um VisionSystem.")
	assert(_attack_controller != null, "DetectionController: attack_controller_path não aponta para um AttackController.")
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
	_check_detection()


# Um inimigo que ainda não está em alerta e é atacado entra em alerta, com o grupo dele.
func _on_attack_started(_attacker: Unit, defender: Unit) -> void:
	if not is_instance_valid(defender) or defender.hp <= 0:
		return
	if defender.team != Unit.Team.ENEMY or defender.alerted:
		return
	print("Alerta por ataque: %s (grupo %d) foi atacado" % [defender.unit_name, defender.cluster_id])
	_alert_cluster(defender)


func _on_cell_reached(_unit: Unit, _cell: Vector2i) -> void:
	_check_detection()


func _on_move_finished(_unit: Unit) -> void:
	_check_detection()


# Cada inimigo sem alerta que enxerga algum soldado vivo alerta o próprio grupo. Como o grupo todo
# fica em alerta de uma vez, cada grupo é alertado no máximo uma vez por chamada.
func _check_detection() -> void:
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
			_alert_cluster(enemy)


# Alerta todos os inimigos vivos do mesmo grupo; com cluster_id 0, só o próprio inimigo.
func _alert_cluster(enemy: Unit) -> void:
	if enemy.cluster_id == 0:
		enemy.set_alerted(true)
		return
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var other: Unit = node as Unit
		if other == null or not is_instance_valid(other) or other.hp <= 0:
			continue
		if other.team == Unit.Team.ENEMY and other.cluster_id == enemy.cluster_id:
			other.set_alerted(true)
