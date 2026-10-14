class_name Unit
extends Node3D
## Unidade genérica da grade (esquadrão ou inimigos).
## A origem do nó fica na superfície do chão; a malha "Body" fica acima dela.

## Lado ao qual a unidade pertence.
enum Team { SQUAD, ENEMY }

## Emitido quando a unidade termina de percorrer um caminho.
signal move_finished(unit: Unit)
## Emitido quando os pontos de vida mudam.
signal health_changed(unit: Unit, hp: int, max_hp: int)
## Emitido uma única vez, quando os pontos de vida chegam a 0.
signal died(unit: Unit)

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
## Máximo de pontos de vida (HP).
@export var max_hp: int = 4
## Alcance de ataque, em passos de grade (distância em células, nas 4 direções).
@export var attack_range: int = 5

## Célula atual da unidade na grade.
var cell: Vector2i = Vector2i.ZERO
## Verdadeiro enquanto a unidade percorre um caminho.
var is_moving: bool = false
## Pontos de ação restantes neste turno.
var action_points: int = max_action_points
## Pontos de vida atuais (0 = morta).
var hp: int = max_hp

var _hp_label: Label3D

var _grid_manager: GridManager

@onready var _body: MeshInstance3D = $Body


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = body_color
	_body.material_override = material
	add_to_group("units")
	reset_actions()
	hp = max_hp
	_build_hp_label()
	health_changed.connect(_on_health_changed)


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


## Causa dano. Ignora valores <= 0 e dano em unidade já morta; o HP nunca fica abaixo de 0.
## Ao chegar a 0: sai do grupo "units" (deixa de bloquear células) antes de qualquer outra
## coisa, emite health_changed e died (uma única vez) e então libera a unidade com queue_free().
func take_damage(amount: int) -> void:
	if amount <= 0 or hp <= 0:
		return

	var new_hp: int = maxi(hp - amount, 0)
	if new_hp == 0:
		remove_from_group("units")

	hp = new_hp
	health_changed.emit(self, hp, max_hp)

	if hp == 0:
		died.emit(self)
		queue_free()


# Label3D com o HP acima da unidade (2,2 m acima do chão), sempre virado para a câmera e com borda.
func _build_hp_label() -> void:
	_hp_label = Label3D.new()
	_hp_label.name = "HpLabel"
	_hp_label.position = Vector3(0.0, 2.2, 0.0)
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.font_size = 64
	_hp_label.outline_size = 16
	_hp_label.outline_modulate = Color.BLACK
	_hp_label.modulate = Color.WHITE
	_hp_label.text = "%d/%d" % [hp, max_hp]
	add_child(_hp_label)


# Atualiza o texto do Label3D com o HP atual.
func _on_health_changed(_unit: Unit, new_hp: int, new_max_hp: int) -> void:
	_hp_label.text = "%d/%d" % [new_hp, new_max_hp]
