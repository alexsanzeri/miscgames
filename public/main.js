const ws = new WebSocket("ws://localhost:3000"); // ← This is fine if server handles it

let playerName = "";

ws.onopen = () => {
  console.log("✅ Connected to game server");
  playerName = prompt("Enter your player name") || "anon";
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log("📥 Received:", data);

  if (data.type === "player_joined") {
    alert(`🎮 ${data.playerId} joined room ${data.roomCode}`);
  } else if (data.type === "action_broadcast") {
    console.log("📨 Action broadcast:", data);
  }
};

document.getElementById("joinBtn").addEventListener("click", () => {
  const roomCode = document.getElementById("roomCodeInput").value.trim().toUpperCase();

  if (!roomCode) {
    alert("❗ Please enter a room code.");
    return;
  }

  ws.send(JSON.stringify({
    type: "join_room",
    roomCode: roomCode,
    playerId: playerName
  }));

  console.log(`📤 Sent join_room with code ${roomCode}`);
});

document.getElementById("actionBtn").addEventListener("click", () => {
  const roomCode = document.getElementById("roomCodeInput").value.trim().toUpperCase();

  if (!roomCode) {
    alert("❗ Please enter a room code first.");
    return;
  }

  ws.send(JSON.stringify({
    type: "player_action",
    roomCode: roomCode,
    action: "ACTION_EXAMPLE"
  }));

  console.log("📤 Sent action for room:", roomCode);
});
