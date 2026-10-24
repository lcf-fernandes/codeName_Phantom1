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

var _cover_map: CoverMap
var _combat_calc: CombatCalc


func _ready() -> void:
	_cover_map = get_node(cover_map_path) as CoverMap
	_combat_calc = get_node(combat_calc_path) as CombatCalc
	assert(_cover_map != null, "VisionSystem: cover_map_path não aponta para um CoverMap.")
	assert(_combat_calc != null, "VisionSystem: combat_calc_path não aponta para um CombatCalc.")
	if debug_vision_test:
		_run_vision_test()


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
