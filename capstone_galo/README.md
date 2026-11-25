# Canteen Pre-Order App

**Project Name:** Canteen Pre-Order App\
**Project Code:** Capstone Project X5\
**Workstation:** #25

Capstone project X5. Students browse the canteen menu, add items to a cart, and place a pre-order. Canteen staff see the orders live and mark them **Ready**, and the student's screen updates by itself. When the student collects the food, staff mark it **Picked up**.

**Scope:** cash-on-pickup only, a single canteen, and no user accounts (students type their student ID). Android app built with Flutter and Cloud Firestore.

## Features
**Student (default mode)**
- Live menu grouped by category, with sold-out items greyed out
- Bottom navbar: Menu, Orders, Cart (with item count)
- Cart with quantity controls and a running total
- Checkout with student ID and name (remembered on the phone), cash on pickup
- Order status screen with a pickup number (e.g. `#0042`) and a live Pending → Ready → Picked up status
- Cancel an order while it is still Pending
- My Orders: past orders for the saved student ID

**Staff (tap the avatar to open the drawer → Staff Mode, or long-press "School Canteen" in the menu header, then the PIN)**
- Live order queue with Pending and Ready tabs, a **Mark Ready** button, and **Picked up** to clear collected orders
- Menu management: add, edit or delete items and toggle sold-out; "Load sample menu" on an empty menu

## Demo mode (fallback)
The app is connected to the Firebase project `canteen-preorder-6fab0` for Android and Web. On a platform that wasn't configured, it starts with an in-memory database filled with the sample menu and shows a **DEMO DATA** corner banner. Everything works on one device, but that data resets when the app restarts.

## Setup
1. Install Flutter and enable Windows **Developer Mode** (`start ms-settings:developers`), which plugin builds need.
2. The app is already connected (`lib/firebase_options.dart`, `android/app/google-services.json`). These hold public client settings, not secrets, so they are committed. To connect a different Firebase project instead:
   ```sh
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,web
   ```
   `firebase` and `flutterfire` install into `%APPDATA%\npm` and `%LOCALAPPDATA%\Pub\Cache\bin`, so both folders need to be on your PATH.
3. Deploy the security rules. This also creates the Firestore database if it doesn't exist yet:
   ```sh
   firebase deploy --only firestore:rules
   ```
4. Optional: set the staff PIN by creating the document `config/app` with field `staffPin` (string). Until then the PIN is **1234**.
5. Run `flutter pub get`, then `flutter run`. In Staff Mode → Menu, tap **Load sample menu**.

## Firestore data
| Collection | Fields |
|---|---|
| `menu_items` | name, price, category, imageUrl?, available, createdAt |
| `orders` | orderNo, studentId, studentName, items[{menuItemId, name, price, qty}], total, status (`pending`/`ready`/`picked_up`/`cancelled`), paymentMethod, createdAt, readyAt, closedAt |
| `config/app` | staffPin, nextOrderNo |

## Security note
There are no accounts, so the staff PIN is checked inside the app and the Firestore rules can only check the shape of each write. This is demo-level security, not real access control.
