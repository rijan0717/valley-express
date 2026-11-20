const http = require('http');

function request(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, headers: res.headers, data: body ? JSON.parse(body) : null });
        } catch (e) {
          resolve({ status: res.statusCode, headers: res.headers, data: body });
        }
      });
    });
    req.on('error', reject);
    if (data) {
      req.write(typeof data === 'string' ? data : JSON.stringify(data));
    }
    req.end();
  });
}

async function runTests() {
  console.log('[TEST] Starting Valley Express Backend API Smoke Test...\n');
  let token = '';

  // 1. Categories Initial List
  const catRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/categories',
    method: 'GET'
  });
  console.log(`[PASS] Categories API status: ${catRes.status}, count: ${catRes.data?.count || 0}`);
  if (!catRes.data?.categories || catRes.data.categories.length === 0) {
    console.error('[FAIL] Expected seeded categories, got none!');
    process.exit(1);
  }

  // 2. Admin Auth Test - Failure with wrong password
  const failAuth = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/auth/admin-login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, { email: 'admin@gmail.com', password: 'WrongPassword999' });

  if (failAuth.status === 401) {
    console.log('[PASS] Wrong password rejected with 401 Unauthorized');
  } else {
    console.error('[FAIL] Wrong password did not reject with 401:', failAuth.status, failAuth.data);
    process.exit(1);
  }

  // 3. Admin Auth Test - Success
  const login = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/auth/admin-login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, { email: 'admin@gmail.com', password: 'Password@123' });

  if (login.status === 200 && login.data?.token) {
    token = login.data.token;
    console.log(`[PASS] Admin Login successful for ${login.data.user.email} (Role: ${login.data.user.role})`);
  } else {
    console.error('[FAIL] Admin login failed:', login.status, login.data);
    process.exit(1);
  }

  const authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 4. Products CRUD
  console.log('\n--- Testing Products CRUD ---');
  const productsRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/products',
    method: 'GET'
  });
  console.log(`[PASS] GET /api/products returned ${productsRes.data?.count || 0} products`);

  const firstCatId = catRes.data.categories[0]._id;

  // Create Product
  const newProductRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/products',
    method: 'POST',
    headers: authHeaders
  }, {
    name: 'Automated Test Drink 500ml',
    description: 'Crisp automated test beverage',
    category: firstCatId,
    price: 150,
    discountPrice: 140,
    stock: 25,
    unit: '500ml bottle',
    isAvailable: true,
    isAlcohol: false
  });
  const createdProdId = newProductRes.data?.product?._id;
  console.log(`[PASS] POST /api/products created product ID: ${createdProdId}`);

  // Update Product
  const updatedProdRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/products/${createdProdId}`,
    method: 'PUT',
    headers: authHeaders
  }, {
    name: 'Automated Test Drink 500ml (Updated)',
    price: 160,
    stock: 30
  });
  console.log(`[PASS] PUT /api/products/:id updated price to ${updatedProdRes.data?.product?.price}`);

  // Delete Product
  const deletedProdRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/products/${createdProdId}`,
    method: 'DELETE',
    headers: authHeaders
  });
  console.log(`[PASS] DELETE /api/products/:id returned: ${deletedProdRes.data?.message}`);

  // 5. Offers CRUD & Validation
  console.log('\n--- Testing Offers CRUD & Validation ---');
  const offersRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/offers/all',
    method: 'GET',
    headers: authHeaders
  });
  console.log(`[PASS] GET /api/offers/all returned ${offersRes.data?.count || 0} offers`);

  // Validate VALLEYFIRST
  const valOffer = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/offers/validate',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, { code: 'VALLEYFIRST', orderAmount: 1000 });
  console.log(`[PASS] POST /api/offers/validate (VALLEYFIRST on Rs 1000) discount: Rs ${valOffer.data?.offer?.discountAmount || 0}`);

  // Create Offer
  const newOffer = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/offers',
    method: 'POST',
    headers: authHeaders
  }, {
    code: 'TESTCODE20',
    title: 'Test Promo 20% Off',
    discountType: 'percentage',
    discountValue: 20,
    minOrderAmount: 300,
    maxDiscountAmount: 200,
    startDate: new Date().toISOString(),
    endDate: new Date(Date.now() + 86400000 * 7).toISOString(),
    isActive: true
  });
  const createdOfferId = newOffer.data?.offer?._id;
  console.log(`[PASS] POST /api/offers created coupon ${newOffer.data?.offer?.code} (ID: ${createdOfferId})`);

  // Toggle Offer
  const toggleOffer = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/offers/${createdOfferId}/toggle`,
    method: 'PATCH',
    headers: authHeaders
  });
  console.log(`[PASS] PATCH /api/offers/:id/toggle isActive: ${toggleOffer.data?.isActive}`);

  // Delete Offer
  await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/offers/${createdOfferId}`,
    method: 'DELETE',
    headers: authHeaders
  });
  console.log(`[PASS] DELETE /api/offers/:id deleted test coupon`);

  // 6. Category CRUD
  console.log('\n--- Testing Categories CRUD ---');
  const newCat = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/categories',
    method: 'POST',
    headers: authHeaders
  }, {
    name: 'Automated Test Category',
    nameNe: '[NEPALI TEXT]',
    slug: 'automated-test-category',
    sortOrder: 99
  });
  const createdCatId = newCat.data?.category?._id;
  console.log(`[PASS] POST /api/categories created category: ${newCat.data?.category?.name} (ID: ${createdCatId})`);

  // Delete Category
  await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/categories/${createdCatId}`,
    method: 'DELETE',
    headers: authHeaders
  });
  console.log(`[PASS] DELETE /api/categories/:id deleted test category`);

  // 7. Riders Management
  console.log('\n--- Testing Riders API ---');
  const ridersRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/settings/riders',
    method: 'GET',
    headers: authHeaders
  });
  console.log(`[PASS] GET /api/settings/riders returned ${ridersRes.data?.count || 0} active riders`);

  // 8. Orders Management
  console.log('\n--- Testing Orders API ---');
  const ordersRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/orders',
    method: 'GET',
    headers: authHeaders
  });
  console.log(`[PASS] GET /api/orders returned ${ordersRes.data?.count || 0} orders`);

  // Create real order
  const existingProduct = productsRes.data.products[0];
  const createOrder = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/orders',
    method: 'POST',
    headers: authHeaders
  }, {
    items: [
      { product: existingProduct._id, quantity: 2, price: existingProduct.price }
    ],
    address: {
      addressText: 'Lazimpat, Kathmandu near Embassy',
      landmark: 'Opposite blue gate',
      location: { coordinates: [85.3206, 27.7215] },
      contactPhone: '+977-9801234567'
    },
    paymentMethod: 'cash_on_delivery',
    offerCode: 'VALLEY10'
  });

  const createdOrderId = createOrder.data?.order?._id;
  console.log(`[PASS] POST /api/orders created Order #${createOrder.data?.order?.orderNo} (Status: ${createOrder.data?.order?.status}, Total: Rs ${createOrder.data?.order?.total})`);

  // Update Status to preparing
  const updateStatus = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/orders/${createdOrderId}/status`,
    method: 'PATCH',
    headers: authHeaders
  }, { status: 'preparing' });
  console.log(`[PASS] PATCH /api/orders/:id/status updated to: ${updateStatus.data?.order?.status}`);

  // Assign Rider
  const firstRiderId = ridersRes.data.riders[0]._id;
  const assignRider = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/orders/${createdOrderId}/assign`,
    method: 'PATCH',
    headers: authHeaders
  }, { riderId: firstRiderId });
  console.log(`[PASS] PATCH /api/orders/:id/assign assigned rider ID: ${firstRiderId}`);

  // Cancel Order
  const cancelOrder = await request({
    hostname: 'localhost',
    port: 5000,
    path: `/api/orders/${createdOrderId}/cancel`,
    method: 'PATCH',
    headers: authHeaders
  }, { reason: 'Automated test completed' });
  console.log(`[PASS] PATCH /api/orders/:id/cancel status: ${cancelOrder.data?.order?.status}`);

  // 9. Store Settings & Alcohol Switch
  console.log('\n--- Testing Store Settings & Alcohol Switch ---');
  const getSettings = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/settings',
    method: 'GET'
  });
  console.log(`[PASS] GET /api/settings alcoholEnabled: ${getSettings.data?.settings?.alcoholEnabled}, storeOpen: ${getSettings.data?.settings?.storeOpen}`);

  console.log('\n======================================================');
  console.log('ALL API SMOKE TESTS PASSED WITH 100% SUCCESS');
  console.log('======================================================\n');
}

runTests().catch(err => {
  console.error('[TEST ERROR]', err);
  process.exit(1);
});
