require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const connectDB = require('./config/db');
const { setupSockets } = require('./sockets');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  // Connect to Database
  await connectDB();

  // Create HTTP server
  const server = http.createServer(app);

  // Initialize Socket.io
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
    },
  });

  setupSockets(io);

  server.listen(PORT, () => {
    console.log(`===============================================`);
    console.log(`Valley Express Backend Server running`);
    console.log(`HTTP & Socket.io Port: http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`===============================================`);
  });
};

startServer();
