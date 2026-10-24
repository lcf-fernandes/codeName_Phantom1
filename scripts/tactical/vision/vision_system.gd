class_name VisionSystem
extends Node
## Linha de visão na grade. Sem efeito no jogo ainda: só responde se uma célula enxerga outra.
## A reta vai do centro de uma célula ao da outra (em coordenadas de célula, o centro é o ponto
## inteiro). Só cobertura ALTA bloqueia; cobertura baixa e unidades não bloqueiam.

## Caminho até o CoverMap (quais células têm cobertura).
@export var cover_map_path: NodePath = ^"../CoverMap"
## Caminho até o CombatCalc (distância em passos de grade).
@export var combat_calc_path: NodePath = ^"../CombatCalc"
## Quando verdadeiro, roda ao iniciar os testes de linha de visão e imprime o resultado.
@export var debug_vision_test: bool = true
## Caminho até o GridManager (quais células estão dentro da grade).
@export var grid_manager_path: NodePath = ^"../GridManager"
## Caminho até o TurnManager (a visão é recalculada no início de cada turno).
@export var turn_manager_path: NodePath = ^"../TurnManager"
## Quando verdadeiro, imprime uma linha sempre que a lista de inimigos visíveis muda.
@export var debug_vision_report: bool = true

## Emitido quando o conjunto de células visíveis muda em relação ao cálculo anterior.
signal visibility_changed

const UNITS_GROUP: StringName = &"units"

## Células que o esquadrão enxerga agora (célula -> true). Atualizada por recompute().
var visible_cells: Dictionary[Vector2i, bool] = {}

# Durante um movimento, a célula real da unidade (a lógica só muda no fim): unidade -> célula.
var _live_cells: Dictionary[Unit, Vector2i] = {}
var _grid_manager: GridManager
var _turn_manager: TurnManager
var _last_enemy_report: String = ""
var _has_reported: bool = false

var _cover_map: CoverMap
var _combat_calc: CombatCalc


func _ready() -> void:
	_cover_map = get_node(cover_map_path) as CoverMap
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	assert(_cover_map != null, "VisionSystem: cover_map_path não aponta para um CoverMap.")
	assert(_combat_calc != null, "VisionSystem: combat_calc_path não aponta para um CombatCalc.")
	_grid_manager = get_node(grid_manager_path) as GridManager
	_turn_manager = get_node(turn_manager_path) as TurnManager
	assert(_grid_manager != null, "VisionSystem: grid_manager_path não aponta para um GridManager.")
	assert(_turn_manager != null, "VisionSystem: turn_manager_path não aponta para um TurnManager.")
	if debug_vision_test:
		_run_vision_test()
	# Depois de as unidades existirem (os spawners as criam no _ready deles).
	_connect_units.call_deferred()


## Verdadeiro se nenhuma célula de cobertura ALTA fica entre as duas, sobre a reta entre os centros.
## A reta é amostrada em n = ceil(max(|dx|, |dy|) * 4) passos; as células iguais a from ou a to são
## ignoradas. Se from == to, devolve true.
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true

	var dx: int = to.x - from.x
	var dy: int = to.y - from.y
	var n: int = ceili(float(maxi(absi(dx), absi(dy))) * 4.0)

	for i: int in range(1, n):
		var cell: Vector2i = Vector2i(
			roundi(float(from.x) + float(dx * i) / float(n)),
			roundi(float(from.y) + float(dy * i) / float(n))
		)
		if cell == from or cell == to:
			continue
		if _cover_map.get_cover(cell) == CoverMap.CoverType.HIGH:
			return false
	return true


## Verdadeiro se a distância (em passos de grade) está dentro do alcance de visão e há linha de visão.
func can_see(from: Vector2i, to: Vector2i, sight_range: int) -> bool:
	return _combat_calc.get_distance(from, to) <= sight_range and has_line_of_sight(from, to)


## Célula que vale para a visão da unidade: durante um movimento, a última célula alcançada (guardada
## por cell_reached); senão, unit.cell.
func vision_cell(unit: Unit) -> Vector2i:
	if _live_cells.has(unit):
		return _live_cells[unit]
	return unit.cell


## Verdadeiro se o esquadrão enxerga a célula.
func is_cell_visible(cell: Vector2i) -> bool:
	return visible_cells.has(cell)


## Soldado: sempre visível. Inimigo: visível se a célula de visão dele está em visible_cells.
func is_unit_visible(unit: Unit) -> bool:
	if unit.team == Unit.Team.SQUAD:
		return true
	return visible_cells.has(vision_cell(unit))


