# Valley Express System Architecture & Implementation Blueprint

## 1. Executive Overview

**Valley Express** is an on-demand quick-commerce delivery platform designed for fast food, snacks (chips, bites, appetizers), soft drinks, and alcohol (beers, wines, spirits).

The system consists of three coordinated software layers:
1. **Flutter Mobile Application**: A single binary with dynamic role-based interfaces for **Customers** and **Riders**.
2. **React Admin Web Application**: An operations command center for store managers and admins to track orders in real time, view rider locations on a live map, and reply instantly to customer support chat.
3. **Node.js/Express + Socket.io + MongoDB Backend**: The central engine coordinating REST transactions, real-time WebSockets, push notifications (FCM), geospatial queries, and SMS OTP verification.

---

## 2. Mobile Application Architecture (Customer & Rider)

The mobile app is written in **Flutter (Dart)** to achieve high performance on Android (priority for riders and local market) and iOS.

### 2.1 Role-Based Routing Architecture
A single application handles both Customer and Rider personas to reduce app store maintenance overhead:
```
                                 [ App Launch ]
                                       │
                                [ Splash Screen ]
                                       │
                         [ Check Auth State & Token ]
                                ┌──────┴──────┐
                             No Token      Valid Token
                                │             │
                        [ Phone OTP Login ]   │
                                │             │
                    ┌───────────┴─────────────┴───────────┐
                    │                                     │
            role == 'customer'                     role == 'rider'
                    │                                     │
           [ Customer Shell ]                      [ Rider Shell ]
       - Home (Beers, Snacks, Food)            - Duty Toggle (Online/Offline)
       - Offers & Search                       - New Order Incoming Alerts
       - Cart & Checkout                       - GPS Tracking Heartbeat
       - Real-time Order Tracking              - Step Status Actions
       - Direct Chat with Admin                - Route Navigation
```

### 2.2 Customer Experience & Features
1. **Age Verification & Compliance**:
   - At onboarding, users must declare they are of legal drinking age (18+ or 21+).
   - If the backend setting `alcoholEnabled` is set to `false` (e.g. while awaiting liquor license), alcohol categories are automatically hidden from the catalog, displaying only fast food, chips, and non-alcoholic drinks.
2. **Catalog & Combos**:
   - Fast food combos (e.g., Beer + Fried Chicken wings, Chips + Dip + Chilled Soda).
   - Dynamic search, filters by temperature (Chilled / Room Temp), brand, alcohol volume (ABV), and dietary tags.
3. **Offers & Promo Engine**:
   - Promo codes (e.g., `FIRST50`, `WEEKENDPARTY`) verified on the server for minimum spend and expiration.
4. **Checkout & Geolocation**:
   - Integrated Google Maps address picker with draggable pin + automatic reverse geocoding.
   - House number / Landmark input (vital for Kathmandu Valley navigation).
   - Payment options: Cash On Delivery (COD) as default; eSewa / Khalti / Fonepay ready.
5. **Real-time Order Tracker**:
   - Progress Stepper: `Placed` → `Accepted` → `Preparing` → `Rider Assigned` → `On The Way` → `Delivered`.
   - Live Map showing the store location, customer pin, and the Rider's moving motorcycle marker updated every 5–10 seconds.
6. **In-App Customer Support Chat**:
   - Customers can open a real-time chat with the store admin directly from their active order screen.
   - Ideal for order modifications ("Please add extra napkins", "Do you have ice?"), address clarifications, and delivery updates.

### 2.3 Rider Experience & Features
1. **Online/Offline Shift Toggle**:
   - Riders flip an availability switch. When active, their coordinates ping the server and make them eligible for auto-assignment or manual dispatch.
2. **Incoming Order Dispatch Alert**:
   - Audio ringtone and vibrating full-screen modal showing pickup distance, dropoff landmark, estimated payout, and items.
3. **Turn-by-Turn Navigation**:
   - Deep-linking into Google Maps / Apple Maps from the current rider position to the store, and from store to customer dropoff.
4. **Order State Lifecycle Actions**:
   - Single-button transition:
     - `Accept Order`
     - `Arrived at Store`
     - `Order Picked Up`
     - `Start Delivery (On The Way)`
     - `Delivered (with Doorstep Age Check Confirmation)`
