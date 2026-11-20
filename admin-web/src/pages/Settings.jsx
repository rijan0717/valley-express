import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

const Settings = ({ onReplaySplash }) => {
  const { showAlert, showToast } = useModal();
  const [settings, setSettings] = useState({
    alcoholEnabled: false,
    storeOpen: true,
    serviceHours: { open: '10:00', close: '23:30' },
    defaultDeliveryFee: 100,
    freeDeliveryThreshold: 1500,
    contactPhone: '+977-9800000000',
    contactEmail: 'admin@gmail.com',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  useEffect(() => {
    api.get('/admin/settings')
      .then((res) => {
        if (res.data.success && res.data.settings) {
          setSettings(res.data.settings);
        }
      })
      .finally(() => setLoading(false));
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setSaveSuccess(false);
    try {
      const res = await api.put('/admin/settings', settings);
      if (res.data.success) {
        setSettings(res.data.settings);
        setSaveSuccess(true);
        showToast('Store settings saved successfully', 'success');
        setTimeout(() => setSaveSuccess(false), 3000);
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Settings Save Failed', 'danger');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <Navbar title="Store Operations & Compliance Settings" onReplaySplash={onReplaySplash} />
      <div className="page-body" style={{ maxWidth: '800px' }}>
        {loading ? (
          <ValleyLoader text="Loading settings from MongoDB..." />
        ) : (
          <>
            <div style={{ marginBottom: '20px' }}>
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: '#003893' }}>
                Kathmandu Valley Configuration
              </h2>
              <p style={{ fontSize: '12px', color: '#1F2A44' }}>
                System operational policies, liquor licensing compliance switch, and delivery fees
              </p>
            </div>

            {saveSuccess && (
              <div
                style={{
                  background: '#FFFFFF',
                  border: '1px solid #003893',
                  color: '#003893',
                  padding: '12px 16px',
                  borderRadius: '4px',
                  marginBottom: '20px',
                  fontWeight: 500,
                  fontSize: '13px',
                }}
              >
                Settings saved and synchronized with MongoDB database.
              </div>
            )}

            <form onSubmit={handleSave}>
              {/* Section 1: Alcohol Compliance Switch */}
              <div
                style={{
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '20px',
                  marginBottom: '20px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                  <div>
                    <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#003893' }}>
                      Alcohol Delivery Regulatory Master Switch
                    </h3>
                    <p style={{ fontSize: '12px', color: '#1F2A44', marginTop: '4px' }}>
                      Enables or disables alcoholic beverages across the customer catalog.
                    </p>
                  </div>
                  <label className="switch">
                    <input
                      type="checkbox"
                      checked={settings.alcoholEnabled}
                      onChange={(e) => setSettings({ ...settings, alcoholEnabled: e.target.checked })}
                    />
                    <span className="slider"></span>
                  </label>
                </div>

                <div
                  style={{
                    background: '#FFFFFF',
                    border: '1px solid #D1D5DB',
                    padding: '12px',
                    borderRadius: '4px',
                    fontSize: '12px',
                    color: '#1F2A44',
                  }}
                >
                  Current State:{' '}
                  <strong style={{ color: settings.alcoholEnabled ? '#FF6B1A' : '#003893' }}>
                    {settings.alcoholEnabled
                      ? 'ACTIVE — Customer can view and purchase beers, whiskey, and spirits with 18+ verification.'
                      : 'RESTRICTED — All alcohol products are hidden from public queries pending municipal permit.'}
                  </strong>
                </div>
              </div>

              {/* Section 2: Store Operating Status */}
              <div
                style={{
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '20px',
                  marginBottom: '20px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
                  <div>
                    <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#003893' }}>
                      Store Online Status
                    </h3>
                    <p style={{ fontSize: '12px', color: '#1F2A44', marginTop: '4px' }}>
                      Allows customer app to place orders during operational hours
                    </p>
                  </div>
                  <label className="switch">
                    <input
                      type="checkbox"
                      checked={settings.storeOpen}
                      onChange={(e) => setSettings({ ...settings, storeOpen: e.target.checked })}
                    />
                    <span className="slider"></span>
                  </label>
                </div>

                <div className="form-grid">
                  <div className="form-group">
                    <label className="form-label">Opening Time</label>
                    <input
                      type="time"
                      value={settings.serviceHours?.open || '10:00'}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          serviceHours: { ...settings.serviceHours, open: e.target.value },
                        })
                      }
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Closing Time</label>
                    <input
                      type="time"
                      value={settings.serviceHours?.close || '23:30'}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          serviceHours: { ...settings.serviceHours, close: e.target.value },
                        })
                      }
                    />
                  </div>
                </div>
              </div>

              {/* Section 3: Pricing & Delivery Fee Logic */}
              <div
                style={{
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '20px',
                  marginBottom: '20px',
                }}
              >
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#003893', marginBottom: '16px' }}>
                  Delivery Fee Rules (Kathmandu Valley)
                </h3>

                <div className="form-grid">
                  <div className="form-group">
                    <label className="form-label">Default Base Delivery Fee (NPR)</label>
                    <input
                      type="number"
                      value={settings.defaultDeliveryFee}
                      onChange={(e) =>
                        setSettings({ ...settings, defaultDeliveryFee: Number(e.target.value) })
                      }
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Free Delivery Basket Threshold (NPR)</label>
                    <input
                      type="number"
                      value={settings.freeDeliveryThreshold}
                      onChange={(e) =>
                        setSettings({ ...settings, freeDeliveryThreshold: Number(e.target.value) })
                      }
                    />
                  </div>
                </div>
              </div>

              {/* Section 4: Contact Information */}
              <div
                style={{
                  background: '#FFFFFF',
                  border: '1px solid #D1D5DB',
                  borderRadius: '4px',
                  padding: '20px',
                  marginBottom: '24px',
                }}
              >
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#003893', marginBottom: '16px' }}>
                  Support &amp; Operations Contacts
                </h3>

                <div className="form-grid">
                  <div className="form-group">
                    <label className="form-label">Customer Support Phone</label>
                    <input
                      type="text"
                      value={settings.contactPhone || '+977-9800000000'}
                      onChange={(e) => setSettings({ ...settings, contactPhone: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Administrative Email</label>
                    <input
                      type="email"
                      value={settings.contactEmail || 'admin@gmail.com'}
                      onChange={(e) => setSettings({ ...settings, contactEmail: e.target.value })}
                    />
                  </div>
                </div>
              </div>

              <button type="submit" disabled={saving} className="btn btn-primary" style={{ width: '100%' }}>
                {saving ? 'Saving to Database...' : 'Save Operations Settings'}
              </button>
            </form>
          </>
        )}
      </div>
    </>
  );
};

export default Settings;
