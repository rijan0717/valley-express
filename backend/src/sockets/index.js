let ioInstance = null;

const setupSockets = (io) => {
  ioInstance = io;

  io.on('connection', (socket) => {
    console.log(`[Socket Connected] ID: ${socket.id}`);

    // Join room for specific order updates
    socket.on('join:order', (orderId) => {
      socket.join(`order:${orderId}`);
      console.log(`[Socket] ${socket.id} joined order room order:${orderId}`);
    });

    // Join admin operations room (for new orders, rider map)
    socket.on('join:admin', () => {
      socket.join('admin-room');
      console.log(`[Socket] ${socket.id} joined admin-room`);
    });

    // Join rider specific room
    socket.on('join:rider', (riderId) => {
      socket.join(`rider:${riderId}`);
      console.log(`[Socket] ${socket.id} joined rider:${riderId}`);
    });

    // Handle rider GPS location streaming
    socket.on('rider:location', (data) => {
      // data: { riderId, orderId, coordinates: [lng, lat], heading, speed }
      console.log(`[Socket rider:location] Rider ${data.riderId} location update`);
      // Broadcast to admin room
      io.to('admin-room').emit('rider:location', data);
      // If associated with active order, broadcast to customer watching the order
      if (data.orderId) {
        io.to(`order:${data.orderId}`).emit('rider:location', data);
      }
    });

    // Handle chat message in real time
    socket.on('chat:message', (messageData) => {
      // messageData: { orderId, threadId, sender, text, createdAt }
      if (messageData.orderId) {
        io.to(`order:${messageData.orderId}`).emit('chat:message', messageData);
      }
      io.to('admin-room').emit('chat:message', messageData);
    });

    socket.on('disconnect', () => {
      console.log(`[Socket Disconnected] ID: ${socket.id}`);
    });
  });
};

const getIO = () => {
  if (!ioInstance) {
    // Return a dummy object if socket is not initialized to avoid crashes
    return {
      to: () => ({ emit: () => {} }),
      emit: () => {},
    };
  }
  return ioInstance;
};

module.exports = { setupSockets, getIO };
