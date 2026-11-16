extends Node3D

@onready var wave_label: Label = $HUD_NextWave/WaveLabel
@onready var boost_panel: PanelContainer = $HUD_NextWave/BoostPanel
@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")

#RECUPERATION NOEUDS
const tscn_enemy = preload("res://scenes/enemy.tscn")

#SIGNAUX
signal bonus_choisi

#PARAMETRE JEU
var vague_MAX = 10
var nbr_enemyMax = 3
var nbr_enemy = 3
var vague_num = 1

func _ready() -> void:
	vague_enemy(nbr_enemyMax) #vague 1
	
func _process(delta: float) -> void:
	$HUD_InGame/HpLabel.text = "Hp : " + str(player.hp) + "/" + str(player.max_hp)
	$HUD_InGame/Nbr_enemyLabel.text = "Enemy : " + str(nbr_enemy)
	$HUD_InGame/DegatLabel.text = "Dégâts : " + str(player.damage)
	$HUD_InGame/ShieldLabel.text = "Shield : " + str(player.shield)
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
		
	if vague_num > vague_MAX: 
		get_tree().quit()
	
func vague_enemy(x):
	for i in range(x):
		var instance_enemy = tscn_enemy.instantiate()
		$Environment.add_child(instance_enemy)
		instance_enemy.global_position = $Environment/SpawnPoints.get_children().pick_random().global_position
		instance_enemy.global_position += Vector3(randf_range(-4, 4),0,randf_range(-4, 4))
		instance_enemy.mort.connect(enemy_dead)
		
		
func enemy_dead():
	nbr_enemy -= 1
	
	if nbr_enemy <= 0:
		await get_tree().create_timer(2.0).timeout #await temporaire a modif
		get_tree().call_group("enemy", "queue_free")
		nbr_enemyMax += 3
		nbr_enemy = nbr_enemyMax
		vague_suivante()

func vague_suivante():
	#ici on met affichage vague n°.. + bonus +  changement nbr enemy en fonction de la vague --> modif a faire dans func enemy dead
	vague_num += 1
	wave_label.text = "Vague " + str(vague_num)
	wave_label.visible = true 
	boost_panel.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	
	await bonus_choisi
	
	wave_label.visible = false
	boost_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	get_tree().paused = false
	vague_enemy(nbr_enemyMax)
	
func _on_boost_1_pressed() -> void:
	player.hp += 25
	player.max_hp += 25
	bonus_choisi.emit()
func _on_boost_2_pressed() -> void:
	player.damage += 15
	bonus_choisi.emit()
func _on_boost_3_pressed() -> void:
	player.max_ammo += 2
	bonus_choisi.emit()
	
#A FAIRE
#============= PROBLEMES ==========#

#============= REVOIR =============#
#Revoir pourquoi le reload avait bug quand je mettais pas 

#============= SONS ===============#
#AJOUTER MUSIQUE JEU

#============= UI =================#
#AJOUTER OPTION CHANGEMENT DE CROSSAIR

#============= GAMEPLAY ===========#
#AJOUT CHANGEMENT D'ARMES
#MANCHE 10 LE 1 MUR S'OUVRE + CHANGEMENT SPAWN
#AJOUT OBJET AU SOL ex:+vie +shield
