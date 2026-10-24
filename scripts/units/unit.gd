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
## Emitido toda vez que a unidade termina de andar até uma célula do caminho (inclusive a última).
signal cell_reached(unit: Unit, cell: Vector2i)
## Emitido quando o último pedido de espera do movimento (hold_move) é liberado.
signal hold_released

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
## Retrato exibido na faixa de retratos (opcional; sem imagem, a faixa mostra o número da unidade).
@export var portrait: Texture2D = null
## Distância que o corpo avança ao atacar, em metros.
@export var lunge_distance: float = 0.5
## Tempo do avanço do ataque, em segundos.
@export var lunge_out_time: float = 0.12
## Tempo da volta do ataque, em segundos.
@export var lunge_back_time: float = 0.18
## Deslocamento máximo do tremor ao ser atingida, em metros.
@export var shake_amount: float = 0.12
## Duração do tremor e do clarão vermelho ao ser atingida, em segundos.
@export var hit_time: float = 0.25
## Cor do clarão ao ser atingida (overlay vermelho semitransparente).
@export var flash_color: Color = Color(1.0, 0.3, 0.3, 0.6)
## Tempo em que o corpo encolhe até sumir na morte, em segundos.
@export var death_time: float = 0.3
## Cor do anel que marca a unidade em Defender (ciano semitransparente).
@export var defend_marker_color: Color = Color(0.2, 0.9, 1.0, 0.85)
## Cor do anel que marca a unidade em Vigilância (laranja semitransparente).
@export var overwatch_marker_color: Color = Color(1.0, 0.6, 0.1, 0.85)
## Temporário: com ele ligado, imprime "Passo: <nome> em (x, y)" a cada célula alcançada no movimento.
@export var debug_steps: bool = false

## Célula atual da unidade na grade.
var cell: Vector2i = Vector2i.ZERO
## Verdadeiro enquanto a unidade percorre um caminho.
var is_moving: bool = false
## Quantos ouvintes pediram para o movimento esperar na célula atual (hold_move / release_move).
var move_holds: int = 0
## Pontos de ação restantes neste turno.
var action_points: int = max_action_points
## Pontos de vida atuais (0 = morta).
var hp: int = max_hp

var _hp_label: Label3D

# Posição de repouso do Body (cena da unidade) e estado das animações só visuais.
const BODY_REST_POSITION: Vector3 = Vector3(0.0, 0.6, 0.0)
var _anim_tween: Tween
var _hit_ready_msec: int = 0

## Verdadeiro enquanto a unidade guarda a posição (Defender); volta a falso em reset_actions().
var is_defending: bool = false

# Anel de Defender, criado em código na primeira vez que é preciso.
var _defend_marker: MeshInstance3D = null

## Verdadeiro enquanto a unidade está em Vigilância; volta a falso em reset_actions().
var is_overwatching: bool = false

# Anel de Vigilância, criado em código na primeira vez que é preciso.
var _overwatch_marker: MeshInstance3D = null

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
## Ao chegar em cada célula emite cell_reached; se algum ouvinte pediu espera (hold_move) durante o
## sinal, aguarda hold_released antes de seguir. A célula lógica só é atualizada no fim, por
## place_on_cell, e então move_finished é emitido.
## Exige que place_on_cell já tenha sido chamado ao menos uma vez (guarda o GridManager).
func move_along_path(path: Array[Vector2i]) -> void:
	if path.is_empty() or is_moving:
		return
	assert(_grid_manager != null, "Unit: chame place_on_cell antes de move_along_path.")

	is_moving = true
	for step: Vector2i in path:
		var target: Vector3 = _grid_manager.cell_to_world(step)
		var duration: float = global_position.distance_to(target) / maxf(move_speed, 0.001)
		var tween: Tween = create_tween()
		tween.tween_property(self, "global_position", target, duration)
		await tween.finished

		if debug_steps:
			print("Passo: %s em (%d, %d)" % [unit_name, step.x, step.y])
		cell_reached.emit(self, step)

		# Um ouvinte pede a espera chamando hold_move() de forma síncrona dentro do cell_reached.
		var waited: bool = false
		while move_holds > 0:
			waited = true
			await hold_released

		# Depois de uma espera, a unidade pode ter morrido ou sido liberada: encerra sem travar quem
		# espera move_finished.
		if waited and (not is_instance_valid(self) or is_queued_for_deletion() or hp <= 0):
			is_moving = false
			move_finished.emit(self)
			return

	_finish_move(path[path.size() - 1])


