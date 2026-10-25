class_name TargetPreview
extends Node3D
## Com o mouse sobre um inimigo e um soldado selecionado, mostra (via hover_text) a cobertura do
## inimigo contra esse soldado; com o mouse sobre um soldado vivo, lista as ameaças a ele.
## Só lê o estado dos outros nós; não altera nada neles.

const UNITS_GROUP: StringName = &"units"

## Caminho até a câmera da fase.
@export var camera_path: NodePath = ^"../Camera"
## Caminho até o SelectionController (leitura de selected_unit).
@export var selection_controller_path: NodePath = ^"../SelectionController"
## Caminho até o CoverMap.
@export var cover_map_path: NodePath = ^"../CoverMap"
## Caminho até o TurnManager.
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Caminho até o CombatCalc (distância e chance de acerto).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Caminho até o VisionSystem (linha de visão).
@export var vision_system_path: NodePath = ^"../VisionSystem"
## Camada de colisão das unidades (camada 2).
@export_flags_3d_physics var unit_collision_mask: int = 2
## Comprimento do raio, em metros.
@export var ray_length: float = 200.0

## Texto para o HUD; vazio quando não há nada a mostrar.
var hover_text: String = ""

var _camera: Camera3D
var _selection: SelectionController
var _cover_map: CoverMap
var _turn_manager: TurnManager
var _combat_calc: CombatCalc
var _vision: VisionSystem
var _mouse_pos: Vector2 = Vector2.ZERO
var _last_enemy: Unit = null


func _ready() -> void:
	_camera = get_node(camera_path) as Camera3D
	_selection = get_node(selection_controller_path) as SelectionController
	_cover_map = get_node(cover_map_path) as CoverMap
	_turn_manager = get_node(turn_manager_path) as TurnManager
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	_vision = get_node(vision_system_path) as VisionSystem
	assert(_camera != null, "TargetPreview: camera_path não aponta para uma Camera3D.")
	assert(_selection != null, "TargetPreview: selection_controller_path não aponta para um SelectionController.")
	assert(_cover_map != null, "TargetPreview: cover_map_path não aponta para um CoverMap.")
	assert(_turn_manager != null, "TargetPreview: turn_manager_path não aponta para um TurnManager.")
	assert(_combat_calc != null, "TargetPreview: combat_calc_path não aponta para um CombatCalc.")
	assert(_vision != null, "TargetPreview: vision_system_path não aponta para um VisionSystem.")
	_mouse_pos = get_viewport().get_mouse_position()


# Guarda a posição do mouse; o evento não é consumido.
func _input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_mouse_pos = motion.position


func _process(_delta: float) -> void:
	var soldier: Unit = _selection.selected_unit
	var hovered: Unit = null
	if _turn_manager.side == TurnManager.TurnSide.PLAYER and not _is_any_unit_moving():
		hovered = _pick_unit(_mouse_pos)

	# Mouse sobre um soldado vivo (selecionado ou não): lista as ameaças a ele.
	if hovered != null and hovered.team == Unit.Team.SQUAD and hovered.hp > 0:
		hover_text = _threat_text(hovered)
		_last_enemy = null
		return

	var enemy: Unit = null
	if soldier != null and hovered != null and hovered.team == Unit.Team.ENEMY:
		enemy = hovered

	if enemy == null:
		hover_text = ""
		_last_enemy = null
		return

	var distance: int = _combat_calc.get_distance(soldier.cell, enemy.cell)
	if distance > soldier.attack_range:
		# Fora de alcance: sem cobertura nem chance (e sem a linha "Mira").
		hover_text = "%s · distância %d · fora de alcance (máx. %d)" % [enemy.unit_name, distance, soldier.attack_range]
		_last_enemy = null
		return

	# Ao alcance, mas sem linha de visão do soldado até o inimigo: sem cobertura nem chance.
	if not _vision.can_see(soldier.cell, enemy.cell, soldier.sight_range):
		hover_text = "%s · distância %d · sem linha de visão" % [enemy.unit_name, distance]
		_last_enemy = null
		return

	var cover: CoverMap.CoverType = _cover_map.get_cover_against(enemy.cell, soldier.cell)
	var hit_chance: int = _combat_calc.get_hit_chance(soldier.cell, enemy.cell)
	hover_text = "%s · cobertura contra %s: %s · distância %d · chance de acerto %d%%" % [
		enemy.unit_name, soldier.unit_name, _cover_label(cover), distance, hit_chance
	]

	# Só imprime quando o inimigo sob o mouse muda.
	if enemy != _last_enemy:
		_last_enemy = enemy
		print("Mira: %s vs %s -> %s" % [enemy.unit_name, soldier.unit_name, String(CoverMap.CoverType.keys()[cover])])


## Texto das ameaças a um soldado: cada inimigo vivo e visível (em ordem de nome) que o alcança e tem
## linha de visão até ele, com a distância, a cobertura do soldado contra ele e a chance de acerto do
## inimigo (considerando o Defender).
func _threat_text(soldier: Unit) -> String:
	var threats: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var enemy: Unit = node as Unit
		if enemy == null or enemy.team != Unit.Team.ENEMY or enemy.hp <= 0 or enemy.is_fogged:
			continue
		if _combat_calc.get_distance(enemy.cell, soldier.cell) > enemy.attack_range:
			continue
		if _vision.can_see(enemy.cell, soldier.cell, enemy.sight_range):
			threats.append(enemy)

	if threats.is_empty():
		return "%s · nenhum inimigo ao alcance" % soldier.unit_name

	threats.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_name < b.unit_name)

	var header: String = "%s · ameaças" % soldier.unit_name
	if soldier.is_defending:
		header += " · em guarda"
	var lines: PackedStringArray = PackedStringArray([header])
	for enemy: Unit in threats:
		var distance: int = _combat_calc.get_distance(enemy.cell, soldier.cell)
		var cover: CoverMap.CoverType = _cover_map.get_cover_against(soldier.cell, enemy.cell)
		var chance: int = _combat_calc.get_hit_chance(enemy.cell, soldier.cell, soldier.is_defending)
		lines.append("%s · distância %d · cobertura %s · %d%%" % [enemy.unit_name, distance, _cover_label(cover), chance])
	return "\n".join(lines)


## Unidade sob o ponto da tela, pelo raio físico (só na camada das unidades); null se não houver.
func _pick_unit(screen_pos: Vector2) -> Unit:
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var end: Vector3 = origin + _camera.project_ray_normal(screen_pos) * ray_length
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end, unit_collision_mask)
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Node = hit["collider"] as Node
	return collider.get_parent() as Unit


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false


func _cover_label(cover: CoverMap.CoverType) -> String:
	match cover:
		CoverMap.CoverType.LOW:
			return "Baixa"
		CoverMap.CoverType.HIGH:
			return "Alta"
		_:
			return "Nenhuma"