## Recalcula visible_cells: a união, para cada soldado vivo, das células dentro do losango de
## distância <= sight_range ao redor da célula de visão dele que estejam na grade e passem em can_see.
## Emite visibility_changed só se o conjunto mudou desde o cálculo anterior.
func recompute() -> void:
	var new_cells: Dictionary[Vector2i, bool] = {}
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var soldier: Unit = node as Unit
		if soldier == null or not is_instance_valid(soldier):
			continue
		if soldier.team != Unit.Team.SQUAD or soldier.hp <= 0:
			continue
		var origin: Vector2i = vision_cell(soldier)
		var reach: int = soldier.sight_range
		for dx: int in range(-reach, reach + 1):
			var rest: int = reach - absi(dx)
			for dy: int in range(-rest, rest + 1):
				var cell: Vector2i = origin + Vector2i(dx, dy)
				if new_cells.has(cell) or not _grid_manager.is_inside(cell):
					continue
				if can_see(origin, cell, reach):
					new_cells[cell] = true

	var changed: bool = new_cells.size() != visible_cells.size()
	if not changed:
		for cell: Vector2i in new_cells.keys():
			if not visible_cells.has(cell):
				changed = true
				break
	visible_cells = new_cells
	if changed:
		visibility_changed.emit()
	_report_visible_enemies()


# Conecta os sinais das unidades e do TurnManager e faz o primeiro cálculo.
func _connect_units() -> void:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null:
			continue
		unit.cell_reached.connect(_on_cell_reached)
		unit.move_finished.connect(_on_move_finished)
		unit.died.connect(_on_unit_died)
	_turn_manager.turn_started.connect(_on_turn_started)
	recompute()


func _on_cell_reached(unit: Unit, cell: Vector2i) -> void:
	_live_cells[unit] = cell
	recompute()


func _on_move_finished(unit: Unit) -> void:
	_live_cells.erase(unit)
	recompute()


func _on_unit_died(unit: Unit) -> void:
	_live_cells.erase(unit)
	recompute()


func _on_turn_started(_turn_number: int, _side: TurnManager.TurnSide) -> void:
	recompute()


# Imprime uma linha quando a lista de inimigos visíveis muda (e no primeiro cálculo).
func _report_visible_enemies() -> void:
	var names: PackedStringArray = PackedStringArray()
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var enemy: Unit = node as Unit
		if enemy == null or enemy.team != Unit.Team.ENEMY or enemy.hp <= 0:
			continue
		if is_unit_visible(enemy):
			names.append(enemy.unit_name)
	names.sort()
	var enemy_list: String = ", ".join(names) if not names.is_empty() else "nenhum"

	if _has_reported and enemy_list == _last_enemy_report:
		return
	_has_reported = true
	_last_enemy_report = enemy_list
	if debug_vision_report:
		print("[Visão] células visíveis: %d | inimigos visíveis: %s" % [visible_cells.size(), enemy_list])


# Roda os 15 casos (12 de has_line_of_sight e 3 de can_see) e imprime cada resultado e o total.
# Considera as coberturas atuais: altas em (8,5) e (2,7); baixas em (3,5), (4,5) e (7,6).
func _run_vision_test() -> void:
	# sight_range = -1 significa "testar has_line_of_sight"; senão, "testar can_see".
	var cases: Array[Dictionary] = [
		{"from": Vector2i(4, 0), "to": Vector2i(4, 11), "range": -1, "expected": true},
		{"from": Vector2i(8, 0), "to": Vector2i(8, 11), "range": -1, "expected": false},
		{"from": Vector2i(7, 0), "to": Vector2i(9, 11), "range": -1, "expected": false},
		{"from": Vector2i(6, 0), "to": Vector2i(6, 11), "range": -1, "expected": true},
		{"from": Vector2i(2, 0), "to": Vector2i(2, 11), "range": -1, "expected": false},
		{"from": Vector2i(0, 0), "to": Vector2i(11, 0), "range": -1, "expected": true},
		{"from": Vector2i(3, 0), "to": Vector2i(3, 11), "range": -1, "expected": true},
		{"from": Vector2i(8, 11), "to": Vector2i(8, 0), "range": -1, "expected": false},
		{"from": Vector2i(7, 4), "to": Vector2i(9, 6), "range": -1, "expected": false},
		{"from": Vector2i(4, 0), "to": Vector2i(4, 1), "range": -1, "expected": true},
		{"from": Vector2i(5, 5), "to": Vector2i(5, 5), "range": -1, "expected": true},
		{"from": Vector2i(9, 0), "to": Vector2i(9, 11), "range": -1, "expected": true},
		{"from": Vector2i(4, 0), "to": Vector2i(4, 8), "range": 8, "expected": true},
		{"from": Vector2i(4, 0), "to": Vector2i(4, 9), "range": 8, "expected": false},
		{"from": Vector2i(8, 3), "to": Vector2i(8, 7), "range": 8, "expected": false},
	]

	print("[Visão] teste de has_line_of_sight e can_see:")
	var passed: int = 0
	for i: int in cases.size():
		var from: Vector2i = cases[i]["from"]
		var to: Vector2i = cases[i]["to"]
		var sight_range: int = cases[i]["range"]
		var expected: bool = cases[i]["expected"]

		var result: bool = has_line_of_sight(from, to) if sight_range < 0 else can_see(from, to, sight_range)
		var ok: bool = result == expected
		if ok:
			passed += 1

		var what: String = "linha de visão" if sight_range < 0 else "can_see (alcance %d)" % sight_range
		print("  %2d. %s %s -> %s: %s (esperado %s) %s" % [
			i + 1, what, from, to, result, expected, "OK" if ok else "FALHA"
		])
	print("[Visão] testes: %d/%d OK" % [passed, cases.size()])