## Pede que o movimento espere na célula atual (some 1 ao contador de esperas).
## Deve ser chamado de forma síncrona dentro do tratamento de cell_reached.
func hold_move() -> void:
	move_holds += 1


## Libera um pedido de espera (subtrai 1, nunca abaixo de 0). Ao chegar a 0, emite hold_released.
func release_move() -> void:
	if move_holds <= 0:
		return
	move_holds -= 1
	if move_holds == 0:
		hold_released.emit()


func _finish_move(final_cell: Vector2i) -> void:
	place_on_cell(_grid_manager, final_cell)
	is_moving = false
	move_finished.emit(self)


## Gasta pontos de ação (nunca fica abaixo de 0).
func spend_action(cost: int = 1) -> void:
	action_points = maxi(action_points - cost, 0)


## Devolve todos os pontos de ação (início do turno) e encerra o Defender e a Vigilância.
func reset_actions() -> void:
	action_points = max_action_points
	is_defending = false
	_update_defend_marker()
	is_overwatching = false
	_update_overwatch_marker()


## Ação Defender: gasta TODOS os PA restantes e deixa a unidade em guarda até o próximo reset_actions().
## Sem PA ou já defendendo, não faz nada e devolve false.
func defend() -> bool:
	if action_points < 1 or is_defending:
		return false
	is_defending = true
	_update_defend_marker()
	spend_action(action_points)
	print("Defender: %s guarda a posição" % unit_name)
	return true


# Mostra o anel enquanto is_defending for verdadeiro e o esconde caso contrário.
func _update_defend_marker() -> void:
	if _defend_marker == null:
		if not is_defending:
			return
		_defend_marker = _build_defend_marker()
	_defend_marker.visible = is_defending


# Anel ciano deitado no chão, filho da raiz da unidade (não do Body), sem sombra e sem colisor.
func _build_defend_marker() -> MeshInstance3D:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "DefendMarker"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.75
	torus.outer_radius = 0.95
	marker.mesh = torus
	marker.scale = Vector3(1.0, 0.15, 1.0)
	marker.position = Vector3(0.0, 0.05, 0.0)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = defend_marker_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	return marker


## Ação Vigilância: gasta TODOS os PA restantes e deixa a unidade em vigilância até o próximo
## reset_actions(). Sem PA, em Defender ou já em vigilância, não faz nada e devolve false.
func go_overwatch() -> bool:
	if action_points < 1 or is_defending or is_overwatching:
		return false
	is_overwatching = true
	_update_overwatch_marker()
	spend_action(action_points)
	print("Vigilância: %s em vigilância" % unit_name)
	return true


## Gasta a vigilância (ela reagiu): desliga is_overwatching e esconde o anel laranja.
func consume_overwatch() -> void:
	is_overwatching = false
	_update_overwatch_marker()


# Mostra o anel laranja enquanto is_overwatching for verdadeiro e o esconde caso contrário.
func _update_overwatch_marker() -> void:
	if _overwatch_marker == null:
		if not is_overwatching:
			return
		_overwatch_marker = _build_overwatch_marker()
	_overwatch_marker.visible = is_overwatching


# Mesmo anel do Defender (mesma geometria e posição), na cor de Vigilância.
func _build_overwatch_marker() -> MeshInstance3D:
	var marker: MeshInstance3D = _build_defend_marker()
	marker.name = "OverwatchMarker"
	var material: StandardMaterial3D = marker.material_override as StandardMaterial3D
	material.albedo_color = overwatch_marker_color
	return marker


## Causa dano. Ignora valores <= 0 e dano em unidade já morta; o HP nunca fica abaixo de 0.
## Ao chegar a 0: sai do grupo "units" (deixa de bloquear células) antes de qualquer outra
## coisa, emite health_changed e died (uma única vez) e então toca a animação de morte, que termina
## com queue_free().
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
		_play_death_animation()


