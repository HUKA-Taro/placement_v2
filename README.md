# Placement V2

Based on [Placement Flutter](https://github.com/IMGIITRoorkee/placement-flutter). The original app and design are credited to the Information Management Group (IMG) team at IIT Roorkee.

Browse placement listings, apply through Channel i, and get Android alerts when placement results change.

## Install on Android

1. Download the APK from [GitHub Releases](https://github.com/HUKA-Taro/placementv2/releases/latest) and open it on your phone.
2. Sign in with your Channel i account and allow notifications if you want alerts.

If you installed a V2 debug build, uninstall it before installing the release APK. GitHub restricts downloads to users with repository access while the repository is private.

Your installed version is shown at the bottom of **Profile**. Tap **Check for updates** to see if a newer public release is available.

## Features

- Browse placement listings, track application deadlines, and apply from your phone.
- Browse company-wise and branch-wise results. Search by branch within a company’s results or by company within a branch’s results.
- Enable profile links at the top of a result screen, then tap a student’s name to open their Channel i profile in your browser.
- Receive alerts when company-wise placement results change, including while the app is open.

## Notification settings

Open **Profile → Notification settings** to manage alerts and see the checker’s status. The status refreshes every 30 seconds while this screen is open. You can also tap the refresh icon.

Automatic alerts depend on the [Channel i checker](https://github.com/HUKA-Taro/channeli-checker) reaching the feeds and sending pushes through Firebase Cloud Messaging. An online checker can still show that a feed is unready. Contact [HUKA_Taro](https://github.com/HUKA-Taro) if you want to host the checker. The public checker sends result alerts. Deadline alerts require a checker that supports them.

Android can display alerts after you swipe the app away from Recents. If you force-stop the app in Android settings, reopen it to resume delivery.

## Build locally

Install Flutter and the Android SDK. Register `com.huka.taro.placementv2` as an Android app in your Firebase project and put its `google-services.json` in `android/app/`. Your checker must send to the same Firebase project to deliver pushes to your build.

```sh
flutter pub get
flutter build apk --debug
```

Find the APK at `build/app/outputs/flutter-apk/app-debug.apk` relative to the Flutter project directory.