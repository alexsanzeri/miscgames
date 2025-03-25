const express = require('express');
const http = require('http');
const WebSocket = require('ws');

// Create an Express app
const app = express();
// Create an HTTP server
const server = http.createServer(app);

// Set up a raw WebSocket server using 'ws'
const wss = new WebSocket.Server({ server });

// Map from roomCode -> Set of websocket clients
const rooms = new Map();

wss.on('connection', (ws) => {
  console.log('A user connected via raw WebSocket.');

  ws.on('message', (message) => {
    console.log('Received message:', message.toString());
    let data;
    try {
      data = JSON.parse(message.toString());
    } catch (err) {
      console.error('Message was not valid JSON:', err);
      return;
    }
    if (!data) return;

    switch (data.type) {
      case 'join_room': {
        const { roomCode } = data;
        console.log(`Client joining room: ${roomCode}`);

        // Create the room if it doesn't exist yet
        if (!rooms.has(roomCode)) {
          rooms.set(roomCode, new Set());
        }
        // Add this ws to the room
        rooms.get(roomCode).add(ws);

        // Broadcast "player_joined" to everyone in that room
        broadcastToRoom(roomCode, {
          type: 'player_joined'
        });
        break;
      }

      case 'player_action': {
        const { roomCode, action } = data;
        console.log(`Player action in room ${roomCode}: ${action}`);
        // Broadcast "action_broadcast" to that room
        broadcastToRoom(roomCode, {
          type: 'action_broadcast',
          roomCode,
          action
        });
        break;
      }
    }
  });

  ws.on('close', () => {
    console.log('A user disconnected.');
    // Remove from all rooms
    for (const [roomCode, clients] of rooms.entries()) {
      if (clients.has(ws)) {
        clients.delete(ws);
        // Optionally broadcast a “player_left” event if needed
      }
    }
  });
});

// Helper function to broadcast a message to everyone in a given room
function broadcastToRoom(roomCode, payload) {
  if (!rooms.has(roomCode)) return;
  const msgString = JSON.stringify(payload);
  for (const client of rooms.get(roomCode)) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msgString);
    }
  }
}

// Serve static files from the 'public' folder (for index.html, main.js, etc.)
app.use(express.static('public'));

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`Server listening at http://localhost:${PORT}`);
});