5. **Background Location Service**:
   - High-accuracy background GPS sender that emits `rider:location` socket events and HTTP fallback pings to the server.

---

## 3. Admin Web Application Architecture

The Admin Web App is built using **React (Vite)**, **React Router**, **Tailwind CSS**, and **Socket.io Client**. It serves as the operations bridge connecting store staff, inventory, riders, and customers.

### 3.1 Live Order Kanban Board
- Columns represent real-time states:
  1. **New Incoming Orders** (flashes red, triggers audible ding on `order:new` socket event).
  2. **Accepted & Preparing** (kitchen / packing staff assemble fast food and chill drinks).
  3. **Ready for Pickup** (assign rider dropdown or auto-dispatch).
  4. **Out for Delivery** (live ETA and active rider info).
  5. **Completed / Cancelled**.
- Instant action buttons: `Accept`, `Reject`, `Assign Rider`, `Cancel`.

### 3.2 Live Customer Chat & Text Reply Center
- Built-in two-way messaging center (similar to a WhatsApp Web dashboard):
  - Left pane: Active order conversations, sorted by newest incoming unread message with customer name and order number.
  - Right pane: Full conversation thread with timestamps and status indicators.
  - Instant text reply box with quick canned responses ("Your order is being packed!", "Rider will reach in 10 mins").
  - Sends immediate Socket.io message to the customer's phone and triggers a Firebase Push Notification if the customer has minimized the app.

### 3.3 Live Rider Dispatch & Tracking Map
- Full Google Map view of Kathmandu Valley showing:
  - Valley Express Hub / Dark store location.
  - Active riders with green (idle) or blue (on delivery) icons.
  - Customer dropoff pins with order route lines.

### 3.4 Store & Alcohol Compliance Controls
- **Alcohol Master Switch (`alcoholEnabled`)**:
  - One-click toggle in Settings.
  - When disabled: API prevents alcohol items from returning in customer app queries and blocks any checkout containing alcoholic SKU IDs.
- **Store Hours & Surge Delivery Fee**:
  - Set opening and closing hours.
  - Configure rain or late-night delivery surcharges per kilometer.

---

## 4. Real-Time Communication Pipeline (Socket.io)

### Room Management
- `room:admin`: All authenticated admin dashboards join this room.
- `room:order_{orderId}`: Joined by customer, assigned rider, and admin handling this order.
- `room:rider_{riderId}`: Dedicated channel for dispatching alerts to specific riders.
- `room:user_{userId}`: Dedicated channel for user-specific account notifications.

### Event Matrix

| Event Name | Direction | Payload | Description |
| :--- | :--- | :--- | :--- |
| `order:new` | Server → `room:admin` | `{ order }` | Audio ping on admin web dashboard when customer checks out. |
| `order:assigned` | Server → `room:rider_{id}` | `{ orderId, pickup, dropoff }` | Alert rider of new delivery assignment. |
| `order:status_update`| Server → `room:order_{id}` | `{ orderId, status, timestamp }` | Updates stepper in mobile app and moves card on admin kanban. |
| `rider:location_update`| Rider → Server → `room:order_{id}` & `room:admin` | `{ orderId, riderId, lat, lng, heading }` | Moves rider marker on customer and admin maps. |
| `chat:send_message` | Customer/Admin → Server | `{ orderId, text, senderRole }` | Delivers real-time message to the other party. |
| `chat:new_message` | Server → `room:order_{id}` | `{ messageId, text, sender, time }` | Renders message bubble in mobile app / admin chat panel. |

---

## 5. Push Notification Architecture (Firebase Cloud Messaging - FCM)

Push notifications wake up devices when the app is in the background or killed:
1. **Order Placed**: Customer gets receipt confirmation.
2. **Order Dispatched**: "Your rider [Rider Name] is on the way with your food & drinks!"
3. **Rider Arriving**: "Your rider is 2 minutes away. Please be ready with payment/ID."
4. **Chat Message**: When admin replies to a customer query, an instant FCM push delivers the preview.
5. **Flash Deals**: Targeted promotional pushes (e.g., "Chilled Beer & Wings combo 20% off tonight!").
