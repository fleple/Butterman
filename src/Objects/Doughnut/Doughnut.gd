extends Area2D

var velocity := Vector2.ZERO
var direction := Vector2.ZERO

var current_speed := 300

func set_speed(speed: int) -> void:
    current_speed = speed

func set_direction(dir: Vector2) -> void:
    direction = dir

func _physics_process(delta):
    velocity = Vector2(
        current_speed * delta * sign(direction.x),
        current_speed * delta * sign(direction.y)
    )
    translate(velocity)


func _on_Doughnut_body_entered(body: Node) -> void:
    if body.name == 'Player':
        body.die()
    queue_free()
