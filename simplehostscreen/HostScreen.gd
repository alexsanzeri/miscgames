extends Node2D

@export var socket_url: String = "ws://localhost:3000"

var ws := WebSocketPeer.new()
var is_ws_connected := false

@onready var room_code_field: LineEdit = $RoomCodeField
@onready var join_button: Button = $JoinRoomButton
@onready var action_button: Button = $ActionButton

func _ready() -> void:
	var err = ws.connect_to_url(socket_url)
	if err != OK:
		push_error("❌ Failed to connect to %s (Error %d)" % [socket_url, err])
	else:
		print("🟡 Connecting to:", socket_url)

	join_button.pressed.connect(_on_join_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)

func _process(_delta: float) -> void:
	ws.poll()

	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass  # Still connecting...
		WebSocketPeer.STATE_OPEN:
			if not is_ws_connected:
				is_ws_connected = true
				print("✅ WebSocket connection established!")

			while ws.get_available_packet_count() > 0:
				var message = ws.get_packet().get_string_from_utf8()
				handle_message(message)
		WebSocketPeer.STATE_CLOSING:
			print("WebSocket is closing...")
		WebSocketPeer.STATE_CLOSED:
			if is_ws_connected:
				is_ws_connected = false
				print("🚫 WebSocket connection closed.")

func handle_message(message: String) -> void:
	var result = JSON.parse_string(message)
	if result.error != OK:
		print("⚠️ Failed to parse JSON:", message)
		return

	var data = result.result
	match data.get("type", ""):
		"player_joined":
			print("🎮 A player joined the room!")
		"action_broadcast":
			print("📨 Action received:", data.get("action"))
		_:
			print("ℹ️ Unknown message type:", data)

func _on_join_button_pressed() -> void:
	var room_code = room_code_field.text.strip_edges()
	join_room(room_code)

func _on_action_button_pressed() -> void:
	var room_code = room_code_field.text.strip_edges()
	send_player_action(room_code, "ACTION_EXAMPLE")

func join_room(room_code: String) -> void:
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("❌ Not connected. Can't join room.")
		return

	var payload = {
		"type": "join_room",
		"roomCode": room_code
	}
	var msg = JSON.stringify(payload)
	ws.put_packet(msg.to_utf8())
	print("📤 Sent join_room for:", room_code)

func send_player_action(room_code: String, action: String) -> void:
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("❌ Not connected. Can't send action.")
		return

	var payload = {
		"type": "player_action",
		"roomCode": room_code,
		"action": action
	}
	var msg = JSON.stringify(payload)
	ws.put_packet(msg.to_utf8())
	print("📤 Sent action:", action, "for room:", room_code)
