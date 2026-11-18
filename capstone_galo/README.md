# Canteen Pre-Order App

**Project Name:** Canteen Pre-Order App\
**Project Code:** Capstone Project X5\
**Workstation:** #25

Capstone project X5. Students browse the canteen menu, add items to a cart, and place a pre-order. Canteen staff see the orders live and mark them **Ready**, and the student's screen updates by itself.

**Scope:** cash-on-pickup only, a single canteen, and no user accounts (students type their student ID). Android app built with Flutter and Cloud Firestore.

## Features
**Student (default mode)**
- Live menu grouped by category, with sold-out items greyed out
- Cart with quantity controls and a running total
- Checkout with student ID and name (remembered on the phone), cash on pickup
- Order status screen with a pickup number (e.g. `#0042`) and a live Pending → Ready status
- My Orders: past orders for the saved student ID

**Staff (drawer → Staff Mode, or long-press the "Canteen Menu" title, then the PIN)**
- Live order queue with Pending and Ready tabs, and a **Mark Ready** button
- Menu management: add, edit or delete items and toggle sold-out; "Load sample menu" on an empty menu

## Demo mode (no Firebase yet)
If `flutterfire configure` has not been run, the app starts with an in-memory database filled with the sample menu. Everything works on one phone, but data resets when the app restarts. Configuring Firebase (below) switches to the real database automatically.

## Setup
1. Install Flutter and enable Windows **Developer Mode** (`start ms-settings:developers`), which plugin builds need.
2. Create a project in the [Firebase console](https://console.firebase.google.com) and turn on **Cloud Firestore**.
3. Connect the app (this overwrites the placeholder `lib/firebase_options.dart`):
   ```sh
   npm install -g firebase-tools && firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android
   ```
4. Paste `firestore.rules` into Firestore → Rules and publish.
5. Optional: set the staff PIN by creating the document `config/app` with field `staffPin` (string). Until then the PIN is **1234**.
6. Run `flutter pub get`, then `flutter run`. In Staff Mode → Menu, tap **Load sample menu**.

## Firestore data
| Collection | Fields |
|---|---|
| `menu_items` | name, price, category, imageUrl?, available, createdAt |
| `orders` | orderNo, studentId, studentName, items[{menuItemId, name, price, qty}], total, status (`pending`/`ready`), paymentMethod, createdAt, readyAt |
| `config/app` | staffPin, nextOrderNo |

## Security note
There are no accounts, so the staff PIN is checked inside the app and the Firestore rules can only check the shape of each write. This is demo-level security, not real access control.
