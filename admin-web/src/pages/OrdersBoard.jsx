import React, { useEffect, useState, useMemo } from 'react';
import { MapIcon } from '../components/Icons';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

const ClockIcon = ({ size = 12, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ display: 'inline-block', verticalAlign: 'middle' }}>
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);

const formatTimeAgo = (rawDate) => {
  if (!rawDate) return '';
  const dt = new Date(rawDate);
  if (Number.isNaN(dt.getTime())) return '';

  const now = new Date();
  const diffMs = now.getTime() - dt.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  if (diffSec < 45) return 'Just now';

  const diffMins = Math.floor(diffSec / 60);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffDays >= 1) {
    return diffDays === 1 ? '1 day ago' : `${diffDays} days ago`;
  }

  if (diffHours >= 1) {
    const remMins = diffMins % 60;
    const hourPart = diffHours === 1 ? '1 hour' : `${diffHours} hours`;
    if (remMins === 0) {
      return `${hourPart} ago`;
    }
    const minPart = remMins === 1 ? '1 min' : `${remMins} mins`;
    return `${hourPart} ${minPart} ago`;
  }

  return diffMins <= 1 ? '1 min ago' : `${diffMins} mins ago`;
};

const OrdersBoard = ({ onReplaySplash }) => {
  const [orders, setOrders] = useState([]);
  const [riders, setRiders] = useState([]);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [assigningOrder, setAssigningOrder] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState('list'); // 'list' (WooCommerce style) | 'kanban'
  const [activeCardFilter, setActiveCardFilter] = useState('all'); // 'all' | 'placed' | 'preparing' | 'on_the_way' | 'delivered' | 'cancelled'
  const [selectedOrderIds, setSelectedOrderIds] = useState([]);
  const [bulkAction, setBulkAction] = useState('');

  const { showAlert, showConfirm, showPrompt, showToast } = useModal();
  const { latestOrder, socket } = useSocket();

  const fetchOrdersAndRiders = async () => {
    try {
      let token = localStorage.getItem('valley_token');
      if (!token) {
        try {
          const authRes = await api.post('/auth/admin-login', {
            email: 'admin@gmail.com',
            password: 'Password@123',
          });
          if (authRes.data.success) {
            token = authRes.data.token;
            localStorage.setItem('valley_token', token);
            localStorage.setItem('valley_user', JSON.stringify(authRes.data.user));
          }
        } catch {
          // ignore
        }
      }

      const [oRes, rRes] = await Promise.all([
        api.get('/orders'),
        api.get('/admin/settings/riders'),
      ]);
      if (oRes.data.success) setOrders(oRes.data.orders);
      if (rRes.data.success) setRiders(rRes.data.riders);
    } catch (e) {
      console.error('Error fetching orders:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrdersAndRiders();
  }, []);

  useEffect(() => {
    if (latestOrder) {
      setOrders((prev) => [latestOrder, ...prev.filter((o) => o._id !== latestOrder._id)]);
    }

    if (socket) {
      socket.on('order:status', (updatedOrder) => {
        setOrders((prev) =>
          prev.map((o) => (o._id === updatedOrder._id ? updatedOrder : o))
        );
        if (selectedOrder?._id === updatedOrder._id) {
          setSelectedOrder(updatedOrder);
        }
      });
    }
  }, [latestOrder, socket, selectedOrder]);

  const updateStatus = async (orderId, newStatus) => {
    try {
      const res = await api.patch(`/orders/${orderId}/status`, { status: newStatus });
      if (res.data.success) {
        setOrders((prev) =>
          prev.map((o) => (o._id === orderId ? res.data.order : o))
        );
        showToast(`Order status updated to ${newStatus.toUpperCase()}`, 'success');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Failed to Update Status', 'danger');
    }
  };

  const handleCancelOrder = async (orderId) => {
    const reason = await showPrompt('Please specify reason for order cancellation:', 'Customer requested cancellation', 'Cancel Order');
    if (!reason) return;
    try {
      const res = await api.patch(`/orders/${orderId}/cancel`, { reason });
      if (res.data.success) {
        setOrders((prev) =>
          prev.map((o) => (o._id === orderId ? res.data.order : o))
        );
        showToast('Order successfully cancelled', 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Cancellation Failed', 'danger');
    }
  };

  const handleDeleteOrder = async (orderId, orderNo) => {
    const confirmed = await showConfirm(
      `Are you sure you want to permanently purge order #${orderNo} from database? This action is irreversible.`,
      'Purge Order Confirmation',
      true,
      'Permanently Delete',
      'Keep Order'
    );
    if (!confirmed) return;
    try {
      const res = await api.delete(`/orders/${orderId}`);
      if (res.data.success) {
        setOrders((prev) => prev.filter((o) => o._id !== orderId));
        setSelectedOrderIds((prev) => prev.filter((id) => id !== orderId));
        if (selectedOrder?._id === orderId) setSelectedOrder(null);
        showToast(`Order #${orderNo} deleted from database`, 'success');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete Order Failed', 'danger');
    }
  };

  const handleAssignRider = async (riderId) => {
    if (!assigningOrder) return;
    try {
      const res = await api.patch(`/orders/${assigningOrder._id}/assign`, { riderId });
      if (res.data.success) {
        setOrders((prev) =>
          prev.map((o) => (o._id === assigningOrder._id ? res.data.order : o))
        );
        showToast('Rider assigned successfully', 'success');
        setAssigningOrder(null);
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Assign Rider Failed', 'danger');
    }
  };

  // Bulk actions (WooCommerce pattern)
  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedOrderIds(filteredOrders.map((o) => o._id));
    } else {
      setSelectedOrderIds([]);
    }
  };

  const handleToggleSelectOne = (orderId) => {
    setSelectedOrderIds((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
  };

  const handleExecuteBulkAction = async () => {
    if (!bulkAction || selectedOrderIds.length === 0) {
      showAlert('Please select at least one order and a bulk action to proceed.', 'Selection Required', 'warning');
      return;
    }

    if (bulkAction === 'delete') {
      const confirmed = await showConfirm(
        `Are you sure you want to permanently purge ${selectedOrderIds.length} selected orders from MongoDB?`,
        'Bulk Delete Confirmation',
        true,
        'Purge Selected',
        'Cancel'
      );
      if (!confirmed) return;
      try {
        await Promise.all(selectedOrderIds.map((id) => api.delete(`/orders/${id}`)));
        setOrders((prev) => prev.filter((o) => !selectedOrderIds.includes(o._id)));
        showToast(`${selectedOrderIds.length} orders purged from database`, 'success');
        setSelectedOrderIds([]);
        setBulkAction('');
      } catch (err) {
        showAlert(err.response?.data?.message || err.message, 'Bulk Delete Error', 'danger');
      }
      return;
    }

    if (bulkAction === 'preparing' || bulkAction === 'delivered') {
      try {
        await Promise.all(
          selectedOrderIds.map((id) => api.patch(`/orders/${id}/status`, { status: bulkAction }))
        );
        fetchOrdersAndRiders();
        showToast(`Updated ${selectedOrderIds.length} orders to ${bulkAction.toUpperCase()}`, 'success');
        setSelectedOrderIds([]);
        setBulkAction('');
      } catch (err) {
        showAlert(err.response?.data?.message || err.message, 'Bulk Status Error', 'danger');
      }
    }
  };

  // KPI Calculations
  const stats = useMemo(() => {
    const totalCount = orders.length;
    const totalRevenue = orders.reduce(
      (sum, o) => sum + (o.status !== 'cancelled' ? o.total || 0 : 0),
      0
    );
    const placedCount = orders.filter((o) => o.status === 'placed').length;
    const prepCount = orders.filter((o) => ['accepted', 'preparing'].includes(o.status)).length;
    const wayCount = orders.filter((o) =>
      ['rider_assigned', 'picked_up', 'on_the_way'].includes(o.status)
    ).length;
    const delivCount = orders.filter((o) => o.status === 'delivered').length;
    const cancelCount = orders.filter((o) => o.status === 'cancelled').length;

    return {
      total: totalCount,
      revenue: totalRevenue,
      placed: placedCount,
      preparing: prepCount,
      onTheWay: wayCount,
      delivered: delivCount,
      cancelled: cancelCount,
    };
  }, [orders]);

  // Filtering
  const filteredOrders = useMemo(() => {
    return orders.filter((o) => {
      // 1. Text Search query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const addr = o.deliveryAddress?.addressText || o.address?.addressText || '';
        const landmark = o.deliveryAddress?.landmark || o.address?.landmark || '';
        const matches =
          o.orderNo?.toLowerCase().includes(q) ||
          o.customer?.name?.toLowerCase().includes(q) ||
          o.customer?.phone?.includes(q) ||
          addr.toLowerCase().includes(q) ||
          landmark.toLowerCase().includes(q);

        if (!matches) return false;
      }

      // 2. Interactive Column Card Filter
      if (activeCardFilter === 'placed') return o.status === 'placed';
      if (activeCardFilter === 'preparing') return ['accepted', 'preparing'].includes(o.status);
      if (activeCardFilter === 'on_the_way')
        return ['rider_assigned', 'picked_up', 'on_the_way'].includes(o.status);
      if (activeCardFilter === 'delivered') return o.status === 'delivered';
      if (activeCardFilter === 'cancelled') return o.status === 'cancelled';

      return true;
    });
  }, [orders, searchQuery, activeCardFilter]);

  // Kanban slices
  const placed = filteredOrders.filter((o) => o.status === 'placed');
  const preparing = filteredOrders.filter((o) => ['accepted', 'preparing'].includes(o.status));
  const onTheWay = filteredOrders.filter((o) =>
    ['rider_assigned', 'picked_up', 'on_the_way'].includes(o.status)
  );
  const delivered = filteredOrders.filter((o) => o.status === 'delivered');

  const renderCard = (order) => {
    const addr = order.deliveryAddress?.addressText || order.address?.addressText || 'Kathmandu';
    const landmark = order.deliveryAddress?.landmark || order.address?.landmark;

    return (
      <div
        key={order._id}
        className="kanban-card"
        onClick={() => setSelectedOrder(order)}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '6px' }}>
          <div>
            <span style={{ fontWeight: 800, color: '#003893', fontSize: '14px' }}>#{order.orderNo}</span>
          </div>
          <div style={{ textAlign: 'right' }}>
            <span style={{ fontWeight: 800, color: '#FF6B1A', fontSize: '13px' }}>
              Rs. {order.total}
            </span>
            <div style={{ fontSize: '10.5px', color: '#003893', fontWeight: 700 }}>
              Delivery: Rs. {order.deliveryFee || 50}
            </div>
          </div>
        </div>

        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          fontSize: '11px',
          fontWeight: 700,
          color: '#FF6B1A',
          marginBottom: '8px'
        }}>
          <ClockIcon size={12} color="#FF6B1A" />
          <span>Placed {formatTimeAgo(order.createdAt)}</span>
          <span style={{ color: '#94A3B8', fontWeight: 400 }}>•</span>
          <span style={{ color: '#64748B', fontWeight: 500 }}>
            {new Date(order.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>

        <div style={{ marginBottom: '8px' }}>
          <div style={{ fontWeight: 500, fontSize: '13px' }}>{order.customer?.name || 'Customer'}</div>
          <div style={{ fontSize: '11px', color: '#1F2A44' }}>{order.customer?.phone}</div>
        </div>

        <div style={{ fontSize: '12px', color: '#1F2A44', marginBottom: '8px', lineHeight: 1.3 }}>
          {addr}
          {landmark && (
            <div style={{ fontSize: '11px', color: '#1F2A44' }}>Near {landmark}</div>
          )}
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <span style={{ fontSize: '11px', color: '#1F2A44' }}>
            {order.items?.length || 0} items
            {order.containsAlcohol && (
              <span style={{ color: '#FF6B1A', fontWeight: 700, marginLeft: '4px' }}>
                (18+)
              </span>
            )}
          </span>
          <span className="badge badge-neutral" style={{ fontSize: '10px' }}>
            {order.paymentMethod?.replace(/_/g, ' ')}
          </span>
        </div>

        {/* Action Buttons */}
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }} onClick={(e) => e.stopPropagation()}>
          {order.status === 'placed' && (
            <button
              onClick={() => updateStatus(order._id, 'preparing')}
              className="btn btn-primary btn-sm"
              style={{ flex: 1 }}
            >
              Accept &amp; Prepare
            </button>
          )}

          {order.status === 'preparing' && (
            <button
              onClick={() => setAssigningOrder(order)}
              className="btn btn-brand btn-sm"
              style={{ flex: 1 }}
            >
              Assign Rider
            </button>
          )}

          {['rider_assigned', 'picked_up', 'on_the_way'].includes(order.status) && (
            <button
              onClick={() => updateStatus(order._id, 'delivered')}
              className="btn btn-secondary btn-sm"
              style={{ flex: 1, borderColor: '#003893', color: '#003893' }}
            >
              Mark Delivered
            </button>
          )}

          {order.status !== 'delivered' && order.status !== 'cancelled' && (
            <button
              onClick={() => handleCancelOrder(order._id)}
              className="btn btn-secondary btn-sm"
              style={{ color: '#FF6B1A', borderColor: '#D1D5DB' }}
              title="Cancel Order"
            >
              Cancel
            </button>
          )}
        </div>
      </div>
    );
  };

  return (
    <>
      <Navbar title="Live Orders Board & WooCommerce Pipeline" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader variant="scooter" text="Loading live orders pipeline from MongoDB..." />
        ) : (
          <>
            {/* Interactive 6-Column Quick Filter Cards (Same as Users Directory) */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                gap: '12px',
                marginBottom: '20px',
              }}
            >
              {/* Column 1: All Orders */}
              <div
                onClick={() => setActiveCardFilter('all')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'all' ? '2px solid #003893' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  All Orders
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '24px', fontWeight: 700, color: '#003893' }}>
                    {stats.total}
                  </span>
                  <span style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 700 }}>
                    Rs. {stats.revenue.toLocaleString()}
                  </span>
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'all' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'all' ? '● Showing All' : 'Click to show all'}
                </div>
              </div>

              {/* Column 2: Placed (New) */}
              <div
                onClick={() => setActiveCardFilter('placed')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'placed' ? '2px solid #003893' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  Placed (New)
                </div>
                <div style={{ fontSize: '24px', fontWeight: 700, color: '#003893' }}>
                  {stats.placed}
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'placed' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'placed' ? '● Showing Placed' : 'Needs kitchen accept'}
                </div>
              </div>

              {/* Column 3: Preparing */}
              <div
                onClick={() => setActiveCardFilter('preparing')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'preparing' ? '2px solid #003893' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  Kitchen Prep
                </div>
                <div style={{ fontSize: '24px', fontWeight: 700, color: '#003893' }}>
                  {stats.preparing}
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'preparing' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'preparing' ? '● Showing Prep' : 'Packing & chilling'}
                </div>
              </div>

              {/* Column 4: On The Way */}
              <div
                onClick={() => setActiveCardFilter('on_the_way')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'on_the_way' ? '2px solid #FF6B1A' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  On The Way
                </div>
                <div style={{ fontSize: '24px', fontWeight: 700, color: '#FF6B1A' }}>
                  {stats.onTheWay}
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'on_the_way' ? '#FF6B1A' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'on_the_way' ? '● Showing Transit' : 'Riders dispatched'}
                </div>
              </div>

              {/* Column 5: Delivered */}
              <div
                onClick={() => setActiveCardFilter('delivered')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'delivered' ? '2px solid #003893' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  Delivered
                </div>
                <div style={{ fontSize: '24px', fontWeight: 700, color: '#003893' }}>
                  {stats.delivered}
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'delivered' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'delivered' ? '● Showing Delivered' : 'Cash collected'}
                </div>
              </div>

              {/* Column 6: Cancelled */}
              <div
                onClick={() => setActiveCardFilter('cancelled')}
                style={{
                  background: '#FFFFFF',
                  border: activeCardFilter === 'cancelled' ? '2px solid #1F2A44' : '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '12px 14px',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  transition: 'border-color 0.15s ease',
                }}
              >
                <div style={{ fontSize: '10px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '2px' }}>
                  Cancelled
                </div>
                <div style={{ fontSize: '24px', fontWeight: 700, color: '#1F2A44' }}>
                  {stats.cancelled}
                </div>
                <div style={{ fontSize: '10px', color: activeCardFilter === 'cancelled' ? '#1F2A44' : '#1F2A44', fontWeight: 600, marginTop: '6px' }}>
                  {activeCardFilter === 'cancelled' ? '● Showing Cancelled' : 'Voided orders'}
                </div>
              </div>
            </div>

            {/* View Switcher, Search & Bulk Actions Bar */}
            <div
              style={{
                background: '#FFFFFF',
                border: '1px solid #D1D5DB',
                borderRadius: '4px',
                padding: '14px',
                marginBottom: '20px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              {/* View Switcher Tabs */}
              <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                <button
                  type="button"
                  onClick={() => setViewMode('list')}
                  className={`btn ${viewMode === 'list' ? 'btn-brand' : 'btn-secondary'} btn-sm`}
                  style={{ borderRadius: '20px', padding: '6px 16px' }}
                >
                  WooCommerce Table View
                </button>
                <button
                  type="button"
                  onClick={() => setViewMode('kanban')}
                  className={`btn ${viewMode === 'kanban' ? 'btn-brand' : 'btn-secondary'} btn-sm`}
                  style={{ borderRadius: '20px', padding: '6px 16px' }}
                >
                  Kanban Pipeline
                </button>
              </div>

              {/* Bulk Actions (WooCommerce style) */}
              {viewMode === 'list' && (
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <select
                    value={bulkAction}
                    onChange={(e) => setBulkAction(e.target.value)}
                    style={{ height: '36px', fontSize: '12px', minWidth: '160px' }}
                  >
                    <option value="">Bulk Actions</option>
                    <option value="preparing">Change status to Preparing</option>
                    <option value="delivered">Change status to Delivered</option>
                    <option value="delete">Delete Selected Orders</option>
                  </select>
                  <button
                    type="button"
                    onClick={handleExecuteBulkAction}
                    disabled={selectedOrderIds.length === 0 || !bulkAction}
                    className="btn btn-secondary btn-sm"
                    style={{ height: '36px' }}
                  >
                    Apply ({selectedOrderIds.length})
                  </button>
                </div>
              )}

              {/* Search & Refresh */}
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flex: '1 1 240px', justifyContent: 'flex-end' }}>
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search order #, customer, phone, landmark..."
                  style={{ width: '100%', maxWidth: '300px', height: '36px', fontSize: '12px' }}
                />
                <button onClick={fetchOrdersAndRiders} className="btn btn-secondary btn-sm" style={{ height: '36px' }}>
                  Refresh
                </button>
              </div>
            </div>

            {/* VIEW 1: WOOCOMMERCE STYLE DATA TABLE */}
            {viewMode === 'list' && (
              <div style={{ background: '#FFFFFF', border: '1px solid #D1D5DB', borderRadius: '4px', overflowX: 'auto', marginBottom: '24px' }}>
                {filteredOrders.length === 0 ? (
                  <div style={{ padding: '48px', textAlign: 'center', color: '#1F2A44', fontSize: '13px' }}>
                    No orders found matching the filter or search criteria.
                  </div>
                ) : (
                  <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr>
                        <th style={{ width: '36px', textAlign: 'center' }}>
                          <input
                            type="checkbox"
                            checked={
                              filteredOrders.length > 0 &&
                              selectedOrderIds.length === filteredOrders.length
                            }
                            onChange={handleSelectAll}
                          />
                        </th>
                        <th>Order</th>
                        <th>Customer</th>
                        <th>Ship To (Kathmandu)</th>
                        <th>Purchased Items</th>
                        <th>Total &amp; Method</th>
                        <th>Status</th>
                        <th style={{ textAlign: 'right' }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredOrders.map((o) => {
                        const addr = o.deliveryAddress?.addressText || o.address?.addressText || 'Kathmandu Valley';
                        const landmark = o.deliveryAddress?.landmark || o.address?.landmark;
                        const isSelected = selectedOrderIds.includes(o._id);

                        return (
                          <tr key={o._id} style={{ background: isSelected ? '#FFFFFF' : '#FFFFFF' }}>
                            {/* Checkbox */}
                            <td style={{ textAlign: 'center' }}>
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => handleToggleSelectOne(o._id)}
                              />
                            </td>

                            {/* Order */}
                            <td>
                              <div
                                onClick={() => setSelectedOrder(o)}
                                style={{
                                  fontWeight: 700,
                                  fontSize: '13px',
                                  color: '#003893',
                                  cursor: 'pointer',
                                  textDecoration: 'none',
                                }}
                              >
                                #{o.orderNo}
                              </div>
                              <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                                <ClockIcon size={11} color="#FF6B1A" />
                                <span>Placed {formatTimeAgo(o.createdAt)}</span>
                              </div>
                              <div style={{ fontSize: '10px', color: '#6B7280', marginTop: '1px' }}>
                                {new Date(o.createdAt).toLocaleString()}
                              </div>
                            </td>

                            {/* Customer */}
                            <td>
                              <div style={{ fontWeight: 600, fontSize: '12px', color: '#1F2A44' }}>
                                {o.customer?.name || 'Customer'}
                              </div>
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                                {o.customer?.phone || o.deliveryAddress?.contactPhone || 'N/A'}
                              </div>
                            </td>

                            {/* Ship To */}
                            <td>
                              <div style={{ fontSize: '12px', color: '#1F2A44', maxWidth: '220px' }}>
                                {addr}
                              </div>
                              {landmark && (
                                <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 600 }}>
                                  Landmark: {landmark}
                                </div>
                              )}
                            </td>

                            {/* Items */}
                            <td>
                              <div style={{ fontSize: '12px', color: '#1F2A44', maxWidth: '200px' }}>
                                {o.items?.map((it, idx) => (
                                  <div key={idx} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                    {it.quantity}x {it.name}
                                  </div>
                                ))}
                              </div>
                              <div style={{ display: 'flex', gap: '4px', marginTop: '4px' }}>
                                <span style={{ fontSize: '10px', color: '#003893', fontWeight: 600 }}>
                                  {o.items?.length || 0} items
                                </span>
                                {o.containsAlcohol && (
                                  <span style={{ fontSize: '10px', color: '#FF6B1A', fontWeight: 700 }}>
                                    (18+ Alcohol)
                                  </span>
                                )}
                              </div>
                            </td>

                            {/* Total & Payment */}
                            <td>
                              <div style={{ fontWeight: 700, fontSize: '13px', color: '#FF6B1A' }}>
                                Rs. {(o.total || 0).toLocaleString()}
                              </div>
                              <div style={{ fontSize: '10px', color: '#1F2A44', marginTop: '2px' }}>
                                <span style={{ fontWeight: 600, color: '#003893' }}>Delivery: Rs. {(o.deliveryFee ?? 50).toLocaleString()}</span>
                                <span style={{ margin: '0 4px', color: '#D1D5DB' }}>•</span>
                                <span>Items: Rs. {Math.max(0, (o.total || 0) - (o.deliveryFee ?? 50)).toLocaleString()}</span>
                              </div>
                              <div style={{ fontSize: '11px', color: '#1F2A44', textTransform: 'capitalize', display: 'flex', alignItems: 'center', gap: '4px', flexWrap: 'wrap', marginTop: '3px' }}>
                                <span>{o.paymentMethod?.replace(/_/g, ' ') || 'Cash on Delivery'}</span>
                                {o.paymentStatus === 'paid' ? (
                                  <span style={{ fontSize: '9px', fontWeight: 700, color: '#16A34A', background: '#DCFCE7', padding: '1px 4px', borderRadius: '3px' }}>PAID</span>
                                ) : (
                                  <span style={{ fontSize: '9px', fontWeight: 600, color: '#64748B' }}>PENDING</span>
                                )}
                              </div>
                              {o.discount > 0 && (
                                <div style={{ fontSize: '10px', color: '#003893', fontWeight: 600 }}>
                                  Coupon: -Rs. {o.discount}
                                </div>
                              )}
                            </td>

                            {/* Status */}
                            <td>
                              <span
                                style={{
                                  display: 'inline-block',
                                  padding: '3px 8px',
                                  borderRadius: '4px',
                                  fontSize: '11px',
                                  fontWeight: 700,
                                  textTransform: 'uppercase',
                                  letterSpacing: '0.3px',
                                  border: `1px solid ${
                                    o.status === 'delivered'
                                      ? '#003893'
                                      : o.status === 'on_the_way'
                                      ? '#FF6B1A'
                                      : o.status === 'cancelled'
                                      ? '#D1D5DB'
                                      : '#003893'
                                  }`,
                                  color:
                                    o.status === 'delivered'
                                      ? '#003893'
                                      : o.status === 'on_the_way'
                                      ? '#FF6B1A'
                                      : o.status === 'cancelled'
                                      ? '#1F2A44'
                                      : '#003893',
                                  background: '#FFFFFF',
                                }}
                              >
                                {o.status?.replace(/_/g, ' ')}
                              </span>
                            </td>

                            {/* Actions (WooCommerce style) */}
                            <td style={{ textAlign: 'right' }}>
                              <div style={{ display: 'inline-flex', gap: '6px' }}>
                                {o.status === 'placed' && (
                                  <button
                                    type="button"
                                    onClick={() => updateStatus(o._id, 'preparing')}
                                    className="btn btn-primary btn-sm"
                                    style={{ fontSize: '11px', padding: '4px 8px' }}
                                  >
                                    Accept
                                  </button>
                                )}

                                {o.status === 'preparing' && (
                                  <button
                                    type="button"
                                    onClick={() => setAssigningOrder(o)}
                                    className="btn btn-brand btn-sm"
                                    style={{ fontSize: '11px', padding: '4px 8px' }}
                                  >
                                    Assign Rider
                                  </button>
                                )}

                                {['rider_assigned', 'picked_up', 'on_the_way'].includes(o.status) && (
                                  <button
                                    type="button"
                                    onClick={() => updateStatus(o._id, 'delivered')}
                                    className="btn btn-secondary btn-sm"
                                    style={{ fontSize: '11px', padding: '4px 8px', color: '#003893', borderColor: '#003893' }}
                                  >
                                    Deliver
                                  </button>
                                )}

                                <button
                                  type="button"
                                  onClick={() => setSelectedOrder(o)}
                                  className="btn btn-secondary btn-sm"
                                  style={{ fontSize: '11px', padding: '4px 8px' }}
                                >
                                  Details
                                </button>

                                {o.status !== 'delivered' && o.status !== 'cancelled' && (
                                  <button
                                    type="button"
                                    onClick={() => handleCancelOrder(o._id)}
                                    className="btn btn-secondary btn-sm"
                                    style={{ fontSize: '11px', padding: '4px 8px', color: '#FF6B1A' }}
                                  >
                                    Cancel
                                  </button>
                                )}

                                <button
                                  type="button"
                                  onClick={() => handleDeleteOrder(o._id, o.orderNo)}
                                  className="btn btn-secondary btn-sm"
                                  style={{ fontSize: '11px', padding: '4px 8px', color: '#FF6B1A', borderColor: '#D1D5DB' }}
                                  title="Permanently Delete Order from Database"
                                >
                                  Delete
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                )}
              </div>
            )}

            {/* VIEW 2: KANBAN PIPELINE */}
            {viewMode === 'kanban' && (
              <div className="kanban-board">
                <div className="kanban-column">
                  <div className="kanban-col-header">
                    <span className="kanban-col-title">Placed</span>
                    <span className="kanban-count">{placed.length}</span>
                  </div>
                  <div className="kanban-cards">
                    {placed.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '24px', color: '#1F2A44', fontSize: '12px' }}>
                        No new incoming orders
                      </div>
                    ) : (
                      placed.map(renderCard)
                    )}
                  </div>
                </div>

                <div className="kanban-column">
                  <div className="kanban-col-header">
                    <span className="kanban-col-title">Preparing</span>
                    <span className="kanban-count">{preparing.length}</span>
                  </div>
                  <div className="kanban-cards">
                    {preparing.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '24px', color: '#1F2A44', fontSize: '12px' }}>
                        Kitchen queue idle
                      </div>
                    ) : (
                      preparing.map(renderCard)
                    )}
                  </div>
                </div>

                <div className="kanban-column">
                  <div className="kanban-col-header">
                    <span className="kanban-col-title">On The Way</span>
                    <span className="kanban-count">{onTheWay.length}</span>
                  </div>
                  <div className="kanban-cards">
                    {onTheWay.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '24px', color: '#1F2A44', fontSize: '12px' }}>
                        No riders currently en route
                      </div>
                    ) : (
                      onTheWay.map(renderCard)
                    )}
                  </div>
                </div>

                <div className="kanban-column">
                  <div className="kanban-col-header">
                    <span className="kanban-col-title">Delivered</span>
                    <span className="kanban-count">{delivered.length}</span>
                  </div>
                  <div className="kanban-cards">
                    {delivered.length === 0 ? (
                      <div style={{ textAlign: 'center', padding: '24px', color: '#1F2A44', fontSize: '12px' }}>
                        No delivered orders matching
                      </div>
                    ) : (
                      delivered.slice(0, 10).map(renderCard)
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Assign Rider Modal */}
            {assigningOrder && (
              <div className="modal-overlay">
                <div className="modal-content">
                  <div className="modal-header">
                    <h3 className="modal-title">
                      Assign Rider to {assigningOrder.orderNo}
                    </h3>
                    <button
                      onClick={() => setAssigningOrder(null)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  <p style={{ fontSize: '12px', color: '#1F2A44', marginBottom: '16px' }}>
                    Select an active Kathmandu rider for delivery to{' '}
                    <strong>
                      {assigningOrder.deliveryAddress?.addressText || assigningOrder.address?.addressText}
                    </strong>
                  </p>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {riders.map((r) => (
                      <div
                        key={r._id}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '12px 16px',
                          border: '1px solid #D1D5DB',
                          borderRadius: '4px',
                        }}
                      >
                        <div>
                          <div style={{ fontWeight: 500, color: '#003893' }}>{r.name}</div>
                          <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                            {r.phone} • {r.vehicleNumber} ({r.vehicleType || 'Bike'})
                          </div>
                        </div>
                        <button
                          onClick={() => handleAssignRider(r._id)}
                          className="btn btn-primary btn-sm"
                        >
                          Dispatch
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Order Detail Modal */}
            {selectedOrder && (
              <div className="modal-overlay">
                <div className="modal-content">
                  <div className="modal-header">
                    <div>
                      <h3 className="modal-title">{selectedOrder.orderNo} Details</h3>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px', flexWrap: 'wrap' }}>
                        <span className="badge badge-brand">
                          {selectedOrder.status.replace(/_/g, ' ')}
                        </span>
                        <span style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                          <ClockIcon size={12} color="#FF6B1A" />
                          Placed {formatTimeAgo(selectedOrder.createdAt)}
                        </span>
                        <span style={{ fontSize: '11px', color: '#6B7280' }}>
                          ({new Date(selectedOrder.createdAt).toLocaleString()})
                        </span>
                      </div>
                    </div>
                    <button
                      onClick={() => setSelectedOrder(null)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  {/* Customer Information */}
                  <div style={{ borderBottom: '1px solid #D1D5DB', paddingBottom: '12px', marginBottom: '12px' }}>
                    <div style={{ fontWeight: 700, fontSize: '12px', textTransform: 'uppercase', color: '#003893', marginBottom: '4px' }}>
                      Customer &amp; Drop-off
                    </div>
                    <div style={{ fontWeight: 500 }}>{selectedOrder.customer?.name}</div>
                    <div style={{ fontSize: '12px', color: '#1F2A44' }}>{selectedOrder.customer?.phone}</div>
                    <div style={{ fontSize: '12px', color: '#1F2A44', marginTop: '4px' }}>
                      Address: {selectedOrder.deliveryAddress?.addressText || selectedOrder.address?.addressText}
                    </div>
                    {selectedOrder.deliveryAddress?.landmark && (
                      <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 600 }}>
                        Landmark: {selectedOrder.deliveryAddress.landmark}
                      </div>
                    )}
                    {selectedOrder.deliveryAddress?.formattedAddress && (
                      <div style={{ fontSize: '11px', color: '#4B5563', marginTop: '2px' }}>
                        {selectedOrder.deliveryAddress.formattedAddress}
                      </div>
                    )}
                    {selectedOrder.deliveryAddress?.location?.coordinates && (
                      <div style={{ marginTop: '8px', display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
                        <span style={{ fontSize: '10px', fontFamily: 'monospace', background: '#F3F4F6', padding: '2px 6px', borderRadius: '4px', border: '1px solid #D1D5DB', color: '#003893', fontWeight: 700 }}>
                          GPS: {selectedOrder.deliveryAddress.location.coordinates[1].toFixed(4)}N, {selectedOrder.deliveryAddress.location.coordinates[0].toFixed(4)}E
                        </span>
                        <a
                          href={`https://www.openstreetmap.org/?mlat=${selectedOrder.deliveryAddress.location.coordinates[1]}&mlon=${selectedOrder.deliveryAddress.location.coordinates[0]}#map=16/${selectedOrder.deliveryAddress.location.coordinates[1]}/${selectedOrder.deliveryAddress.location.coordinates[0]}`}
                          target="_blank"
                          rel="noreferrer"
                          style={{ fontSize: '11px', color: '#003893', fontWeight: 700, textDecoration: 'underline' }}
                        >
                          <MapIcon size={13} /> View on OpenStreetMap
                        </a>
                      </div>
                    )}
                  </div>

                  {/* Items breakdown */}
                  <div style={{ borderBottom: '1px solid #D1D5DB', paddingBottom: '12px', marginBottom: '12px' }}>
                    <div style={{ fontWeight: 700, fontSize: '12px', textTransform: 'uppercase', color: '#003893', marginBottom: '8px' }}>
                      Ordered Items
                    </div>
                    {selectedOrder.items?.map((item, idx) => (
                      <div
                        key={idx}
                        style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', marginBottom: '4px' }}
                      >
                        <span>
                          {item.quantity}x {item.name}
                          {item.isAlcohol && <span style={{ color: '#FF6B1A', fontWeight: 700, marginLeft: '4px' }}>(18+)</span>}
                        </span>
                        <span style={{ fontWeight: 500 }}>Rs. {item.price * item.quantity}</span>
                      </div>
                    ))}
                  </div>

                  {/* Pricing Total */}
                  <div style={{ borderBottom: '1px solid #D1D5DB', paddingBottom: '12px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span>Subtotal</span>
                      <span>Rs. {selectedOrder.subtotal}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span>Delivery Fee</span>
                      <span>Rs. {selectedOrder.deliveryFee}</span>
                    </div>
                    {selectedOrder.discount > 0 && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: '#FF6B1A', marginBottom: '4px' }}>
                        <span>Discount ({selectedOrder.offerCode || 'COUPON'})</span>
                        <span>- Rs. {selectedOrder.discount}</span>
                      </div>
                    )}
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '15px', fontWeight: 700, color: '#003893', marginTop: '6px' }}>
                      <span>Total</span>
                      <span>Rs. {selectedOrder.total}</span>
                    </div>
                  </div>

                  {/* Actions */}
                  <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                    <button
                      onClick={() => handleDeleteOrder(selectedOrder._id, selectedOrder.orderNo)}
                      className="btn btn-secondary btn-sm"
                      style={{ color: '#FF6B1A' }}
                    >
                      Delete Order
                    </button>
                    {selectedOrder.status !== 'delivered' && selectedOrder.status !== 'cancelled' && (
                      <button
                        onClick={() => handleCancelOrder(selectedOrder._id)}
                        className="btn btn-secondary btn-sm"
                      >
                        Cancel Order
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
};

export default OrdersBoard;
