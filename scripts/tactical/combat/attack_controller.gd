class_name AttackController
extends Node
## Um soldado selecionado ataca o inimigo clicado.
## Sem IA dos inimigos e sem revide. A chance vem do CombatCalc; o dano e o custo são exports.

const UNITS_GROUP: StringName = &"units"

## Emitido quando o modo de mira liga ou desliga.
signal attack_mode_changed(active: bool)

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
## Caminho até o MovementRange (esconde e redesenha as células coloridas).
@export var movement_range_path: NodePath = ^"../MovementRange"
## Caminho até o GridManager (posição dos marcadores de alvo).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Cor dos marcadores de alvo do modo de mira (vermelho semitransparente).
@export var target_marker_color: Color = Color(1.0, 0.15, 0.15, 0.45)
## Lado dos marcadores de alvo, em metros.
@export var target_marker_size: float = 1.8
## Altura dos marcadores de alvo acima do chão, em metros.
@export var target_marker_height: float = 0.025
## Distância (em células) a partir da qual o ataque mostra um projétil; mais perto, sem projétil.
@export var min_projectile_distance: int = 2
## Raio do projétil, em metros.
@export var projectile_radius: float = 0.12
## Velocidade do projétil, em metros por segundo (o voo dura entre 0,15 s e 0,5 s).
@export var projectile_speed: float = 30.0
## Cor do projétil (amarelo, com brilho).
@export var projectile_color: Color = Color(1.0, 0.9, 0.2)

## Verdadeiro enquanto o jogador escolhe o alvo do ataque.
var attack_mode: bool = false

var _selection: SelectionController
var _turn_manager: TurnManager
var _combat_calc: CombatCalc
var _movement_range: MovementRange
var _grid_manager: GridManager
var _marker_mesh: PlaneMesh
var _marker_material: StandardMaterial3D
var _markers: Array[MeshInstance3D] = []


func _ready() -> void:
	_selection = get_node(selection_controller_path) as SelectionController
	_turn_manager = get_node(turn_manager_path) as TurnManager
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	_movement_range = get_node(movement_range_path) as MovementRange
	_grid_manager = get_node(grid_manager_path) as GridManager
	assert(_selection != null, "AttackController: selection_controller_path não aponta para um SelectionController.")
	assert(_turn_manager != null, "AttackController: turn_manager_path não aponta para um TurnManager.")
	assert(_combat_calc != null, "AttackController: combat_calc_path não aponta para um CombatCalc.")
	assert(_movement_range != null, "AttackController: movement_range_path não aponta para um MovementRange.")
	assert(_grid_manager != null, "AttackController: grid_manager_path não aponta para um GridManager.")

	_marker_mesh = PlaneMesh.new()
	_marker_mesh.size = Vector2(target_marker_size, target_marker_size)
	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = target_marker_color
	_marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_selection.enemy_clicked.connect(_on_enemy_clicked)
	_selection.unit_selected.connect(_on_unit_selected)
	_selection.selection_cleared.connect(_on_selection_cleared)
	_turn_manager.turn_started.connect(_on_turn_changed)
	_turn_manager.turn_ended.connect(_on_turn_changed)


# Se uma unidade começa a se mover, o modo de mira termina (as células já foram escondidas).
func _process(_delta: float) -> void:
	if attack_mode and _is_any_unit_moving():
		cancel_attack_mode(false)


# Esc ou botão direito cancelam o modo de mira e restauram as células coloridas.
func _unhandled_input(event: InputEvent) -> void:
	if not attack_mode:
		return
	var cancel: bool = false
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		cancel = true
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		cancel = true
	if cancel:
		cancel_attack_mode(true)
		get_viewport().set_input_as_handled()


## Liga o modo de mira: esconde as células coloridas e marca os inimigos vivos ao alcance.
## Não faz nada sem soldado selecionado, fora do turno do jogador, com unidade em movimento,
## sem PA para atacar ou sem inimigo ao alcance.
func enter_attack_mode() -> void:
	if attack_mode:
		return
	var soldier: Unit = _selection.selected_unit
	if soldier == null or not is_instance_valid(soldier):
		return
	if _turn_manager.side != TurnManager.TurnSide.PLAYER or _is_any_unit_moving():
		return
	if soldier.action_points < attack_cost:
		return
	var targets: Array[Unit] = _enemies_in_range(soldier)
	if targets.is_empty():
		return

	attack_mode = true
	_movement_range.hide_range()
	for enemy: Unit in targets:
		_add_marker(enemy)
	attack_mode_changed.emit(true)


