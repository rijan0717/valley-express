import React, { useState, useEffect, useMemo } from 'react';
import Navbar from '../components/Navbar';
import ValleyLoader from '../components/ValleyLoader';
import { useModal } from '../context/ModalContext';
import api from '../api/client';

const Users = ({ onReplaySplash }) => {
  const { showAlert, showConfirm, showToast } = useModal();
  const [users, setUsers] = useState([]);
  const [summary, setSummary] = useState({
    total: 0,
    customers: 0,
    riders: 0,
    admins: 0,
    ageVerified: 0,
  });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRole, setSelectedRole] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [activeCardFilter, setActiveCardFilter] = useState('all'); // 'all' | 'customer' | 'rider' | 'admin' | 'verified'

  // Selected user for details drawer/modal
  const [selectedUser, setSelectedUser] = useState(null);
  const [userDetailsLoading, setUserDetailsLoading] = useState(false);
  const [userOrders, setUserOrders] = useState([]);

  // Role edit modal
  const [roleEditUser, setRoleEditUser] = useState(null);
  const [newRole, setNewRole] = useState('customer');

  const fetchUsers = async () => {
    setLoading(true);
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
          // Continue
        }
      }

      const res = await api.get('/users');
      if (res.data.success) {
        setUsers(res.data.users);
        if (res.data.summary) {
          setSummary(res.data.summary);
        }
      }
    } catch (err) {
      console.error('[Users Error]', err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleOpenDetails = async (user) => {
    setSelectedUser(user);
    setUserDetailsLoading(true);
    try {
      const res = await api.get(`/users/${user._id}`);
      if (res.data.success) {
        setUserOrders(res.data.recentOrders || []);
      }
    } catch (err) {
      console.error('[User Details Error]', err.message);
    } finally {
      setUserDetailsLoading(false);
    }
  };

  const handleToggleStatus = async (userId, currentStatus) => {
    const nextStatus = currentStatus === 'active' ? 'suspended' : 'active';
    try {
      const res = await api.patch(`/users/${userId}/status`, { status: nextStatus });
      if (res.data.success) {
        setUsers((prev) =>
          prev.map((u) => (u._id === userId ? { ...u, status: nextStatus } : u))
        );
        if (selectedUser?._id === userId) {
          setSelectedUser((prev) => ({ ...prev, status: nextStatus }));
        }
        showToast(`User status set to ${nextStatus}`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Status Update Failed', 'danger');
    }
  };

  const handleSaveRole = async (e) => {
    e.preventDefault();
    if (!roleEditUser) return;
    try {
      const res = await api.patch(`/users/${roleEditUser._id}/role`, { role: newRole });
      if (res.data.success) {
        setUsers((prev) =>
          prev.map((u) => (u._id === roleEditUser._id ? { ...u, role: newRole } : u))
        );
        setRoleEditUser(null);
        showToast(`User role updated to ${newRole}`, 'success');
        fetchUsers();
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Role Change Failed', 'danger');
    }
  };

  const handleDeleteUser = async (user) => {
    const confirmed = await showConfirm(
      `Confirm removal of registered account "${user.name || user.phone}" from Valley Express? This action cannot be reversed.`,
      'Delete User Account',
      true,
      'Delete User',
      'Keep User'
    );
    if (!confirmed) return;

    try {
      const res = await api.delete(`/users/${user._id}`);
      if (res.data.success) {
        setUsers((prev) => prev.filter((u) => u._id !== user._id));
        if (selectedUser?._id === user._id) setSelectedUser(null);
        showToast(`User "${user.name || user.phone}" removed`, 'info');
        fetchUsers();
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete User Failed', 'danger');
    }
  };

  // Filtered list
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const matchesSearch =
        !searchTerm.trim() ||
        (u.name && u.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (u.phone && u.phone.includes(searchTerm.trim())) ||
        (u.email && u.email.toLowerCase().includes(searchTerm.toLowerCase()));

      let matchesCard = true;
      if (activeCardFilter === 'customer') matchesCard = u.role === 'customer';
      else if (activeCardFilter === 'rider') matchesCard = u.role === 'rider';
      else if (activeCardFilter === 'admin') matchesCard = u.role === 'admin';
      else if (activeCardFilter === 'verified') matchesCard = u.ageConfirmed === true;

      const matchesRole = selectedRole === 'all' || u.role === selectedRole;
      const matchesStatus = selectedStatus === 'all' || u.status === selectedStatus;

      return matchesSearch && matchesCard && matchesRole && matchesStatus;
    });
  }, [users, searchTerm, activeCardFilter, selectedRole, selectedStatus]);

  return (
    <>
      <Navbar title="Registered Users & Customer Directory" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {/* KPI Interactive Column Filter Cards */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
            gap: '12px',
            marginBottom: '20px',
          }}
        >
          {/* Column 1: Total */}
          <div
            onClick={() => {
              setActiveCardFilter('all');
              setSelectedRole('all');
            }}
            style={{
              background: '#FFFFFF',
              border: activeCardFilter === 'all' ? '2px solid #003893' : '1px solid #D1D5DB',
              borderRadius: '4px',
              padding: '14px 16px',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              transition: 'border-color 0.15s ease',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '4px' }}>
              Total Accounts
            </div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: '#003893', lineHeight: 1.1 }}>
              {summary.total}
            </div>
            <div style={{ fontSize: '10px', color: activeCardFilter === 'all' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '8px' }}>
              {activeCardFilter === 'all' ? '● Showing All' : 'Click to show all'}
            </div>
          </div>

          {/* Column 2: Customers */}
          <div
            onClick={() => {
              setActiveCardFilter('customer');
              setSelectedRole('customer');
            }}
            style={{
              background: '#FFFFFF',
              border: activeCardFilter === 'customer' ? '2px solid #1F2A44' : '1px solid #D1D5DB',
              borderRadius: '4px',
              padding: '14px 16px',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              transition: 'border-color 0.15s ease',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '4px' }}>
              Customers
            </div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: '#1F2A44', lineHeight: 1.1 }}>
              {summary.customers}
            </div>
            <div style={{ fontSize: '10px', color: activeCardFilter === 'customer' ? '#1F2A44' : '#1F2A44', fontWeight: 600, marginTop: '8px' }}>
              {activeCardFilter === 'customer' ? '● Showing Customers' : 'Click to filter'}
            </div>
          </div>

          {/* Column 3: Riders */}
          <div
            onClick={() => {
              setActiveCardFilter('rider');
              setSelectedRole('rider');
            }}
            style={{
              background: '#FFFFFF',
              border: activeCardFilter === 'rider' ? '2px solid #003893' : '1px solid #D1D5DB',
              borderRadius: '4px',
              padding: '14px 16px',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              transition: 'border-color 0.15s ease',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '4px' }}>
              Delivery Riders
            </div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: '#003893', lineHeight: 1.1 }}>
              {summary.riders}
            </div>
            <div style={{ fontSize: '10px', color: activeCardFilter === 'rider' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '8px' }}>
              {activeCardFilter === 'rider' ? '● Showing Riders' : 'Click to filter'}
            </div>
          </div>

          {/* Column 4: Admins */}
          <div
            onClick={() => {
              setActiveCardFilter('admin');
              setSelectedRole('admin');
            }}
            style={{
              background: '#FFFFFF',
              border: activeCardFilter === 'admin' ? '2px solid #FF6B1A' : '1px solid #D1D5DB',
              borderRadius: '4px',
              padding: '14px 16px',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              transition: 'border-color 0.15s ease',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '4px' }}>
              Operations Admins
            </div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: '#FF6B1A', lineHeight: 1.1 }}>
              {summary.admins}
            </div>
            <div style={{ fontSize: '10px', color: activeCardFilter === 'admin' ? '#FF6B1A' : '#1F2A44', fontWeight: 600, marginTop: '8px' }}>
              {activeCardFilter === 'admin' ? '● Showing Admins' : 'Click to filter'}
            </div>
          </div>

          {/* Column 5: 18+ Age Verified */}
          <div
            onClick={() => {
              setActiveCardFilter('verified');
              setSelectedRole('all');
            }}
            style={{
              background: '#FFFFFF',
              border: activeCardFilter === 'verified' ? '2px solid #003893' : '1px solid #D1D5DB',
              borderRadius: '4px',
              padding: '14px 16px',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              transition: 'border-color 0.15s ease',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: '4px' }}>
              18+ Age Verified
            </div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: '#003893', lineHeight: 1.1 }}>
              {summary.ageVerified}
            </div>
            <div style={{ fontSize: '10px', color: activeCardFilter === 'verified' ? '#003893' : '#1F2A44', fontWeight: 600, marginTop: '8px' }}>
              {activeCardFilter === 'verified' ? '● Showing 18+ Verified' : 'Click to filter'}
            </div>
          </div>
        </div>

        {/* Filter and Search Bar */}
        <div
          style={{
            background: '#FFFFFF',
            border: '1px solid #D1D5DB',
            borderRadius: '4px',
            padding: '16px',
            marginBottom: '20px',
            display: 'flex',
            flexWrap: 'wrap',
            gap: '12px',
            alignItems: 'center',
          }}
        >
          <div style={{ flex: '1 1 280px' }}>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by name, phone (+977), or email..."
              style={{ width: '100%', height: '40px' }}
            />
          </div>

          <div style={{ minWidth: '150px' }}>
            <select
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value)}
              style={{ width: '100%', height: '40px' }}
            >
              <option value="all">All Roles</option>
              <option value="customer">Customers</option>
              <option value="rider">Riders</option>
              <option value="admin">Administrators</option>
            </select>
          </div>

          <div style={{ minWidth: '150px' }}>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              style={{ width: '100%', height: '40px' }}
            >
              <option value="all">All Statuses</option>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>

          <button
            type="button"
            onClick={fetchUsers}
            className="btn btn-secondary"
            style={{ height: '40px', padding: '0 18px' }}
          >
            Refresh
          </button>
        </div>

        {/* Users Table */}
        <div style={{ background: '#FFFFFF', border: '1px solid #D1D5DB', borderRadius: '4px', overflowX: 'auto' }}>
          {loading ? (
            <div style={{ padding: '60px 0' }}>
              <ValleyLoader variant="scooter" text="Loading registered accounts from MongoDB..." />
            </div>
          ) : filteredUsers.length === 0 ? (
            <div style={{ padding: '48px', textAlign: 'center', color: '#1F2A44', fontSize: '13px' }}>
              No registered users found matching the selected filters.
            </div>
          ) : (
            <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr>
                  <th>User Identity</th>
                  <th>Contact Details</th>
                  <th>System Role</th>
                  <th>18+ Verified</th>
                  <th>Orders &amp; Spent</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((u) => {
                  const roleBadgeColor =
                    u.role === 'admin' ? '#FF6B1A' : u.role === 'rider' ? '#003893' : '#1F2A44';

                  return (
                    <tr key={u._id}>
                      {/* Identity */}
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div
                            style={{
                              width: '34px',
                              height: '34px',
                              borderRadius: '4px',
                              background: '#FFFFFF',
                              border: `1px solid ${roleBadgeColor}`,
                              color: roleBadgeColor,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 700,
                              fontSize: '13px',
                            }}
                          >
                            {(u.name ? u.name.charAt(0) : u.phone.slice(-2)).toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893' }}>
                              {u.name || '[UNNAMED USER]'}
                            </div>
                            <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                              Joined: {new Date(u.createdAt).toLocaleDateString()}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Contact */}
                      <td>
                        <div style={{ fontWeight: 600, fontSize: '12px', color: '#1F2A44' }}>
                          {u.phone}
                        </div>
                        <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                          {u.email || '[PHONE ONLY ACCOUNT]'}
                        </div>
                      </td>

                      {/* Role */}
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
                            border: `1px solid ${roleBadgeColor}`,
                            color: roleBadgeColor,
                            background: '#FFFFFF',
                          }}
                        >
                          {u.role}
                        </span>
                      </td>

                      {/* Age Verification */}
                      <td>
                        {u.ageConfirmed ? (
                          <span
                            style={{
                              display: 'inline-block',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              fontSize: '11px',
                              fontWeight: 700,
                              background: '#FFFFFF',
                              color: '#003893',
                              border: '1px solid #003893',
                            }}
                          >
                            18+ Verified
                          </span>
                        ) : (
                          <span
                            style={{
                              display: 'inline-block',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              fontSize: '11px',
                              fontWeight: 500,
                              background: '#FFFFFF',
                              color: '#1F2A44',
                              border: '1px solid #D1D5DB',
                            }}
                          >
                            Unverified
                          </span>
                        )}
                      </td>

                      {/* Orders & Spent */}
                      <td>
                        <div style={{ fontWeight: 700, fontSize: '12px', color: '#1F2A44' }}>
                          {u.orderCount || 0} orders
                        </div>
                        <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 600 }}>
                          Rs. {(u.totalSpent || 0).toLocaleString()}
                        </div>
                      </td>

                      {/* Status */}
                      <td>
                        <span
                          className={`badge ${u.status === 'active' ? 'badge-brand' : 'badge-neutral'}`}
                          style={{
                            background: '#FFFFFF',
                            borderColor: u.status === 'active' ? '#003893' : '#FF6B1A',
                            color: u.status === 'active' ? '#003893' : '#FF6B1A',
                          }}
                        >
                          {u.status || 'active'}
                        </span>
                      </td>

                      {/* Actions */}
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: '6px' }}>
                          <button
                            type="button"
                            onClick={() => handleOpenDetails(u)}
                            className="btn btn-secondary btn-sm"
                            style={{ fontSize: '11px', padding: '4px 10px' }}
                          >
                            Details
                          </button>

                          {u.email !== 'admin@gmail.com' && (
                            <>
                              <button
                                type="button"
                                onClick={() => {
                                  setRoleEditUser(u);
                                  setNewRole(u.role);
                                }}
                                className="btn btn-secondary btn-sm"
                                style={{ fontSize: '11px', padding: '4px 10px' }}
                              >
                                Role
                              </button>

                              <button
                                type="button"
                                onClick={() => handleToggleStatus(u._id, u.status || 'active')}
                                className="btn btn-secondary btn-sm"
                                style={{
                                  fontSize: '11px',
                                  padding: '4px 10px',
                                  color: u.status === 'suspended' ? '#003893' : '#FF6B1A',
                                  borderColor: u.status === 'suspended' ? '#003893' : '#FF6B1A',
                                }}
                              >
                                {u.status === 'suspended' ? 'Activate' : 'Suspend'}
                              </button>

                              <button
                                type="button"
                                onClick={() => handleDeleteUser(u)}
                                className="btn btn-secondary btn-sm"
                                style={{ fontSize: '11px', padding: '4px 8px', color: '#FF6B1A', borderColor: '#D1D5DB' }}
                              >
                                Delete
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* User Details Modal */}
        {selectedUser && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '640px' }}>
              <div className="modal-header">
                <div>
                  <h3 className="modal-title">
                    {selectedUser.name || 'User Profile'} Details
                  </h3>
                  <span style={{ fontSize: '11px', color: '#1F2A44' }}>
                    User ID: {selectedUser._id}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedUser(null)}
                  className="btn btn-secondary btn-sm"
                >
                  Close
                </button>
              </div>

              {/* Profile Details Grid */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '12px',
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '14px',
                  marginBottom: '16px',
                }}
              >
                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    Phone Number (Login ID)
                  </div>
                  <div style={{ fontSize: '13px', fontWeight: 700, color: '#003893' }}>
                    {selectedUser.phone}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    Email Address
                  </div>
                  <div style={{ fontSize: '13px', color: '#1F2A44' }}>
                    {selectedUser.email || '[NONE CONFIGURED]'}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    Assigned Role
                  </div>
                  <div style={{ fontSize: '13px', fontWeight: 700, textTransform: 'capitalize' }}>
                    {selectedUser.role}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    Account Status
                  </div>
                  <div style={{ fontSize: '13px', fontWeight: 700, textTransform: 'capitalize', color: selectedUser.status === 'suspended' ? '#FF6B1A' : '#003893' }}>
                    {selectedUser.status || 'active'}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    18+ Age Compliance
                  </div>
                  <div style={{ fontSize: '12px', fontWeight: 600 }}>
                    {selectedUser.ageConfirmed ? 'Verified (Permitted for Alcohol)' : 'Not Verified'}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44', fontWeight: 700 }}>
                    Registration Date
                  </div>
                  <div style={{ fontSize: '12px', color: '#1F2A44' }}>
                    {new Date(selectedUser.createdAt).toLocaleString()}
                  </div>
                </div>
              </div>

              {/* Saved Delivery Addresses */}
              <div style={{ marginBottom: '16px' }}>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893', marginBottom: '8px' }}>
                  Saved Delivery Addresses ({selectedUser.addresses?.length || 0})
                </div>

                {!selectedUser.addresses || selectedUser.addresses.length === 0 ? (
                  <div style={{ fontSize: '12px', color: '#1F2A44', padding: '10px', border: '1px solid #D1D5DB', borderRadius: '4px' }}>
                    No delivery addresses saved in address book yet.
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {selectedUser.addresses.map((addr, idx) => (
                      <div
                        key={idx}
                        style={{
                          border: '1px solid #D1D5DB',
                          borderRadius: '4px',
                          padding: '10px',
                          fontSize: '12px',
                        }}
                      >
                        <div style={{ fontWeight: 700, color: '#003893', marginBottom: '2px' }}>
                          {addr.label || 'Saved Location'} {addr.isDefault && '(Default)'}
                        </div>
                        <div>{addr.addressText}</div>
                        {addr.landmark && (
                          <div style={{ color: '#FF6B1A', fontSize: '11px', marginTop: '2px' }}>
                            Landmark: {addr.landmark}
                          </div>
                        )}
                        {addr.location?.coordinates && (
                          <div style={{ color: '#1F2A44', fontSize: '10px', marginTop: '2px' }}>
                            Coordinates: [{addr.location.coordinates[0]}, {addr.location.coordinates[1]}]
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Order History */}
              <div>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893', marginBottom: '8px' }}>
                  Recent Orders Placed
                </div>

                {userDetailsLoading ? (
                  <div style={{ padding: '20px', textAlign: 'center', fontSize: '12px' }}>
                    Loading recent order history...
                  </div>
                ) : userOrders.length === 0 ? (
                  <div style={{ fontSize: '12px', color: '#1F2A44', padding: '10px', border: '1px solid #D1D5DB', borderRadius: '4px' }}>
                    No completed or active orders on record for this account.
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto' }}>
                    {userOrders.map((ord) => (
                      <div
                        key={ord._id}
                        style={{
                          border: '1px solid #D1D5DB',
                          borderRadius: '4px',
                          padding: '8px 12px',
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                          fontSize: '12px',
                        }}
                      >
                        <div>
                          <span style={{ fontWeight: 700, color: '#003893' }}>{ord.orderNo}</span>
                          <span style={{ marginLeft: '10px', color: '#1F2A44', fontSize: '11px' }}>
                            {new Date(ord.createdAt).toLocaleDateString()}
                          </span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <span style={{ fontWeight: 700, color: '#FF6B1A' }}>Rs. {ord.total}</span>
                          <span
                            className="badge badge-brand"
                            style={{ fontSize: '10px', padding: '2px 6px', textTransform: 'capitalize' }}
                          >
                            {ord.status.replace('_', ' ')}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div style={{ marginTop: '20px', textAlign: 'right' }}>
                <button
                  type="button"
                  onClick={() => setSelectedUser(null)}
                  className="btn btn-primary"
                  style={{ minWidth: '100px' }}
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Change Role Modal */}
        {roleEditUser && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '420px' }}>
              <div className="modal-header">
                <h3 className="modal-title">Change System Role</h3>
                <button
                  type="button"
                  onClick={() => setRoleEditUser(null)}
                  className="btn btn-secondary btn-sm"
                >
                  Cancel
                </button>
              </div>

              <form onSubmit={handleSaveRole}>
                <div style={{ marginBottom: '14px', fontSize: '12px', color: '#1F2A44' }}>
                  Update access permissions for <strong>{roleEditUser.name || roleEditUser.phone}</strong>:
                </div>

                <div className="form-group">
                  <label className="form-label">Select System Role</label>
                  <select
                    value={newRole}
                    onChange={(e) => setNewRole(e.target.value)}
                    style={{ width: '100%', height: '40px' }}
                  >
                    <option value="customer">Customer (Mobile order placement)</option>
                    <option value="rider">Rider (Delivery jobs &amp; GPS dispatch)</option>
                    <option value="admin">Administrator (Full operations dashboard)</option>
                  </select>
                </div>

                <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                  <button
                    type="button"
                    onClick={() => setRoleEditUser(null)}
                    className="btn btn-secondary"
                    style={{ flex: 1 }}
                  >
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>
                    Save Role
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default Users;
