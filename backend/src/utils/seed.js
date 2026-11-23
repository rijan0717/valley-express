require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Category = require('../models/Category');
const Product = require('../models/Product');
const User = require('../models/User');
const Setting = require('../models/Setting');
const Offer = require('../models/Offer');
const Order = require('../models/Order');

const seedData = async () => {
  try {
    // See src/config/db.js: the IPv4 loopback is explicit because mongod
    // binds only 127.0.0.1 while "localhost" may resolve to ::1 first.
    const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/valley_express';
    await mongoose.connect(mongoUri);
    console.log('[Seed] Connected to MongoDB for seeding');

    // Clear existing data
    await Promise.all([
      Category.deleteMany({}),
      Product.deleteMany({}),
      User.deleteMany({}),
      Setting.deleteMany({}),
      Offer.deleteMany({}),
      Order.deleteMany({}),
    ]);

    // 1. Settings
    const setting = await Setting.create({
      alcoholEnabled: true, // Enabled for testing convenience, switchable anytime
      storeOpen: true,
      serviceHours: { open: '10:00', close: '02:00' },
      defaultDeliveryFee: 100,
      freeDeliveryThreshold: 1500,
      surgeFeePerKm: 25,
      contactPhone: '+977-9801234567',
      contactEmail: 'orders@valleyexpress.com.np',
    });
    console.log('[Seed] Settings created');

    // 2. Users (Admin, Riders, Customer)
    const adminPasswordHash = await bcrypt.hash('Password@123', 10);
    const admin = await User.create({
      phone: '9800000000',
      name: 'Valley Operations Admin',
      email: 'admin@gmail.com',
      password: adminPasswordHash,
      role: 'admin',
      ageConfirmed: true,
    });

    const riderPasswordHash = await bcrypt.hash('Rider@123', 10);
    const rider1 = await User.create({
      phone: '9811111111',
      name: 'Ramesh Thapa',
      password: riderPasswordHash,
      role: 'rider',
      isOnline: true,
      vehicleNumber: 'BA 92 PA 1234',
      vehicleType: 'Motorcycle',
      currentCoordinates: [85.3240, 27.7172], // Kathmandu Durbar Marg
    });

    const rider2 = await User.create({
      phone: '9822222222',
      name: 'Bikash Shrestha',
      password: riderPasswordHash,
      role: 'rider',
      isOnline: true,
      vehicleNumber: 'BA 88 PA 5678',
      vehicleType: 'Scooter',
      currentCoordinates: [85.3150, 27.6980], // Lalitpur Jhamsikhel
    });

    const customer = await User.create({
      phone: '9841234567',
      name: 'Prajina Maharjan',
      password: await bcrypt.hash('Customer@123', 10),
      email: 'prajina@example.com',
      role: 'customer',
      ageConfirmed: true,
      addresses: [
        {
          label: 'Home',
          addressText: 'Baluwatar, near Russian Embassy',
          landmark: 'House #42, White gate',
          location: { type: 'Point', coordinates: [85.3300, 27.7280] },
          isDefault: true,
        },
      ],
    });
    console.log('[Seed] Users created');

    // 3. Categories
    const catBeers = await Category.create({
      name: 'Beers & Ciders',
      nameNe: 'बियर तथा साइडर',
      slug: 'beers-ciders',
      icon: '',
      isRestricted: true,
      sortOrder: 1,
    });

    const catWhiskey = await Category.create({
      name: 'Whiskey & Spirits',
      nameNe: 'ह्विस्की र रक्सी',
      slug: 'whiskey-spirits',
      icon: '',
      isRestricted: true,
      sortOrder: 2,
    });

    const catFastFood = await Category.create({
      name: 'Fast Food & Momos',
      nameNe: 'फास्ट फुड र मःम',
      slug: 'fast-food',
      icon: '',
      isRestricted: false,
      sortOrder: 3,
    });

    const catSnacks = await Category.create({
      name: 'Snacks & Chips',
      nameNe: 'स्न्याक्स तथा चिप्स',
      slug: 'snacks-chips',
      icon: '',
      isRestricted: false,
      sortOrder: 4,
    });

    const catBeverages = await Category.create({
      name: 'Soft Drinks & Energy',
      nameNe: 'कोल्ड ड्रिंक्स',
      slug: 'beverages',
      icon: '',
      isRestricted: false,
      sortOrder: 5,
    });
    console.log('[Seed] Categories created');

    // 4. Products
    const products = await Product.create([
      {
        name: 'Gorkha Premium Beer (650ml)',
        nameNe: 'गोर्खा प्रिमियम बियर',
        description: 'Smooth brewed authentic Nepalese beer with 5% ABV. Best served chilled.',
        category: catBeers._id,
        price: 380,
        stock: 50,
        unit: '650ml bottle',
        images: ['https://images.unsplash.com/photo-1608270199042-359f4b50035d?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: true,
        alcoholPercentage: 5.0,
        isFeatured: true,
      },
      {
        name: 'Tuborg Classic Premium Strong (650ml)',
        nameNe: 'टुबोर्ग क्लासिक बियर',
        description: 'Rich malty character brewed for high strength and smooth taste.',
        category: catBeers._id,
        price: 410,
        stock: 45,
        unit: '650ml bottle',
        images: ['https://images.unsplash.com/photo-1535958636474-b021ee887b13?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: true,
        alcoholPercentage: 6.5,
        isFeatured: true,
      },
      {
        name: 'Old Durbar Black Chimney Whiskey (750ml)',
        nameNe: 'ओल्ड दरबार ब्ल्याक चिम्नी',
        description: 'Masterfully blended peated malt scotch finished in charred oak barrels.',
        category: catWhiskey._id,
        price: 3600,
        stock: 20,
        unit: '750ml bottle',
        images: ['https://images.unsplash.com/photo-1527281400683-1aae777175f8?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: true,
        alcoholPercentage: 42.8,
        isFeatured: true,
      },
      {
        name: 'Khukri XXX Rum (750ml)',
        nameNe: 'खुकुरी रम',
        description: 'The Pride of Nepal. Dark spiced molasses rum with Himalayan herbs.',
        category: catWhiskey._id,
        price: 1850,
        stock: 30,
        unit: '750ml bottle',
        images: ['https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: true,
        alcoholPercentage: 42.8,
        isFeatured: false,
      },
      {
        name: 'Steamed Chicken Momo (10 pcs)',
        nameNe: 'चिकेन स्टीम मःम',
        description: 'Juicy Himalayan minced chicken dumplings served with spicy tomato sesame jhol achar.',
        category: catFastFood._id,
        price: 240,
        stock: 100,
        unit: 'Plate (10 pcs)',
        images: ['https://images.unsplash.com/photo-1625220194771-7ebdea0b70b9?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: true,
      },
      {
        name: 'Spicy Buff C-Momo (10 pcs)',
        nameNe: 'बफ सि-मःम',
        description: 'Crispy fried buff momo tossed in fiery wok chili sauce with bell peppers and onions.',
        category: catFastFood._id,
        price: 260,
        stock: 80,
        unit: 'Plate (10 pcs)',
        images: ['https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: true,
      },
      {
        name: 'Crispy Fried Chicken Wings (6 pcs)',
        nameNe: 'क्रिस्पी चिकेन विंग्स',
        description: 'Golden spiced battered chicken wings with Valley Express hot dip.',
        category: catFastFood._id,
        price: 390,
        stock: 40,
        unit: 'Plate (6 pcs)',
        images: ['https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: true,
      },
      {
        name: 'Lay\'s India\'s Magic Masala (Large)',
        nameNe: 'लेज म्याजिक मसाला चिप्स',
        description: 'Crispy potato wafers tossed with robust aromatic Indian spices.',
        category: catSnacks._id,
        price: 80,
        stock: 120,
        unit: '115g pack',
        images: ['https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: false,
      },
      {
        name: 'Kurkure Masala Munch (Large)',
        nameNe: 'कुरकुरे मसाला मन्च',
        description: 'Crunchy corn puffs seasoned with authentic tangy spice blend.',
        category: catSnacks._id,
        price: 60,
        stock: 150,
        unit: '90g pack',
        images: ['https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: false,
      },
      {
        name: 'Pringles Sour Cream & Onion (107g)',
        nameNe: 'प्रिंगल्स चिप्स',
        description: 'Iconic curved potato crisps loaded with savory sour cream and herb aroma.',
        category: catSnacks._id,
        price: 290,
        stock: 60,
        unit: 'Can 107g',
        images: ['https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: false,
      },
      {
        name: 'Red Bull Energy Drink (250ml)',
        nameNe: 'रेड बुल इनर्जी ड्रिंक',
        description: 'Vitalizes body and mind with premium taurine, B-group vitamins, and caffeine.',
        category: catBeverages._id,
        price: 190,
        stock: 90,
        unit: 'Can 250ml',
        images: ['https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: true,
      },
      {
        name: 'Coca-Cola Pet Bottle (2.25L)',
        nameNe: 'कोका-कोला २.२५ लिटर',
        description: 'Classic refreshing bubbly cola. Party size bottle for get-togethers.',
        category: catBeverages._id,
        price: 220,
        stock: 75,
        unit: '2.25L Bottle',
        images: ['https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=500&q=80'],
        isAlcohol: false,
        isFeatured: false,
      },
    ]);
    console.log('[Seed] Products created');

    // 5. Offers
    await Offer.create([
      {
        code: 'VALLEYFIRST',
        title: 'Welcome to Valley Express!',
        description: 'Get 15% discount up to Rs. 200 on orders above Rs. 500',
        discountType: 'percentage',
        discountValue: 15,
        minOrderAmount: 500,
        maxDiscountAmount: 200,
        startDate: new Date(),
        endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'MIDNIGHT50',
        title: 'Late Night Cravings',
        description: 'Flat Rs. 50 discount on quick snacks & drinks after 9:00 PM',
        discountType: 'flat',
        discountValue: 50,
        minOrderAmount: 400,
        startDate: new Date(),
        endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
    ]);
    console.log('[Seed] Offers created');

    // 6. Sample Live Orders for Kanban UI
    const order1 = await Order.create({
      orderNo: 'VX-10842',
      customer: customer._id,
      rider: rider1._id,
      items: [
        { product: products[0]._id, name: products[0].name, price: 380, quantity: 2, isAlcohol: true },
        { product: products[4]._id, name: products[4].name, price: 240, quantity: 2, isAlcohol: false },
        { product: products[7]._id, name: products[7].name, price: 80, quantity: 2, isAlcohol: false },
      ],
      subtotal: 1400,
      deliveryFee: 100,
      discount: 0,
      total: 1500,
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'pending',
      deliveryAddress: {
        addressText: 'Baluwatar, near Russian Embassy',
        landmark: 'House #42, White gate',
        location: { type: 'Point', coordinates: [85.3300, 27.7280] },
        contactPhone: customer.phone,
      },
      status: 'on_the_way',
      statusHistory: [
        { status: 'placed', timestamp: new Date(Date.now() - 30 * 60 * 1000), note: 'Order placed' },
        { status: 'accepted', timestamp: new Date(Date.now() - 25 * 60 * 1000), note: 'Kitchen accepted' },
        { status: 'preparing', timestamp: new Date(Date.now() - 20 * 60 * 1000), note: 'Food & drinks packed' },
        { status: 'rider_assigned', timestamp: new Date(Date.now() - 15 * 60 * 1000), note: 'Ramesh Thapa assigned' },
        { status: 'picked_up', timestamp: new Date(Date.now() - 10 * 60 * 1000), note: 'Package in delivery bag' },
        { status: 'on_the_way', timestamp: new Date(Date.now() - 5 * 60 * 1000), note: 'Rider heading to Baluwatar' },
      ],
      ageCheckedAtDoor: false,
    });

    const order2 = await Order.create({
      orderNo: 'VX-10843',
      customer: customer._id,
      items: [
        { product: products[2]._id, name: products[2].name, price: 3600, quantity: 1, isAlcohol: true },
        { product: products[9]._id, name: products[9].name, price: 290, quantity: 2, isAlcohol: false },
      ],
      subtotal: 4180,
      deliveryFee: 0, // Free delivery > 1500
      discount: 200,
      total: 3980,
      paymentMethod: 'esewa',
      paymentStatus: 'paid',
      deliveryAddress: {
        addressText: 'Naxal, Kathmandu',
        landmark: 'Opposite Marriott Hotel',
        location: { type: 'Point', coordinates: [85.3260, 27.7140] },
        contactPhone: customer.phone,
      },
      status: 'preparing',
      statusHistory: [
        { status: 'placed', timestamp: new Date(Date.now() - 12 * 60 * 1000), note: 'Order placed' },
        { status: 'accepted', timestamp: new Date(Date.now() - 8 * 60 * 1000), note: 'Order accepted' },
        { status: 'preparing', timestamp: new Date(Date.now() - 3 * 60 * 1000), note: 'Order being packed' },
      ],
      ageCheckedAtDoor: false,
    });

    const order3 = await Order.create({
      orderNo: 'VX-10844',
      customer: customer._id,
      items: [
        { product: products[5]._id, name: products[5].name, price: 260, quantity: 1, isAlcohol: false },
        { product: products[6]._id, name: products[6].name, price: 390, quantity: 1, isAlcohol: false },
        { product: products[10]._id, name: products[10].name, price: 190, quantity: 2, isAlcohol: false },
      ],
      subtotal: 1030,
      deliveryFee: 100,
      discount: 0,
      total: 1130,
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'pending',
      deliveryAddress: {
        addressText: 'Jhamsikhel, Lalitpur',
        landmark: 'Near St. Marys School',
        location: { type: 'Point', coordinates: [85.3120, 27.6760] },
        contactPhone: customer.phone,
      },
      status: 'placed',
      statusHistory: [
        { status: 'placed', timestamp: new Date(Date.now() - 2 * 60 * 1000), note: 'Newly placed' },
      ],
      ageCheckedAtDoor: false,
    });
    console.log('[Seed] Orders created');

    console.log('Seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
};

seedData();