## Desliga o modo de mira e remove os marcadores. Com restore_cells, redesenha as células
## coloridas do soldado selecionado direto no MovementRange (sem refazer a seleção).
func cancel_attack_mode(restore_cells: bool = true) -> void:
	if not attack_mode:
		return
	attack_mode = false
	_clear_markers()
	attack_mode_changed.emit(false)

	if restore_cells:
		var soldier: Unit = _selection.selected_unit
		if soldier != null and is_instance_valid(soldier):
			_movement_range._on_unit_selected(soldier)


## Liga o modo de mira se estiver desligado; se estiver ligado, cancela restaurando as células.
func toggle_attack_mode() -> void:
	if attack_mode:
		cancel_attack_mode(true)
	else:
		enter_attack_mode()


# Mudança de seleção ou de turno: o fluxo que disparou já cuida das células, então não restaura.
func _on_unit_selected(_unit: Unit) -> void:
	cancel_attack_mode(false)


func _on_selection_cleared() -> void:
	cancel_attack_mode(false)


func _on_turn_changed(_turn_number: int, _side: TurnManager.TurnSide) -> void:
	cancel_attack_mode(false)


# Inimigos vivos a distância <= attack_range do soldado.
func _enemies_in_range(soldier: Unit) -> Array[Unit]:
	var result: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var enemy: Unit = node as Unit
		if enemy == null or enemy.team != Unit.Team.ENEMY or enemy.hp <= 0:
			continue
		if _combat_calc.get_distance(soldier.cell, enemy.cell) <= soldier.attack_range:
			result.append(enemy)
	return result


# Marcador de alvo: quadrado vermelho achatado sob o inimigo.
func _add_marker(enemy: Unit) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "TargetMarker"
	marker.mesh = _marker_mesh
	marker.material_override = _marker_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	marker.global_position = _grid_manager.cell_to_world(enemy.cell) + Vector3(0.0, target_marker_height, 0.0)
	_markers.append(marker)


func _clear_markers() -> void:
	for marker: MeshInstance3D in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()


func _on_enemy_clicked(enemy: Unit) -> void:
	# Fora do modo de mira, clicar em inimigo não ataca.
	if not attack_mode:
		print("Use o botão Atacar (tecla 1)")
		return

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

	var distance: int = _combat_calc.get_distance(soldier.cell, enemy.cell)
	if distance > soldier.attack_range:
		print("Ataque ignorado: fora de alcance (distância %d, alcance %d)" % [distance, soldier.attack_range])
		return

	# O modo termina ANTES do ataque; as células são redesenhadas pela reseleção logo abaixo.
	cancel_attack_mode(false)
	await perform_attack(soldier, enemy)

	# Como depois de um movimento: o marcador continua e o alcance é recalculado
	# (com 0 PA os quadrados azuis somem); o HUD acompanha os PA sozinho.
	if is_instance_valid(soldier):
		_selection.select_unit(soldier)


## Resolve um ataque: calcula a chance, faz a rolagem (respeitando forced_roll), gasta os PA do
## atacante, aplica o dano, imprime o resultado, mostra o texto flutuante e imprime a morte,
## se o defensor morrer. Não faz nenhuma checagem de turno nem de alcance: quem chama decide.
func perform_attack(attacker: Unit, defender: Unit) -> void:
	var chance: int = _combat_calc.get_hit_chance(attacker.cell, defender.cell, defender.is_defending)
	var roll: int = forced_roll if forced_roll != 0 else randi_range(1, 100)
	var hit: bool = roll <= chance

	# Animações (só visuais): o atacante avança; se acertou, o defensor reage quando o golpe chega
	# (com projétil, quando ele chega).
	attacker.play_attack_animation(defender)
	var hit_delay: float = attacker.lunge_out_time
	if _combat_calc.get_distance(attacker.cell, defender.cell) >= min_projectile_distance:
		hit_delay += _spawn_projectile(attacker, defender, hit)

	# O atacante fica "ocupado" (is_moving) até o impacto; quem bloqueia cliques e turnos lê isso.
	attacker.spend_action(attack_cost)
	# Nomes guardados antes da espera: as unidades podem deixar de existir até o impacto.
	var attacker_name: String = attacker.unit_name
	var defender_name: String = defender.unit_name
	attacker.is_moving = true

	# Espera o impacto: o avanço do atacante e, havendo projétil, o voo dele.
	await get_tree().create_timer(hit_delay).timeout

	# No impacto o alvo pode já não existir (ou ter morrido) nesse meio tempo.
	if not is_instance_valid(defender) or defender.hp <= 0:
		print("Ataque cancelado: alvo indisponível")
		if is_instance_valid(attacker):
			attacker.is_moving = false
		return

	# Guarda o que a morte pode apagar: a unidade só é liberada ao fim da animação de morte (alguns
	# décimos de segundo depois), mas já sai do grupo "units" e perde o colisor de clique na hora.
	var defender_cell: Vector2i = defender.cell
	var defender_position: Vector3 = defender.global_position
	var hp_before: int = defender.hp

	if hit:
		# A reação vem antes do dano: se o golpe matar, a animação de morte já a incorpora (chamar
		# play_hit_animation depois do take_damage interromperia a morte e a unidade não seria liberada).
		defender.play_hit_animation(0.0)
		defender.take_damage(attack_damage)
	var damage_dealt: int = hp_before - defender.hp

	if hit:
		_show_feedback(defender_position, "-%d" % damage_dealt, Color(1.0, 0.35, 0.25))
	else:
		_show_feedback(defender_position, "ERROU", Color(0.9, 0.9, 0.9))

	print("Ataque: %s -> %s | chance %d%% | rolagem %d -> %s | dano %d | hp %d/%d" % [
		attacker_name, defender_name, chance, roll, "ACERTOU" if hit else "ERROU",
		damage_dealt, defender.hp, defender.max_hp
	])
	# A unidade em si não imprime nada ao morrer (isso é feito pelo DebugTools nos atalhos de teste).
	if defender.hp <= 0:
		print("%s morreu em (%d, %d)" % [defender_name, defender_cell.x, defender_cell.y])

	# Fim do ataque: o atacante deixa de ficar "ocupado".
	if is_instance_valid(attacker):
		attacker.is_moving = false


