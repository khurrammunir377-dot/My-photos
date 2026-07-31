# My Photo Organizer

Capture, auto-organize, and clean up your photos. Free plan: 1 folder. Pro: unlimited folders.

## Features built so far

- Splash → animated Welcome screen → Login/Signup
- Folder create/select (Free = 1 folder, Pro = unlimited)
- Camera capture with filters (Normal/B&W/Sepia/Vivid/Cool/Warm) → auto-saves into a named album in the phone's public Gallery
- Gallery view per folder
- Auto-Organize: on-device duplicate/similar-photo detection
- Subscriptions (Monthly $1 / Annual $10 / 2-Year $15), currency preview selector
- Referral program: refer 10 people → 6 months Pro free, repeatable *(needs Firebase - see below)*
- Admin dashboard: user stats + full user list *(needs Firebase - see below)*

---

## Current status: Firebase is OFF for easy testing

`AppConstants.kFirebaseEnabled` (in `lib/utils/constants.dart`) is currently set to **`false`**. This means:

- **Login/signup is local-only** — type any email, no password needed, no real account, nothing sent anywhere. Just tap Log In / Sign Up to get into the app.
- **Referrals and the admin dashboard are hidden** — both need a real Firestore database, so they're disabled along with Firebase.
- **Everything else works fully**: folders, camera + filters, gallery, auto-organize, the subscription pricing screen, and the orange **"Enable Test Pro"** button to unlock unlimited folders for testing.
- The `google-services` Gradle plugin is also commented out in `android/build.gradle` and `android/app/build.gradle`, which is why the build no longer needs `google-services.json` at all right now.

This is the fastest path to a working APK to install and try today.

## Re-enabling Firebase later (real login, referrals, admin dashboard)

When you're ready:

1. Create a Firebase project at https://console.firebase.google.com → **Add project**
2. Add an Android app with package name `com.uudsaero.myphotoorganizer` → download **`google-services.json`** → place it at `android/app/google-services.json`
3. In Firebase Console: **Build → Authentication → Sign-in method** → enable **Email/Password** and **Google**
4. **Build → Firestore Database → Create database** → start in test mode
5. In `lib/utils/constants.dart`, change:
   ```dart
   static const bool kFirebaseEnabled = false;
   ```
   to
   ```dart
   static const bool kFirebaseEnabled = true;
   ```
6. In `android/app/build.gradle`, uncomment this line in the `plugins` block:
   ```gradle
   id "com.google.gms.google-services"
   ```
7. In `android/build.gradle`, uncomment this line in the `dependencies` block:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.2'
   ```
8. *(Optional)* Set your real email in `AppConstants.adminEmails` to see the admin dashboard

---

## Part 1 — Setup for testing / personal use (do this now)

Nothing extra is required beyond building and installing — Firebase is off, so there's no account setup needed at all right now.
- **Signing**: the app builds with Android's default debug signing, which is fine for installing on your own device.
- **Currency selector, filters, auto-organize, gallery**: all work with no extra setup.

### Installing the built APK on your phone
1. Push to GitHub → GitHub Actions builds automatically
2. Go to the **Actions** tab → open the latest successful run → download the `MyPhotoOrganizer-APK` artifact (it's a zip containing the `.apk`)
3. Transfer the `.apk` to your Android phone (email it to yourself, use Google Drive, or a USB cable)
4. On your phone, tap the file to install — you'll need to allow "install unknown apps" for whichever app you used to open it (Android will prompt you)

---

## Part 2 — Checklist before Play Store launch (do this later)

Come back to this list when you're ready to publish. None of it blocks personal testing.

- [ ] **Release signing**: generate your own upload keystore and replace `signingConfig = signingConfigs.debug` in `android/app/build.gradle` — Play Store won't accept a debug-signed app
- [ ] **Play Console subscription products**: create `pro_monthly`, `pro_annual`, `pro_2year` under Monetize → Subscriptions with matching IDs, then remove the "Enable Test Pro" developer button from `subscription_screen.dart`
- [ ] **Firestore security rules**: tighten from test mode — restrict each user to their own document, and move referral-crediting logic into a Cloud Function so a modified APK can't fake referrals (current implementation writes directly from the client, fine for testing, not for public launch)
- [ ] **Privacy Policy**: required by Play Store since the app uses camera, accounts, and Firestore — host a simple page and link it in your Play Console listing
- [ ] **App icon & Play Store graphics**: feature graphic, screenshots, listing copy
- [ ] **Admin dashboard access control**: currently a client-side email allowlist — fine for a solo admin, but add a matching Firestore rule restricting full `users` collection reads to your admin UID before launch
- [ ] Optional roadmap items from earlier: batch tagging, OCR, watermarking, cloud photo backup

---

## Deployment workflow

1. Zip this folder (include the `.github` hidden folder — easy to miss in drag-and-drop)
2. Upload to your GitHub repo
3. GitHub Actions builds automatically on push to `main` → download the `MyPhotoOrganizer-APK` artifact
4. If pushing from a freshly unzipped folder: `git init` then `git push --force`

## Project structure

```
lib/
  screens/
    splash_screen.dart
    welcome_screen.dart          - animated gradient welcome screen
    auth/                        login_screen.dart, signup_screen.dart
    folder/                      folder_select_screen.dart, create_folder_screen.dart
    camera/                      camera_screen.dart (with filter strip)
    gallery/                     gallery_screen.dart
    organize/                    auto_organize_screen.dart
    subscription/                subscription_screen.dart - pricing, currency, referral, test-mode toggle
    admin/                       admin_dashboard_screen.dart - stats + full user list
  services/
    auth_service.dart            - Firebase Auth wrapper
    folder_service.dart          - SQLite folder CRUD + local Free/Pro cache
    photo_service.dart           - camera save to gallery album (saver_gallery), read device photos
    duplicate_detector.dart      - perceptual hash duplicate/similarity grouping
    subscription_service.dart    - Google Play Billing wiring
    referral_service.dart        - referral code application + reward logic
    user_directory_service.dart  - Firestore user profiles + admin stats/queries
    currency_helper.dart         - currency preference + live/fallback FX rates
  models/
    folder_model.dart
    subscription_plan.dart
  utils/
    constants.dart               - colors, text styles, app constants, admin allowlist
    camera_filters.dart          - filter presets, live preview + baked-in processing
```
