extends Node

var main_win:Window
var l_win:Window
var r_win:Window
var screen_size:Vector2i

var direction:Vector2
const BASE_SPEED := 300.0
const BALL_SPEED := 512.0
var speed := BALL_SPEED

var sfx_paddle = preload("res://Beep.wav")
var sfx_wall = preload("res://Beep2.wav")
var sfx_goal = preload("res://Goal.wav")
var audio_player:AudioStreamPlayer

enum {
	LEFT,
	RIGHT,
}

enum State {
	WAITING,
	PLAYING,
}

var state:State = State.WAITING

var top_ball:float
var bottom_ball:float
var top_paddle:float
var bottom_paddle:float
var left_oob:float
var right_oob:float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = DisplayServer.screen_get_size()

	main_win = get_window()
	main_win.borderless = true
	main_win.size = Vector2i(64, 64)
	main_win.gui_embed_subwindows = false
	main_win.position = Vector2i(screen_size / 2 - main_win.size / 2)

	l_win = Window.new()
	l_win.borderless = true
	l_win.always_on_top = true
	l_win.size = Vector2i(64, 256)
	l_win.position = Vector2i(0, screen_size.y / 2 - l_win.size.y / 2)
	get_tree().root.add_child.call_deferred(l_win)

	r_win = Window.new()
	r_win.borderless = true
	r_win.always_on_top = true
	r_win.size = Vector2i(64, 256)
	r_win.position = Vector2i(screen_size.x - r_win.size.x, screen_size.y / 2 - r_win.size.y / 2)
	get_tree().root.add_child.call_deferred(r_win)

	top_ball = 0.0
	top_paddle = 0.0
	bottom_ball = screen_size.y - main_win.size.y
	bottom_paddle = screen_size.y - l_win.size.y
	left_oob = 0.0 - main_win.size.x
	right_oob = screen_size.x

	audio_player = AudioStreamPlayer.new()
	get_tree().root.add_child.call_deferred(audio_player)

	direction = get_random_angle_vector(-1)
	state = State.WAITING


func _process(delta) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit(0)

	var lmov = Input.get_axis(&"l_up", &"l_down")
	var lpos = l_win.position + Vector2i(0, lmov * BASE_SPEED * delta)
	if lpos.y < top_paddle:
		lpos.y = top_paddle
	if lpos.y > bottom_paddle:
		lpos.y = bottom_paddle
	l_win.position = lpos

	var rmov = Input.get_axis(&"r_up", &"r_down")
	var rpos = r_win.position + Vector2i(0, rmov * BASE_SPEED * delta)
	if rpos.y < top_paddle:
		rpos.y = top_paddle
	if rpos.y > bottom_paddle:
		rpos.y = bottom_paddle
	r_win.position = rpos

	if state == State.WAITING:
		if Input.is_action_just_pressed(&"start"):
			play_sfx(sfx_paddle)
			state = State.PLAYING

	if state == State.PLAYING:
		main_win.position += Vector2i(direction * speed * delta)

		var rect_m := Rect2i(main_win.position, main_win.size)
		var rect_l := Rect2i(l_win.position, l_win.size)
		var rect_r := Rect2i(r_win.position, r_win.size)

		var intercepted := false
		var adjust:Vector2
		if rect_m.intersects(rect_l):
			intercepted = true
			adjust = Vector2(rect_l.get_center() - rect_m.get_center()).normalized()
		elif rect_m.intersects(rect_r):
			intercepted = true
			adjust = Vector2(rect_r.get_center() - rect_m.get_center()).normalized()

		if intercepted:
			play_sfx(sfx_paddle)
			direction = (direction.reflect(Vector2.UP) - adjust).normalized()
			speed += 32

		if main_win.position.y <= top_ball || main_win.position.y >= bottom_ball:
			play_sfx(sfx_wall)
			direction = direction.reflect(Vector2.RIGHT)

		if main_win.position.x < -main_win.size.x:
			scores(RIGHT)
		elif main_win.position.x > screen_size.x:
			scores(LEFT)


func scores(who) -> void:
	play_sfx(sfx_goal)
	main_win.position = Vector2i(screen_size / 2 - main_win.size / 2)
	state = State.WAITING
	direction = get_random_angle_vector(who)
	speed = BALL_SPEED


func play_sfx(what:AudioStream) -> void:
	audio_player.stream = what
	audio_player.play()


func get_random_angle_vector(who) -> Vector2:
	const mina := PI / 6.0
	const maxa := PI - mina
	var res: = randf_range(mina, maxa)

	match who:
		RIGHT:
			res -= PI / 2.0
		LEFT:
			res += PI / 2.0
		_:
			res += -PI / 2.0 if randi_range(0, 1) > 0 else PI / 2.0

	return Vector2.from_angle(res).normalized()
