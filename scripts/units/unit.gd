class_name Unit
extends Node3D
## Unidade genérica da grade (esquadrão ou inimigos).
## A origem do nó fica na superfície do chão; a malha "Body" fica acima dela.

## Lado ao qual a unidade pertence.
enum Team { SQUAD, ENEMY }

## Emitido quando a unidade termina de percorrer um caminho.
signal move_finished(unit: Unit)

## Nome exibido da unidade.
@export var unit_name: String = "Unidade"
## Cor do corpo da unidade.
@export var body_color: Color = Color.WHITE
## Lado da unidade (esquadrão ou inimigo).
@export var team: Team = Team.SQUAD
## Alcance de movimento, em passos (células) nas 4 direções.
@export var move_range: int = 5
## Velocidade do movimento animado, em metros por segundo.
@export var move_speed: float = 8.0
## Máximo de pontos de ação (PA) por turno.
@export var max_action_points: int = 2

## Célula atual da unidade na grade.
var cell: Vector2i = Vector2i.ZERO
## Verdadeiro enquanto a unidade percorre um caminho.
var is_moving: bool = false
## Pontos de ação restantes neste turno.
var action_points: int = max_action_points

var _grid_manager: GridManager

@onready var _body: MeshInstance3D = $Body


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = body_color
	_body.material_override = material
	add_to_group("units")
	reset_actions()


## Coloca a unidade na célula informada, usando o GridManager para obter a posição.
func place_on_cell(grid_manager: GridManager, new_cell: Vector2i) -> void:
	_grid_manager = grid_manager
	cell = new_cell
	global_position = grid_manager.cell_to_world(new_cell)


## Anima a unidade célula por célula pelo caminho (da primeira célula depois da origem até o destino),
## em linha reta entre os centros das células e com velocidade constante (move_speed).
## A célula lógica só é atualizada no fim, por place_on_cell, e então move_finished é emitido.
## Exige que place_on_cell já tenha sido chamado ao menos uma vez (guarda o GridManager).
func move_along_path(path: Array[Vector2i]) -> void:
	if path.is_empty() or is_moving:
		return
	assert(_grid_manager != null, "Unit: chame place_on_cell antes de move_along_path.")

	is_moving = true
	var tween: Tween = create_tween()
	var previous: Vector3 = global_position
	for step: Vector2i in path:
		var target: Vector3 = _grid_manager.cell_to_world(step)
		var duration: float = previous.distance_to(target) / maxf(move_speed, 0.001)
		tween.tween_property(self, "global_position", target, duration)
		previous = target
	tween.tween_callback(_finish_move.bind(path[path.size() - 1]))


func _finish_move(final_cell: Vector2i) -> void:
	place_on_cell(_grid_manager, final_cell)
	is_moving = false
	move_finished.emit(self)


## Gasta pontos de ação (nunca fica abaixo de 0).
func spend_action(cost: int = 1) -> void:
	action_points = maxi(action_points - cost, 0)


## Devolve todos os pontos de ação (início do turno).
func reset_actions() -> void:
	action_points = max_action_points