const PROJECTILE_MIN_TIME: float = 0.15
const PROJECTILE_MAX_TIME: float = 0.5
const MISS_SIDE_OFFSET: float = 0.7
const MISS_OVERSHOOT: float = 1.5


# Projétil visual (só efeito): esfera amarela com brilho, na raiz da cena, que sai do Body do atacante
# depois do avanço e voa em linha reta até o Body do defensor (acerto) ou passa ao lado dele (erro:
# 0,7 m para o lado e 1,5 m além). Devolve o tempo de voo, para o defensor piscar quando ele chega.
func _spawn_projectile(attacker: Unit, defender: Unit, hit: bool) -> float:
	var start_estimate: Vector3 = _body_position(attacker)
	var target_position: Vector3 = _body_position(defender)

	var end_position: Vector3 = target_position
	if not hit:
		var shot: Vector3 = target_position - start_estimate
		shot.y = 0.0
		if shot.length() > 0.001:
			var forward: Vector3 = shot.normalized()
			var side: Vector3 = Vector3(-forward.z, 0.0, forward.x)
			if randf() < 0.5:
				side = -side
			end_position = target_position + side * MISS_SIDE_OFFSET + forward * MISS_OVERSHOOT

	# Velocidade constante, com o voo total entre 0,15 s e 0,5 s.
	var flight_time: float = clampf(
		start_estimate.distance_to(end_position) / maxf(projectile_speed, 0.001),
		PROJECTILE_MIN_TIME, PROJECTILE_MAX_TIME
	)

	var projectile: MeshInstance3D = MeshInstance3D.new()
	projectile.name = "Projectile"
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = projectile_radius
	mesh.height = projectile_radius * 2.0
	projectile.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = projectile_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = projectile_color
	material.emission_energy_multiplier = 2.0
	projectile.material_override = material
	projectile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	projectile.process_mode = Node.PROCESS_MODE_ALWAYS
	projectile.visible = false
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = start_estimate

	var tween: Tween = projectile.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(attacker.lunge_out_time)
	tween.tween_callback(_launch_projectile.bind(projectile, attacker, start_estimate))
	tween.tween_property(projectile, "global_position", end_position, flight_time)
	tween.tween_callback(projectile.queue_free)
	return flight_time


# Começo do voo: o projétil aparece no Body do atacante (que acabou de avançar).
func _launch_projectile(projectile: MeshInstance3D, attacker: Unit, fallback: Vector3) -> void:
	projectile.global_position = _body_position(attacker) if is_instance_valid(attacker) else fallback
	projectile.visible = true


# Posição global do Body da unidade (ou 0,6 m acima da raiz, se não houver Body).
func _body_position(unit: Unit) -> Vector3:
	var body: Node3D = unit.get_node_or_null("Body") as Node3D
	if body != null:
		return body.global_position
	return unit.global_position + Vector3(0.0, 0.6, 0.0)


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
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(label)
	label.global_position = world_position + Vector3(0.0, feedback_height, 0.0)

	var tween: Tween = label.create_tween()
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
