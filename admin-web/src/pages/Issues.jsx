import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

// Clean Lucide SVG Icon components (strictly no emojis)
const ClockIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);

const SearchIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="11" cy="11" r="8" />
    <line x1="21" y1="21" x2="16.65" y2="16.65" />
  </svg>
);

const CheckCircleIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
    <polyline points="22 4 12 14.01 9 11.01" />
  </svg>
);

const XCircleIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10" />
    <line x1="15" y1="9" x2="9" y2="15" />
    <line x1="9" y1="9" x2="15" y2="15" />
  </svg>
);

const LayersIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="12 2 2 7 12 12 22 7 12 2" />
    <polyline points="2 17 12 22 22 17" />
    <polyline points="2 12 12 17 22 12" />
  </svg>
);

const UserIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
    <circle cx="12" cy="7" r="4" />
  </svg>
);

const BikeIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="5.5" cy="17.5" r="3.5" />
    <circle cx="18.5" cy="17.5" r="3.5" />
    <path d="M15 6a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-3 11.5V14l-3-3 4-3 2 3h4" />
  </svg>
);

const EditIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
  </svg>
);

const TrashIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="3 6 5 6 21 6" />
    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
  </svg>
);

const EyeIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
    <circle cx="12" cy="12" r="3" />
  </svg>
);

