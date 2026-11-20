# Valley Express
### Kathmandu Valley Fast Delivery Platform: Snacks, Soft Drinks, Ice, Mixers and Essentials

Valley Express is an on-demand quick-delivery platform built for Kathmandu Valley (Kathmandu, Lalitpur, and Bhaktapur). Customers order snacks, soft drinks, ice, mixers, and essentials from their phone. Riders deliver on bikes and scooters. Admin manages operations from a desktop web dashboard. An alcohol category exists in the system but stays disabled until the store liquor licence is issued.

---

## Monorepo Structure

```
valley-express/
|-- backend/          # Node.js, Express, MongoDB REST API & Socket.io Server (Port 5000)
|-- admin-web/        # React 18, Vite Admin Operations Dashboard & Live Order Board (Port 5173)
|-- mobile-app/       # Flutter Cross-Platform App (Customer and Rider roles)
|-- docs/             # Technical Architecture, Features Status & Schema Documentation
|-- start_dev.bat     # One-click launcher script for MongoDB, API & Web Dashboard
`-- README.md
```

---

## Prerequisites

| Tool | Version used | Notes |
| --- | --- | --- |
| Node.js | 22 LTS or newer | npm 10+ |
| MongoDB Server | 8.x | Run as a local daemon on port 27017 |
| Flutter SDK | 3.50+ (Dart 3.14) | Only for the native mobile app |
| Android Studio | Latest, with SDK + licences accepted | Only for Android builds |

The Android build needs **Gradle 9.5 / AGP 9.3** (already configured) because the
JDK bundled with current Android Studio is Java 25. Older Gradle fails with
*"Gradle version is incompatible with the Java version"*.

## Quick Start

Run `start_dev.bat` from the repo root — it locates `mongod.exe`, starts the
database, the API and the dashboard. It works from whatever folder you cloned
into. Or run the services individually:

### 0. One-time setup
```powershell
# Backend environment file
copy backend\.env.example backend\.env     # then set JWT_SECRET

# Dependencies
cd backend    ; npm install
cd ..\admin-web ; npm install
```

Minimum `backend\.env`:
```
PORT=5000
NODE_ENV=development
MONGO_URI=mongodb://localhost:27017/valley_express
JWT_SECRET=<any long random string>
JWT_EXPIRES_IN=7d
```
SMS and payment-gateway keys are optional; without them OTP falls back to a
development sandbox that logs the code to the console and returns it as `devOtp`.

### 1. Database & Backend API
```powershell
# 1. MongoDB daemon on port 27017, data under the repo:
"C:\Program Files\MongoDB\Server\8.3\bin\mongod.exe" --dbpath ".\backend\data\db" --port 27017

# 2. Seed categories, products, offers and the admin account (first run only):
cd backend
npm run seed

# 3. Launch the backend API & Socket.io:
npm run dev
# Server running at http://localhost:5000
# Health check: http://localhost:5000/health
```

> `npm run seed` wipes and recreates all collections. The `backend\data\db`
> directory checked into the repo is not usable — restore it only from a proper
> `mongodump`, never by committing a live WiredTiger directory.

### 2. Admin Web Application
```powershell
cd admin-web
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
cd mobile-app
flutter pub get
flutter run -d chrome          # fastest, no emulator boot
flutter run                    # pick an emulator or attached device
flutter build apk --debug      # build\app\outputs\flutter-apk\app-debug.apk
```
`run_mobile_web.bat` and `run_mobile_android.bat` in the repo root wrap the
last two.

The API host is fixed in `lib/core/constants.dart`: `localhost:5000` on web,
`10.0.2.2:5000` on Android (the emulator's alias for the host machine). A
**physical phone** cannot reach either — point `baseUrl`/`socketUrl` at your
machine's LAN IP and allow inbound 5000 through Windows Firewall.

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
