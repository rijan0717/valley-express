import React, { useCallback, useEffect, useMemo, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import ValleyLoader from '../components/ValleyLoader';

/**
 * Contact Us — the inbox for everything the public website collects.
 *
 * Two kinds of record share one collection: messages from the contact form,
 * and sign-ups for the app-launch notify list. They are filtered apart here
 * rather than paged separately, since the volume is small.
 */

const MailIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="4" width="20" height="16" rx="2" />
    <path d="m22 7-10 6L2 7" />
  </svg>
);

const PhoneIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.79 19.79 0 0 1 2.12 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.69 2.81a2 2 0 0 1-.45 2.11L8.1 9.9a16 16 0 0 0 6 6l1.26-1.26a2 2 0 0 1 2.11-.45c.9.33 1.85.56 2.81.69A2 2 0 0 1 22 16.92z" />
  </svg>
);

const CheckIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="20 6 9 17 4 12" />
  </svg>
);

const TrashIcon = ({ size = 14, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2m2 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" />
  </svg>
);

const formatWhen = (iso) => {
  const d = new Date(iso);
  return d.toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const Enquiries = ({ onReplaySplash }) => {
  const [leads, setLeads] = useState([]);
  const [counts, setCounts] = useState({ unhandledContact: 0, notifyTotal: 0 });
  const [tab, setTab] = useState('contact');
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busyId, setBusyId] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/leads', { params: { limit: 300 } });
      if (res.data.success) {
        setLeads(res.data.leads || []);
        setCounts({
          unhandledContact: res.data.unhandledContact || 0,
          notifyTotal: res.data.notifyTotal || 0,
        });
      }
    } catch (err) {
      setError(
        err?.response?.data?.message || 'Could not load enquiries. Check the API is running.'
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const setHandled = async (id, handled) => {
    setBusyId(id);
    try {
      await api.patch(`/leads/${id}`, { handled });
      setLeads((all) => all.map((l) => (l._id === id ? { ...l, handled } : l)));
      setCounts((c) => ({
        ...c,
        unhandledContact: Math.max(0, c.unhandledContact + (handled ? -1 : 1)),
      }));
    } catch (err) {
      setError(err?.response?.data?.message || 'Could not update that enquiry.');
    } finally {
      setBusyId(null);
    }
  };

  const remove = async (id) => {
    setBusyId(id);
    try {
      await api.delete(`/leads/${id}`);
      setLeads((all) => all.filter((l) => l._id !== id));
    } catch (err) {
      setError(err?.response?.data?.message || 'Could not delete that enquiry.');
    } finally {
      setBusyId(null);
    }
  };

  const visible = useMemo(() => {
    const wanted = tab === 'contact' ? 'contact' : 'app-notify';
    const q = query.trim().toLowerCase();
    return leads
      .filter((l) => l.source === wanted)
      .filter((l) =>
        !q
          ? true
          : [l.name, l.email, l.phone, l.subject, l.message]
              .filter(Boolean)
              .join(' ')
              .toLowerCase()
              .includes(q)
      );
  }, [leads, tab, query]);

  const tabButton = (key, label, badge) => (
    <button
      type="button"
      onClick={() => setTab(key)}
      className={`btn btn-sm ${tab === key ? 'btn-primary' : 'btn-secondary'}`}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}
    >
      <span>{label}</span>
      {badge > 0 && (
        <span
          style={{
            background: tab === key ? 'rgba(255,255,255,0.22)' : 'rgba(255,107,26,0.14)',
            color: tab === key ? '#fff' : '#C2410C',
            borderRadius: 999,
            padding: '1px 7px',
            fontSize: 11,
            fontWeight: 700,
          }}
        >
          {badge}
        </span>
      )}
    </button>
  );

  return (
    <>
      <Navbar title="Contact Us" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Loading enquiries from the website..." />
        ) : (
          <>
            <div className="stat-grid">
              <div className="stat-card">
                <div className="stat-label">Messages waiting</div>
                <div className="stat-value">{counts.unhandledContact}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>not yet marked replied</div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Messages total</div>
                <div className="stat-value">
                  {leads.filter((l) => l.source === 'contact').length}
                </div>
                <div style={{ fontSize: 12, color: '#64748B' }}>from the contact form</div>
              </div>
              <div className="stat-card">
                <div className="stat-label">App notify list</div>
                <div className="stat-value">{counts.notifyTotal}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>waiting for launch</div>
              </div>
            </div>

            {error && (
              <div
                style={{
                  marginTop: 16,
                  padding: '10px 14px',
                  borderRadius: 10,
                  border: '1px solid rgba(220,38,38,0.25)',
                  background: 'rgba(220,38,38,0.06)',
                  color: '#B91C1C',
                  fontSize: 13,
                }}
              >
                {error}
              </div>
            )}

            <div className="table-card" style={{ marginTop: 18 }}>
              <div className="table-header" style={{ flexWrap: 'wrap', gap: 10 }}>
                <div style={{ display: 'flex', gap: 8 }}>
                  {tabButton('contact', 'Messages', counts.unhandledContact)}
                  {tabButton('notify', 'App notify list', 0)}
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <input
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    placeholder="Search name, email, phone or text"
                    style={{
                      padding: '8px 12px',
                      borderRadius: 10,
                      border: '1px solid #E2E8F0',
                      fontSize: 13,
                      minWidth: 240,
                    }}
                  />
                  <button type="button" className="btn btn-secondary btn-sm" onClick={load}>
                    Refresh
                  </button>
                </div>
              </div>

              {visible.length === 0 ? (
                <div style={{ padding: '32px 18px', textAlign: 'center', color: '#64748B', fontSize: 13 }}>
                  {tab === 'contact'
                    ? 'No contact messages yet. They arrive here the moment somebody uses the form on the website.'
                    : 'Nobody has joined the app notify list yet.'}
                </div>
              ) : (
                <div className="table-responsive">
                  <table>
                    <thead>
                      <tr>
                        <th>When</th>
                        {tab === 'contact' ? <th>From</th> : <th>Contact</th>}
                        {tab === 'contact' && <th>Subject</th>}
                        {tab === 'contact' ? <th>Message</th> : <th>Platform</th>}
                        <th style={{ textAlign: 'right' }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {visible.map((lead) => (
                        <tr key={lead._id} style={{ opacity: lead.handled ? 0.6 : 1 }}>
                          <td style={{ whiteSpace: 'nowrap', fontSize: 12, color: '#64748B' }}>
                            {formatWhen(lead.createdAt)}
                          </td>
                          <td>
                            {tab === 'contact' && (
                              <div style={{ fontWeight: 600, marginBottom: 2 }}>{lead.name}</div>
                            )}
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                              {lead.email && (
                                <a
                                  href={`mailto:${lead.email}`}
                                  style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12.5 }}
                                >
                                  <MailIcon size={13} />
                                  {lead.email}
                                </a>
                              )}
                              {lead.phone && (
                                <a
                                  href={`tel:${lead.phone.replace(/\s/g, '')}`}
                                  style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12.5 }}
                                >
                                  <PhoneIcon size={13} />
                                  {lead.phone}
                                </a>
                              )}
                            </div>
                          </td>
                          {tab === 'contact' && (
                            <td style={{ fontSize: 13 }}>
                              <span className="badge">{lead.subject || 'No subject'}</span>
                            </td>
                          )}
                          <td style={{ fontSize: 13, maxWidth: 420 }}>
                            {tab === 'contact' ? (
                              <span style={{ whiteSpace: 'pre-wrap' }}>{lead.message}</span>
                            ) : (
                              <span className="badge badge-brand">
                                {lead.platform === 'ios'
                                  ? 'iPhone'
                                  : lead.platform === 'android'
                                  ? 'Android'
                                  : 'Either'}
                              </span>
                            )}
                          </td>
                          <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                            {tab === 'contact' && (
                              <button
                                type="button"
                                className="btn btn-secondary btn-sm"
                                disabled={busyId === lead._id}
                                onClick={() => setHandled(lead._id, !lead.handled)}
                                style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}
                              >
                                <CheckIcon size={13} />
                                {lead.handled ? 'Reopen' : 'Mark replied'}
                              </button>
                            )}
                            <button
                              type="button"
                              className="btn btn-secondary btn-sm"
                              disabled={busyId === lead._id}
                              onClick={() => remove(lead._id)}
                              style={{ marginLeft: 8, display: 'inline-flex', alignItems: 'center', gap: 6 }}
                              title="Delete this enquiry"
                            >
                              <TrashIcon size={13} />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </>
  );
};

export default Enquiries;
