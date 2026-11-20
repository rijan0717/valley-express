import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

const Offers = ({ onReplaySplash }) => {
  const { showAlert, showConfirm, showToast } = useModal();
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingOffer, setEditingOffer] = useState(null);
  const [formData, setFormData] = useState({
    code: '',
    title: '',
    description: '',
    discountType: 'percentage',
    discountValue: 15,
    minOrderAmount: 500,
    maxDiscountAmount: 200,
  });

  const fetchOffers = async () => {
    try {
      const res = await api.get('/offers/all');
      if (res.data.success) {
        setOffers(res.data.offers);
      }
    } catch (e) {
      console.error('Error fetching offers:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOffers();
  }, []);

  const openAddModal = () => {
    setEditingOffer(null);
    setFormData({
      code: '',
      title: '',
      description: '',
      discountType: 'percentage',
      discountValue: 15,
      minOrderAmount: 500,
      maxDiscountAmount: 200,
    });
    setShowModal(true);
  };

  const openEditModal = (offer) => {
    setEditingOffer(offer);
    setFormData({
      code: offer.code,
      title: offer.title || '',
      description: offer.description || '',
      discountType: offer.discountType || 'percentage',
      discountValue: offer.discountValue || 15,
      minOrderAmount: offer.minOrderAmount || 0,
      maxDiscountAmount: offer.maxDiscountAmount || 0,
    });
    setShowModal(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...formData,
        code: formData.code.toUpperCase().trim(),
        discountValue: Number(formData.discountValue),
        minOrderAmount: Number(formData.minOrderAmount),
        maxDiscountAmount: Number(formData.maxDiscountAmount) || null,
      };

      if (editingOffer) {
        const res = await api.put(`/offers/${editingOffer._id}`, payload);
        if (res.data.success) {
          setOffers(offers.map((o) => (o._id === editingOffer._id ? res.data.offer : o)));
          setShowModal(false);
          showToast('Coupon details updated successfully', 'success');
        }
      } else {
        const res = await api.post('/offers', payload);
        if (res.data.success) {
          setOffers([res.data.offer, ...offers]);
          setShowModal(false);
          showToast('New promotional coupon created', 'success');
        }
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Save Coupon Error', 'danger');
    }
  };

  const handleToggle = async (id) => {
    try {
      const res = await api.patch(`/offers/${id}/toggle`);
      if (res.data.success) {
        setOffers(offers.map((o) => (o._id === id ? { ...o, isActive: res.data.isActive } : o)));
        showToast(`Coupon status set to ${res.data.isActive ? 'Active' : 'Disabled'}`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Status Toggle Error', 'danger');
    }
  };

  const handleDelete = async (id, code) => {
    const confirmed = await showConfirm(
      `Confirm permanent deletion of coupon code "${code}"? Customers will no longer receive discounts with this code.`,
      'Delete Promotional Offer',
      true,
      'Delete Coupon',
      'Keep Coupon'
    );
    if (!confirmed) return;

    try {
      const res = await api.delete(`/offers/${id}`);
      if (res.data.success) {
        setOffers(offers.filter((o) => o._id !== id));
        showToast(`Coupon "${code}" deleted`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete Offer Error', 'danger');
    }
  };

  return (
    <>
      <Navbar title="Offers & Promotional Deals" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Loading promotional coupons from database..." />
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
                  Coupons &amp; Valley Express Deals
                </h2>
                <p style={{ fontSize: '12px', color: '#1F2A44' }}>
                  Manage promotional discount codes redeemable at customer checkout
                </p>
              </div>
              <button onClick={openAddModal} className="btn btn-primary btn-sm">
                + Create New Offer
              </button>
            </div>

            <div className="table-card">
              <div className="table-responsive">
                <table>
                  <thead>
                    <tr>
                      <th>Promo Code</th>
                      <th>Title &amp; Scope</th>
                      <th>Discount Value</th>
                      <th>Min Order</th>
                      <th>Max Cap</th>
                      <th>Usage Count</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {offers.length === 0 ? (
                      <tr>
                        <td colSpan="8" style={{ textAlign: 'center', padding: '36px', color: '#1F2A44' }}>
                          No coupon deals currently configured in database.
                        </td>
                      </tr>
                    ) : (
                      offers.map((offer) => (
                        <tr key={offer._id}>
                          <td>
                            <span
                              style={{
                                fontFamily: 'monospace',
                                fontWeight: 700,
                                fontSize: '13px',
                                color: '#003893',
                                padding: '4px 8px',
                                border: '1px solid #003893',
                                borderRadius: '4px',
                              }}
                            >
                              {offer.code}
                            </span>
                          </td>
                          <td>
                            <div style={{ fontWeight: 500 }}>{offer.title || 'Promotional Offer'}</div>
                            {offer.description && (
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                                {offer.description}
                              </div>
                            )}
                          </td>
                          <td style={{ fontWeight: 700, color: '#FF6B1A' }}>
                            {offer.discountType === 'percentage'
                              ? `${offer.discountValue}% OFF`
                              : `Rs. ${offer.discountValue} FLAT`}
                          </td>
                          <td>Rs. {offer.minOrderAmount || 0}</td>
                          <td>{offer.maxDiscountAmount ? `Rs. ${offer.maxDiscountAmount}` : 'No Cap'}</td>
                          <td style={{ fontWeight: 500 }}>{offer.usedCount || 0} orders</td>
                          <td>
                            <button
                              onClick={() => handleToggle(offer._id)}
                              className={`badge ${offer.isActive ? 'badge-accent' : 'badge-neutral'}`}
                              style={{ cursor: 'pointer', background: '#FFFFFF' }}
                              title="Click to toggle status"
                            >
                              {offer.isActive ? 'Active' : 'Disabled'}
                            </button>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: '6px' }}>
                              <button
                                onClick={() => openEditModal(offer)}
                                className="btn btn-secondary btn-sm"
                              >
                                Edit
                              </button>
                              <button
                                onClick={() => handleDelete(offer._id, offer.code)}
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

            {/* Offer Create / Edit Modal */}
            {showModal && (
              <div className="modal-overlay">
                <div className="modal-content">
                  <div className="modal-header">
                    <h3 className="modal-title">
                      {editingOffer ? `Edit Offer: ${editingOffer.code}` : 'Create Promotional Deal'}
                    </h3>
                    <button
                      onClick={() => setShowModal(false)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  <form onSubmit={handleSave}>
                    <div className="form-group">
                      <label className="form-label">Coupon Code *</label>
                      <input
                        type="text"
                        required
                        value={formData.code}
                        onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                        placeholder="e.g. VALLEYFIRST"
                        style={{ textTransform: 'uppercase', fontFamily: 'monospace' }}
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Offer Title *</label>
                      <input
                        type="text"
                        required
                        value={formData.title}
                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                        placeholder="e.g. First Order 15% Discount"
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Description</label>
                      <textarea
                        rows={2}
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                        placeholder="Applies across snack and beverage baskets over Rs. 500"
                      />
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Discount Type *</label>
                        <select
                          value={formData.discountType}
                          onChange={(e) => setFormData({ ...formData, discountType: e.target.value })}
                        >
                          <option value="percentage">Percentage (%)</option>
                          <option value="flat">Flat Amount (NPR)</option>
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="form-label">
                          {formData.discountType === 'percentage' ? 'Percentage Value (%)' : 'Flat Amount (NPR)'} *
                        </label>
                        <input
                          type="number"
                          required
                          value={formData.discountValue}
                          onChange={(e) => setFormData({ ...formData, discountValue: e.target.value })}
                          placeholder="15"
                        />
                      </div>
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Minimum Order (NPR)</label>
                        <input
                          type="number"
                          value={formData.minOrderAmount}
                          onChange={(e) => setFormData({ ...formData, minOrderAmount: e.target.value })}
                          placeholder="500"
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Maximum Discount Cap (NPR)</label>
                        <input
                          type="number"
                          value={formData.maxDiscountAmount}
                          onChange={(e) => setFormData({ ...formData, maxDiscountAmount: e.target.value })}
                          placeholder="200 (optional)"
                        />
                      </div>
                    </div>

                    <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                      <button
                        type="button"
                        onClick={() => setShowModal(false)}
                        className="btn btn-secondary"
                        style={{ flex: 1 }}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>
                        {editingOffer ? 'Save Changes' : 'Create Offer in DB'}
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

export default Offers;