const FileTextIcon = ({ size = 28, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <polyline points="14 2 14 8 20 8" />
    <line x1="16" y1="13" x2="8" y2="13" />
    <line x1="16" y1="17" x2="8" y2="17" />
    <polyline points="10 9 9 9 8 9" />
  </svg>
);

const CloseIcon = ({ size = 16, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="18" y1="6" x2="6" y2="18" />
    <line x1="6" y1="6" x2="18" y2="18" />
  </svg>
);

const Issues = ({ onReplaySplash }) => {
  const { showConfirm, showToast } = useModal();
  const [issues, setIssues] = useState([]);
  const [stats, setStats] = useState({
    all: 0,
    pending: 0,
    investigating: 0,
    resolved: 0,
    rejected: 0,
  });
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('all');
  const [roleFilter, setRoleFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Selected issue for updating status & admin note
  const [selectedIssue, setSelectedIssue] = useState(null);
  const [newStatus, setNewStatus] = useState('pending');
  const [adminNote, setAdminNote] = useState('');
  const [savingStatus, setSavingStatus] = useState(false);

  // Full screenshot preview modal
  const [previewImage, setPreviewImage] = useState(null);

  const fetchIssues = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (statusFilter !== 'all') params.append('status', statusFilter);
      if (roleFilter !== 'all') params.append('role', roleFilter);
      if (searchQuery.trim()) params.append('search', searchQuery.trim());

      const res = await api.get(`/issues?${params.toString()}`);
      if (res.data.success) {
        setIssues(res.data.issues || []);
        if (res.data.stats) {
          setStats(res.data.stats);
        }
      }
    } catch (err) {
      console.error('Error fetching issues:', err);
      showToast('Failed to load issues', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIssues();
  }, [statusFilter, roleFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchIssues();
  };

  const openStatusModal = (issue) => {
    setSelectedIssue(issue);
    setNewStatus(issue.status);
    setAdminNote(issue.adminNote || '');
  };

  const closeStatusModal = () => {
    setSelectedIssue(null);
    setAdminNote('');
  };

  const handleUpdateStatus = async (e) => {
    e.preventDefault();
    if (!selectedIssue) return;

    try {
      setSavingStatus(true);
      const res = await api.patch(`/issues/${selectedIssue._id}/status`, {
        status: newStatus,
        adminNote: adminNote.trim(),
      });

      if (res.data.success) {
        showToast(`Issue #${selectedIssue.ticketNo} status updated to ${newStatus}`, 'success');
        closeStatusModal();
        fetchIssues();
      }
    } catch (err) {
      console.error('Error updating issue status:', err);
      showToast(err.response?.data?.message || 'Failed to update issue status', 'error');
    } finally {
      setSavingStatus(false);
    }
  };

  const handleDeleteIssue = (issue) => {
    showConfirm(
      `Delete Issue #${issue.ticketNo}?`,
      'Are you sure you want to permanently delete this issue? Once removed by admin, it will disappear from both user and admin portals.',
      async () => {
        try {
          const res = await api.delete(`/issues/${issue._id}`);
          if (res.data.success) {
            showToast(`Issue #${issue.ticketNo} deleted permanently`, 'success');
            fetchIssues();
          }
        } catch (err) {
          console.error('Error deleting issue:', err);
          showToast('Failed to delete issue', 'error');
        }
      }
    );
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'pending':
        return (
          <span style={{
            background: 'rgba(245, 158, 11, 0.12)',
            color: '#B45309',
            border: '1px solid rgba(245, 158, 11, 0.3)',
            padding: '3px 10px',
            borderRadius: '999px',
            fontSize: '11px',
            fontWeight: 700,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px'
          }}>
            <ClockIcon size={12} color="#B45309" />
            <span>Pending Review</span>
          </span>
        );
      case 'investigating':
        return (
          <span style={{
            background: 'rgba(59, 130, 246, 0.12)',
            color: '#1D4ED8',
            border: '1px solid rgba(59, 130, 246, 0.3)',
            padding: '3px 10px',
            borderRadius: '999px',
            fontSize: '11px',
            fontWeight: 700,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px'
          }}>
            <SearchIcon size={12} color="#1D4ED8" />
            <span>Investigating</span>
          </span>
        );
      case 'resolved':
        return (
          <span style={{
            background: 'rgba(16, 185, 129, 0.12)',
            color: '#047857',
            border: '1px solid rgba(16, 185, 129, 0.3)',
            padding: '3px 10px',
            borderRadius: '999px',
            fontSize: '11px',
            fontWeight: 700,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px'
          }}>
            <CheckCircleIcon size={12} color="#047857" />
            <span>Resolved</span>
          </span>
        );
      case 'rejected':
        return (
          <span style={{
            background: 'rgba(107, 114, 128, 0.12)',
            color: '#374151',
            border: '1px solid rgba(107, 114, 128, 0.3)',
            padding: '3px 10px',
            borderRadius: '999px',
            fontSize: '11px',
            fontWeight: 700,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px'
          }}>
            <XCircleIcon size={12} color="#374151" />
            <span>Closed</span>
          </span>
        );
      default:
        return <span>{status}</span>;
    }
  };

  const getCategoryBadge = (category) => {
    const formatted = (category || 'other').replace('_', ' ').toUpperCase();
    return (
      <span style={{
        background: '#F1F5F9',
        color: '#475569',
        padding: '2px 8px',
        borderRadius: '6px',
        fontSize: '10.5px',
        fontWeight: 600
      }}>
        {formatted}
      </span>
    );
  };

  return (
    <div className="issues-page">
      <Navbar title="Reported Issues & Escalations" onReplaySplash={onReplaySplash} />

      <div className="container" style={{ padding: '24px', maxWidth: '1400px', margin: '0 auto' }}>
        {/* Top Header & Metrics */}
        <div style={{ marginBottom: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '16px' }}>
          <div>
            <h2 style={{ fontSize: '22px', fontWeight: 800, color: '#0F172A', margin: 0, letterSpacing: '-0.3px' }}>
              Help Desk & Incident Management
            </h2>
            <p style={{ color: '#64748B', fontSize: '13px', margin: '4px 0 0 0' }}>
              Review issues raised by customers and fleet riders, update resolution status with notes, and manage escalation records.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            <div style={{ background: '#FFF', border: '1px solid #E2E8F0', borderRadius: '12px', padding: '10px 18px', textAlign: 'center', minWidth: '95px' }}>
              <div style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, letterSpacing: '0.5px' }}>TOTAL ISSUES</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#0F172A' }}>{stats.all || 0}</div>
            </div>
            <div style={{ background: '#FFF', border: '1px solid #FDE68A', borderRadius: '12px', padding: '10px 18px', textAlign: 'center', minWidth: '95px' }}>
              <div style={{ fontSize: '11px', color: '#B45309', fontWeight: 700, letterSpacing: '0.5px' }}>PENDING</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#D97706' }}>{stats.pending || 0}</div>
            </div>
            <div style={{ background: '#FFF', border: '1px solid #BFDBFE', borderRadius: '12px', padding: '10px 18px', textAlign: 'center', minWidth: '95px' }}>
              <div style={{ fontSize: '11px', color: '#1D4ED8', fontWeight: 700, letterSpacing: '0.5px' }}>INVESTIGATING</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#2563EB' }}>{stats.investigating || 0}</div>
            </div>
            <div style={{ background: '#FFF', border: '1px solid #A7F3D0', borderRadius: '12px', padding: '10px 18px', textAlign: 'center', minWidth: '95px' }}>
              <div style={{ fontSize: '11px', color: '#047857', fontWeight: 700, letterSpacing: '0.5px' }}>RESOLVED</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#059669' }}>{stats.resolved || 0}</div>
            </div>
          </div>
        </div>

        {/* Filter Controls Bar */}
        <div style={{
          background: '#FFF',
          border: '1px solid #E2E8F0',
          borderRadius: '16px',
          padding: '16px 20px',
          marginBottom: '24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '14px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.03)'
        }}>
          {/* Status Tabs */}
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            {[
              { id: 'all', label: 'All', count: stats.all || 0, icon: (active) => <LayersIcon size={13} color={active ? '#FFF' : '#64748B'} /> },
              { id: 'pending', label: 'Pending', count: stats.pending || 0, icon: (active) => <ClockIcon size={13} color={active ? '#FFF' : '#D97706'} /> },
              { id: 'investigating', label: 'Investigating', count: stats.investigating || 0, icon: (active) => <SearchIcon size={13} color={active ? '#FFF' : '#2563EB'} /> },
              { id: 'resolved', label: 'Resolved', count: stats.resolved || 0, icon: (active) => <CheckCircleIcon size={13} color={active ? '#FFF' : '#059669'} /> },
              { id: 'rejected', label: 'Closed', count: stats.rejected || 0, icon: (active) => <XCircleIcon size={13} color={active ? '#FFF' : '#64748B'} /> },
            ].map((tab) => {
              const active = statusFilter === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setStatusFilter(tab.id)}
                  style={{
                    padding: '8px 14px',
                    borderRadius: '10px',
                    fontSize: '12.5px',
                    fontWeight: active ? 700 : 600,
                    border: active ? '1px solid #003893' : '1px solid #E2E8F0',
                    background: active ? '#003893' : '#F8FAFC',
                    color: active ? '#FFF' : '#475569',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {tab.icon(active)}
                  <span>{tab.label} ({tab.count})</span>
                </button>
              );
            })}
          </div>

          {/* Role Filter & Search Bar */}
          <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              style={{
                padding: '8px 12px',
                borderRadius: '10px',
                border: '1px solid #CBD5E1',
                fontSize: '12.5px',
                fontWeight: 600,
                color: '#334155',
                background: '#FFF',
                outline: 'none',
                cursor: 'pointer'
              }}
            >
              <option value="all">All Reporters</option>
              <option value="customer">Customers Only</option>
              <option value="rider">Riders Only</option>
            </select>

            <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: '6px' }}>
              <input
                type="text"
                placeholder="Search ticket, name, phone..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '10px',
                  border: '1px solid #CBD5E1',
                  fontSize: '12.5px',
                  width: '210px',
                  outline: 'none',
                }}
              />
              <button
                type="submit"
                style={{
                  padding: '8px 14px',
                  background: '#FF6B1A',
                  color: '#FFF',
                  border: 'none',
                  borderRadius: '10px',
                  fontSize: '12.5px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  transition: 'background 0.15s ease'
                }}
              >
                <SearchIcon size={13} color="#FFF" />
                <span>Search</span>
              </button>
            </form>
          </div>
        </div>

        {/* Content Section */}
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '320px' }}>
            <ValleyLoader size={72} label="Loading issues..." />
          </div>
        ) : issues.length === 0 ? (
          <div style={{
            background: '#FFF',
            border: '1px dashed #CBD5E1',
            borderRadius: '16px',
            padding: '60px 20px',
            textAlign: 'center'
          }}>
            <div style={{
              width: '56px',
              height: '56px',
              borderRadius: '16px',
              background: '#F1F5F9',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 14px auto',
              color: '#64748B'
            }}>
              <FileTextIcon size={28} color="#64748B" />
            </div>
            <h3 style={{ fontSize: '17px', fontWeight: 700, color: '#1E293B', margin: '0 0 6px 0' }}>
              No issues found
            </h3>
            <p style={{ color: '#64748B', fontSize: '13px', margin: 0 }}>
              There are no reported issues matching the selected filters.
            </p>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(420px, 1fr))', gap: '18px' }}>
            {issues.map((issue) => (
              <div
                key={issue._id}
                style={{
                  background: '#FFF',
                  border: '1px solid #E2E8F0',
                  borderRadius: '18px',
                  padding: '20px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  boxShadow: '0 2px 6px rgba(0,0,0,0.03)',
                  transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                }}
              >
                <div>
                  {/* Card Header: Ticket No, Badges */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{
                        background: '#0F172A',
                        color: '#FFF',
                        padding: '3px 8px',
                        borderRadius: '6px',
                        fontSize: '11px',
                        fontWeight: 800,
                        letterSpacing: '0.5px'
                      }}>
                        #{issue.ticketNo}
                      </span>
                      {getCategoryBadge(issue.category)}
                    </div>
                    {getStatusBadge(issue.status)}
                  </div>

                  {/* Issue Title & Description */}
                  <h4 style={{ fontSize: '15px', fontWeight: 800, color: '#0F172A', margin: '6px 0 8px 0', lineHeight: 1.3 }}>
                    {issue.title}
                  </h4>
                  <p style={{
                    fontSize: '13px',
                    color: '#475569',
                    margin: '0 0 14px 0',
                    lineHeight: 1.5,
                    whiteSpace: 'pre-line',
                    background: '#F8FAFC',
                    padding: '10px 12px',
                    borderRadius: '10px',
                    border: '1px solid #F1F5F9'
                  }}>
                    {issue.description}
                  </p>

                  {/* Screenshot Thumbnail if Present */}
                  {issue.screenshot && (
                    <div style={{ marginBottom: '14px' }}>
                      <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748B', marginBottom: '6px' }}>
                        ATTACHED SCREENSHOT:
                      </div>
                      <div
                        onClick={() => setPreviewImage(issue.screenshot)}
                        style={{
                          display: 'inline-block',
                          border: '2px solid #E2E8F0',
                          borderRadius: '10px',
                          overflow: 'hidden',
                          cursor: 'pointer',
                          maxHeight: '120px',
                          position: 'relative'
                        }}
                      >
                        <img
                          src={issue.screenshot}
                          alt="Issue Attachment"
                          style={{ height: '100px', width: 'auto', objectFit: 'cover', display: 'block' }}
                        />
                        <div style={{
                          position: 'absolute',
                          inset: 0,
                          background: 'rgba(15, 23, 42, 0.45)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#FFF',
                          fontSize: '11px',
                          fontWeight: 700,
                          gap: '5px'
                        }}>
                          <EyeIcon size={13} color="#FFF" />
                          <span>Click to View</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Admin Resolution Note if already exists */}
                  {issue.adminNote && (
                    <div style={{
                      background: 'rgba(16, 185, 129, 0.08)',
                      border: '1px solid rgba(16, 185, 129, 0.25)',
                      borderRadius: '10px',
                      padding: '10px 12px',
                      marginBottom: '14px'
                    }}>
                      <div style={{ fontSize: '11px', fontWeight: 800, color: '#047857', marginBottom: '2px' }}>
                        ADMIN RESOLUTION NOTE (VISIBLE TO USER):
                      </div>
                      <div style={{ fontSize: '12.5px', color: '#065F46', lineHeight: 1.4 }}>
                        {issue.adminNote}
                      </div>
                    </div>
                  )}

                  {/* Reporter Details */}
                  <div style={{
                    borderTop: '1px solid #F1F5F9',
                    paddingTop: '12px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    fontSize: '12px',
                    color: '#64748B'
                  }}>
                    <div>
                      <div style={{ fontWeight: 700, color: '#1E293B', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        {issue.reporterRole === 'rider' ? (
                          <BikeIcon size={14} color="#FF6B1A" />
                        ) : (
                          <UserIcon size={14} color="#003893" />
                        )}
                        <span>{issue.reporterRole === 'rider' ? 'Fleet Rider' : 'Customer'}:</span>
                        <span style={{ color: '#0F172A' }}>{issue.reporterName}</span>
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                        {issue.reporterPhone || issue.reporterEmail || 'No contact provided'}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right', fontSize: '11px' }}>
                      {new Date(issue.createdAt).toLocaleDateString()} at{' '}
                      {new Date(issue.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </div>
                </div>

                {/* Card Action Buttons */}
                <div style={{
                  borderTop: '1px solid #E2E8F0',
                  marginTop: '16px',
                  paddingTop: '14px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  gap: '8px'
                }}>
                  <button
                    onClick={() => openStatusModal(issue)}
                    style={{
                      flex: 1,
                      padding: '8px 12px',
                      background: '#003893',
                      color: '#FFF',
                      border: 'none',
                      borderRadius: '10px',
                      fontSize: '12.5px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '6px',
                      transition: 'background 0.15s ease'
                    }}
                  >
                    <EditIcon size={13} color="#FFF" />
                    <span>Update Status & Note</span>
                  </button>

                  <button
                    onClick={() => handleDeleteIssue(issue)}
                    title="Remove issue from system"
                    style={{
                      padding: '8px 12px',
                      background: 'rgba(239, 68, 68, 0.08)',
                      color: '#DC2626',
                      border: '1px solid rgba(239, 68, 68, 0.25)',
                      borderRadius: '10px',
                      fontSize: '12.5px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '5px',
                      transition: 'background 0.15s ease'
                    }}
                  >
                    <TrashIcon size={13} color="#DC2626" />
                    <span>Delete</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Update Status & Note Modal */}
      {selectedIssue && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(15, 23, 42, 0.65)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '16px'
        }}>
          <div style={{
            background: '#FFF',
            borderRadius: '20px',
            maxWidth: '540px',
            width: '100%',
            padding: '28px',
            boxShadow: '0 20px 40px rgba(0,0,0,0.2)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  Update Issue #{selectedIssue.ticketNo}
                </h3>
                <span style={{ fontSize: '12px', color: '#64748B' }}>
                  Reporter: {selectedIssue.reporterName} ({selectedIssue.reporterRole === 'rider' ? 'Fleet Rider' : 'Customer'})
                </span>
              </div>
              <button
                onClick={closeStatusModal}
                style={{
                  background: '#F1F5F9',
                  border: 'none',
                  borderRadius: '8px',
                  width: '32px',
                  height: '32px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  color: '#64748B'
                }}
              >
                <CloseIcon size={16} color="#64748B" />
              </button>
            </div>

            <form onSubmit={handleUpdateStatus}>
              {/* Status Picker */}
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                  RESOLUTION STATUS
                </label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: '10px',
                    border: '1px solid #CBD5E1',
                    fontSize: '13px',
                    fontWeight: 600,
                    outline: 'none',
                    color: '#0F172A'
                  }}
                >
                  <option value="pending">Pending Review</option>
                  <option value="investigating">Under Investigation</option>
                  <option value="resolved">Resolved (Completed)</option>
                  <option value="rejected">Closed / Rejected</option>
                </select>
              </div>

              {/* Admin Note Textarea */}
              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                  ACTION / RESOLUTION NOTE (DISPATCHED TO USER):
                </label>
                <textarea
                  rows={4}
                  value={adminNote}
                  onChange={(e) => setAdminNote(e.target.value)}
                  placeholder="Explain what steps were taken (e.g. 'Store manager investigated, replacement bottle dispatched immediately.', 'Rider contacted and cash adjustment made.')..."
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: '10px',
                    border: '1px solid #CBD5E1',
                    fontSize: '13px',
                    outline: 'none',
                    fontFamily: 'inherit',
                    resize: 'vertical'
                  }}
                />
                <span style={{ fontSize: '11px', color: '#64748B', display: 'block', marginTop: '4px' }}>
                  * This note is automatically pushed to the customer/rider mobile view so they see what has been done.
                </span>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button
                  type="button"
                  onClick={closeStatusModal}
                  style={{
                    padding: '10px 18px',
                    borderRadius: '10px',
                    border: '1px solid #CBD5E1',
                    background: '#FFF',
                    color: '#475569',
                    fontSize: '13px',
                    fontWeight: 600,
                    cursor: 'pointer'
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={savingStatus}
                  style={{
                    padding: '10px 22px',
                    borderRadius: '10px',
                    border: 'none',
                    background: '#FF6B1A',
                    color: '#FFF',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  {savingStatus ? 'Saving...' : 'Save & Notify Reporter'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Screenshot Lightbox Modal */}
      {previewImage && (
        <div
          onClick={() => setPreviewImage(null)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.88)',
            backdropFilter: 'blur(5px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 10000,
            padding: '24px',
            cursor: 'zoom-out'
          }}
        >
          <div style={{ position: 'relative', maxWidth: '90vw', maxHeight: '90vh' }}>
            <img
              src={previewImage}
              alt="Issue Full Attachment"
              style={{ maxWidth: '100%', maxHeight: '85vh', borderRadius: '12px', display: 'block', boxShadow: '0 10px 30px rgba(0,0,0,0.5)' }}
            />
            <div style={{ textAlign: 'center', color: '#FFF', fontSize: '12px', marginTop: '10px', fontWeight: 600 }}>
              Click anywhere to close preview
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Issues;
