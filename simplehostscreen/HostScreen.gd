extends Node2D

func _ready():
	# Generate a 6-character code with letters/numbers
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	randomize()
	for i in range(6):
		code += characters[randi() % characters.length()]
	
	$roomcodelabel.text = "Room Code: " + code
