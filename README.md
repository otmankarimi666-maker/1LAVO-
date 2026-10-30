# 1LAVO – Flutter Reservation App

This archive contains the Flutter/Dart source files supplied for 1LAVO, plus a Codemagic configuration.

## Important
The original ZIP contained only:
- `lib/main.dart`
- `pubspec.yaml`
- `README.md`

It did **not** include the generated `android/` and `ios/` platform folders. The Codemagic workflow below runs `flutter create . --platforms=android,ios` to generate missing platform scaffolding during the cloud build.

## Upload to GitHub
Upload the **contents of this `lavo` folder** into the root of your GitHub repository (so `pubspec.yaml`, `codemagic.yaml`, and `lib/` are at the repository root). Do not upload only the outer ZIP file.

## Codemagic
1. Connect the GitHub repository in Codemagic.
2. Select the workflow `android-workflow` to build a release APK.
3. The Android APK should appear in Codemagic build artifacts if the build succeeds.
4. The `ios-workflow` builds an iOS app without code signing. To create a distributable IPA or publish to the App Store, Apple signing credentials and App Store setup are still required.

## Local commands
```bash
flutter create . --platforms=android,ios
flutter pub get
flutter build apk --release
```

## App settings
The reservation email is currently configured in `lib/main.dart` as `emailDest`. Verify that it is the correct address before launch.
