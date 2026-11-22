import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

const Riders = ({ onReplaySplash }) => {
  const { showAlert, showConfirm, showToast } = useModal();
  const [riders, setRiders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [simulating, setSimulating] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingRider, setEditingRider] = useState(null);
  const [showPassword, setShowPassword] = useState(false);
  const { latestRiderLocation, socket } = useSocket();

  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    vehicleNumber: 'BA 92 PA 1234',
    vehicleType: 'Motorcycle',
    isOnline: true,
  });

  const fetchRiders = async () => {
    try {
      const res = await api.get('/admin/settings/riders');
      if (res.data.success) {
        setRiders(res.data.riders);
      }
    } catch (e) {
      console.error('Error fetching riders:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRiders();
  }, []);

  const openAddModal = () => {
    setEditingRider(null);
    setShowPassword(false);
    setFormData({
      name: '',
      phone: '',
      email: '',
      password: '',
      vehicleNumber: 'BA 92 PA 1234',
      vehicleType: 'Motorcycle',
      isOnline: true,
    });
    setShowAddModal(true);
  };

  const openEditModal = (rider) => {
    setEditingRider(rider);
    setShowPassword(false);
    setFormData({
      name: rider.name,
      phone: rider.phone,
      email: rider.email || '',
      password: '',
      vehicleNumber: rider.vehicleNumber || 'BA 92 PA 1234',
      vehicleType: rider.vehicleType || 'Motorcycle',
      isOnline: rider.isOnline,
    });
    setShowAddModal(true);
  };

  const handleSaveRider = async (e) => {
    e.preventDefault();
    try {
      if (editingRider) {
        const res = await api.put(`/admin/settings/riders/${editingRider._id}`, formData);
        if (res.data.success) {
          setRiders(riders.map((r) => (r._id === editingRider._id ? res.data.rider : r)));
          setShowAddModal(false);
          showToast('Rider profile updated successfully', 'success');
        }
      } else {
        const res = await api.post('/admin/settings/riders', formData);
        if (res.data.success) {
          setRiders([...riders, res.data.rider]);
          setShowAddModal(false);
          showToast('New rider added to Valley Express fleet', 'success');
        }
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Rider Save Error', 'danger');
    }
  };

  const handleDeleteRider = async (id, name) => {
    const confirmed = await showConfirm(
      `Confirm removal of rider "${name}" from Valley Express fleet? Their active delivery assignments will be unlinked.`,
      'Remove Fleet Rider',
      true,
      'Remove Rider',
      'Keep Rider'
    );
    if (!confirmed) return;

    try {
      const res = await api.delete(`/admin/settings/riders/${id}`);
      if (res.data.success) {
        setRiders(riders.filter((r) => r._id !== id));
        showToast(`Rider "${name}" removed from fleet`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete Rider Failed', 'danger');
    }
  };

  const handleToggleDuty = async (id) => {
    try {
      const res = await api.patch(`/admin/settings/riders/${id}/toggle`);
      if (res.data.success) {
        setRiders(riders.map((r) => (r._id === id ? { ...r, isOnline: res.data.isOnline } : r)));
        showToast(`Rider duty updated to ${res.data.isOnline ? 'Online (Active)' : 'Offline'}`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Toggle Status Failed', 'danger');
    }
  };

  const simulateGPS = () => {
    if (!socket || riders.length === 0) return;
    setSimulating(true);

    const targetRider = riders[0];
    const waypoints = [
      [85.3240, 27.7172], // Durbar Marg
      [85.3265, 27.7205], // Naxal
      [85.3285, 27.7245], // Police HQ
      [85.3300, 27.7280], // Baluwatar Destination
    ];

    let step = 0;
    const interval = setInterval(() => {
      if (step >= waypoints.length) {
        clearInterval(interval);
        setSimulating(false);
        return;
      }
      const coords = waypoints[step];
      socket.emit('rider:location', {
        riderId: targetRider._id,
        riderName: targetRider.name,
        coordinates: coords,
        heading: 45,
        speed: 35,
      });
      step++;
    }, 1200);
  };

  useEffect(() => {
    if (latestRiderLocation) {
      setRiders((prev) =>
        prev.map((r) =>
          r._id === latestRiderLocation.riderId
            ? { ...r, currentCoordinates: latestRiderLocation.coordinates }
            : r
        )
      );
    }
  }, [latestRiderLocation]);

  return (
    <>
      <Navbar title="Riders Fleet & Live Dispatch Radar" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Fetching riders fleet from MongoDB..." />
        ) : (
          <>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '20px',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              <div>
                <h2 style={{ fontSize: '18px', fontWeight: 700, color: '#003893' }}>
                  Delivery Fleet Operations
                </h2>
                <p style={{ fontSize: '12px', color: '#1F2A44' }}>
                  Real-time rider tracking and fleet directory across Kathmandu Valley
                </p>
              </div>

              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  onClick={simulateGPS}
                  disabled={simulating || riders.length === 0}
                  className="btn btn-secondary btn-sm"
                >
                  {simulating ? 'Broadcasting Route...' : 'Simulate GPS Stream'}
                </button>
                <button onClick={openAddModal} className="btn btn-primary btn-sm">
                  + Add New Rider
                </button>
              </div>
            </div>

            {/* Kathmandu Dispatch Radar Map (Strict 5-colors, dynamic DB coordinates) */}
            <div
              style={{
                background: '#FFFFFF',
                border: '1px solid #D1D5DB',
                borderRadius: '4px',
                padding: '20px',
                marginBottom: '24px',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '16px',
                }}
              >
                <div>
                  <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#003893' }}>
                    Kathmandu Valley Live Dispatch Radar
                  </h3>
                  <span style={{ fontSize: '11px', color: '#1F2A44' }}>
                    Coordinates: 27.7172 N, 85.3240 E (Central Kathmandu Reference)
                  </span>
                </div>
                <span className="badge badge-brand">
                  {riders.filter((r) => r.isOnline).length} Active Online
                </span>
              </div>

              <div
                style={{
                  height: '240px',
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  position: 'relative',
                  overflow: 'hidden',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {/* Grid reference markings */}
                <svg
                  style={{
                    position: 'absolute',
                    inset: 0,
                    width: '100%',
                    height: '100%',
                    pointerEvents: 'none',
                  }}
                >
                  <defs>
                    <pattern id="radarGrid" width="40" height="40" patternUnits="userSpaceOnUse">
                      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#D1D5DB" strokeWidth="1" />
                    </pattern>
                  </defs>
                  <rect width="100%" height="100%" fill="url(#radarGrid)" />
                </svg>

                <div
                  style={{
                    position: 'absolute',
                    top: '12px',
                    left: '12px',
                    fontSize: '11px',
                    fontFamily: 'monospace',
                    color: '#1F2A44',
                  }}
                >
                  HUB: DURBAR MARG / BALUWATAR
                </div>

                {/* Dynamically render pins for ALL riders from DB */}
                {riders.map((r, index) => {
                  const coords = r.currentCoordinates || [85.324, 27.717];
                  // Map coordinates roughly across the 240px container
                  const posX = Math.min(85, Math.max(15, ((coords[0] - 85.31) / 0.03) * 100));
                  const posY = Math.min(85, Math.max(15, 100 - ((coords[1] - 27.70) / 0.03) * 100));

                  return (
                    <div
                      key={r._id || index}
                      style={{
                        position: 'absolute',
                        left: `${posX}%`,
                        top: `${posY}%`,
                        transform: 'translate(-50%, -50%)',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        zIndex: 10,
                      }}
                    >
                      <div
                        style={{
                          background: '#FFFFFF',
                          border: `1px solid ${r.isOnline ? '#003893' : '#D1D5DB'}`,
                          color: r.isOnline ? '#003893' : '#1F2A44',
                          padding: '2px 6px',
                          borderRadius: '2px',
                          fontSize: '10px',
                          fontWeight: 700,
                          whiteSpace: 'nowrap',
                          marginBottom: '3px',
                        }}
                      >
                        {r.name} ({r.vehicleType || 'Bike'})
                      </div>
                      <div
                        style={{
                          width: '10px',
                          height: '10px',
                          background: r.isOnline ? '#FF6B1A' : '#D1D5DB',
                          border: '1px solid #1F2A44',
                          borderRadius: '50%',
                        }}
                      />
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Riders Directory Table */}
            <div className="table-card">
              <div className="table-responsive">
                <table>
                  <thead>
                    <tr>
                      <th>Rider Name</th>
                      <th>Phone Number</th>
                      <th>Vehicle Info</th>
                      <th>Current Coordinates</th>
                      <th>Duty Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {riders.length === 0 ? (
                      <tr>
                        <td colSpan="6" style={{ textAlign: 'center', padding: '36px', color: '#1F2A44' }}>
                          No delivery riders currently registered. Click "+ Add New Rider" to enroll.
                        </td>
                      </tr>
                    ) : (
                      riders.map((rider) => (
                        <tr key={rider._id}>
                          <td>
                            <div style={{ fontWeight: 500, color: '#003893' }}>{rider.name}</div>
                            {rider.email && (
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>{rider.email}</div>
                            )}
                          </td>
                          <td style={{ fontFamily: 'monospace' }}>
                            <div style={{ fontWeight: 600 }}>{rider.phone}</div>
                            <div style={{ fontSize: '10px', color: '#003893', fontWeight: 700, textTransform: 'uppercase' }}>
                              Direct App Login ID
                            </div>
                          </td>
                          <td>
                            <div style={{ fontWeight: 500 }}>{rider.vehicleNumber || 'BA 92 PA 1234'}</div>
                            <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                              {rider.vehicleType || 'Motorcycle'}
                            </div>
                          </td>
                          <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>
                            {rider.currentCoordinates && rider.currentCoordinates.length === 2
                              ? `[${rider.currentCoordinates[0].toFixed(4)}, ${rider.currentCoordinates[1].toFixed(4)}]`
                              : '[85.3240, 27.7172]'}
                          </td>
                          <td>
                            <button
                              onClick={() => handleToggleDuty(rider._id)}
                              className={`badge ${rider.isOnline ? 'badge-brand' : 'badge-neutral'}`}
                              style={{ cursor: 'pointer', background: '#FFFFFF' }}
                              title="Click to toggle duty status"
                            >
                              {rider.isOnline ? 'Online (Ready)' : 'Offline'}
                            </button>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: '6px' }}>
                              <button
                                onClick={() => openEditModal(rider)}
                                className="btn btn-secondary btn-sm"
                              >
                                Edit
                              </button>
                              <button
                                onClick={() => handleDeleteRider(rider._id, rider.name)}
                                className="btn btn-secondary btn-sm"
                                style={{ color: '#FF6B1A' }}
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Rider Add / Edit Modal */}
            {showAddModal && (
              <div className="modal-overlay">
                <div className="modal-content">
                  <div className="modal-header">
                    <h3 className="modal-title">
                      {editingRider ? `Edit Rider: ${editingRider.name}` : 'Enroll New Delivery Rider'}
                    </h3>
                    <button
                      onClick={() => setShowAddModal(false)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  <form onSubmit={handleSaveRider}>
                    <div className="form-group">
                      <label className="form-label">Full Name *</label>
                      <input
                        type="text"
                        required
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        placeholder="e.g. Ramesh Thapa"
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Mobile Phone Number (Login ID) *</label>
                      <input
                        type="tel"
                        required
                        value={formData.phone}
                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                        placeholder="9811111111"
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">
                        Rider Mobile Login Password {editingRider ? '(Leave blank to retain current)' : '*'}
                      </label>
                      <div style={{ position: 'relative' }}>
                        <input
                          type={showPassword ? 'text' : 'password'}
                          required={!editingRider}
                          minLength={editingRider && !formData.password ? undefined : 6}
                          value={formData.password}
                          onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                          placeholder={editingRider ? '•••••••• (leave blank to keep current)' : 'Min. 6 chars secure password'}
                          style={{ paddingRight: '54px' }}
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          style={{
                            position: 'absolute',
                            right: '10px',
                            top: '50%',
                            transform: 'translateY(-50%)',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            color: '#6B7280',
                            fontSize: '11px',
                            fontWeight: 700,
                          }}
                        >
                          {showPassword ? 'HIDE' : 'SHOW'}
                        </button>
                      </div>
                      <span style={{ fontSize: '11px', color: '#003893', marginTop: '4px', display: 'block' }}>
                        Stored securely with bcrypt encryption. Passwords are never displayed on this panel.
                      </span>
                    </div>

                    <div className="form-group">
                      <label className="form-label">Email Address (Optional)</label>
                      <input
                        type="email"
                        value={formData.email}
                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                        placeholder="rider@valleyexpress.com.np"
                      />
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Vehicle Registration Number</label>
                        <input
                          type="text"
                          value={formData.vehicleNumber}
                          onChange={(e) => setFormData({ ...formData, vehicleNumber: e.target.value })}
                          placeholder="BA 92 PA 1234"
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Vehicle Type</label>
                        <select
                          value={formData.vehicleType}
                          onChange={(e) => setFormData({ ...formData, vehicleType: e.target.value })}
                        >
                          <option value="Motorcycle">Motorcycle</option>
                          <option value="Scooter">Scooter</option>
                          <option value="Electric Scooter">Electric Scooter</option>
                          <option value="Bicycle">Bicycle</option>
                        </select>
                      </div>
                    </div>

                    <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                      <button
                        type="button"
                        onClick={() => setShowAddModal(false)}
                        className="btn btn-secondary"
                        style={{ flex: 1 }}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>
                        {editingRider ? 'Save Changes' : 'Create Rider in DB'}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
};

export default Riders;
