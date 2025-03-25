// main.js

// Create a WebSocket pointing to our Node server
const ws = new WebSocket("ws://localhost:3000");

// When the connection opens
ws.onopen = () => {
  console.log("Connected to raw WebSocket server!");
};

// Handle incoming messages
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // We handle "player_joined" and "action_broadcast" just like before
  if (data.type === "player_joined") {
    alert("A new player joined the room!");
  } else if (data.type === "action_broadcast") {
    console.log("Action broadcast received:", data);
    alert(`Action from room ${data.roomCode}: ${data.action}`);
  }
};

// Button: Join the room
document.getElementById('joinBtn').addEventListener('click', () => {
  const roomCode = document.getElementById('roomCodeInput').value.trim();
  ws.send(JSON.stringify({
    type: "join_room",
    roomCode
  }));
});

// Button: Send an action
document.getElementById('actionBtn').addEventListener('click', () => {
  const roomCode = document.getElementById('roomCodeInput').value.trim();
  ws.send(JSON.stringify({
    type: "player_action",
    roomCode,
    action: "ACTION_EXAMPLE"
  }));
});
