# My Photo Organizer

Capture, auto-organize, and clean up your photos. Free plan: 1 folder. Pro: unlimited folders.

## What's built (Phase 1)

- Splash screen → Welcome screen → Login/Signup (Firebase Auth: email + Google)
- Folder create/select (Free = 1 folder, Pro = unlimited — gated in `FolderService`)
- Camera capture → auto-saves photo into a named album in the phone's public Gallery
- Gallery view per folder
- Auto-Organize screen: on-device duplicate/similar-photo detection (perceptual hashing, no internet/model download needed)

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

- Wire `in_app_purchase` to a real Play Store subscription product for Pro unlock (currently `FolderService.setProUser()` is a manual toggle stub)
- Release signing config (currently uses debug signing — fine for testing, not for Play Store submission)
- Privacy Policy page/link (required by Play Store since the app uses camera + accounts)
- App icon & Play Store graphics
- Batch tagging, OCR, watermarking, cloud backup (from the earlier feature roadmap)

## Project structure

```
lib/
  screens/
    splash_screen.dart
    welcome_screen.dart
    auth/            login_screen.dart, signup_screen.dart
    folder/           folder_select_screen.dart, create_folder_screen.dart
    camera/           camera_screen.dart
    gallery/          gallery_screen.dart
    organize/          auto_organize_screen.dart
  services/
    auth_service.dart        - Firebase Auth wrapper
    folder_service.dart      - SQLite folder CRUD + Free/Pro gating
    photo_service.dart       - camera save to gallery album, read device photos
    duplicate_detector.dart  - perceptual hash duplicate/similarity grouping
  models/
    folder_model.dart
  utils/
    constants.dart           - colors, text styles, app constants
```
