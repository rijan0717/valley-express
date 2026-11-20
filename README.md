# Valley Express
### Kathmandu Valley Fast Delivery Platform: Snacks, Soft Drinks, Ice, Mixers and Essentials

Valley Express is an on-demand quick-delivery platform built for Kathmandu Valley (Kathmandu, Lalitpur, and Bhaktapur). Customers order snacks, soft drinks, ice, mixers, and essentials from their phone. Riders deliver on bikes and scooters. Admin manages operations from a desktop web dashboard. An alcohol category exists in the system but stays disabled until the store liquor licence is issued.

---

## Monorepo Structure

```
C:\valley express\
|-- backend/          # Node.js, Express, MongoDB REST API & Socket.io Server (Port 5000)
|-- admin-web/        # React 18, Vite Admin Operations Dashboard & Live Order Board (Port 5173)
|-- mobile-app/       # Flutter Cross-Platform App (Customer and Rider roles)
|-- docs/             # Technical Architecture, Features Status & Schema Documentation
|-- start_dev.bat     # One-click launcher script for MongoDB, API & Web Dashboard
`-- README.md
```

---

## Quick Start

Run [`start_dev.bat`](file:///C:/valley%20express/start_dev.bat) in `C:\valley express\` or run the services individually:

### 1. Database & Backend API
```powershell
# 1. MongoDB Daemon runs on port 27017 with data in:
"C:\Program Files\MongoDB\Server\8.3\bin\mongod.exe" --dbpath "C:\valley express\backend\data\db" --port 27017

# 2. Launch the backend API & Socket.io:
cd "C:\valley express\backend"
npm run dev
# Server running at http://localhost:5000
# Health check: http://localhost:5000/health
```

### 2. Admin Web Application
```powershell
cd "C:\valley express\admin-web"
npm run dev
# Dashboard running at http://localhost:5173
```
- **Admin Credentials:**
  - Email: `admin@gmail.com`
  - Password: `Password@123`
  - Role: `admin`

### 3. Mobile App (Flutter & Web Simulator)
- **Interactive Web Simulator:** Open `http://localhost:5173/mobile-preview` in your browser to test both **Customer** and **Rider** flows connected to MongoDB and Socket.io.
- **Flutter Native Mobile:**
```powershell
cd "C:\valley express\mobile-app"
flutter pub get
flutter run
```

---

## Implemented Features & Modules

### Admin Web Dashboard (`admin-web`)
1. **Live Order Kanban Board (`/orders`)**:
   - Status progression: `Placed` -> `Accepted` -> `Preparing` -> `Rider Assigned` -> `Picked Up` -> `On The Way` -> `Delivered` (plus `Cancelled`).
   - Real-time updates via Socket.io events (`order:new`, `order:status`).
   - Assign Rider modal, Cancel Order, and Delete Order actions.
2. **Operations Dashboard (`/`)**:
   - Live KPI cards: Total Revenue, Active Orders, Riders on Duty, Pending Dispatch.
   - One-click legal alcohol compliance master switch.
   - Live incoming order stream with immediate audio-visual notification.
3. **Products & Inventory (`/products`)**:
   - Real MongoDB Product CRUD (Add, Edit, Delete, Stock increment/decrement).
   - Category CRUD modal (Add, Edit, Delete categories directly from dashboard).
   - Price, discount, unit, stock, and alcohol restriction indicators.
4. **Coupons & Deals (`/offers`)**:
   - Real MongoDB Offer CRUD (Create code, Edit details, Toggle active status, Delete).
   - Validation against order minimums and percentage caps.
5. **Riders Fleet & Map Radar (`/riders`)**:
   - Real MongoDB Rider CRUD (Add rider, Edit contact/vehicle details, Delete, Toggle duty).
   - Live Kathmandu GPS coordinates plotted on radar with online indicators.
6. **Customer Support Chat (`/chat`)**:
   - Two-way customer order chat inbox with persistent message history stored in MongoDB.
7. **Store & Regulatory Settings (`/settings`)**:
   - Central Alcohol Compliance switch (disables alcohol category globally on backend).
   - Store open/closed toggle, delivery fee rules, free delivery threshold, and support contacts.
8. **Mobile App Preview Simulator (`/mobile-preview`)**:
   - Interactive phone simulator testing full checkout, live order tracking, and rider job fulfillment directly against the backend.
   - **Open API Map Address Selector**: Interactive Leaflet / OpenStreetMap address picker with Kathmandu search autocomplete, draggable pin marker, and 1-tap area quick chips (like Pathao & Yango).

---

### Mobile Application (`mobile-app`)
1. **Role-Based Routing**:
   - Single application binary automatically routes to Customer or Rider UI based on user role.
2. **Customer Journey**:
   - **Splash Screen**: Animated Valley Express logo loader.
   - **Phone Login & OTP Verification**: Phone login with rate-limited OTP.
   - **Interactive Map Address Picker (Open API / OpenStreetMap)**:
     - Search & select any Kathmandu Valley chowk, street, or landmark with instant autocomplete.
     - Draggable center drop-off pin marker (Pathao / Yango style) with automatic reverse-geocoding.
     - Quick-select chips for popular hubs (Baluwatar, Thamel, Jhamsikhel, Patan Durbar, New Baneshwor, etc.).
     - Live GPS location centering.
   - **Catalog & Category Filter**: Snacks, Soft Drinks, Ice, Mixers, and regulatory-controlled Alcohol.
   - **Cart & Checkout**: Real-time coupon calculation (`VALLEYFIRST`, `MIDNIGHT50`), live drop-off address card with map pin coordinates, landmark notes, and **18+ legal age verification confirmation**.
   - **Live Order Tracking**: 7-stage order status stepper with live Socket.io updates and OpenStreetMap drop-off destination map card.
3. **Rider Partner Journey**:
   - **Online / Offline Duty Switch**: Updates availability in dispatch pool.
   - **Active Delivery Cards**: Customer address, landmark, contact phone, cash collection amount, and 1-tap "Map Route" button opening customer coordinates on OpenStreetMap.
   - **Status Progression Buttons**: Large touch targets (>= 56px) for one-handed outdoor operation.

---

## Design System Tokens
- Background: `#FFFFFF`
- Text: `#1F2A44`
- Accent (Orange): `#FF6B1A`
- Brand Blue (Nepal Flag Blue): `#003893`
- Border: `#D1D5DB`
- Typography: Headings Poppins (700), Body Poppins (400, 500)
- Styling rules: No gradients, no glow, no glassmorphism, no decorative shadows, zero emojis.
