class_name AttackController
extends Node
## Um soldado selecionado ataca o inimigo clicado.
## Sem IA dos inimigos e sem revide. A chance vem do CombatCalc; o dano e o custo são exports.

const UNITS_GROUP: StringName = &"units"

## Caminho até o SelectionController (soldado selecionado e sinal enemy_clicked).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o TurnManager (de quem é a vez).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Caminho até o CombatCalc (chance de acerto).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## PA gastos por ataque.
@export var attack_cost: int = 1
## Dano de um ataque que acerta.
@export var attack_damage: int = 2
## 0 = rolagem aleatória (1 a 100); de 1 a 100 = rolagem fixa, só para teste.
@export_range(0, 100) var forced_roll: int = 0
## Duração do texto flutuante, em segundos.
@export var feedback_duration: float = 1.0
## Altura inicial do texto flutuante acima do chão, em metros.
@export var feedback_height: float = 2.7
## Quanto o texto sobe durante a animação, em metros.
@export var feedback_rise: float = 0.8

var _selection: SelectionController
var _turn_manager: TurnManager
var _combat_calc: CombatCalc


func _ready() -> void:
	_selection = get_node(selection_controller_path) as SelectionController
	_turn_manager = get_node(turn_manager_path) as TurnManager
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	assert(_selection != null, "AttackController: selection_controller_path não aponta para um SelectionController.")
	assert(_turn_manager != null, "AttackController: turn_manager_path não aponta para um TurnManager.")
	assert(_combat_calc != null, "AttackController: combat_calc_path não aponta para um CombatCalc.")
	_selection.enemy_clicked.connect(_on_enemy_clicked)


func _on_enemy_clicked(enemy: Unit) -> void:
	var soldier: Unit = _selection.selected_unit
	if soldier == null:
		print("Ataque ignorado: nenhum soldado selecionado")
		return
	if _turn_manager.side != TurnManager.TurnSide.PLAYER:
		print("Ataque ignorado: turno dos inimigos")
		return
	if _is_any_unit_moving():
		print("Ataque ignorado: movimento em andamento")
		return
	if not is_instance_valid(enemy) or enemy.hp <= 0:
		print("Ataque ignorado: o inimigo já morreu")
		return
	if soldier.action_points < attack_cost:
		print("%s sem PA" % soldier.unit_name)
		return

	var chance: int = _combat_calc.get_hit_chance(soldier.cell, enemy.cell)
	var roll: int = forced_roll if forced_roll != 0 else randi_range(1, 100)
	var hit: bool = roll <= chance

	# Guarda o que a morte pode apagar (a unidade é liberada no fim do quadro).
	var enemy_name: String = enemy.unit_name
	var enemy_cell: Vector2i = enemy.cell
	var enemy_position: Vector3 = enemy.global_position
	var hp_before: int = enemy.hp

	soldier.spend_action(attack_cost)
	if hit:
		enemy.take_damage(attack_damage)
	var damage_dealt: int = hp_before - enemy.hp

	print("Ataque: %s -> %s | chance %d%% | rolagem %d -> %s | dano %d | hp %d/%d" % [
		soldier.unit_name, enemy_name, chance, roll, "ACERTOU" if hit else "ERROU",
		damage_dealt, enemy.hp, enemy.max_hp
	])
	# A unidade em si não imprime nada ao morrer (isso é feito pelo DebugTools nos atalhos de teste).
	if enemy.hp <= 0:
		print("%s morreu em (%d, %d)" % [enemy_name, enemy_cell.x, enemy_cell.y])

	if hit:
		_show_feedback(enemy_position, "-%d" % damage_dealt, Color(1.0, 0.35, 0.25))
	else:
		_show_feedback(enemy_position, "ERROU", Color(0.9, 0.9, 0.9))

	# Como depois de um movimento: o marcador continua e o alcance é recalculado
	# (com 0 PA os quadrados azuis somem); o HUD acompanha os PA sozinho.
	_selection.select_unit(soldier)


# Texto flutuante sobre o inimigo: sobe um pouco e some. Criado e removido por este nó.
func _show_feedback(world_position: Vector3, text: String, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.name = "AttackFeedback"
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.outline_size = 16
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.no_depth_test = true
	add_child(label)
	label.global_position = world_position + Vector3(0.0, feedback_height, 0.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + feedback_rise, feedback_duration)
	tween.tween_property(label, "modulate:a", 0.0, feedback_duration)
	tween.tween_property(label, "outline_modulate:a", 0.0, feedback_duration)
	tween.chain().tween_callback(label.queue_free)


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false
