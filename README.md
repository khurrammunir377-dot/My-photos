# My Photo Organizer

Capture, auto-organize, and clean up your photos. Free plan: 1 folder. Pro: unlimited folders.

## What's built (Phase 1)

- Splash screen → Welcome screen (now animated: shifting gradient background, floating icons, staggered entrance) → Login/Signup (Firebase Auth: email + Google)
- Folder create/select (Free = 1 folder, Pro = unlimited — gated in `FolderService`)
- Camera capture → auto-saves photo into a named album in the phone's public Gallery
- Gallery view per folder
- Auto-Organize screen: on-device duplicate/similar-photo detection (perceptual hashing, no internet/model download needed)

## What's built (Phase 2)

- **Subscriptions**: real Google Play Billing wiring via `in_app_purchase` (`subscription_service.dart`), 3 plans — Monthly $1, Annual $10, 2-Year $15 (`models/subscription_plan.dart`)
- **Currency selector**: lets a user preview pricing in AED/EUR/GBP/INR/PKR/SAR/CAD/AUD (`services/currency_helper.dart`). Important: Google Play Billing already localizes the *actual* checkout price/currency automatically based on the buyer's Play Store country once your products are configured — this in-app selector is a preview/estimate only, not what controls real billing.
- **Referral program**: each user gets a code; refer 10 signups → 6 months Pro free, repeatable (`services/referral_service.dart`). Entered at signup, tracked in Firestore.
- **Admin dashboard**: stats (total/pro/free users, active today, total referrals, total visits) + live user list, gated to emails in `AppConstants.adminEmails` (`screens/admin/admin_dashboard_screen.dart`)
- **Camera filters**: Normal / B&W / Sepia / Vivid / Cool / Warm, live preview + baked into the saved photo (`utils/camera_filters.dart`)

## ⚠️ Required setup for Phase 2

1. **Firestore**: In Firebase Console → Build → Firestore Database → Create database. Referrals and the admin dashboard read/write a `users` collection there.
2. **Firestore security rules** (important before going live): by default a fresh Firestore is either locked (denies everything) or in test mode (allows everything, expires in 30 days). Set rules so:
   - A user can read/write only their **own** `users/{uid}` document
   - Referral code lookups (`where('referralCode', ...)`) need a rule allowing reads across the collection for that specific query, OR move referral crediting into a Cloud Function (recommended before launch — the current `referral_service.dart` writes directly from the client, which is fine for testing but spoofable in a modified APK)
   - Only UIDs matching your admin account(s) can read the *entire* `users` collection (the admin dashboard needs this)
3. **Play Console subscription products**: create 3 subscription products with IDs exactly matching `pro_monthly`, `pro_annual`, `pro_2year` (see `models/subscription_plan.dart`) under Monetize → Products → Subscriptions. Purchases won't load until these exist and the app is at least in internal testing.
4. **Admin email**: replace the placeholder in `lib/utils/constants.dart` → `AppConstants.adminEmails` with your real email before building.
5. **Currency preview API**: `currency_helper.dart` calls a free public exchange-rate API for live rates and silently falls back to static approximate rates if that fails — no setup needed, but you can swap in a paid FX API later for more accuracy.

## ⚠️ Required setup before this builds: Firebase

This project needs **your own Firebase project** — I can't create one on your behalf since it's tied to a Google account.

1. Go to https://console.firebase.google.com → Create a project (e.g. "My Photo Organizer")
2. Add an Android app inside that Firebase project:
   - Package name: `com.uudsaero.myphotoorganizer` (matches `android/app/build.gradle` — change both if you want a different package name)
3. Download the generated **`google-services.json`**
4. Place it at: `android/app/google-services.json` (this file is git-ignored by default for security — you'll add it manually after upload, or commit it if the repo is private)
5. In the Firebase Console, enable **Authentication → Sign-in method → Email/Password** and **Google**
6. For Google Sign-In specifically, you'll also need to add your app's SHA-1 fingerprint in Firebase project settings (Firebase Console → Project Settings → Your apps → Add fingerprint). GitHub Actions builds are unsigned/debug-signed by default, so use the debug SHA-1 for now:
   ```
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

Without `google-services.json`, the build will fail at the `google-services` Gradle plugin step.

## Deployment workflow (same as your UUDS app)

1. Zip this folder (include the `.github` hidden folder — don't miss it in drag-and-drop)
2. Upload to your GitHub repo (new repo, e.g. `KMBERP/MyPhotoOrganizer`)
3. GitHub Actions builds automatically on push to `main` → download the `MyPhotoOrganizer-APK` artifact
4. If pushing from a freshly unzipped folder: `git init` then `git push --force` as before

## Next steps (not yet built)

- Move referral crediting to a Cloud Function for tamper-resistance (see security note above)
- Release signing config (currently uses debug signing — fine for testing, not for Play Store submission)
- Privacy Policy page/link (required by Play Store since the app uses camera + accounts + now Firestore)
- App icon & Play Store graphics
- Batch tagging, OCR, watermarking, cloud photo backup (from the earlier feature roadmap)
- Admin actions beyond viewing (e.g. manually grant/revoke Pro, ban a user) — currently read-only

## Project structure

```
lib/
  screens/
    splash_screen.dart
    welcome_screen.dart        - animated gradient welcome screen
    auth/            login_screen.dart, signup_screen.dart (signup now takes a referral code)
    folder/           folder_select_screen.dart, create_folder_screen.dart
    camera/           camera_screen.dart (now with filter strip)
    gallery/          gallery_screen.dart
    organize/          auto_organize_screen.dart
    subscription/      subscription_screen.dart - pricing, currency selector, referral card
    admin/              admin_dashboard_screen.dart - stats + full user list
  services/
    auth_service.dart          - Firebase Auth wrapper
    folder_service.dart        - SQLite folder CRUD + local Free/Pro cache
    photo_service.dart         - camera save to gallery album, read device photos
    duplicate_detector.dart    - perceptual hash duplicate/similarity grouping
    subscription_service.dart  - Google Play Billing wiring
    referral_service.dart      - referral code application + reward logic
    user_directory_service.dart - Firestore user profiles + admin stats/queries
    currency_helper.dart       - currency preference + live/fallback FX rates
  models/
    folder_model.dart
    subscription_plan.dart
  utils/
    constants.dart             - colors, text styles, app constants, admin allowlist
    camera_filters.dart        - filter presets, live preview + baked-in processing
```
