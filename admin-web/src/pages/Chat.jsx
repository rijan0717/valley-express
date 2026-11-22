import React, { useEffect, useState, useRef } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import { useChatUnread } from '../context/ChatUnreadContext';
import ValleyLoader from '../components/ValleyLoader';

// Clean Lucide SVG Icon components (strictly no emojis)
const UserIcon = ({ size = 12, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
    <circle cx="12" cy="7" r="4" />
  </svg>
);

const BikeIcon = ({ size = 12, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="5.5" cy="17.5" r="3.5" />
    <circle cx="18.5" cy="17.5" r="3.5" />
    <path d="M15 6a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-3 11.5V14l-3-3 4-3 2 3h4" />
  </svg>
);

const PackageIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="16.5" y1="9.4" x2="7.5" y2="4.21" />
    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
    <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
    <line x1="12" y1="22.08" x2="12" y2="12" />
  </svg>
);

const Chat = ({ onReplaySplash }) => {
  const { showAlert, showToast } = useModal();
  const [threads, setThreads] = useState([]);
  const [selectedThread, setSelectedThread] = useState(null);
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState('all'); // 'all' | 'customer' | 'rider'
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

  const fetchMessages = async (thread) => {
    if (!thread) return;
    try {
      const ch = thread.channel || (thread.threadType === 'rider' ? 'fleet' : 'support');
      const res = await api.get(`/chat/${thread._id}?channel=${ch}`);
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
      fetchMessages(selectedThread);
      markThreadRead(selectedThread._id);
      if (socket) {
        socket.emit('join:order', selectedThread._id);
        if (selectedThread.channel === 'fleet' || selectedThread.threadType === 'rider') {
          socket.emit('join:rider', selectedThread._id);
        }
      }
    }
  }, [selectedThread, socket, markThreadRead]);

  useEffect(() => {
    if (socket) {
      const handleChatMessage = (newMsg) => {
        const threadId = selectedThread?._id;
        const msgOrderId = newMsg.order?._id || newMsg.order;
        const msgCustomerId = newMsg.customer?._id || newMsg.customer;
        const msgRiderId = newMsg.rider?._id || newMsg.rider;

        if (threadId && (msgOrderId === threadId || msgCustomerId === threadId || msgRiderId === threadId)) {
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
    const channel = selectedThread.channel || (selectedThread.threadType === 'rider' ? 'fleet' : 'support');

    try {
      const res = await api.post(`/chat/${selectedThread._id}`, {
        text,
        channel,
        senderRole: 'admin',
      });
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

  const customerThreads = threads.filter((t) => t.threadType !== 'rider');
  const riderThreads = threads.filter((t) => t.threadType === 'rider' || t.isFleetRider);
  const filteredThreads = filterType === 'customer'
    ? customerThreads
    : (filterType === 'rider' ? riderThreads : threads);

  return (
    <>
      <Navbar title="Operations Dispatch & Messages" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Loading live conversations from dispatch..." />
        ) : (
          <div className="chat-container">
            {/* Threads List */}
            <div className="threads-sidebar">
              <div className="threads-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 800 }}>Dispatch Conversations</span>
                {totalUnread > 0 && (
                  <span className="unread-count" title={`${totalUnread} unread in total`}>
                    {totalUnread > 99 ? '99+' : totalUnread}
                  </span>
                )}
              </div>

              {/* Category Filter Tabs: All, Customer, Rider */}
              <div style={{
                display: 'flex',
                padding: '8px 12px',
                gap: '6px',
                background: '#F8FAFC',
                borderBottom: '1px solid #E2E8F0',
              }}>
                <button
                  type="button"
                  onClick={() => setFilterType('all')}
                  style={{
                    flex: 1,
                    padding: '5px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    borderRadius: '6px',
                    border: '1px solid',
                    borderColor: filterType === 'all' ? '#003893' : '#CBD5E1',
                    background: filterType === 'all' ? '#003893' : '#FFFFFF',
                    color: filterType === 'all' ? '#FFFFFF' : '#475569',
                    cursor: 'pointer',
                  }}
                >
                  All ({threads.length})
                </button>
                <button
                  type="button"
                  onClick={() => setFilterType('customer')}
                  style={{
                    flex: 1,
                    padding: '5px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    borderRadius: '6px',
                    border: '1px solid',
                    borderColor: filterType === 'customer' ? '#FF6B1A' : '#CBD5E1',
                    background: filterType === 'customer' ? '#FF6B1A' : '#FFFFFF',
                    color: filterType === 'customer' ? '#FFFFFF' : '#475569',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '4px'
                  }}
                >
                  <UserIcon size={12} color={filterType === 'customer' ? '#FFF' : '#FF6B1A'} />
                  <span>Users ({customerThreads.length})</span>
                </button>
                <button
                  type="button"
                  onClick={() => setFilterType('rider')}
                  style={{
                    flex: 1,
                    padding: '5px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    borderRadius: '6px',
                    border: '1px solid',
                    borderColor: filterType === 'rider' ? '#059669' : '#CBD5E1',
                    background: filterType === 'rider' ? '#059669' : '#FFFFFF',
                    color: filterType === 'rider' ? '#FFFFFF' : '#475569',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '4px'
                  }}
                >
                  <BikeIcon size={12} color={filterType === 'rider' ? '#FFF' : '#059669'} />
                  <span>Riders ({riderThreads.length})</span>
                </button>
              </div>

              <ul className="thread-list">
                {filteredThreads.length === 0 ? (
                  <li style={{ padding: '24px', textAlign: 'center', color: '#64748B', fontSize: '12px' }}>
                    No conversations in this section yet.
                  </li>
                ) : (
                  filteredThreads.map((thread) => {
                    const hasUnread = (unreadByThread[thread._id] || 0) > 0;
                    const isRider = thread.threadType === 'rider' || thread.isFleetRider;
                    return (
                      <li
                        key={thread._id}
                        onClick={() => setSelectedThread(thread)}
                        className={`thread-item ${selectedThread?._id === thread._id ? 'active' : ''}`}
                        style={{ position: 'relative' }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px', gap: '6px' }}>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            {/* Unread dot indicator */}
                            {hasUnread && (
                              <span
                                style={{
                                  display: 'inline-block',
                                  width: '8px',
                                  height: '8px',
                                  borderRadius: '50%',
                                  backgroundColor: '#FF6B1A',
                                  boxShadow: '0 0 6px rgba(255,107,26,0.6)',
                                }}
                                title="New incoming message"
                              />
                            )}
                            <span style={{ fontWeight: 800, color: isRider ? '#059669' : '#003893' }}>
                              {thread.orderNo}
                            </span>
                          </span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            {hasUnread && (
                              <span
                                className="unread-count"
                                title={`${unreadByThread[thread._id]} unread message${unreadByThread[thread._id] === 1 ? '' : 's'}`}
                              >
                                {unreadByThread[thread._id] > 99 ? '99+' : unreadByThread[thread._id]}
                              </span>
                            )}
                            <span
                              className={`badge ${isRider ? 'badge-success' : 'badge-neutral'}`}
                              style={{ fontSize: '10px', textTransform: 'uppercase' }}
                            >
                              {isRider ? 'FLEET RIDER' : thread.status}
                            </span>
                          </span>
                        </div>
                        <div style={{ fontWeight: 600, fontSize: '12px', display: 'flex', alignItems: 'center', gap: '5px' }}>
                          {isRider ? (
                            <BikeIcon size={12} color="#059669" />
                          ) : (
                            <UserIcon size={12} color="#003893" />
                          )}
                          <span>{thread.customer?.name || (isRider ? thread.rider?.name : 'Customer')}</span>
                        </div>
                        <div style={{ fontSize: '11px', color: '#64748B', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {thread.deliveryAddress?.addressText || thread.address?.addressText || (isRider ? 'On Duty Fleet Rider' : '')}
                        </div>
                      </li>
                    );
                  })
                )}
              </ul>
            </div>

            {/* Chat Pane */}
            <div className="chat-pane">
              {selectedThread ? (
                <>
                  <div className="chat-header">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ fontWeight: 800, color: (selectedThread.threadType === 'rider' || selectedThread.isFleetRider) ? '#059669' : '#003893', fontSize: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        {(selectedThread.threadType === 'rider' || selectedThread.isFleetRider) ? (
                          <BikeIcon size={16} color="#059669" />
                        ) : (
                          <PackageIcon size={16} color="#003893" />
                        )}
                        <span>{selectedThread.orderNo} — {selectedThread.customer?.name} {selectedThread.customer?.phone ? `(${selectedThread.customer?.phone})` : ''}</span>
                      </div>
                      <span className={`badge ${(selectedThread.threadType === 'rider' || selectedThread.isFleetRider) ? 'badge-success' : 'badge-neutral'}`}>
                        {(selectedThread.threadType === 'rider' || selectedThread.isFleetRider) ? 'RIDER FLEET LINE' : 'CUSTOMER ORDER'}
                      </span>
                    </div>
                    <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                      {(selectedThread.threadType === 'rider' || selectedThread.isFleetRider)
                        ? `Operational Dispatch Line • ${selectedThread.deliveryAddress?.addressText || 'Kathmandu Valley Fleet'}`
                        : `Drop-off: ${selectedThread.deliveryAddress?.addressText || selectedThread.address?.addressText || 'Valley Customer'}`}
                    </div>
                  </div>

                  <div className="chat-messages">
                    {messages.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '36px', color: '#64748B', fontSize: '12px' }}>
                        No messages exchanged yet. Send a message to start conversation.
                      </div>
                    ) : (
                      messages.map((msg) => {
                        const isMe = msg.senderRole === 'admin' || msg.sender?._id === msg.recipient;
                        const isRiderMsg = msg.senderRole === 'rider';
                        return (
                          <div
                            key={msg._id}
                            className={`chat-bubble ${isMe ? 'outbound' : 'inbound'}`}
                          >
                            <div style={{ fontSize: '11px', fontWeight: 700, marginBottom: '2px', display: 'flex', alignItems: 'center', gap: '5px' }}>
                              {isMe ? (
                                'Operations Dispatch'
                              ) : isRiderMsg ? (
                                <>
                                  <BikeIcon size={12} color="#059669" />
                                  <span>{msg.sender?.name || 'Fleet Rider'}</span>
                                </>
                              ) : (
                                <>
                                  <UserIcon size={12} color="#003893" />
                                  <span>{msg.sender?.name || 'Customer'}</span>
                                </>
                              )}
                            </div>
                            <div>{msg.text}</div>
                            <div style={{ fontSize: '10px', color: isMe ? '#D1D5DB' : '#64748B', textAlign: 'right', marginTop: '4px' }}>
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
                      placeholder={(selectedThread.threadType === 'rider' || selectedThread.isFleetRider)
                        ? "Type dispatch message to rider..."
                        : "Type response to customer..."}
                      style={{ flex: 1 }}
                    />
                    <button type="submit" className="btn btn-primary btn-sm">
                      Send Reply
                    </button>
                  </form>
                </>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: '#64748B' }}>
                  Select a conversation from the sidebar to start messaging
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
