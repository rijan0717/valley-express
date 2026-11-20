import React, { createContext, useContext, useCallback, useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from './AuthContext';
import { useSocket } from './SocketContext';

const ChatUnreadContext = createContext();

export const ChatUnreadProvider = ({ children }) => {
  const [total, setTotal] = useState(0);
  const [threads, setThreads] = useState({});
  const { isAuthenticated } = useAuth();
  const { socket } = useSocket();

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setTotal(0);
      setThreads({});
      return;
    }
    try {
      const res = await api.get('/chat/unread');
      if (res.data.success) {
        setTotal(res.data.total);
        setThreads(res.data.threads || {});
      }
    } catch {
      // Badge is non-critical; leave the last known count in place
    }
  }, [isAuthenticated]);

  const markThreadRead = useCallback(
    async (threadId) => {
      if (!threadId) return;
      try {
        await api.post(`/chat/${threadId}/read`);
      } catch {
        // Ignore; refresh below keeps the badge honest either way
      }
      refresh();
    },
    [refresh]
  );

  useEffect(() => {
    refresh();
  }, [refresh]);

  // Keep the badge live as messages arrive or threads are opened elsewhere
  useEffect(() => {
    if (!socket) return undefined;
    socket.on('chat:message', refresh);
    socket.on('chat:read', refresh);
    return () => {
      socket.off('chat:message', refresh);
      socket.off('chat:read', refresh);
    };
  }, [socket, refresh]);

  return (
    <ChatUnreadContext.Provider value={{ total, threads, refresh, markThreadRead }}>
      {children}
    </ChatUnreadContext.Provider>
  );
};

export const useChatUnread = () => useContext(ChatUnreadContext);
