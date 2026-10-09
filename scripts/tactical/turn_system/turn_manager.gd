class_name TurnManager
extends Node
## Ciclo de turnos mínimo: turno do jogador, turno dos inimigos (sem ação por enquanto) e contador.
## Enter encerra o turno do jogador.

## Lado que está jogando. (Não usar o nome "Side": ele já existe como enum global do Godot.)
enum TurnSide { PLAYER, ENEMY }

## Emitido quando um turno começa.
signal turn_started(turn_number: int, side: TurnSide)
## Emitido quando um turno termina.
signal turn_ended(turn_number: int, side: TurnSide)

const UNITS_GROUP: StringName = &"units"

## Duração do turno dos inimigos (por enquanto só uma espera), em segundos.
@export var enemy_turn_duration: float = 0.5

## Número do turno atual (começa em 1; o turno dos inimigos tem o mesmo número do turno do jogador).
var turn_number: int = 1
## Lado que está jogando agora.
var side: TurnSide = TurnSide.PLAYER


func _ready() -> void:
	# Adiado para que os nós que ouvem os sinais já estejam conectados.
	_announce_player_turn.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return

	if side != TurnSide.PLAYER:
		print("Enter ignorado: turno dos inimigos")
		return
	if _is_any_unit_moving():
		print("Enter ignorado: movimento em andamento")
		return
	end_player_turn()


## Encerra o turno do jogador, roda o turno dos inimigos e devolve a vez ao jogador.
func end_player_turn() -> void:
	turn_ended.emit(turn_number, TurnSide.PLAYER)

	side = TurnSide.ENEMY
	turn_started.emit(turn_number, TurnSide.ENEMY)
	print("Turno dos inimigos (sem ação por enquanto)")
	await get_tree().create_timer(enemy_turn_duration).timeout
	turn_ended.emit(turn_number, TurnSide.ENEMY)

	turn_number += 1
	side = TurnSide.PLAYER
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.SQUAD:
			unit.reset_actions()
	_announce_player_turn()


func _announce_player_turn() -> void:
	print("Turno %d: jogador" % turn_number)
	turn_started.emit(turn_number, TurnSide.PLAYER)


func _is_any_unit_moving() -> bool:
	for node: Node in get_tree().get_nodes_in_group(UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.is_moving:
			return true
	return false
