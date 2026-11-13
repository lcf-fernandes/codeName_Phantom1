class_name CombatCalc
extends Node
## Cálculo da chance de acerto (em %). Só cálculo: não ataca, não causa dano e não mexe nos PA.
##
## chance = base_hit_chance
##          + (proximity_reference - distância) * proximity_bonus_per_cell
##          - penalidade da cobertura (baixa ou alta)
##          - defend_penalty (se o defensor estiver em Defender)
##          - extra_penalty
##          + unaware_bonus (se o alvo estiver desprevenido)
## O resultado fica entre min_hit_chance e max_hit_chance.

## Caminho até o CoverMap (usado em get_hit_chance).
@export var cover_map_path: NodePath = ^"../CoverMap"
## Chance base de acerto, em % (a pontaria inicial).
@export var base_hit_chance: int = 65
## Penalidade, em pontos percentuais, contra cobertura baixa.
@export var low_cover_penalty: int = 20
## Penalidade, em pontos percentuais, contra cobertura alta.
@export var high_cover_penalty: int = 40
## Penalidade, em pontos percentuais, quando o defensor está em Defender (guardando a posição).
@export var defend_penalty: int = 20
## Distância (em células) em que o bônus de proximidade é zero. Mais perto soma, mais longe subtrai.
@export var proximity_reference: int = 6
## Pontos percentuais por célula de diferença para a distância de referência.
@export var proximity_bonus_per_cell: int = 4
## Bônus, em pontos percentuais, quando o alvo ainda não foi alertado (emboscada).
@export var unaware_bonus: int = 20
## Chance mínima, em %.
@export var min_hit_chance: int = 0
## Chance máxima, em %. Nunca 100: um tiro sempre pode errar.
@export var max_hit_chance: int = 99
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


## Chance de acerto (em %) para uma distância e uma cobertura dadas. Com `defending`, o defensor
## está em Defender e a chance perde defend_penalty; `extra_penalty` é uma penalidade a mais, em
## pontos percentuais; com `unaware`, o alvo está desprevenido e a chance ganha unaware_bonus.
func compute_hit_chance(distance: int, cover: CoverMap.CoverType, defending: bool = false, extra_penalty: int = 0, unaware: bool = false) -> int:
	var cover_penalty: int = 0
	match cover:
		CoverMap.CoverType.LOW:
			cover_penalty = low_cover_penalty
		CoverMap.CoverType.HIGH:
			cover_penalty = high_cover_penalty

	var proximity: int = (proximity_reference - distance) * proximity_bonus_per_cell
	var chance: int = base_hit_chance + proximity - cover_penalty - extra_penalty
	if defending:
		chance -= defend_penalty
	if unaware:
		chance += unaware_bonus
	return clampi(chance, min_hit_chance, max_hit_chance)


## Chance de acerto (em %) do atacante contra o defensor, pela distância e pela cobertura do defensor.
func get_hit_chance(attacker: Vector2i, defender: Vector2i, defending: bool = false, extra_penalty: int = 0, unaware: bool = false) -> int:
	var distance: int = get_distance(attacker, defender)
	var cover: CoverMap.CoverType = _cover_map.get_cover_against(defender, attacker)
	return compute_hit_chance(distance, cover, defending, extra_penalty, unaware)


# Roda os casos de compute_hit_chance e imprime cada resultado e o total.
func _run_combat_test() -> void:
	var cases: Array[Dictionary] = [
		{"distance": 1, "cover": CoverMap.CoverType.NONE, "expected": 85},
		{"distance": 5, "cover": CoverMap.CoverType.NONE, "expected": 69},
		{"distance": 5, "cover": CoverMap.CoverType.LOW, "expected": 49},
		{"distance": 5, "cover": CoverMap.CoverType.HIGH, "expected": 29},
		{"distance": 5, "cover": CoverMap.CoverType.HIGH, "defending": true, "expected": 9},
		{"distance": 5, "cover": CoverMap.CoverType.HIGH, "defending": true, "extra": 15, "expected": 0},
		{"distance": 1, "cover": CoverMap.CoverType.NONE, "unaware": true, "expected": 99},
		{"distance": 5, "cover": CoverMap.CoverType.NONE, "unaware": true, "expected": 89},
		{"distance": 3, "cover": CoverMap.CoverType.LOW, "unaware": true, "expected": 77},
		{"distance": 8, "cover": CoverMap.CoverType.NONE, "expected": 57},
	]

	print("[Combate] teste de compute_hit_chance:")
	var passed: int = 0
	for i: int in cases.size():
		var test: Dictionary = cases[i]
		var distance: int = test["distance"]
		var cover: CoverMap.CoverType = test["cover"]
		var defending: bool = test.get("defending", false)
		var extra: int = test.get("extra", 0)
		var unaware: bool = test.get("unaware", false)
		var expected: int = test["expected"]
		var result: int = compute_hit_chance(distance, cover, defending, extra, unaware)
		var ok: bool = result == expected
		if ok:
			passed += 1
		print("  %d. distância %d, %s, defendendo %s, extra %d, desprevenido %s -> %d (esperado %d) %s" % [
			i + 1, distance, String(CoverMap.CoverType.keys()[cover]), defending, extra, unaware,
			result, expected, "OK" if ok else "FALHA"
		])
	print("[Combate] testes: %d/%d OK" % [passed, cases.size()])
