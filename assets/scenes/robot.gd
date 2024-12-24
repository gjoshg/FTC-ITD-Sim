extends CharacterBody2D



enum COMMANDS {MOVEMENT, ROTATION, WAIT}
var robotActions = []
var movementSpeed = 100
var rotationSpeed = 85
var rotationalEpsilon = 1
var positionalEpsilon = 0.1
var lastPosition = null
var robotWeight = 10

func _ready() -> void:
	blueRight()
	pass
	

func blueLeft():
	pass

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
	lastPosition = position
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
					
	# needed to push rigidbodies				
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * robotWeight)
	

	move_and_slide()
