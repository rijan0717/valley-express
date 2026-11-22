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

    // Join one conversation on an order. Chat is split per channel (support,
    // delivery, fleet) so a customer watching their support thread is not
    // handed the rider's traffic.
    socket.on('join:thread', ({ orderId, channel = 'support' } = {}) => {
      if (!orderId) return;
      socket.join(`order:${orderId}:${channel}`);
      console.log(`[Socket] ${socket.id} joined order:${orderId}:${channel}`);
    });

    // Join the caller's personal room, used for chat fan-out and badges.
    socket.on('join:user', (userId) => {
      if (!userId) return;
      socket.join(`user:${userId}`);
      console.log(`[Socket] ${socket.id} joined user:${userId}`);
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

    // Chat is never relayed straight from a client: messages are broadcast by
    // the REST handler once they are authorised and stored, so a socket
    // cannot inject a message it was not allowed to send.

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
