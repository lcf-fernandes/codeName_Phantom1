class_name CombatCalc
extends Node
## Cálculo da chance de acerto (em %). Só cálculo: não ataca, não causa dano e não mexe nos PA.
##
## chance = base_hit_chance
##          - penalidade da cobertura (baixa ou alta)
##          - max(0, distância - distance_free_cells) * distance_penalty_per_cell
## O resultado fica entre min_hit_chance e max_hit_chance.

## Caminho até o CoverMap (usado em get_hit_chance).
@export var cover_map_path: NodePath = ^"../CoverMap"
## Chance base de acerto, em %.
@export var base_hit_chance: int = 75
## Penalidade, em pontos percentuais, contra cobertura baixa.
@export var low_cover_penalty: int = 20
## Penalidade, em pontos percentuais, contra cobertura alta.
@export var high_cover_penalty: int = 40
## Distância (em células) até a qual não há penalidade.
@export var distance_free_cells: int = 6
## Penalidade, em pontos percentuais, por célula além de distance_free_cells.
@export var distance_penalty_per_cell: int = 2
## Chance mínima, em %.
@export var min_hit_chance: int = 5
## Chance máxima, em %.
@export var max_hit_chance: int = 95
## Quando verdadeiro, roda ao iniciar o teste de compute_hit_chance e imprime o resultado.
@export var debug_combat_test: bool = true

var _cover_map: CoverMap


func _ready() -> void:
	_cover_map = get_node(cover_map_path) as CoverMap
	assert(_cover_map != null, "CombatCalc: cover_map_path não aponta para um CoverMap.")
	if debug_combat_test:
		_run_combat_test()


## Distância em células entre duas células da grade: |dx| + |dy|.
func get_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	return absi(to_cell.x - from_cell.x) + absi(to_cell.y - from_cell.y)


## Chance de acerto (em %) para uma distância e uma cobertura dadas.
func compute_hit_chance(distance: int, cover: CoverMap.CoverType) -> int:
	var cover_penalty: int = 0
	match cover:
		CoverMap.CoverType.LOW:
			cover_penalty = low_cover_penalty
		CoverMap.CoverType.HIGH:
			cover_penalty = high_cover_penalty

	var distance_penalty: int = maxi(0, distance - distance_free_cells) * distance_penalty_per_cell
	return clampi(base_hit_chance - cover_penalty - distance_penalty, min_hit_chance, max_hit_chance)


## Chance de acerto (em %) do atacante contra o defensor, pela distância e pela cobertura do defensor.
func get_hit_chance(attacker: Vector2i, defender: Vector2i) -> int:
	var distance: int = get_distance(attacker, defender)
	var cover: CoverMap.CoverType = _cover_map.get_cover_against(defender, attacker)
	return compute_hit_chance(distance, cover)


# Roda os 8 casos de compute_hit_chance e imprime cada resultado e o total.
func _run_combat_test() -> void:
	var cases: Array[Dictionary] = [
		{"distance": 4, "cover": CoverMap.CoverType.NONE, "expected": 75},
		{"distance": 4, "cover": CoverMap.CoverType.LOW, "expected": 55},
		{"distance": 4, "cover": CoverMap.CoverType.HIGH, "expected": 35},
		{"distance": 6, "cover": CoverMap.CoverType.NONE, "expected": 75},
		{"distance": 7, "cover": CoverMap.CoverType.NONE, "expected": 73},
		{"distance": 10, "cover": CoverMap.CoverType.LOW, "expected": 47},
		{"distance": 16, "cover": CoverMap.CoverType.HIGH, "expected": 15},
		{"distance": 30, "cover": CoverMap.CoverType.HIGH, "expected": 5},
	]

	print("[Combate] teste de compute_hit_chance:")
	var passed: int = 0
	for i: int in cases.size():
		var distance: int = cases[i]["distance"]
		var cover: CoverMap.CoverType = cases[i]["cover"]
		var expected: int = cases[i]["expected"]
		var result: int = compute_hit_chance(distance, cover)
		var ok: bool = result == expected
		if ok:
			passed += 1
		print("  %d. distância %d, %s -> %d (esperado %d) %s" % [
			i + 1, distance, String(CoverMap.CoverType.keys()[cover]), result, expected, "OK" if ok else "FALHA"
		])
	print("[Combate] testes: %d/%d OK" % [passed, cases.size()])
