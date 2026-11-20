import React, { createContext, useContext, useEffect, useState } from 'react';
import { io } from 'socket.io-client';
import { useAuth } from './AuthContext';

const SocketContext = createContext();

export const SocketProvider = ({ children }) => {
  const [socket, setSocket] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [latestOrder, setLatestOrder] = useState(null);
  const [latestRiderLocation, setLatestRiderLocation] = useState(null);
  const { isAuthenticated } = useAuth();

  useEffect(() => {
    const socketUrl = import.meta.env.VITE_SOCKET_URL || 'http://localhost:5000';
    const s = io(socketUrl, {
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      autoConnect: true,
    });

    s.on('connect', () => {
      console.log('[Socket] Connected to Valley Express server:', s.id);
      setIsConnected(true);
      // Join admin operations room
      s.emit('join:admin');
    });

    s.on('disconnect', () => {
      console.log('[Socket] Disconnected from server');
      setIsConnected(false);
    });

    s.on('order:new', (order) => {
      console.log('[Socket] New Order Received:', order);
      setLatestOrder(order);
    });

    s.on('rider:location', (loc) => {
      setLatestRiderLocation(loc);
    });

    setSocket(s);

    return () => {
      s.disconnect();
    };
  }, [isAuthenticated]);

  return (
    <SocketContext.Provider
      value={{
        socket,
        isConnected,
        latestOrder,
        latestRiderLocation,
      }}
    >
      {children}
    </SocketContext.Provider>
  );
};

export const useSocket = () => useContext(SocketContext);
