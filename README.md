# Placement V2

Based on [Placement Flutter](https://github.com/IMGIITRoorkee/placement-flutter). The original app and design are credited to the Information Management Group (IMG) team at IIT Roorkee.

Browse placement listings, apply through Channel i, and get Android alerts when placement results change.

## Install on Android

1. Open the signed release APK on your phone and follow Android's installation prompts.
2. Sign in with your Channel i account and allow notifications if you want alerts.

Your installed version is shown at the bottom of **Profile**. On launch, the app checks the required build published by the Channel i checker. If an update is required, the app opens the official APK download when you tap **Install latest version**. Android asks you to confirm the installation.

## Features

- Browse placement listings, track application deadlines, and apply from your phone.
- Browse company-wise and branch-wise results. Search by branch within a company’s results or by company within a branch’s results.
- Enable profile links at the top of a result screen, then tap a student’s name to open their Channel i profile in your browser.
- Receive alerts when company-wise placement results change, including while the app is open.

## Notification settings

Open **Profile → Notification settings** to manage alerts.

Automatic alerts depend on the [Channel i checker](https://github.com/HUKA-Taro/channeli-checker) reaching the feeds and sending pushes through Firebase Cloud Messaging. Contact [HUKA_Taro](https://github.com/HUKA-Taro) if you want to host the checker. The public checker sends result alerts. Deadline alerts require a checker that supports them.

**Send test notification** shows a local notification. If Android blocks notifications, the app will ask for permission or direct you to Android settings.

Android can display alerts after you swipe the app away from Recents. If you force-stop the app in Android settings, reopen it to resume delivery.

## Build locally

Install Flutter and the Android SDK. Register `com.huka.taro.placementv2` as an Android app in your Firebase project and put its `google-services.json` in `android/app/`. Your checker must send to the same Firebase project to deliver pushes to your build.

```sh
flutter pub get
flutter build apk --release
```

The Android project builds the release variant only. Find the signed APK at `build/app/outputs/flutter-apk/app-release.apk`. Configure `android/key.properties` locally with the existing release signing key for this app. Keep the properties file and signing key out of Git.

Publish the APK as `placementv2-2.3.0-14.apk` under tag `v2.3.0`. For each future release, use the version and Android build number from `pubspec.yaml`. Publish only once the signed APK is ready. The checker reads both app release repos and makes that build required.
