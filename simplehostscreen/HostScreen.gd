extends Node2D

@export var socket_url: String = "ws://localhost:3000"

var ws := WebSocketPeer.new()
var is_ws_connected := false
var room_code := ""

@onready var room_code_label: Label = get_node("Control/RoomCodeLabel")

func _ready() -> void:
	room_code = generate_room_code()
	room_code_label.text = "Room Code: %s" % room_code
	print("🧩 Room Code for this session:", room_code)

	var err = ws.connect_to_url(socket_url)
	if err != OK:
		push_error("❌ Failed to connect to %s (Error %d)" % [socket_url, err])
	else:
		print("🟡 Connecting to:", socket_url)

	# Wait a moment to ensure connection is ready
	await get_tree().create_timer(1.0).timeout
	join_room_as_host()

func _process(_delta: float) -> void:
	ws.poll()

	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_OPEN:
			if not is_ws_connected:
				is_ws_connected = true
				print("✅ WebSocket connection established. Listening for joins...")

			while ws.get_available_packet_count() > 0:
				var msg = ws.get_packet().get_string_from_utf8()
				handle_message(msg)
		WebSocketPeer.STATE_CLOSING:
			print("🔌 Closing connection...")
		WebSocketPeer.STATE_CLOSED:
			if is_ws_connected:
				is_ws_connected = false
				print("❌ Disconnected from server")

func handle_message(message: String) -> void:
	print("📥 Message from server:", message)

	var parsed = JSON.parse_string(message)
	if parsed == null:
		print("⚠️ Failed to parse JSON:", message)
		return

	var data: Dictionary = parsed
	var msg_type = data.get("type", "")

	match msg_type:
		"player_joined":
			var joined_room = data.get("roomCode", "")
			if joined_room == room_code:
				var player_name = data.get("playerId", "unknown")
				print("🎉 Player '%s' joined room %s!" % [player_name, joined_room])
			else:
				print("👀 Ignored join for different room:", joined_room)

		"action_broadcast":
			var action = data.get("action", "unknown")
			print("📨 Action received:", action)

		_:
			print("ℹ️ Unknown message type:", msg_type)

func join_room_as_host():
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("🚫 Not connected. Cannot host room.")
		return

	var msg = {
		"type": "join_room",
		"roomCode": room_code,
		"playerId": "GodotHost"
	}
	ws.put_packet(JSON.stringify(msg).to_utf8_buffer())
	print("📤 Godot host joined room:", room_code)

func generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code := ""
	for i in 4:
		code += chars[randi() % chars.length()]
	return code
