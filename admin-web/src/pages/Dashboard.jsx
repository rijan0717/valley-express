import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import { Link } from 'react-router-dom';
import ValleyLoader from '../components/ValleyLoader';

const Dashboard = ({ onReplaySplash }) => {
  const { showAlert, showToast } = useModal();
  const [orders, setOrders] = useState([]);
  const [riders, setRiders] = useState([]);
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);
  const { latestOrder } = useSocket();

  const fetchData = async () => {
    try {
      const [ordersRes, ridersRes, settingsRes] = await Promise.allSettled([
        api.get('/orders'),
        api.get('/admin/settings/riders'),
        api.get('/admin/settings'),
      ]);

      if (ordersRes.status === 'fulfilled' && ordersRes.value.data.success) {
        setOrders(ordersRes.value.data.orders);
      }
      if (ridersRes.status === 'fulfilled' && ridersRes.value.data.success) {
        setRiders(ridersRes.value.data.riders);
      }
      if (settingsRes.status === 'fulfilled' && settingsRes.value.data.success) {
        setSettings(settingsRes.value.data.settings);
      }
    } catch (e) {
      console.error('Dashboard fetch error:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (latestOrder) {
      setOrders((prev) => [latestOrder, ...prev.filter((o) => o._id !== latestOrder._id)]);
    }
  }, [latestOrder]);

  const activeOrders = orders.filter((o) => !['delivered', 'cancelled', 'rejected'].includes(o.status));
  const preparingOrders = orders.filter((o) => ['accepted', 'preparing'].includes(o.status));
  const onTheWayOrders = orders.filter((o) => ['rider_assigned', 'picked_up', 'on_the_way'].includes(o.status));
  const onlineRiders = riders.filter((r) => r.isOnline);

  const totalRevenue = orders
    .filter((o) => o.status === 'delivered' || o.paymentStatus === 'paid')
    .reduce((sum, o) => sum + (o.total || 0), 0);

  const toggleAlcohol = async () => {
    try {
      const nextState = !settings?.alcoholEnabled;
      const res = await api.put('/admin/settings', { alcoholEnabled: nextState });
      if (res.data.success) {
        setSettings(res.data.settings);
        showToast(
          nextState
            ? 'Alcohol sales category enabled across apps & stores'
            : 'Alcohol sales category globally restricted (18+ only)',
          'info'
        );
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Settings Update Error', 'danger');
    }
  };

  return (
    <>
      <Navbar title="Operations Overview" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Fetching live operations data from MongoDB..." />
        ) : (
          <>
            {/* KPI Stat Cards (Strict 5-color palette, no gradients) */}
            <div className="stat-grid">
              <div className="stat-card">
                <div className="stat-label">Active Orders</div>
                <div className="stat-value">{activeOrders.length}</div>
                <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '6px' }}>
                  Awaiting dispatch &amp; delivery
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-label">Kitchen &amp; Packing</div>
                <div className="stat-value">{preparingOrders.length}</div>
                <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '6px' }}>
                  Being assembled at hub
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-label">Riders On Road</div>
                <div className="stat-value">{onTheWayOrders.length}</div>
                <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '6px' }}>
                  {onlineRiders.length} riders online on duty
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-label">Delivered Revenue</div>
                <div className="stat-value">Rs. {totalRevenue.toLocaleString()}</div>
                <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '6px' }}>
                  Cash collected &amp; cleared
                </div>
              </div>
            </div>

            {/* Regulatory Alcohol License Switch */}
            <div
              style={{
                background: '#FFFFFF',
                border: '1px solid #D1D5DB',
                borderRadius: '4px',
                padding: '20px',
                marginBottom: '24px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: '16px',
              }}
            >
              <div>
                <div style={{ fontWeight: 700, fontSize: '14px', color: '#003893', marginBottom: '4px' }}>
                  Liquor &amp; Alcoholic Beverage Regulatory License Switch
                </div>
                <p style={{ fontSize: '12px', color: '#1F2A44', maxWidth: '640px' }}>
                  Controls customer visibility and checkout permissions for alcoholic beverages across Kathmandu Valley. Keep disabled until municipal liquor licence verification is active.
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                <span
                  className={`badge ${settings?.alcoholEnabled ? 'badge-accent' : 'badge-neutral'}`}
                  style={{ fontSize: '12px', padding: '6px 12px' }}
                >
                  {settings?.alcoholEnabled ? 'Permit Active' : 'Sales Restricted'}
                </span>
                <label className="switch">
                  <input
                    type="checkbox"
                    checked={settings?.alcoholEnabled || false}
                    onChange={toggleAlcohol}
                  />
                  <span className="slider"></span>
                </label>
              </div>
            </div>

            {/* Live Orders Stream */}
            <div className="table-card">
              <div className="table-header">
                <div>
                  <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#003893' }}>
                    Live Orders Stream
                  </h3>
                  <p style={{ fontSize: '12px', color: '#1F2A44' }}>
                    Real-time customer orders flowing from mobile app
                  </p>
                </div>
                <Link to="/orders" className="btn btn-primary btn-sm">
                  View Kanban Board
                </Link>
              </div>

              <div className="table-responsive">
                <table>
                  <thead>
                    <tr>
                      <th>Order ID</th>
                      <th>Customer</th>
                      <th>Delivery Drop-Off</th>
                      <th>Items Count</th>
                      <th>Total Amount</th>
                      <th>Status</th>
                      <th>Payment</th>
                      <th>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {orders.length === 0 ? (
                      <tr>
                        <td colSpan="8" style={{ textAlign: 'center', padding: '36px', color: '#1F2A44' }}>
                          No orders in database. Place a live test order from Mobile Preview.
                        </td>
                      </tr>
                    ) : (
                      orders.slice(0, 8).map((order) => {
                        const addr = order.deliveryAddress?.addressText || order.address?.addressText || 'Kathmandu';
                        const landmark = order.deliveryAddress?.landmark || order.address?.landmark;
                        return (
                          <tr key={order._id}>
                            <td style={{ fontWeight: 700, color: '#003893' }}>{order.orderNo}</td>
                            <td>
                              <div style={{ fontWeight: 500 }}>{order.customer?.name || 'Customer'}</div>
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>{order.customer?.phone}</div>
                            </td>
                            <td style={{ maxWidth: '220px' }}>
                              <div style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                {addr}
                              </div>
                              {landmark && (
                                <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                                  Landmark: {landmark}
                                </div>
                              )}
                            </td>
                            <td>
                              <span style={{ fontSize: '12px', fontWeight: 500 }}>
                                {order.items?.length || 0} items
                                {order.containsAlcohol && (
                                  <span style={{ marginLeft: '6px', color: '#FF6B1A', fontWeight: 700 }}>
                                    (18+)
                                  </span>
                                )}
                              </span>
                            </td>
                            <td style={{ fontWeight: 700, color: '#FF6B1A' }}>
                              Rs. {order.total?.toLocaleString()}
                            </td>
                            <td>
                              <span
                                className={`badge ${
                                  order.status === 'delivered'
                                    ? 'badge-brand'
                                    : order.status === 'placed'
                                    ? 'badge-accent'
                                    : 'badge-neutral'
                                }`}
                              >
                                {order.status.replace(/_/g, ' ')}
                              </span>
                            </td>
                            <td>
                              <span style={{ fontSize: '11px', textTransform: 'uppercase', fontWeight: 500 }}>
                                {order.paymentMethod?.replace(/_/g, ' ')}
                              </span>
                            </td>
                            <td>
                              <Link to="/orders" className="btn btn-secondary btn-sm">
                                Manage
                              </Link>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </>
        )}
      </div>
    </>
  );
};

export default Dashboard;