## Animação de ataque (só visual): o Body avança em direção ao alvo (direção horizontal, pelas
## posições globais) por lunge_distance e volta. Mexe só no Body, nunca na raiz da unidade.
func play_attack_animation(target: Unit) -> void:
	_stop_body_animation()
	var direction: Vector3 = target.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.001:
		return
	# O Body é filho da raiz: converte a direção do mundo para o espaço local da unidade.
	var local_direction: Vector3 = global_transform.basis.inverse() * direction.normalized()

	_anim_tween = _new_body_tween()
	_anim_tween.tween_property(_body, "position", BODY_REST_POSITION + local_direction * lunge_distance, lunge_out_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_body, "position", BODY_REST_POSITION, lunge_back_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_callback(_reset_body)


## Animação de dano (só visual): após `delay`, o Body treme e pisca com um overlay vermelho
## semitransparente por hit_time; no fim volta à posição original e o overlay sai.
func play_hit_animation(delay: float = 0.0) -> void:
	_stop_body_animation()
	_hit_ready_msec = Time.get_ticks_msec() + int(delay * 1000.0)

	_anim_tween = _new_body_tween()
	if delay > 0.0:
		_anim_tween.tween_interval(delay)
	_append_hit_effect(_anim_tween)
	_anim_tween.tween_callback(_reset_body)


# Morte: esconde o rótulo de vida, segue animando mesmo com o jogo pausado, toca a animação de
# dano (respeitando o que faltava do atraso de um golpe já agendado), encolhe o Body até 0 em
# death_time e só então chama queue_free().
func _play_death_animation() -> void:
	# O anel de Defender some junto com o início da morte.
	if _defend_marker != null:
		_defend_marker.visible = false
	if _overwatch_marker != null:
		_overwatch_marker.visible = false
	# Desliga o colisor de clique: a unidade morrendo não pode mais ser clicada nem atingida pelo raio.
	var hitbox: CollisionObject3D = get_node_or_null("Hitbox") as CollisionObject3D
	if hitbox != null:
		hitbox.set_deferred("collision_layer", 0)

	_hp_label.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	var remaining_delay: float = 0.0
	if _anim_tween != null and _anim_tween.is_valid():
		remaining_delay = maxf(0.0, float(_hit_ready_msec - Time.get_ticks_msec()) / 1000.0)

	_stop_body_animation()
	_anim_tween = _new_body_tween()
	if remaining_delay > 0.0:
		_anim_tween.tween_interval(remaining_delay)
	_append_hit_effect(_anim_tween)
	_anim_tween.tween_property(_body, "scale", Vector3.ZERO, death_time)
	_anim_tween.tween_callback(queue_free)


# Tween das animações do Body: continua rodando mesmo com o jogo pausado (fim da missão).
func _new_body_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


# Clarão vermelho + tremor do Body por hit_time; termina com o Body em repouso e sem overlay.
func _append_hit_effect(tween: Tween) -> void:
	tween.tween_callback(_show_flash)
	var steps: int = 5
	var step_time: float = hit_time / float(steps)
	for i: int in steps:
		var shake: Vector3 = Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		tween.tween_property(_body, "position", BODY_REST_POSITION + shake, step_time)
	tween.tween_callback(_end_hit_effect)


func _show_flash() -> void:
	var flash: StandardMaterial3D = StandardMaterial3D.new()
	flash.albedo_color = flash_color
	flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_body.material_overlay = flash


func _end_hit_effect() -> void:
	_body.position = BODY_REST_POSITION
	_body.material_overlay = null


# Para a animação do Body em andamento (se houver) e o devolve ao estado original.
func _stop_body_animation() -> void:
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = null
	_hit_ready_msec = 0
	_reset_body()


# Body exatamente em position (0, 0.6, 0), scale 1 e sem overlay.
func _reset_body() -> void:
	_body.position = BODY_REST_POSITION
	_body.scale = Vector3.ONE
	_body.material_overlay = null


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
