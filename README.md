# Placement V2

Placement V2 is an unofficial, substantially modified Android app based on [IMG's original Placement Flutter app](https://github.com/IMGIITRoorkee/placement-flutter). The original app and its design are credited to the Information Management Group (IMG), IIT Roorkee.

This fork keeps the Channel i placement workflow and adds focused result search, student profile links, custom result alerts, backend status, and supported-version checks.

## What the app includes

### Placement and application features

- Browse placement and internship profiles, review role details and eligibility, and apply through Channel i.
- Review your application status and deadlines in the app.
- Browse placement results by company or by branch, and choose the relevant year, placement or internship results, and sort order.

### Result search and student profiles

- Search by company in the company-wise results list, or by branch in the branch-wise results list.
- Within a company result, search student names or branches. Within a branch result, search student names or companies.
- On an individual result page, use the link button in the top bar to enable student profile links. Eligible student names become links; tap a name to open that student's Channel i profile in the browser. Turn the link button off to disable these taps.

Profile links depend on the result entry containing a usable enrollment number. Channel i may ask you to sign in in the browser before showing a profile.

### Appearance

- Choose **System**, **Light**, or **Dark** in **Profile > Theme**. System follows your device theme, and Placement remembers your choice.

### Notifications

Open **Notification settings** from **Profile** to manage alerts. The app provides separate switches for **Result updates** and **Deadline changes**; both are enabled by default. Android notification permission is required.

- **Result updates:** The checker can send a push when it detects a new or changed company-wise placement result. The alert can also display while Placement V2 is open.
- **Deadline changes:** The app has a separate preference and can display a matching push. The current checker release does not detect or send deadline-change alerts, so this alert type will not arrive until the checker adds that support.
- **Backend status:** The settings page checks the checker's public heartbeat every 30 seconds and reports whether the checker is online and whether the placement results feed is ready. You can refresh the status manually.
- **Send test notification:** This creates a local Android notification to check that this device can display alerts. It does not test the checker or prove that a remote push was delivered.

Automatic result alerts depend on the separate [Channel i checker](https://github.com/HUKA-Taro/channeli-checker) reaching the Channel i feeds and sending through Firebase Cloud Messaging (FCM). If the checker is stopped, cannot reach a feed, or cannot send through Firebase, automatic alerts may be delayed or unavailable. Placement V2 can still be used to browse placement information and results when the checker is offline.

Android may deliver notifications after the app is swiped away from Recents. If Android's app settings are used to force-stop Placement V2, reopen the app to resume notification delivery.

### App updates

- On Android startup, the app checks a minimum supported build policy stored in Firestore. If this installation is below the required build, the app asks you to install the required release before continuing. A previously cached policy can be used if Firestore cannot be reached.
- **Profile** shows the installed app version and lets you check the policy again. When an update is required, the app opens the release APK download; Android asks you to confirm the installation. The app cannot silently install an APK.

The version policy and APK download link must be kept current when a release is published. The update flow depends on the Firestore policy being available and the release APK being downloadable.

## Install

1. Download the signed Android APK from the [GitHub Releases](https://github.com/HUKA-Taro/placement_v2/releases) page.
2. Open the APK on your Android phone and approve installation if prompted.
3. Sign in with your Channel i account and allow notifications if you want alerts.

## Build locally

Install Flutter and the Android SDK, configure the Android app with the correct Firebase project, and configure the local release signing key. Then run:

```sh
flutter pub get
flutter build apk --release
```

The signed APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Set the app version in `pubspec.yaml` before building. When publishing a release, keep the release tag, APK filename, and app version consistent. Do not commit the local signing key or `android/key.properties`.

## Credits

- Original app and design: [Information Management Group (IMG), IIT Roorkee](https://github.com/IMGIITRoorkee/placement-flutter).
- Placement V2 modifications: HUKA_Taro.
