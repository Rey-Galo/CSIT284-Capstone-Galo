# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Capstone project X5: **Canteen Pre-Order App**. It's a Flutter app for Android only, backed by Cloud Firestore. The instructor's scope:
- **Core features:** menu list, add to cart, place order, order status (Pending/Ready).
- **Deliberately cut:** cash-on-pickup only, a single canteen, and **no user accounts** (students type a student ID).

Don't add auth, online payment, or multi-canteen support unless asked. See `README.md` for features and Firebase setup.

## Commands

Flutter is installed at `C:\Users\l12x16w25\Documents\flutter\flutter\bin`, which is on the user PATH, so `flutter` and `dart` run directly.

```sh
flutter pub get
flutter analyze                                   # must stay clean
flutter test                                      # all tests (no Firebase needed)
flutter test test/services_test.dart              # one file
flutter test --plain-name "markReady"             # tests whose name contains this
dart format lib test
flutter run                                       # demo data until Firebase is configured
```

Building or running with plugins on Windows needs **Developer Mode** turned on (symlink support).

## Architecture

- **One app, two modes.** Student mode is the default (`MenuScreen`). Staff mode (`screens/staff/`) opens from the drawer or by long-pressing the menu title, then `StaffPinScreen`. The PIN is checked on the client against `config/app.staffPin` (default `1234`, see `ConfigService`). This is intentionally not real security.
- **Dependency wiring.** `lib/app.dart` (`CanteenApp`) takes the `FirebaseFirestore` instance as a parameter and provides `MenuService`, `OrderService`, `ConfigService` (plain `Provider`) plus `CartProvider` and `StudentProvider` (`ChangeNotifier`). Tests pass a `FakeFirebaseFirestore` from `fake_cloud_firestore`. Keep services constructor-injected so this keeps working.
- **Firestore access lives only in `lib/services/`.** Screens read services with `context.read` and create their streams once in state fields (`late final _x = context.read<...>().watch...()`), never inside `build`.
- **No composite indexes.** Queries use a single `where` at most, and sorting happens on the client (`OrderService._sorted`, `MenuService.watchMenu`). Keep it that way, or the Firebase console will require index setup.
- **Order numbers.** `OrderService.placeOrder` runs a transaction that reads and increments `config/app.nextOrderNo` and writes the order with `status: 'pending'` and a server `createdAt`. Order lines copy the item name and price so menu edits don't change past orders. `createdAt` can be null briefly on local snapshots, so handle that.
- **No accounts.** `StudentProvider` saves the student ID and name in `shared_preferences`. "My Orders" queries `orders` by `studentId`.
- **Naming.** The menu model is `FoodItem` (Flutter already has a `MenuItem` class), and the order model is `CanteenOrder`.
- **Order lifecycle.** `pending → ready → picked_up`, or `pending → cancelled`. `OrderStatus.value` is the stored snake_case string; write that, never `.name`. All changes go through `OrderService._changeStatus` (a transaction that checks the current status and throws `StateError` otherwise). Orders are never deleted, so "My Orders" keeps the history.
- **Firebase config.** Connected to project `canteen-preorder-6fab0` for Android and Web (`flutterfire configure --platforms=android,web`). On any other platform `DefaultFirebaseOptions` throws `UnsupportedError`, and `main.dart` falls back to an in-memory `FakeFirebaseFirestore` seeded with the sample menu (demo mode, "DEMO DATA" banner, data lost on restart), which is why `fake_cloud_firestore` is a regular dependency. `firestore.rules` holds the security rules, deployed with `firebase deploy --only firestore:rules`. They validate the shape of writes (only the transitions above, and the counter can only increase), since there's no auth to check. The `firebase` CLI is at `%APPDATA%\npm` and isn't on PATH in already-open shells.
- **Testing transactions.** `fake_cloud_firestore` 4.5.0 doesn't await writes made inside `runTransaction`, so tests must wait for the new status (see `waitForStatus` in `test/services_test.dart`) instead of reading right after the call.
- **Images.** Menu photos are an optional `imageUrl` string (Firebase Storage would need the paid Blaze plan), and `FoodThumbnail` falls back to an icon.
