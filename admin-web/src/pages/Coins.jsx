import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import ValleyLoader from '../components/ValleyLoader';

// Valley Coins across the customer base: what each holder has, what they have
// earned and what they have spent, and the ledger behind any one balance.
const Coins = ({ onReplaySplash }) => {
  const [holders, setHolders] = useState([]);
  const [coinValue, setCoinValue] = useState(0.1);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [detail, setDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [query, setQuery] = useState('');

  const fetchHolders = async () => {
    try {
      const res = await api.get('/coins/admin/holders');
      if (res.data.success) {
        setHolders(res.data.users);
        setCoinValue(res.data.coinValue ?? 0.1);
      }
    } catch (e) {
      console.error('Error fetching coin holders:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHolders();
  }, []);

  const openLedger = async (user) => {
    setSelected(user);
    setDetail(null);
    setDetailLoading(true);
    try {
      const res = await api.get(`/coins/admin/${user._id}`);
      if (res.data.success) setDetail(res.data);
    } catch (e) {
      console.error('Error fetching coin ledger:', e);
    } finally {
      setDetailLoading(false);
    }
  };

  const rupees = (coins) => `Rs. ${(coins * coinValue).toFixed(2)}`;

  const visible = holders.filter((u) => {
    const q = query.trim().toLowerCase();
    if (!q) return true;
    return (
      (u.name || '').toLowerCase().includes(q) ||
      (u.phone || '').toLowerCase().includes(q) ||
      (u.email || '').toLowerCase().includes(q)
    );
  });

  // Outstanding coins are a real liability: every one of them comes off a
  // future bill, so the total is worth showing in money as well as in coins.
  const totals = holders.reduce(
    (acc, u) => ({
      balance: acc.balance + (u.balance || 0),
      earned: acc.earned + (u.totalEarned || 0),
      spent: acc.spent + (u.totalSpent || 0),
    }),
    { balance: 0, earned: 0, spent: 0 }
  );

  const entryColour = (type) => {
    if (type === 'earned') return '#10B981';
    if (type === 'spent') return '#003893';
    if (type === 'reversed') return '#EF4444';
    return '#FF4B26';
  };

  return (
    <>
      <Navbar title="Valley Coins Ledger" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Fetching coin balances from MongoDB..." />
        ) : (
          <>
            <div className="stat-grid">
              <div className="stat-card">
                <div className="stat-label">Coins Outstanding</div>
                <div className="stat-value">{totals.balance}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>
                  {rupees(totals.balance)} of future discounts
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Lifetime Earned</div>
                <div className="stat-value">{totals.earned}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>
                  {rupees(totals.earned)} issued
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Lifetime Spent</div>
                <div className="stat-value">{totals.spent}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>
                  {rupees(totals.spent)} redeemed
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Coin Holders</div>
                <div className="stat-value">{holders.length}</div>
                <div style={{ fontSize: 12, color: '#64748B' }}>
                  customers with an account
                </div>
              </div>
            </div>

            <div className="table-card" style={{ marginTop: 18 }}>
              <div className="table-header">
                <h3 style={{ margin: 0, fontSize: 15 }}>Balances by customer</h3>
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search name, phone or email"
                  style={{
                    padding: '8px 12px',
                    borderRadius: 10,
                    border: '1px solid #E2E8F0',
                    fontSize: 13,
                    minWidth: 220,
                  }}
                />
              </div>
              <div className="table-responsive">
                <table>
                  <thead>
                    <tr>
                      <th>Customer</th>
                      <th>Contact</th>
                      <th>Balance</th>
                      <th>Worth</th>
                      <th>Earned</th>
                      <th>Spent</th>
                      <th>Ledger</th>
                    </tr>
                  </thead>
                  <tbody>
                    {visible.length === 0 ? (
                      <tr>
                        <td colSpan={7} style={{ textAlign: 'center', padding: 28, color: '#64748B' }}>
                          No customers match that search.
                        </td>
                      </tr>
                    ) : (
                      visible.map((u) => (
                        <tr key={u._id}>
                          <td style={{ fontWeight: 700 }}>{u.name || 'Unnamed'}</td>
                          <td style={{ color: '#64748B', fontSize: 13 }}>
                            {u.phone || u.email || '—'}
                          </td>
                          <td>
                            <span className="badge badge-brand">{u.balance}</span>
                          </td>
                          <td>{rupees(u.balance)}</td>
                          <td style={{ color: '#10B981' }}>{u.totalEarned}</td>
                          <td style={{ color: '#003893' }}>{u.totalSpent}</td>
                          <td>
                            <button
                              className="btn btn-secondary btn-sm"
                              onClick={() => openLedger(u)}
                            >
                              View
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {selected && (
              <div className="modal-overlay" onClick={() => setSelected(null)}>
                <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                  <div className="modal-header">
                    <h3 className="modal-title">
                      {selected.name} — coin history
                    </h3>
                    <button
                      className="btn btn-secondary btn-sm"
                      onClick={() => setSelected(null)}
                    >
                      Close
                    </button>
                  </div>

                  {detailLoading ? (
                    <ValleyLoader text="Loading ledger..." />
                  ) : !detail ? (
                    <p style={{ color: '#64748B' }}>Could not load this ledger.</p>
                  ) : (
                    <>
                      <div className="stat-grid" style={{ marginBottom: 16 }}>
                        <div className="stat-card">
                          <div className="stat-label">Balance</div>
                          <div className="stat-value">{detail.balance}</div>
                          <div style={{ fontSize: 12, color: '#64748B' }}>
                            Rs. {Number(detail.balanceValue).toFixed(2)}
                          </div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-label">Earned</div>
                          <div className="stat-value">{detail.totalEarned}</div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-label">Spent</div>
                          <div className="stat-value">{detail.totalSpent}</div>
                        </div>
                      </div>

                      <div className="table-responsive" style={{ maxHeight: 340, overflowY: 'auto' }}>
                        <table>
                          <thead>
                            <tr>
                              <th>When</th>
                              <th>Type</th>
                              <th>Order</th>
                              <th>Coins</th>
                              <th>Balance after</th>
                            </tr>
                          </thead>
                          <tbody>
                            {detail.transactions.length === 0 ? (
                              <tr>
                                <td colSpan={5} style={{ textAlign: 'center', padding: 24, color: '#64748B' }}>
                                  Nothing yet. Coins arrive once an order is delivered.
                                </td>
                              </tr>
                            ) : (
                              detail.transactions.map((t) => (
                                <tr key={t._id}>
                                  <td style={{ fontSize: 13, color: '#64748B' }}>
                                    {new Date(t.createdAt).toLocaleString()}
                                  </td>
                                  <td>
                                    <span
                                      className="badge"
                                      style={{
                                        background: `${entryColour(t.type)}1A`,
                                        color: entryColour(t.type),
                                      }}
                                    >
                                      {t.type}
                                    </span>
                                  </td>
                                  <td style={{ fontSize: 13 }}>{t.orderNo || '—'}</td>
                                  <td
                                    style={{
                                      fontWeight: 800,
                                      color: t.coins >= 0 ? '#10B981' : '#EF4444',
                                    }}
                                  >
                                    {t.coins >= 0 ? `+${t.coins}` : t.coins}
                                  </td>
                                  <td>{t.balanceAfter}</td>
                                </tr>
                              ))
                            )}
                          </tbody>
                        </table>
                      </div>
                    </>
                  )}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
};

export default Coins;
