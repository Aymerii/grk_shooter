extends CharacterBody3D

@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var ammoLabel: Label = $CanvasLayer/GunBase/AmmoLabel

#PARAMETRE PERSO
var hp = 50
var max_hp = 50
var shield = 15

var vitesse_marche = 5.0
var gravity = 14.0

var damage = 25

var max_ammo = 7
var current_ammo = 7

#ETATS JOUEUR
var mode = "fight"

#PARAMETRE CONFIG JEU
const MOUSE_SENS = 0.05

#ON/OFF
var can_shoot = true
var dead = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(shoot_anim_done) #je lie la func shoot anim done avec l'animation qui se finis call automatique
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)

func _input(event):
	if dead:
		return
		
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		$Camera3D.rotation_degrees.x -= event.relative.y * MOUSE_SENS
		$Camera3D.rotation_degrees.x = clamp($Camera3D.rotation_degrees.x, -45,45)

func _process(delta):	
	if dead:
		return	
		
	#SHOOT	
	if Input.is_action_just_pressed("shoot"):
		shoot()	
	
	ammoLabel.text = str(current_ammo) + "/" + str(max_ammo) 
	
	if mode == "reloading":
		ammoLabel.text = "Reloading .."
		
func _physics_process(delta):
	if dead:
		return	
		
	#SPRINT 
	var vitesse = vitesse_marche
	if Input.is_action_pressed("sprint"):
		vitesse = vitesse_marche * 1.6
		
	#DIRECTION 
	var input_dir := Input.get_vector("move_left", "move_right", "move_fowards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse
	else:
		#ralentissement progressif 
		velocity.x = move_toward(velocity.x, 0, 0.5 )
		velocity.z = move_toward(velocity.z, 0, 0.5)
	
	#JUMP
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += 5
		
	#GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#RELOAD GUN
	if Input.is_action_just_pressed("reload") and current_ammo != max_ammo:
		reload()
		
	move_and_slide()

func restart():
	get_tree().reload_current_scene()
	
func shoot():
	if !can_shoot:
		return
		
	can_shoot = false
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	
	current_ammo -= 1
	
	if ray_cast_3d.is_colliding(): #si le raycast entre en collision avec objet 
		var target = ray_cast_3d.get_collider()  #on recupere l'objet 
		if target.is_in_group("enemy"): #si il fait partie du grp enemy
			target.hit(damage)   #on lui fait des degats
			
	if current_ammo == 0:
		reload()
		return

func shoot_anim_done():
	if mode != "reloading":
		can_shoot = true
	
func hit(enemy): #je recupere le bon enemy et recevoir dmg qui correspond
	print("l'ennemis fait -" + str(enemy.damage))
	if dead:
		return
	else:	
		if shield >= enemy.damage:
			shield -= enemy.damage
		else:
			hp -= enemy.damage - shield
			shield = 0
			
		if hp <= 0:
			dead = true
			$CanvasLayer/DeathScreen.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func reload():
	if mode == "reloading":
		return
		
	mode = "reloading"	
	can_shoot = false
	await get_tree().create_timer(1.2).timeout #await temporaire pour recharge arme 
	current_ammo = max_ammo
	can_shoot = true
	mode = "fight"
