extends KinematicBody2D

#todo -> full refactor with pure functions

var little = 4
var big = 7

export (int) var ACCELERATION = 2048
export (int) var MAX_SPEED = 256
export (float) var FRICTION = 0.15
export (int) var GRAVITY = 1092
export (int) var WALL_SLIDE_SPEED = 150
export (int) var MAX_WALL_SLIDE_SPEED = 256
export (int) var JUMP_FORCE = 500
export (int) var MAX_SLOPE_ANGLE = 46
export (int) var PHYS_PUSH = 100

enum {
    MOVE,
    WALL_SLIDE
}

var state = MOVE
var motion = Vector2.ZERO
var snap_vector = Vector2.ZERO
var just_jumped = false

onready var label = $Label
onready var sprite = $Sprite

func _physics_process(delta: float) -> void:
    just_jumped = false
    
    if Input.is_action_pressed("speed_up"):
        if is_on_floor():
            MAX_SPEED = 448
        else:
            MAX_SPEED = 488
    if Input.is_action_just_released("speed_up"):
        MAX_SPEED = 256
    
    match state:
        MOVE:
            label.text = 'M'
            var input_vector = get_input_vector()
            apply_horizontal_force(input_vector, delta)
            apply_friction(input_vector)
            update_snap_vector()
            jump_check()
            apply_gravity(delta)
            move()
            wall_slide_check()
            
        WALL_SLIDE:
            label.text = 'W'
            var wall_axis = get_wall_axis()
            if wall_axis != 0:
                sprite.scale.x = wall_axis
            wall_slide_jump_check(wall_axis)
            wall_slide_drop(delta)
            move()
            wall_detach(delta, wall_axis)

func get_input_vector():
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var current_sign = sign(input_vector.x)
    if current_sign != 0:
        sprite.scale.x = current_sign * -1
    return input_vector
    
func apply_horizontal_force(input_vector, delta):
    if input_vector.x != 0:
        motion.x += input_vector.x * ACCELERATION * delta
        motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)
        
func apply_friction(input_vector):
    if input_vector.x == 0 and is_on_floor():
        motion.x = lerp(motion.x, 0, FRICTION)

func update_snap_vector():
    if is_on_floor():
        snap_vector = Vector2.DOWN
        
func jump_check():
    if is_on_floor():
        if Input.is_action_just_pressed("jump"):
            jump(JUMP_FORCE)
            just_jumped = true
    else:
        if Input.is_action_just_released("jump") and motion.y < 0:
            motion.y = 0.0
            
func jump(force):
    motion.y = -force
    snap_vector = Vector2.ZERO
    

func apply_gravity(delta):
    if not is_on_floor():
        motion.y += GRAVITY * delta
        motion.y = min(motion.y, JUMP_FORCE)


        
func move():
    var was_on_air = not is_on_floor()
    var was_on_floor = is_on_floor()
    var last_motion = motion
    var last_position = position
    
    motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE), false)
    
    for index in get_slide_count():
        var collision = get_slide_collision(index)
        if collision.collider.is_in_group("bodies"):
            collision.collider.apply_central_impulse(-collision.normal * PHYS_PUSH)
    
    #Landing
    if was_on_air and is_on_floor():
        motion.x = last_motion.x
    
    # Just left ground
    if was_on_floor and not is_on_floor() and not just_jumped:
        motion.y = 0
        position.y = last_position.y
        
    #Prevent 
    if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
        position.x = last_position.x
        
func wall_slide_check() -> void:
    if not is_on_floor() and is_on_wall():
        state = WALL_SLIDE

func get_wall_axis() -> int:
    var is_right_wall = test_move(transform, Vector2.RIGHT)
    var is_left_wall = test_move(transform, Vector2.LEFT)
    return int(is_left_wall) - int(is_right_wall)
    
#i think here can be rid of some lines
#todo -> refactor
func wall_slide_jump_check(wall_axis):
    #here should be wall jump
    # IDIA
    # when wall is on left then
    # 1. shift + jump + move_right = large jump from the wall on the right direction
    # 2. jump + move_left + [shift] = small jump to wall
    #wall_axis = 1 wall is left
    #wall_axis = -1 walls is right
    if Input.is_action_just_pressed("jump"):
        var left_dir = wall_axis > 0 and Input.is_action_pressed("move_left")
        var right_dir = wall_axis < 0 and Input.is_action_pressed("move_right")
        var left_wall_jump = wall_axis > 0 and Input.is_action_pressed("move_right")
        var right_wall_jump = wall_axis < 0 and Input.is_action_pressed("move_left")
        if left_dir or right_dir:
            motion.x = wall_axis * MAX_SPEED
            motion.y = -JUMP_FORCE * 1.5
            state = MOVE
        elif left_wall_jump or right_wall_jump:
            motion.x = wall_axis * MAX_SPEED
            motion.y = -JUMP_FORCE
            state = MOVE
        else:
            motion.x = wall_axis * MAX_SPEED
            motion.y = -JUMP_FORCE
            state = MOVE
    
func wall_slide_drop(delta):
    var max_slide_speed = WALL_SLIDE_SPEED
    if Input.is_action_pressed("down"):
        max_slide_speed = JUMP_FORCE
    motion.y = min(motion.y + GRAVITY * delta, max_slide_speed)

func wall_detach(delta, wall_axis):
    if Input.is_action_just_pressed("move_right"):
        motion.x = ACCELERATION * delta
        state = MOVE
        
    if Input.is_action_just_pressed("move_left"):
        motion.x = -ACCELERATION * delta
        state = MOVE
        
    if wall_axis == 0 or is_on_floor():
        state = MOVE
