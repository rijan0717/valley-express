import React, { useEffect, useState, useRef } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import { useChatUnread } from '../context/ChatUnreadContext';
import ValleyLoader from '../components/ValleyLoader';

const Chat = ({ onReplaySplash }) => {
  const { showAlert, showToast } = useModal();
  const [threads, setThreads] = useState([]);
  const [selectedThread, setSelectedThread] = useState(null);
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const { socket } = useSocket();
  const { threads: unreadByThread, total: totalUnread, markThreadRead } = useChatUnread();
  const messagesEndRef = useRef(null);

  const fetchThreads = async () => {
    try {
      const res = await api.get('/chat/threads');
      if (res.data.success) {
        setThreads(res.data.threads);
        if (res.data.threads.length > 0 && !selectedThread) {
          setSelectedThread(res.data.threads[0]);
        }
      }
    } catch (e) {
      console.error('Error fetching chat threads:', e);
    } finally {
      setLoading(false);
    }
  };

  const fetchMessages = async (orderId) => {
    try {
      const res = await api.get(`/chat/${orderId}`);
      if (res.data.success) {
        setMessages(res.data.messages);
      }
    } catch (e) {
      console.error('Error fetching messages:', e);
    }
  };

  useEffect(() => {
    fetchThreads();
  }, []);

  useEffect(() => {
    if (selectedThread) {
      fetchMessages(selectedThread._id);
      markThreadRead(selectedThread._id);
      if (socket) {
        socket.emit('join:order', selectedThread._id);
      }
    }
  }, [selectedThread, socket, markThreadRead]);

  useEffect(() => {
    if (socket) {
      const handleChatMessage = (newMsg) => {
        const threadId = selectedThread?._id;
        const msgOrderId = newMsg.order?._id || newMsg.order;
        const msgCustomerId = newMsg.customer?._id || newMsg.customer;

        if (threadId && (msgOrderId === threadId || msgCustomerId === threadId)) {
          setMessages((prev) => {
            if (prev.some((m) => m._id === newMsg._id)) return prev;
            return [...prev, newMsg];
          });
          // The thread is on screen, so it counts as read immediately
          if (newMsg.senderRole !== 'admin') {
            markThreadRead(threadId);
          }
        }
        fetchThreads();
      };

      socket.on('chat:message', handleChatMessage);
      return () => {
        socket.off('chat:message', handleChatMessage);
      };
    }
  }, [socket, selectedThread, markThreadRead]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!selectedThread) {
      showToast('Select a conversation before replying.', 'warning');
      return;
    }
    if (!inputMessage.trim()) {
      showToast('Type a reply before sending.', 'warning');
      return;
    }

    const text = inputMessage.trim();
    setInputMessage('');

    try {
      const res = await api.post(`/chat/${selectedThread._id}`, { text, senderRole: 'admin' });
      if (res.data.success) {
        setMessages((prev) => {
          if (prev.some((m) => m._id === res.data.message._id)) return prev;
          return [...prev, res.data.message];
        });
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Message Delivery Error', 'danger');
    }
  };

  return (
    <>
      <Navbar title="Customer Support & Order Chat" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Loading support threads from database..." />
        ) : (
          <div className="chat-container">
            {/* Threads List */}
            <div className="threads-sidebar">
              <div className="threads-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span>Active Order Conversations</span>
                {totalUnread > 0 && (
                  <span className="unread-count" title={`${totalUnread} unread in total`}>
                    {totalUnread > 99 ? '99+' : totalUnread}
                  </span>
                )}
              </div>
              <ul className="thread-list">
                {threads.length === 0 ? (
                  <li style={{ padding: '24px', textAlign: 'center', color: '#1F2A44', fontSize: '12px' }}>
                    No active chat threads. Conversations start when customers message from the mobile app.
                  </li>
                ) : (
                  threads.map((thread) => (
                    <li
                      key={thread._id}
                      onClick={() => setSelectedThread(thread)}
                      className={`thread-item ${selectedThread?._id === thread._id ? 'active' : ''}`}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px', gap: '6px' }}>
                        <span style={{ fontWeight: 700, color: '#003893' }}>{thread.orderNo}</span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          {unreadByThread[thread._id] > 0 && (
                            <span
                              className="unread-count"
                              title={`${unreadByThread[thread._id]} unread message${unreadByThread[thread._id] === 1 ? '' : 's'}`}
                            >
                              {unreadByThread[thread._id] > 99 ? '99+' : unreadByThread[thread._id]}
                            </span>
                          )}
                          <span className="badge badge-neutral" style={{ fontSize: '10px' }}>
                            {thread.status}
                          </span>
                        </span>
                      </div>
                      <div style={{ fontWeight: 500, fontSize: '12px' }}>
                        {thread.customer?.name || 'Customer'}
                      </div>
                      <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                        {thread.deliveryAddress?.addressText || thread.address?.addressText}
                      </div>
                    </li>
                  ))
                )}
              </ul>
            </div>

            {/* Chat Pane */}
            <div className="chat-pane">
              {selectedThread ? (
                <>
                  <div className="chat-header">
                    <div style={{ fontWeight: 700, color: '#003893' }}>
                      {selectedThread.orderNo} — {selectedThread.customer?.name} ({selectedThread.customer?.phone})
                    </div>
                    <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                      Drop-off: {selectedThread.deliveryAddress?.addressText || selectedThread.address?.addressText}
                    </div>
                  </div>

                  <div className="chat-messages">
                    {messages.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '36px', color: '#1F2A44', fontSize: '12px' }}>
                        No messages exchanged yet. Send a message to customer below.
                      </div>
                    ) : (
                      messages.map((msg) => {
                        const isMe = msg.senderRole === 'admin' || msg.sender?._id === msg.recipient;
                        return (
                          <div
                            key={msg._id}
                            className={`chat-bubble ${isMe ? 'outbound' : 'inbound'}`}
                          >
                            <div style={{ fontSize: '11px', fontWeight: 700, marginBottom: '2px' }}>
                              {isMe ? 'Operations Dispatch' : (msg.sender?.name || 'Customer')}
                            </div>
                            <div>{msg.text}</div>
                            <div style={{ fontSize: '10px', color: '#1F2A44', textAlign: 'right', marginTop: '4px' }}>
                              {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </div>
                          </div>
                        );
                      })
                    )}
                    <div ref={messagesEndRef} />
                  </div>

                  <form onSubmit={handleSend} className="chat-form">
                    <input
                      type="text"
                      value={inputMessage}
                      onChange={(e) => setInputMessage(e.target.value)}
                      placeholder="Type response to customer..."
                      style={{ flex: 1 }}
                    />
                    <button type="submit" className="btn btn-primary btn-sm">
                      Send Reply
                    </button>
                  </form>
                </>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: '#1F2A44' }}>
                  Select an order thread to start messaging
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default Chat;
