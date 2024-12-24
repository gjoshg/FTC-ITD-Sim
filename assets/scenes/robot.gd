extends CharacterBody2D



enum COMMANDS {MOVEMENT, ROTATION, WAIT, ARM_MOVEMENT, ARM_ROTATION, CLAW_TOGGLE}
enum CLAW_STATE{OPEN, CLOSE}
var robotActions = []
var movementSpeed = 100
var rotationSpeed = 85
var rotationalEpsilon = 1
var positionalEpsilon = 0.1
var robotWeight = 10

# reference to arm
@export var arm : Node
# reference to claw
@export var claw : Node
var clawStartingPosition
@export var clawAnimationPlayer : AnimationPlayer

var childSample = null

func _ready() -> void:
	setup()
	blueRight()
	pass
	
func setup():
	clawStartingPosition = claw.position
	
func blueLeft():
	moveLeft(210)
	setLiftTargetPosition(1800)
	moveForward(50)
	setClawState(CLAW_STATE.CLOSE)
	turn(180)
	moveForward(10)
	setClawState(CLAW_STATE.OPEN)
	# second
	setLiftTargetPosition(0)
	turn(0)
	moveLeft(45)
	moveForward(25)
	setLiftTargetPosition(1800)
	setClawState(CLAW_STATE.CLOSE)
	setLiftTargetPosition(0)
	turn(180)
	moveForward(20)
	setClawState(CLAW_STATE.OPEN)
	# third
	moveBackward(20)
	turn(345)
	moveLeft(45)
	moveForward(25)
	setLiftTargetPosition(1800)
	setClawState(CLAW_STATE.CLOSE)
	setLiftTargetPosition(0)
	turn(180)
	moveForward(10)
	setClawState(CLAW_STATE.OPEN)
	turn(30)
	moveForward(350)
	

func blueRight():
	moveRight(150)
	moveForward(200)
	moveRight(50)
	moveForward(-200)
	moveForward(200)
	moveRight(30)
	moveForward(-200)
	moveForward(200)
	moveRight(30)
	moveForward(-200)
	moveForward(50)
	wait(3)
	moveForward(-50)

func redLeft():
	pass

func redRight():
	pass

func setClawState(state: CLAW_STATE):
	robotActions.push_back({type = COMMANDS.CLAW_TOGGLE, value = state})

func setLiftTargetPosition(length : float):
	robotActions.push_back({type = COMMANDS.ARM_MOVEMENT, value = length})

func wait(duration : float):
	robotActions.push_back({type = COMMANDS.WAIT, value = duration})	
	
func waitInternal(duration: float):
	set_physics_process(false)
	await get_tree().create_timer(duration, true, true).timeout
	set_physics_process(true)

func moveForward(distance : float):
	robotActions.push_back({type = COMMANDS.MOVEMENT, value = distance, directionVector = Vector2(0, -1)})
	
func moveBackward(distance : float):
	moveForward(-distance)
	
func moveLeft(distance : float):
	robotActions.push_back({type = COMMANDS.MOVEMENT, value = distance, directionVector = Vector2(-1, 0)})

func moveRight(distance : float):
	moveLeft(-distance)

func turn(degrees : float):
	while degrees > 180:
		degrees -= 360
	while degrees < -180:
		degrees += 360
	robotActions.push_back({type = COMMANDS.ROTATION, value = degrees})
	pass
	

func _physics_process(delta: float) -> void:
	if robotActions.size() > 0:
		var activeCommand = robotActions[0]
		if activeCommand.type == COMMANDS.ROTATION:
			var desiredRobotRotation = activeCommand.value
			# print(rotation_degrees, "\t", desiredRobotRotation) 
			if not (desiredRobotRotation - rotationalEpsilon <= rotation_degrees and rotation_degrees <= desiredRobotRotation + rotationalEpsilon):
				if rotation_degrees < desiredRobotRotation:
					rotation_degrees += rotationSpeed * delta
				else:
					rotation_degrees -= rotationSpeed * delta
			else: 
				robotActions.pop_front()
		elif activeCommand.type == COMMANDS.MOVEMENT:
			if activeCommand.value is not Vector2:
				activeCommand.value = position + activeCommand.directionVector.rotated(rotation) * activeCommand.value
				activeCommand.distanceTraveled = 0.0
				activeCommand.distanceToTravel = activeCommand.value.distance_to(position)
			else:
				var newPosition = position.move_toward(activeCommand.value, movementSpeed * delta)
				# if robot gets stuck, no movement occurs - move on to next command
				activeCommand.distanceTraveled += newPosition.distance_to(position)
				position = newPosition
				if activeCommand.distanceTraveled + positionalEpsilon >= activeCommand.distanceToTravel:
					velocity = Vector2(0, 0)
					robotActions.pop_front()
		elif activeCommand.type == COMMANDS.WAIT:
			robotActions.pop_front()
			await waitInternal(activeCommand.value)
		elif activeCommand.type == COMMANDS.ARM_MOVEMENT:
			var scaleValue = (activeCommand.value / 450.0) + 1 			# 0 = 1/2 ft, 1800 = 5/2 ft --> scale = (length / 450) + 1
			arm.scale.y = scaleValue
			claw.position = clawStartingPosition - Vector2(0, scaleValue*3) # lucky number 3
			robotActions.pop_front()
		elif activeCommand.type == COMMANDS.CLAW_TOGGLE:
			if activeCommand.value == CLAW_STATE.OPEN:
				clawAnimationPlayer.play("open")
				if childSample != null:
					childSample.reparent(get_parent())
			else:
				clawAnimationPlayer.play("close")
				if childSample != null:
					childSample.reparent(claw)
					childSample.position = claw.position - Vector2(0, 20) # lucky number 20
			robotActions.pop_front()
			
					
	# needed to push rigidbodies				
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * robotWeight)
	

	move_and_slide()


func _on_arm_body_entered(body: Node) -> void:
	pass


func _on_claw_grip_collider_body_entered(body: Node) -> void:
	if body.is_in_group("samples"):
		childSample = body


func _on_claw_grip_collider_body_exited(body: Node2D) -> void:
	if body.is_in_group("samples"):
		childSample = null
