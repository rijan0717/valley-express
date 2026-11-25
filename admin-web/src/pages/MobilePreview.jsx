import React, { useState, useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useSocket } from '../context/SocketContext';
import { useModal } from '../context/ModalContext';
import { LogoMark, LogoFull } from '../components/Logo';
import ValleyLoader from '../components/ValleyLoader';
import MapAddressPicker from '../components/MapAddressPicker';
import ProductDetailSheet from '../components/ProductDetailSheet';
import {
  BagIcon,
  SearchIcon,
  CloseIcon,
  BoltIcon,
  TagIcon,
  PackageIcon,
  MapPinIcon,
  MapIcon,
  CashIcon,
  ChatIcon,
  NavigationIcon,
  PhoneIcon,
} from '../components/Icons';

const MobilePreview = ({ onReplaySplash }) => {
  const { showAlert, showToast } = useModal();
  const [role, setRole] = useState('customer'); // 'customer' or 'rider'
  const [activeTab, setActiveTab] = useState('home'); // 'home', 'cart', 'maps', 'tracking', 'chat', 'rider_jobs'
  // Loading states. The branded loaders are shown for these rather than being
  // a separate gallery tab.
  const [catalogLoading, setCatalogLoading] = useState(true);
  const [placingOrder, setPlacingOrder] = useState(false);
  const [chatLoading, setChatLoading] = useState(true);
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('');
  const [cart, setCart] = useState([]);
  const [ageConfirmed, setAgeConfirmed] = useState(false);
  const [activeOrder, setActiveOrder] = useState(null);
  const [riderOrders, setRiderOrders] = useState([]);
  const [isRiderOnline, setIsRiderOnline] = useState(true);
  const [couponCode, setCouponCode] = useState('VALLEYFIRST');
  const [appliedDiscount, setAppliedDiscount] = useState(0);
  const [couponMessage, setCouponMessage] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('cash_on_delivery');
  const [chatMessages, setChatMessages] = useState([]);
  const [chatInput, setChatInput] = useState('');
  const [chatError, setChatError] = useState('');
  // How many admin replies the simulated customer has already looked at. The
  // simulator shares the admin's API session, so it cannot use the server-side
  // unread count — that one belongs to the admin.
  const [chatSeenCount, setChatSeenCount] = useState(0);
  const [showMapPicker, setShowMapPicker] = useState(false);
  // Product tapped in the catalogue; shown as a sheet over the phone screen
  const [detailProduct, setDetailProduct] = useState(null);
  // Add-to-cart flight markers, and the matching pulse on the Cart tab
  const [flyers, setFlyers] = useState([]);
  const [cartPulse, setCartPulse] = useState(false);
  const phoneRef = useRef(null);
  const cartTabRef = useRef(null);
  const [deliveryLocation, setDeliveryLocation] = useState({
    addressText: 'Baluwatar, Kathmandu',
    landmark: 'Near Russian Embassy, House #42',
    formattedAddress: 'Baluwatar Chowk, Prime Minister Residence Road, Kathmandu',
    latitude: 27.7280,
    longitude: 85.3300,
    contactPhone: '9841234567',
    location: { type: 'Point', coordinates: [85.3300, 27.7280] },
  });
  const { socket } = useSocket();

  // Load products, categories & existing orders
  useEffect(() => {
    const initSimulatorSession = async () => {
      // Runs under the signed-in admin's session (this page is now behind
      // ProtectedRoute). It previously signed in with a hardcoded admin email
      // and password, which both shipped those credentials in the bundle and
      // let anyone opening this public page obtain an admin token.
      api.get('/products').then((res) => {
        if (res.data.success) setProducts(res.data.products);
      }).catch(() => {}).finally(() => setCatalogLoading(false));

      api.get('/categories').then((res) => {
        if (res.data.success) setCategories(res.data.categories);
      }).catch(() => {});

      api.get('/orders').then((res) => {
        if (res.data.success && res.data.orders.length > 0) {
          setActiveOrder(res.data.orders[0]);
          setRiderOrders(res.data.orders.filter((o) => o.status !== 'delivered'));
        }
      }).catch(() => {});
    };

    initSimulatorSession();
  }, []);

  // Socket status listener
  useEffect(() => {
    if (socket) {
      socket.on('order:status', (updated) => {
        if (activeOrder?._id === updated._id) {
          setActiveOrder(updated);
        }
        setRiderOrders((prev) =>
          prev.map((o) => (o._id === updated._id ? updated : o))
        );
      });

      socket.on('chat:message', (newMsg) => {
        if (activeOrder && (newMsg.order === activeOrder._id || newMsg.order?._id === activeOrder._id)) {
          setChatMessages((prev) => [...prev, newMsg]);
        }
      });
    }
  }, [socket, activeOrder]);

  // Load chat messages when tracking or chat active
  useEffect(() => {
    const threadId = activeOrder?._id || 'general';
    setChatLoading(true);
    api.get(`/chat/${threadId}`)
      .then((res) => {
        if (res.data.success) setChatMessages(res.data.messages || []);
      })
      .catch(() => {})
      .finally(() => setChatLoading(false));
  }, [activeOrder, activeTab]);

  // Unread badge for the customer's Chat tab: admin replies not yet opened
  const adminReplyCount = chatMessages.filter((m) => m.senderRole === 'admin').length;
  const unreadChatCount = activeTab === 'chat' ? 0 : Math.max(0, adminReplyCount - chatSeenCount);

  useEffect(() => {
    if (activeTab === 'chat') {
      setChatSeenCount(adminReplyCount);
    }
  }, [activeTab, adminReplyCount]);

  // Flies a small marker from the tapped button to the Cart tab, so the count
  // change is visibly connected to the thing that was added.
  const flyToCart = (sourceEl) => {
    const phone = phoneRef.current;
    const target = cartTabRef.current;
    if (!phone || !target || !sourceEl) return;

    const frame = phone.getBoundingClientRect();
    const from = sourceEl.getBoundingClientRect();
    const to = target.getBoundingClientRect();

    const id = Date.now() + Math.random();
    setFlyers((prev) => [
      ...prev,
      {
        id,
        x0: from.left - frame.left + from.width / 2,
        y0: from.top - frame.top + from.height / 2,
        x1: to.left - frame.left + to.width / 2,
        y1: to.top - frame.top + to.height / 2,
      },
    ]);
    setCartPulse(true);
    window.setTimeout(() => {
      setFlyers((prev) => prev.filter((f) => f.id !== id));
      setCartPulse(false);
    }, 650);
  };

  const addToCart = (product, sourceEl) => {
    if (sourceEl) flyToCart(sourceEl);
    setCart((prev) => {
      const existing = prev.find((item) => item.product._id === product._id);
      if (existing) {
        return prev.map((item) =>
          item.product._id === product._id ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  };

  const updateCartQuantity = (productId, delta) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.product._id === productId) {
            const nextQty = item.quantity + delta;
            return nextQty > 0 ? { ...item, quantity: nextQty } : null;
          }
          return item;
        })
        .filter(Boolean)
    );
  };

  const cartSubtotal = cart.reduce((sum, i) => sum + i.product.price * i.quantity, 0);
  const hasAlcohol = cart.some((i) => i.product.isAlcohol);
  const deliveryFee = cartSubtotal >= 1500 ? 0 : 100;
  const cartTotal = Math.max(0, cartSubtotal + deliveryFee - appliedDiscount);

  const handleApplyCoupon = async () => {
    if (!couponCode.trim()) return;
    try {
      const res = await api.post('/offers/validate', {
        code: couponCode.trim(),
        orderAmount: cartSubtotal,
      });
      if (res.data.success) {
        setAppliedDiscount(res.data.offer.discountAmount);
        setCouponMessage(`Discount of Rs. ${res.data.offer.discountAmount} applied!`);
      }
    } catch (err) {
      setAppliedDiscount(0);
      setCouponMessage(err.response?.data?.message || 'Invalid coupon code');
    }
  };

  const handlePlaceOrder = async () => {
    if (cart.length === 0) {
      showToast('Your basket is empty. Add items before checking out.', 'warning');
      return;
    }
    if (hasAlcohol && !ageConfirmed) {
      showAlert('Alcohol Regulatory Notice: Please confirm you are 18+ years of age before purchasing alcohol items.', 'Age Verification Required', 'warning');
      return;
    }

    setPlacingOrder(true);
    try {
      const payload = {
        items: cart.map((i) => ({ product: i.product._id, quantity: i.quantity })),
        address: {
          addressText: deliveryLocation.addressText || 'Kathmandu Valley',
          landmark: deliveryLocation.landmark || '',
          formattedAddress: deliveryLocation.formattedAddress || deliveryLocation.addressText || '',
          location: {
            type: 'Point',
            coordinates: [deliveryLocation.longitude || 85.33, deliveryLocation.latitude || 27.728],
          },
          contactPhone: deliveryLocation.contactPhone || '9841234567',
        },
        paymentMethod: paymentMethod || 'cash_on_delivery',
        paymentStatus: paymentMethod === 'cash_on_delivery' ? 'pending' : 'paid',
        offerCode: appliedDiscount > 0 ? couponCode.trim() : undefined,
      };

      const res = await api.post('/orders', payload);
      if (res.data.success) {
        setActiveOrder(res.data.order);
        setCart([]);
        setAppliedDiscount(0);
        setCouponMessage('');
        setActiveTab('tracking');
        showToast(`Order ${res.data.order.orderNo} placed. Tracking is now live.`, 'success');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Order Placement Failed', 'danger');
    } finally {
      setPlacingOrder(false);
    }
  };

  const handleRiderAction = async (orderId, newStatus) => {
    try {
      const res = await api.patch(`/orders/${orderId}/status`, { status: newStatus });
      if (res.data.success) {
        setRiderOrders((prev) =>
          prev.map((o) => (o._id === orderId ? res.data.order : o))
        );
        if (activeOrder?._id === orderId) {
          setActiveOrder(res.data.order);
        }
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Status Update Failed', 'danger');
    }
  };

  const handleSendCustomerMessage = async (e) => {
    e.preventDefault();
    if (!chatInput.trim()) {
      setChatError('Type a message before sending.');
      return;
    }
    const text = chatInput.trim();
    setChatInput('');
    setChatError('');
    try {
      const threadId = activeOrder?._id || 'general';
      const res = await api.post(`/chat/${threadId}`, { text, senderRole: 'customer' });
      if (res.data.success) {
        setChatMessages((prev) => [...prev, res.data.message]);
      }
    } catch (err) {
      setChatError(err.response?.data?.message || err.message);
    }
  };

  // Category & Live Search Filtering
  const [searchQuery, setSearchQuery] = useState('');
  const filteredProducts = products.filter((p) => {
    const matchesCategory =
      !selectedCategory ||
      p.category?._id === selectedCategory ||
      p.category === selectedCategory ||
      p.category?.slug === selectedCategory;
    const matchesSearch =
      !searchQuery ||
      p.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.nameNe && p.nameNe.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  return (
    <>
      <Navbar title="Mobile Client Simulator" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {/* Role & Action Buttons Centered at the Middle of the Screen */}
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 700, color: '#003893', marginBottom: '4px' }}>
            Mobile Client Interactive Simulator (Flutter)
          </h2>
          <p style={{ fontSize: '12px', color: '#1F2A44', marginBottom: '14px' }}>
            Real-time customer &amp; rider mobile flows connected to MongoDB REST API &amp; Socket.io
          </p>

          <div
            style={{
              display: 'inline-flex',
              background: '#FFFFFF',
              border: '2px solid #003893',
              borderRadius: '40px',
              padding: '4px',
              gap: '6px',
            }}
          >
            <button
              type="button"
              onClick={() => {
                setRole('customer');
                setActiveTab('home');
              }}
              className={`btn ${role === 'customer' ? 'btn-brand' : 'btn-secondary'}`}
              style={{
                borderRadius: '32px',
                padding: '10px 24px',
                minHeight: '40px',
                fontWeight: 700,
                fontSize: '13px',
                border: 'none',
              }}
            >
              Customer Mobile Experience
            </button>
            <button
              type="button"
              onClick={() => {
                setRole('rider');
                setActiveTab('rider_jobs');
              }}
              className={`btn ${role === 'rider' ? 'btn-brand' : 'btn-secondary'}`}
              style={{
                borderRadius: '32px',
                padding: '10px 24px',
                minHeight: '40px',
                fontWeight: 700,
                fontSize: '13px',
                border: 'none',
              }}
            >
              Rider Duty Experience
            </button>
          </div>
        </div>

        {/* Centered Phone Container */}
        <div style={{ display: 'flex', justifyContent: 'center', width: '100%', paddingBottom: '36px' }}>
          {/* Industrial Utility Smartphone Shell */}
          <div
            ref={phoneRef}
            style={{
              width: '380px',
              height: '750px',
              background: '#FFFFFF',
              border: '2px solid #1F2A44',
              borderRadius: '24px',
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden',
              boxShadow: 'none',
              // Anchors the product detail sheet to the phone screen
              position: 'relative',
            }}
          >
          {/* Status Header */}
          <div
            style={{
              padding: '10px 16px',
              borderBottom: '1px solid #D1D5DB',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontSize: '11px',
              fontWeight: 700,
              color: '#1F2A44',
              background: '#FFFFFF',
            }}
          >
            <span>VALLEY EXPRESS MOBILE</span>
            <span style={{ fontFamily: 'monospace' }}>KTM 5G</span>
          </div>

          {/* SCREEN CONTENT: CUSTOMER FLOW */}
          {role === 'customer' && (
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
              {/* Customer Top Bar (matching Figma) */}
              <div
                style={{
                  padding: '12px 14px',
                  borderBottom: '1px solid #E2E8F0',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  background: '#FFFFFF',
                }}
              >
                {/* Profile Icon */}
                <div
                  onClick={() => setActiveTab('chat')}
                  style={{
                    width: '36px',
                    height: '36px',
                    borderRadius: '50%',
                    background: '#F0F5FA',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                  }}
                  title="Profile & Support Chat"
                >
                  <LogoMark size={20} />
                </div>

                {/* Deliver to address dropdown */}
                <div
                  onClick={() => setShowMapPicker(true)}
                  style={{ textAlign: 'center', cursor: 'pointer', flex: 1, padding: '0 8px' }}
                  title="Click to search or pick address on map"
                >
                  <div style={{ fontSize: '9px', color: '#FF6B1A', fontWeight: 700, letterSpacing: '0.5px', textTransform: 'uppercase' }}>
                    DELIVER TO ▾
                  </div>
                  <div style={{ fontSize: '12px', fontWeight: 700, color: '#181C2E', maxWidth: '180px', margin: '0 auto', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {deliveryLocation.addressText}
                  </div>
                </div>

                {/* Dark Navy Cart Button with Orange Badge */}
                <div
                  onClick={() => setActiveTab('cart')}
                  style={{
                    width: '36px',
                    height: '36px',
                    borderRadius: '50%',
                    background: '#181C2E',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    position: 'relative',
                  }}
                  title="View Cart"
                >
                  <BagIcon size={16} />
                  {cart.length > 0 && (
                    <span
                      style={{
                        position: 'absolute',
                        top: '-3px',
                        right: '-3px',
                        background: '#FF6B1A',
                        color: '#FFFFFF',
                        fontSize: '9px',
                        fontWeight: 700,
                        width: '16px',
                        height: '16px',
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      {cart.reduce((s, i) => s + i.quantity, 0)}
                    </span>
                  )}
                </div>
              </div>

              {/* Home Catalog View */}
              {activeTab === 'home' && (
                <div style={{ flex: 1, overflowY: 'auto', padding: '14px', background: '#FAFBFC' }}>
                  {/* Greeting */}
                  <div style={{ marginBottom: '12px' }}>
                    <div style={{ fontSize: '13px', color: '#646982' }}>
                      Hey Valley Customer,
                    </div>
                    <div style={{ fontSize: '17px', fontWeight: 700, color: '#181C2E' }}>
                      Good Afternoon!
                    </div>
                  </div>

                  {/* Search Bar Input */}
                  <div
                    style={{
                      background: '#F0F5FA',
                      borderRadius: '14px',
                      padding: '8px 12px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      marginBottom: '14px',
                    }}
                  >
                    <span style={{ color: '#646982', display: 'flex' }}><SearchIcon size={15} /></span>
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Search drinks, snacks, dishes..."
                      style={{
                        background: 'transparent',
                        border: 'none',
                        outline: 'none',
                        fontSize: '12px',
                        width: '100%',
                        color: '#181C2E',
                      }}
                    />
                    {searchQuery && (
                      <span
                        onClick={() => setSearchQuery('')}
                        style={{ cursor: 'pointer', fontSize: '12px', color: '#646982' }}
                      >
                        <CloseIcon size={12} />
                      </span>
                    )}
                  </div>

                  {/* Categories Row Header */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <div style={{ fontWeight: 700, fontSize: '13px', color: '#181C2E' }}>
                      All Categories
                    </div>
                    <div
                      onClick={() => setSelectedCategory('')}
                      style={{ fontSize: '11px', fontWeight: 600, color: '#FF6B1A', cursor: 'pointer' }}
                    >
                      See All &gt;
                    </div>
                  </div>

                  {/* Category Chips */}
                  <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '10px', marginBottom: '10px' }}>
                    <button
                      onClick={() => setSelectedCategory('')}
                      style={{
                        padding: '6px 14px',
                        borderRadius: '12px',
                        fontSize: '11px',
                        fontWeight: 600,
                        border: selectedCategory === '' ? '1.5px solid #FF6B1A' : '1px solid #E2E8F0',
                        background: selectedCategory === '' ? '#FF6B1A' : '#FFFFFF',
                        color: selectedCategory === '' ? '#FFFFFF' : '#181C2E',
                        cursor: 'pointer',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      All Items
                    </button>
                    {categories.map((c) => {
                      const isSel = selectedCategory === c._id || selectedCategory === c.slug;
                      return (
                        <button
                          key={c._id}
                          onClick={() => setSelectedCategory(c._id)}
                          style={{
                            padding: '6px 14px',
                            borderRadius: '12px',
                            fontSize: '11px',
                            fontWeight: 600,
                            border: isSel ? '1.5px solid #FF6B1A' : '1px solid #E2E8F0',
                            background: isSel ? '#FF6B1A' : '#FFFFFF',
                            color: isSel ? '#FFFFFF' : '#181C2E',
                            cursor: 'pointer',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {c.name}
                        </button>
                      );
                    })}
                  </div>

                  {/* Hurry Offers Card Banner (matching Figma) */}
                  <div
                    style={{
                      background: '#FF6B1A',
                      color: '#FFFFFF',
                      borderRadius: '16px',
                      padding: '14px',
                      marginBottom: '16px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <span
                        style={{
                          background: '#FFFFFF',
                          color: '#FF6B1A',
                          fontSize: '9px',
                          fontWeight: 700,
                          padding: '2px 6px',
                          borderRadius: '4px',
                          letterSpacing: '0.5px',
                        }}
                      >
                        <BoltIcon size={11} /> KATHMANDU 30-MIN EXPRESS
                      </span>
                      <div style={{ fontSize: '14px', fontWeight: 700, marginTop: '6px', lineHeight: 1.2 }}>
                        Hurry Offers!<br />Get 15% Discount
                      </div>
                      <div style={{ fontSize: '10px', color: '#FFE3D3', marginTop: '4px' }}>
                        Use code: <strong>VALLEYFIRST</strong>
                      </div>
                    </div>
                    <div
                      style={{
                        width: '42px',
                        height: '42px',
                        borderRadius: '50%',
                        background: '#FFFFFF',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '20px',
                      }}
                    >
                      <TagIcon size={20} />
                    </div>
                  </div>

                  {/* Products Grid Header */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                    <div style={{ fontWeight: 700, fontSize: '13px', color: '#181C2E' }}>
                      Popular Kathmandu Items
                    </div>
                    <div style={{ fontSize: '11px', color: '#646982' }}>
                      {filteredProducts.length} items
                    </div>
                  </div>

                  {/* Products Grid (matching Figma 2-column cards) */}
                  {catalogLoading ? (
                    <ValleyLoader
                      variant="scooter"
                      text="Loading tonight's menu across the Valley..."
                    />
                  ) : filteredProducts.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '28px 12px', color: '#646982', fontSize: '12px' }}>
                      Nothing matches that search. Try another drink or snack.
                    </div>
                  ) : (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '10px' }}>
                    {filteredProducts.map((p) => (
                      <div
                        key={p._id}
                        role="button"
                        tabIndex={0}
                        onClick={() => setDetailProduct(p)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' || e.key === ' ') {
                            e.preventDefault();
                            setDetailProduct(p);
                          }
                        }}
                        title={`View details for ${p.name}`}
                        style={{
                          border: '1px solid #E2E8F0',
                          borderRadius: '16px',
                          padding: '10px',
                          display: 'flex',
                          flexDirection: 'column',
                          justifyContent: 'space-between',
                          background: '#FFFFFF',
                          cursor: 'pointer',
                        }}
                      >
                        <div>
                          <div
                            style={{
                              height: '80px',
                              width: '100%',
                              marginBottom: '8px',
                              background: '#F0F5FA',
                              borderRadius: '12px',
                              overflow: 'hidden',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              position: 'relative',
                            }}
                          >
                            {p.images && p.images.length > 0 ? (
                              <img
                                src={p.images[0]}
                                alt={p.name}
                                style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                                onError={(e) => {
                                  e.target.style.display = 'none';
                                }}
                              />
                            ) : (
                              <PackageIcon size={26} />
                            )}
                            {p.isAlcohol && (
                              <span
                                style={{
                                  position: 'absolute',
                                  top: '4px',
                                  left: '4px',
                                  background: '#FF6B1A',
                                  color: '#FFFFFF',
                                  fontSize: '8px',
                                  fontWeight: 700,
                                  padding: '2px 4px',
                                  borderRadius: '4px',
                                }}
                              >
                                18+
                              </span>
                            )}
                          </div>
                          <div style={{ fontWeight: 700, fontSize: '12px', color: '#181C2E', lineHeight: 1.2 }}>
                            {p.name}
                          </div>
                          {p.nameNe && (
                            <div style={{ fontSize: '10px', color: '#646982', marginTop: '2px' }}>
                              {p.nameNe}
                            </div>
                          )}
                          <div style={{ fontSize: '10px', color: '#A0A5BA', marginTop: '2px' }}>
                            {p.unit || '650ml bottle'}
                          </div>
                        </div>

                        {/* Bottom Row: Price & Circular Orange '+' Button */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '10px' }}>
                          <span style={{ fontWeight: 700, color: '#181C2E', fontSize: '13px' }}>
                            Rs. {p.price}
                          </span>
                          <button
                            onClick={(e) => {
                              // Keep the quick-add from opening the detail sheet
                              e.stopPropagation();
                              addToCart(p, e.currentTarget);
                            }}
                            title={`Add ${p.name} to basket`}
                            style={{
                              width: '28px',
                              height: '28px',
                              borderRadius: '50%',
                              background: '#FF6B1A',
                              color: '#FFFFFF',
                              border: 'none',
                              fontSize: '16px',
                              fontWeight: 700,
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              padding: 0,
                            }}
                          >
                            +
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                  )}
                </div>
              )}

              {/* Live Delivery Map: pick and confirm the drop-off point */}
              {activeTab === 'maps' && (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
                  <div style={{ padding: '10px 14px', borderBottom: '1px solid #D1D5DB' }}>
                    <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893' }}>
                      Delivery Map
                    </div>
                    <div style={{ fontSize: '10px', color: '#646982', marginTop: '2px' }}>
                      Drag the pin or search to set exactly where the rider should meet you.
                    </div>
                  </div>
                  <div style={{ flex: 1, overflow: 'hidden' }}>
                    <MapAddressPicker
                      initialLocation={deliveryLocation}
                      isModal={false}
                      onConfirm={(newLoc) => {
                        setDeliveryLocation(newLoc);
                        showToast('Drop-off location updated', 'success');
                        setActiveTab('cart');
                      }}
                      onClose={() => setActiveTab('home')}
                    />
                  </div>
                </div>
              )}

              {/* Cart & Checkout View */}
              {activeTab === 'cart' && (
                <div style={{ flex: 1, overflowY: 'auto', padding: '14px', display: 'flex', flexDirection: 'column' }}>
                  <div style={{ fontWeight: 700, fontSize: '14px', color: '#003893', marginBottom: '12px' }}>
                    Your Delivery Basket ({cart.length} items)
                  </div>

                  {cart.length === 0 ? (
                    <div style={{ textAlign: 'center', margin: 'auto', color: '#1F2A44', fontSize: '12px' }}>
                      Your basket is empty. Browse the catalog to select items.
                    </div>
                  ) : (
                    <>
                      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                        {cart.map((item) => (
                          <div
                            key={item.product._id}
                            style={{
                              border: '1px solid #D1D5DB',
                              borderRadius: '4px',
                              padding: '10px',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                            }}
                          >
                            <div style={{ flex: 1 }}>
                              <div style={{ fontWeight: 500, fontSize: '12px', color: '#003893' }}>
                                {item.product.name}
                              </div>
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                                Rs. {item.product.price} each
                              </div>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <button
                                onClick={() => updateCartQuantity(item.product._id, -1)}
                                className="btn btn-secondary btn-sm"
                                style={{ padding: '2px 8px', minHeight: '24px' }}
                              >
                                -
                              </button>
                              <span style={{ fontWeight: 700, fontSize: '12px' }}>{item.quantity}</span>
                              <button
                                onClick={() => updateCartQuantity(item.product._id, 1)}
                                className="btn btn-secondary btn-sm"
                                style={{ padding: '2px 8px', minHeight: '24px' }}
                              >
                                +
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>

                      {/* Coupon Box */}
                      <div style={{ border: '1px solid #D1D5DB', borderRadius: '4px', padding: '10px', marginBottom: '14px' }}>
                        <div style={{ fontSize: '11px', fontWeight: 700, textTransform: 'uppercase', marginBottom: '6px' }}>
                          Promo Code / Coupon
                        </div>
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <input
                            type="text"
                            value={couponCode}
                            onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                            placeholder="e.g. VALLEYFIRST"
                            style={{ flex: 1, minHeight: '34px', fontSize: '12px', fontFamily: 'monospace' }}
                          />
                          <button
                            type="button"
                            onClick={handleApplyCoupon}
                            className="btn btn-secondary btn-sm"
                            style={{ minHeight: '34px' }}
                          >
                            Apply
                          </button>
                        </div>
                        {couponMessage && (
                          <div style={{ fontSize: '11px', color: appliedDiscount > 0 ? '#003893' : '#FF6B1A', marginTop: '4px' }}>
                            {couponMessage}
                          </div>
                        )}
                      </div>

                      {/* Delivery Address & Map Selection (Pathao / Yango UX) */}
                      <div
                        style={{
                          border: '2px solid #003893',
                          borderRadius: '6px',
                          padding: '12px',
                          marginBottom: '14px',
                          background: '#F8FAFC',
                        }}
                      >
                        <div
                          style={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            marginBottom: '6px',
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <span style={{ color: '#FF6B1A', display: 'flex' }}><MapPinIcon size={15} /></span>
                            <span
                              style={{
                                fontSize: '11px',
                                fontWeight: 700,
                                color: '#003893',
                                textTransform: 'uppercase',
                                letterSpacing: '0.3px',
                              }}
                            >
                              Drop-off Address
                            </span>
                          </div>
                          <button
                            type="button"
                            onClick={() => setShowMapPicker(true)}
                            className="btn btn-primary btn-sm"
                            style={{ padding: '3px 10px', fontSize: '11px', height: '26px' }}
                          >
                            <MapIcon size={12} /> Select on Map
                          </button>
                        </div>

                        <div style={{ fontSize: '13px', fontWeight: 700, color: '#1F2A44', marginBottom: '2px' }}>
                          {deliveryLocation.addressText}
                        </div>
                        <div style={{ fontSize: '11px', color: '#4B5563', marginBottom: '6px', lineHeight: 1.3 }}>
                          {deliveryLocation.formattedAddress}
                        </div>

                        {deliveryLocation.landmark && (
                          <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 600, marginBottom: '6px' }}>
                            Landmark: {deliveryLocation.landmark}
                          </div>
                        )}

                        <div
                          style={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            borderTop: '1px dashed #D1D5DB',
                            paddingTop: '6px',
                            marginTop: '6px',
                          }}
                        >
                          <span style={{ fontSize: '10px', color: '#6B7280', fontFamily: 'monospace' }}>
                            GPS: {deliveryLocation.latitude?.toFixed(4)}N, {deliveryLocation.longitude?.toFixed(4)}E
                          </span>
                          <span
                            onClick={() => setShowMapPicker(true)}
                            style={{
                              fontSize: '10px',
                              color: '#003893',
                              fontWeight: 700,
                              cursor: 'pointer',
                              textDecoration: 'underline',
                            }}
                          >
                            Change Location
                          </span>
                        </div>
                      </div>

                      {/* Alcohol Age Verification Check */}
                      {hasAlcohol && (
                        <div style={{ border: '1px solid #FF6B1A', borderRadius: '4px', padding: '10px', marginBottom: '14px' }}>
                          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '11px', fontWeight: 500, color: '#1F2A44' }}>
                            <input
                              type="checkbox"
                              checked={ageConfirmed}
                              onChange={(e) => setAgeConfirmed(e.target.checked)}
                            />
                            I certify I am 18+ years of age. Rider will inspect national ID at drop-off.
                          </label>
                        </div>
                      )}

                      {/* Payment Method Selector */}
                      <div style={{ border: '1px solid #D1D5DB', borderRadius: '8px', padding: '10px', marginBottom: '14px', background: '#FFFFFF' }}>
                        <div style={{ fontSize: '10px', fontWeight: 700, color: '#003893', textTransform: 'uppercase', marginBottom: '8px', letterSpacing: '0.5px' }}>
                          Select Payment Method
                        </div>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                          <label
                            onClick={() => setPaymentMethod('cash_on_delivery')}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              padding: '8px 10px',
                              border: `1px solid ${paymentMethod === 'cash_on_delivery' ? '#FF6B1A' : '#E2E8F0'}`,
                              borderRadius: '6px',
                              background: paymentMethod === 'cash_on_delivery' ? '#FFF5EB' : '#FFFFFF',
                              cursor: 'pointer',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <CashIcon size={17} />
                              <div>
                                <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44' }}>Cash on Delivery</div>
                                <div style={{ fontSize: '9px', color: '#64748B' }}>Pay cash or Scan on delivery</div>
                              </div>
                            </div>
                            <input
                              type="radio"
                              name="paymentMethod"
                              checked={paymentMethod === 'cash_on_delivery'}
                              onChange={() => setPaymentMethod('cash_on_delivery')}
                            />
                          </label>

                          <label
                            onClick={() => setPaymentMethod('esewa')}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              padding: '8px 10px',
                              border: `1px solid ${paymentMethod === 'esewa' ? '#60BB46' : '#E2E8F0'}`,
                              borderRadius: '6px',
                              background: paymentMethod === 'esewa' ? '#F0FDF4' : '#FFFFFF',
                              cursor: 'pointer',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <span style={{ fontSize: '12px', fontWeight: 800, background: '#60BB46', color: '#FFFFFF', padding: '2px 4px', borderRadius: '3px' }}>eS</span>
                              <div>
                                <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44' }}>eSewa Mobile Wallet</div>
                                <div style={{ fontSize: '9px', color: '#16A34A', fontWeight: 600 }}>Sandbox e-Payment Instant</div>
                              </div>
                            </div>
                            <input
                              type="radio"
                              name="paymentMethod"
                              checked={paymentMethod === 'esewa'}
                              onChange={() => setPaymentMethod('esewa')}
                            />
                          </label>

                          <label
                            onClick={() => setPaymentMethod('khalti')}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              padding: '8px 10px',
                              border: `1px solid ${paymentMethod === 'khalti' ? '#5C2D91' : '#E2E8F0'}`,
                              borderRadius: '6px',
                              background: paymentMethod === 'khalti' ? '#FAF5FF' : '#FFFFFF',
                              cursor: 'pointer',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <span style={{ fontSize: '12px', fontWeight: 800, background: '#5C2D91', color: '#FFFFFF', padding: '2px 4px', borderRadius: '3px' }}>Kh</span>
                              <div>
                                <div style={{ fontSize: '11px', fontWeight: 700, color: '#1F2A44' }}>Khalti Digital Wallet</div>
                                <div style={{ fontSize: '9px', color: '#7E22CE', fontWeight: 600 }}>Balance &amp; e-Banking</div>
                              </div>
                            </div>
                            <input
                              type="radio"
                              name="paymentMethod"
                              checked={paymentMethod === 'khalti'}
                              onChange={() => setPaymentMethod('khalti')}
                            />
                          </label>
                        </div>
                      </div>

                      {/* Pricing Summary */}
                      <div style={{ borderTop: '1px solid #D1D5DB', paddingTop: '10px', marginBottom: '14px', fontSize: '12px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                          <span>Subtotal</span>
                          <span>Rs. {cartSubtotal}</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                          <span>Delivery Fee</span>
                          <span>Rs. {deliveryFee}</span>
                        </div>
                        {appliedDiscount > 0 && (
                          <div style={{ display: 'flex', justifyContent: 'space-between', color: '#FF6B1A', marginBottom: '4px' }}>
                            <span>Discount</span>
                            <span>- Rs. {appliedDiscount}</span>
                          </div>
                        )}
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 700, fontSize: '14px', color: '#003893', marginTop: '6px' }}>
                          <span>Total Amount</span>
                          <span>Rs. {cartTotal}</span>
                        </div>
                      </div>

                      <button
                        onClick={handlePlaceOrder}
                        className="btn btn-primary"
                        style={{
                          width: '100%',
                          background: paymentMethod === 'esewa' ? '#60BB46' : paymentMethod === 'khalti' ? '#5C2D91' : undefined,
                          borderColor: paymentMethod === 'esewa' ? '#60BB46' : paymentMethod === 'khalti' ? '#5C2D91' : undefined,
                        }}
                      >
                        {paymentMethod === 'cash_on_delivery'
                          ? `Place Cash-on-Delivery Order (Rs. ${cartTotal})`
                          : `Simulate & Pay via ${paymentMethod === 'esewa' ? 'eSewa' : 'Khalti'} (Rs. ${cartTotal})`}
                      </button>
                    </>
                  )}
                </div>
              )}

              {/* Order Tracking View */}
              {activeTab === 'tracking' && activeOrder && (
                <div style={{ flex: 1, overflowY: 'auto', padding: '14px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '14px', color: '#003893' }}>
                        {activeOrder.orderNo}
                      </div>
                      <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                        Total: Rs. {activeOrder.total}
                      </div>
                    </div>
                    <span className="badge badge-brand">
                      {activeOrder.status?.replace(/_/g, ' ')}
                    </span>
                  </div>

                  {/* Stepper */}
                  <div style={{ border: '1px solid #D1D5DB', borderRadius: '4px', padding: '14px', marginBottom: '14px' }}>
                    <div style={{ fontWeight: 700, fontSize: '12px', textTransform: 'uppercase', color: '#003893', marginBottom: '12px' }}>
                      Delivery Progression
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{ width: '10px', height: '10px', background: '#003893', borderRadius: '50%' }} />
                        <span>Order Received &amp; Verified</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div
                          style={{
                            width: '10px',
                            height: '10px',
                            background: ['preparing', 'rider_assigned', 'picked_up', 'on_the_way', 'delivered'].includes(activeOrder.status)
                              ? '#003893'
                              : '#D1D5DB',
                            borderRadius: '50%',
                          }}
                        />
                        <span>Kitchen Preparing &amp; Chilling</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div
                          style={{
                            width: '10px',
                            height: '10px',
                            background: ['rider_assigned', 'picked_up', 'on_the_way', 'delivered'].includes(activeOrder.status)
                              ? '#003893'
                              : '#D1D5DB',
                            borderRadius: '50%',
                          }}
                        />
                        <span>Rider Dispatched ({activeOrder.rider?.name || 'Rider on route'})</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div
                          style={{
                            width: '10px',
                            height: '10px',
                            background: activeOrder.status === 'delivered' ? '#003893' : '#D1D5DB',
                            borderRadius: '50%',
                          }}
                        />
                        <span>Delivered &amp; Cash Cleared</span>
                      </div>
                    </div>
                  </div>

                  {/* Customer In-App Chat */}
                  <div style={{ border: '1px solid #D1D5DB', borderRadius: '4px', padding: '12px' }}>
                    <div style={{ fontWeight: 700, fontSize: '12px', color: '#003893', marginBottom: '8px' }}>
                      Direct Chat with Dispatch
                    </div>
                    <div style={{ maxHeight: '140px', overflowY: 'auto', marginBottom: '8px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                      {chatMessages.length === 0 ? (
                        <div style={{ fontSize: '11px', color: '#1F2A44', textAlign: 'center', padding: '12px' }}>
                          Need directions or order changes? Send a message to operations.
                        </div>
                      ) : (
                        chatMessages.map((m) => (
                          <div
                            key={m._id}
                            style={{
                              alignSelf: m.senderRole === 'admin' ? 'flex-start' : 'flex-end',
                              background: '#FFFFFF',
                              border: `1px solid ${m.senderRole === 'admin' ? '#003893' : '#FF6B1A'}`,
                              padding: '6px 10px',
                              borderRadius: '4px',
                              fontSize: '11px',
                              maxWidth: '85%',
                            }}
                          >
                            <span style={{ fontWeight: 700, display: 'block', fontSize: '9px', textTransform: 'uppercase' }}>
                              {m.senderRole === 'admin' ? 'Operations' : 'You'}
                            </span>
                            {m.text}
                          </div>
                        ))
                      )}
                    </div>
                    {chatError && (
                      <div
                        style={{
                          color: '#FF6B1A',
                          fontSize: '11px',
                          marginBottom: '6px',
                          fontWeight: 600,
                          textAlign: 'center',
                        }}
                      >
                        {chatError}
                      </div>
                    )}
                    <form onSubmit={handleSendCustomerMessage} style={{ display: 'flex', gap: '6px' }}>
                      <input
                        type="text"
                        value={chatInput}
                        onChange={(e) => setChatInput(e.target.value)}
                        placeholder="Message store..."
                        style={{ flex: 1, minHeight: '34px', fontSize: '11px' }}
                      />
                      <button type="submit" className="btn btn-primary btn-sm" style={{ minHeight: '34px', padding: '0 14px' }}>
                        Send
                      </button>
                    </form>
                  </div>

                  {/* Centered Tracking Quick Actions */}
                  <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                    <button
                      type="button"
                      onClick={() => setActiveTab('home')}
                      className="btn btn-secondary btn-sm"
                      style={{ flex: 1, fontSize: '11px' }}
                    >
                      Browse Catalog
                    </button>
                    <a
                      href="tel:+9779800000000"
                      className="btn btn-secondary btn-sm"
                      style={{ flex: 1, fontSize: '11px', textAlign: 'center', color: '#003893', borderColor: '#003893' }}
                    >
                      Call Dispatch
                    </a>
                  </div>
                </div>
              )}

              {/* Full Customer Support Chat Screen */}
              {activeTab === 'chat' && (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: '#F8FAFC', overflow: 'hidden' }}>
                  <div style={{ padding: '10px 14px', background: '#FFFFFF', borderBottom: '1px solid #D1D5DB', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893' }}>
                        Store Operations Chat
                      </div>
                      <div style={{ fontSize: '10px', color: '#16A34A', fontWeight: 600 }}>
                        ● Admin Dispatch Online
                      </div>
                    </div>
                    {activeOrder ? (
                      <span className="badge badge-brand" style={{ fontSize: '10px' }}>
                        Order #{activeOrder.orderNo}
                      </span>
                    ) : (
                      <span className="badge badge-neutral" style={{ fontSize: '10px' }}>
                        General Inquiry
                      </span>
                    )}
                  </div>

                  {/* Messages Feed */}
                  <div style={{ flex: 1, overflowY: 'auto', padding: '14px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {chatLoading ? (
                      <div style={{ margin: 'auto' }}>
                        <ValleyLoader variant="badge" size="sm" text="Opening your chat with dispatch..." />
                      </div>
                    ) : chatMessages.length === 0 ? (
                      <div style={{ margin: 'auto', textAlign: 'center', color: '#64748B', fontSize: '12px', padding: '20px' }}>
                        <div style={{ marginBottom: '8px', display: 'flex', justifyContent: 'center' }}><ChatIcon size={30} /></div>
                        <div style={{ fontWeight: 700, color: '#1F2A44', marginBottom: '4px' }}>Direct Support Chat</div>
                        <div>Send questions about cold drinks, delivery ETA, or address directions.</div>
                      </div>
                    ) : (
                      chatMessages.map((m) => {
                        const isMe = m.senderRole === 'customer';
                        return (
                          <div
                            key={m._id}
                            style={{
                              alignSelf: isMe ? 'flex-end' : 'flex-start',
                              maxWidth: '82%',
                              background: isMe ? '#FF6B1A' : '#FFFFFF',
                              color: isMe ? '#FFFFFF' : '#1F2A44',
                              border: isMe ? 'none' : '1px solid #D1D5DB',
                              padding: '8px 12px',
                              borderRadius: isMe ? '12px 12px 2px 12px' : '12px 12px 12px 2px',
                              fontSize: '12px',
                              boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
                            }}
                          >
                            <div style={{ fontSize: '9px', fontWeight: 700, textTransform: 'uppercase', marginBottom: '2px', opacity: 0.85 }}>
                              {isMe ? 'You' : 'Store Admin'}
                            </div>
                            <div>{m.text}</div>
                          </div>
                        );
                      })
                    )}
                  </div>

                  {chatError && (
                    <div
                      role="alert"
                      style={{
                        background: '#FFFFFF',
                        borderTop: '1px solid #EF4444',
                        color: '#EF4444',
                        fontSize: '11px',
                        fontWeight: 600,
                        padding: '6px 12px',
                      }}
                    >
                      {chatError}
                    </div>
                  )}

                  {/* Message Input Box */}
                  <form
                    onSubmit={handleSendCustomerMessage}
                    style={{ padding: '8px 10px', background: '#FFFFFF', borderTop: '1px solid #D1D5DB', display: 'flex', gap: '6px' }}
                  >
                    <input
                      type="text"
                      value={chatInput}
                      onChange={(e) => {
                        setChatInput(e.target.value);
                        if (chatError) setChatError('');
                      }}
                      placeholder="Message store admin..."
                      style={{ flex: 1, minHeight: '36px', fontSize: '12px', padding: '0 12px', borderRadius: '18px', border: '1px solid #D1D5DB' }}
                    />
                    <button
                      type="submit"
                      className="btn btn-primary btn-sm"
                      style={{ minHeight: '36px', padding: '0 14px', borderRadius: '18px' }}
                    >
                      Send
                    </button>
                  </form>
                </div>
              )}

              {/* Centered Mobile Action Dock (Bottom Navigation Bar) */}
              <div
                style={{
                  borderTop: '1px solid #D1D5DB',
                  background: '#FFFFFF',
                  display: 'flex',
                  justifyContent: 'space-around',
                  alignItems: 'center',
                  padding: '6px 4px',
                  minHeight: '52px',
                }}
              >
                <button
                  type="button"
                  onClick={() => setActiveTab('home')}
                  style={{
                    flex: 1,
                    background: 'none',
                    border: 'none',
                    padding: '6px 2px',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    color: activeTab === 'home' ? '#FF6B1A' : '#1F2A44',
                    fontWeight: activeTab === 'home' ? 700 : 500,
                  }}
                >
                  <span style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.3px' }}>
                    Catalog
                  </span>
                  {activeTab === 'home' && (
                    <div style={{ width: '16px', height: '2px', background: '#FF6B1A', borderRadius: '1px' }} />
                  )}
                </button>

                <button
                  type="button"
                  ref={cartTabRef}
                  onClick={() => setActiveTab('cart')}
                  style={{
                    flex: 1,
                    background: 'none',
                    border: 'none',
                    padding: '6px 2px',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    color: activeTab === 'cart' ? '#FF6B1A' : '#1F2A44',
                    fontWeight: activeTab === 'cart' ? 700 : 500,
                    transform: cartPulse ? 'scale(1.18)' : 'scale(1)',
                    transition: 'transform 180ms ease-out',
                  }}
                >
                  <span style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.3px' }}>
                    Cart ({cart.length})
                  </span>
                  {activeTab === 'cart' && (
                    <div style={{ width: '16px', height: '2px', background: '#FF6B1A', borderRadius: '1px' }} />
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => setActiveTab('chat')}
                  style={{
                    flex: 1,
                    background: 'none',
                    border: 'none',
                    padding: '6px 2px',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    color: activeTab === 'chat' ? '#FF6B1A' : '#1F2A44',
                    fontWeight: activeTab === 'chat' ? 700 : 500,
                  }}
                >
                  <span
                    style={{
                      fontSize: '11px',
                      textTransform: 'uppercase',
                      letterSpacing: '0.3px',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px',
                    }}
                  >
                    Chat
                    {unreadChatCount > 0 && (
                      <span
                        className="unread-count"
                        title={`${unreadChatCount} unread repl${unreadChatCount === 1 ? 'y' : 'ies'} from store admin`}
                      >
                        {unreadChatCount > 99 ? '99+' : unreadChatCount}
                      </span>
                    )}
                  </span>
                  {activeTab === 'chat' && (
                    <div style={{ width: '16px', height: '2px', background: '#FF6B1A', borderRadius: '1px' }} />
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => setActiveTab('maps')}
                  style={{
                    flex: 1,
                    background: 'none',
                    border: 'none',
                    padding: '6px 2px',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    color: activeTab === 'maps' ? '#FF6B1A' : '#1F2A44',
                    fontWeight: activeTab === 'maps' ? 700 : 500,
                  }}
                >
                  <span style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.3px' }}>
                    Maps
                  </span>
                  {activeTab === 'maps' && (
                    <div style={{ width: '16px', height: '2px', background: '#FF6B1A', borderRadius: '1px' }} />
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => setActiveTab('tracking')}
                  style={{
                    flex: 1,
                    background: 'none',
                    border: 'none',
                    padding: '6px 2px',
                    cursor: 'pointer',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    color: activeTab === 'tracking' ? '#003893' : '#1F2A44',
                    fontWeight: activeTab === 'tracking' ? 700 : 500,
                  }}
                >
                  <span style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.3px' }}>
                    {activeOrder ? 'Tracking' : 'Orders'}
                  </span>
                  {activeTab === 'tracking' && (
                    <div style={{ width: '16px', height: '2px', background: '#003893', borderRadius: '1px' }} />
                  )}
                </button>
              </div>
            </div>
          )}

          {/* SCREEN CONTENT: RIDER FLOW */}
          {role === 'rider' && (
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
              <div
                style={{
                  padding: '12px',
                  borderBottom: '1px solid #D1D5DB',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  background: '#FFFFFF',
                }}
              >
                <div>
                  <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#1F2A44' }}>
                    Rider Partner
                  </div>
                  <div style={{ fontSize: '13px', fontWeight: 700, color: '#003893' }}>
                    Ramesh Thapa (BA 92 PA 1234)
                  </div>
                </div>

                <button
                  onClick={() => setIsRiderOnline(!isRiderOnline)}
                  className={`badge ${isRiderOnline ? 'badge-brand' : 'badge-neutral'}`}
                  style={{ cursor: 'pointer', background: '#FFFFFF' }}
                >
                  {isRiderOnline ? 'Online on Duty' : 'Offline'}
                </button>
              </div>

              <div style={{ flex: 1, overflowY: 'auto', padding: '14px' }}>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893', marginBottom: '12px' }}>
                  Assigned Delivery Jobs ({riderOrders.length})
                </div>

                {riderOrders.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '36px', color: '#1F2A44', fontSize: '12px' }}>
                    No assigned active orders right now. Ready for dispatch!
                  </div>
                ) : (
                  riderOrders.map((order) => (
                    <div
                      key={order._id}
                      style={{
                        border: '1px solid #D1D5DB',
                        borderRadius: '4px',
                        padding: '12px',
                        marginBottom: '10px',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                        <span style={{ fontWeight: 700, color: '#003893' }}>{order.orderNo}</span>
                        {order.paymentStatus === 'paid' ? (
                          <span style={{ fontWeight: 700, color: '#16A34A', fontSize: '11px', background: '#DCFCE7', padding: '2px 6px', borderRadius: '4px' }}>
                            PREPAID ({order.paymentMethod?.toUpperCase() || 'ONLINE'})
                          </span>
                        ) : (
                          <span style={{ fontWeight: 700, color: '#FF6B1A' }}>
                            Collect: Rs. {order.total}
                          </span>
                        )}
                      </div>

                      <div style={{ fontSize: '12px', fontWeight: 500 }}>
                        Customer: {order.customer?.name} ({order.customer?.phone})
                      </div>
                      <div style={{ fontSize: '11px', color: '#1F2A44', margin: '4px 0' }}>
                        Drop-off: {order.deliveryAddress?.addressText || order.address?.addressText}
                      </div>

                      {order.containsAlcohol && (
                        <div style={{ fontSize: '11px', color: '#FF6B1A', fontWeight: 700, marginBottom: '8px' }}>
                          Mandatory: Inspect customer 18+ physical ID at door.
                        </div>
                      )}

                      <div style={{ display: 'flex', gap: '6px', marginTop: '8px', flexWrap: 'wrap' }}>
                        <button
                          type="button"
                          onClick={() => {
                            const coords = order.deliveryAddress?.location?.coordinates || [85.33, 27.728];
                            window.open(
                              `https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}`,
                              '_blank'
                            );
                          }}
                          className="btn btn-secondary btn-sm"
                          style={{ fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px' }}
                          title="Open turn-by-turn navigation in Google Maps"
                        >
                          <NavigationIcon size={13} /> Navigation
                        </button>
                        <a
                          href={`tel:${order.customer?.phone || '9841234567'}`}
                          className="btn btn-secondary btn-sm"
                          style={{ fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', textDecoration: 'none' }}
                        >
                          <PhoneIcon size={13} /> Call
                        </a>
                        {order.status === 'rider_assigned' && (
                          <button
                            onClick={() => handleRiderAction(order._id, 'picked_up')}
                            className="btn btn-primary btn-sm"
                            style={{ flex: 1 }}
                          >
                            Mark Picked Up
                          </button>
                        )}
                        {order.status === 'picked_up' && (
                          <button
                            onClick={() => handleRiderAction(order._id, 'on_the_way')}
                            className="btn btn-brand btn-sm"
                            style={{ flex: 1 }}
                          >
                            Mark En Route
                          </button>
                        )}
                        {['picked_up', 'on_the_way'].includes(order.status) && (
                          <button
                            onClick={() => handleRiderAction(order._id, 'delivered')}
                            className="btn btn-secondary btn-sm"
                            style={{ flex: 1, borderColor: '#003893', color: '#003893' }}
                          >
                            {order.paymentStatus === 'paid' ? 'Confirm Delivery (Prepaid)' : 'Confirm Delivery & Cash'}
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* Order placement: hold the screen with the branded loader so the
              customer sees the order being sent rather than a dead button */}
          {placingOrder && (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                background: 'rgba(255, 255, 255, 0.94)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                zIndex: 25,
              }}
            >
              <ValleyLoader
                variant="orbit"
                size="lg"
                text="Sending your order to the Valley hub..."
              />
            </div>
          )}

          {/* Add-to-cart flight markers */}
          {flyers.map((f) => (
            <span
              key={f.id}
              className="cart-flyer"
              style={{
                left: `${f.x0}px`,
                top: `${f.y0}px`,
                '--fly-x': `${f.x1 - f.x0}px`,
                '--fly-y': `${f.y1 - f.y0}px`,
              }}
            />
          ))}

          {/* Product detail sheet, slides over the phone screen */}
          {detailProduct && (
            <ProductDetailSheet
              product={detailProduct}
              onClose={() => setDetailProduct(null)}
              onAdd={(qty, sourceEl) => {
                for (let i = 0; i < qty; i += 1) {
                  // Only the first add flies, so the screen does not swarm
                  addToCart(detailProduct, i === 0 ? sourceEl : undefined);
                }
                setDetailProduct(null);
                showToast(
                  `${qty} × ${detailProduct.name} added to basket`,
                  'success'
                );
              }}
            />
          )}
        </div>
        </div>
      </div>

      {/* Full Interactive Map Address Selector Modal (Pathao / Yango Flow) */}
      {showMapPicker && (
        <MapAddressPicker
          initialLocation={deliveryLocation}
          onConfirm={(newLoc) => {
            setDeliveryLocation(newLoc);
            setShowMapPicker(false);
          }}
          onClose={() => setShowMapPicker(false)}
          isModal={true}
        />
      )}
    </>
  );
};

export default MobilePreview;
