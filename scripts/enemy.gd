extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player") #recherche dans groupe plus rapide et plus flexible quand l'arbre sera pleins de noeuds
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var attack_timer: Timer = $AttackTimer

#PARAMETRE ENEMY
#caracteristiques
var hp = 50
var shield = 0
var vitesse_patrouille = 2.0
var vitesse_poursuite = 4.0
var move_speed = vitesse_patrouille
var attack_range = 2.0
var damage = 10
#actions
var dead = false
var can_attack = true
var etat : String
var temps_recherche = 3.0
#position / direction
var pos_initial : Vector3
var direction : Vector3
var derniere_pos : Vector3
#export
@export var mode_jeu = "survie" #par defaut les enemy agissent en mode survival #dans scene campagne modif de l'export en campaign
@export var zone : Area3D
#signaux
signal mort

func _ready() -> void:
	if mode_jeu == "campagne":
		direction = Vector3(randf_range(-1, 1),0,randf_range(-1, 1)).normalized()
		pos_initial = global_position
		etat = "patrouille"
	
func _physics_process(delta: float) -> void:
	if dead:
		return

	if mode_jeu == "survie":
		if player == null:
			return
		
		direction = player.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
	
	if mode_jeu == "campagne":
		move_speed = vitesse_patrouille
		
		if direction == Vector3.ZERO:
			pass #animation a mettre en idle
			
		if is_on_wall():
			direction = get_wall_normal().rotated(Vector3.UP, deg_to_rad(randf_range(-60, 60)))
			direction.y = 0
			direction = direction.normalized()
			
		#si l'ennemi depasse la zone de patrouille 
		if etat == "patrouille" and !zone.overlaps_body(self):
			etat = "retour"
		
		#si player entre dans la zone et que enemy etait en patrouille/retour/recherche et qu'il voit le joueur -> poursuit
		if (etat == "patrouille" or etat == "retour" or etat == "recherche") and zone.overlaps_body(player) and voit_joueur():
			etat = "poursuite"
			
		if etat == "poursuite":
			if voit_joueur():
				derniere_pos = player.global_position
				derniere_pos.y = 0
				move_speed = vitesse_poursuite
				direction = player.global_position - global_position
				direction.y = 0.0 #si joueur saute comme enemy n'a pas de gravité enemy risque de volé
				direction = direction.normalized()
			else:
				temps_recherche = 3.0
				etat = "recherche"
			
		if etat == "recherche":
			direction = derniere_pos - global_position
			direction.y = 0
			direction = direction.normalized()
			if is_on_wall():
				derniere_pos = global_position
			if global_position.distance_to(derniere_pos) <= 0.5:
				direction = Vector3.ZERO
				temps_recherche -= delta
				if temps_recherche <= 0.0:
					etat = "retour"
			
		#si player n'est plus dans la zone ennemi retour pos_initial
		if etat == "poursuite" and !zone.overlaps_body(player):
			etat = "retour"
		if etat == "retour":
			direction = pos_initial - global_position
			direction.y = 0.0
			direction = direction.normalized()
			if is_on_wall():
				etat = "patrouille"
			if pos_initial.distance_to(global_position) <= 0.5:
				etat = "patrouille"
				direction = Vector3(randf_range(-1, 1),0,randf_range(-1, 1)).normalized()
		
	$Label3D.text = etat
	velocity = direction * move_speed
	move_and_slide()
	attempt_to_kill_player()
	
	choisir_animation()
	
func choisir_animation():
	if dead:
		return
	elif animated_sprite_3d.animation == "attack" and animated_sprite_3d.is_playing():
		return
	elif direction == Vector3.ZERO:
		animated_sprite_3d.play("idle")
	else:
		animated_sprite_3d.play("walk")
	
	
func voit_joueur() -> bool:
	var start_eye = $EyePosition.global_position
	var end_eye = player.get_node("EyePosition").global_position
	var query = PhysicsRayQueryParameters3D.create(start_eye,end_eye, 1) #voir si il y a un obstacle eviter de tuer player a travers mur
	var result = get_world_3d().direct_space_state.intersect_ray(query) #tire un trait comme raycast et verifie si objet sur mask1 environnement si non tue player
	return result.is_empty()
	
func attempt_to_kill_player():
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
		
	if voit_joueur() and can_attack and !player.dead:
		can_attack = false
		player.hit(self) #va permettre de dire a player quel enemy hit 
		animated_sprite_3d.play("attack")
		attack_timer.start()
		
func _on_attack_timer_timeout() -> void:
	can_attack = true		
		
		
func hit(degats):
	hp -= degats
	animated_sprite_3d.modulate = Color.RED
	hit_flash_timer.start()
	
	if hp <= 0 and not dead:
		dead = true
		$DeathSound.play()
		animated_sprite_3d.play("death")
		$CollisionShape3D.disabled = true
		mort.emit()
	
func _on_hit_flash_timer_timeout():
		animated_sprite_3d.modulate = Color.WHITE
