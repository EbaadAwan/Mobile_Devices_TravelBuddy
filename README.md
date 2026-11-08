# TravelBuddy

**Discover places worth visiting. Save your favourites. Plan the next stop.**

**CSCI 3101U — Mobile Devices · Ontario Tech University · Fall 2026**  
**Project stage:** Part 2 — Mid-Course Update & Check-in (November 9, 2026)  
**Primary demonstration platform:** Android emulator / Android phone

TravelBuddy is a Flutter application for travellers who want to explore nearby attractions, learn about places of interest, save destinations, and organize upcoming visits. The current checkpoint build brings together location-based discovery, attraction details, locally saved favourites and reviews, a trip planner, Android reminders, and a clearly labelled demonstration of crowd-activity status.

> **Mid-course build:** This is a working project in development, **not a finished travel-information service**. Features that rely on external data may vary with location, connectivity, and API availability. Live crowd levels are not yet connected to a real data provider.

## Contents

- [Explore the app](#explore-the-app)
- [Feature status](#feature-status)
- [Technology stack](#technology-stack)
- [Get started](#get-started)
- [Test account and permissions](#test-account-and-permissions)
- [Suggested evaluation walkthrough](#suggested-evaluation-walkthrough)
- [Project structure](#project-structure)
- [Testing](#testing)
- [Data sources and limitations](#data-sources-and-limitations)
- [Team and development status](#team-and-development-status)
- [Part 2 submission notes](#part-2-submission-notes)
- [Generative AI acknowledgement](#generative-ai-acknowledgement)

## Explore the app

### Discover nearby attractions

The **Home** tab initially displays sample attractions so the interface can be explored without first requesting a location. Tap **Find Nearby Attractions** to request device location and query Wikipedia's geographically nearby pages. Attraction cards provide a name, a displayed rating and distance, favourite controls, and an entry point to details.

**(Add screenshot here — Home screen with the search field, “Find Nearby Attractions” button, and attraction cards. Suggested path: `docs/screenshots/home.png`.)**

**(Add screenshot here — Results after tapping “Find Nearby Attractions” on an Android emulator with location enabled. Suggested path: `docs/screenshots/nearby-attractions.png`.)**

### View details and write reviews

Selecting an attraction opens its detail sheet. The app requests additional place information through OpenStreetMap Nominatim and Wikipedia, where available, and provides a **Reviews** section. Users can give a 1–5-star rating, write text, attach photos using the device picker, inspect reviews, sort/filter them, and remove their own local reviews.

**(Add screenshot here — Attraction detail sheet showing place information, activity-status panel, and reviews. Suggested path: `docs/screenshots/attraction-details.png`.)**

**(Add screenshot here — Review form showing star selection and optional photo controls. Suggested path: `docs/screenshots/write-review.png`.)**

### Save favourite places

Tap the heart on an attraction to save or remove it. The **Favourites** tab shows saved attractions, and the application displays a SnackBar for the action. On Android, saving a favourite can also issue an immediate **local** notification if permission is granted.

**(Add screenshot here — Favourites tab containing at least one saved destination. Suggested path: `docs/screenshots/favourites.png`.)**

### Plan visits and receive reminders

The **Trip Planner** tab allows a user to:

- Create a planned visit with a trip title, destination, date, time, and optional notes.
- Use date/time pickers and required-field validation; confirm or cancel changes.
- Edit and delete visits, view upcoming and past visits, and retain saved trips after restarting the app.
- Rename the trip and adjust its budget. The displayed **$35-per-visit** cost is illustrative, **not a live price or booking estimate**.
- Schedule an Android local reminder when the planned visit and notification permissions allow it; cancel the associated reminder on deletion.

**(Add screenshot here — Trip Planner with an upcoming visit card, budget, and “Create a Visit” action. Suggested path: `docs/screenshots/trip-planner.png`.)**

**(Add screenshot here — “Plan a visit” dialog with title/destination fields and date/time selectors visible. Suggested path: `docs/screenshots/visit-dialog.png`.)**

**(Add screenshot here — Android notification shade showing a TravelBuddy trip reminder. Suggested path: `docs/screenshots/trip-reminder.png`.)**

### See attraction activity status

Activity badges appear on attraction and visit cards. The details panel has **Quiet**, **Moderate**, **Busy**, and **Reset** controls for a **demonstration only**. Until a verified crowd-data service is connected, attractions show **Unavailable · No data**, and manually selected values are explicitly labelled **DEMO**; they are not real-time crowd measurements.

**(Add screenshot here — Attraction activity panel showing a status marked “DEMO” and the status controls. Suggested path: `docs/screenshots/activity-demo.png`.)**

## Feature status

The statuses below describe functionality present in the supplied source code; they are **not** a claim that every device/API scenario has been independently retested for this README.

| Area | Check-in state | Where to find it / scope |
| --- | --- | --- |
| Home and destination cards | **Implemented** | Home tab; seeded cards before location search |
| Nearby attraction discovery | **Implemented with limitations** | Home → **Find Nearby Attractions**; GPS permission, Wikipedia geo-search, internet required |
| Place details | **Implemented with limitations** | Tap an attraction; Nominatim/Wikipedia fields are dependent on available source data |
| Favourites | **Implemented** | Heart buttons and Favourites tab; stored locally |
| Ratings and reviews | **Implemented locally** | Attraction details → Reviews; text, star rating, optional photos, sorting/filtering |
| Trip Planner | **Implemented** | Trip Planner tab; forms, pickers, validation, create/edit/delete, local persistence |
| Notifications | **Implemented for Android locally** | Favourite-save alerts, test notification, scheduled visit reminders; **not remote push** |
| Activity status | **Demonstration** | Attraction detail panel; manually selected crowd levels, **not live data** |
| Navigation menu | **Implemented as a bottom sheet** | Top-right menu; links to Home, Favourites, and Trip Planner |
| Adjustable UI settings | **Not yet implemented** | Menu currently has navigation choices, not working theme/text-size controls |
| Search by typed keyword | **Not yet implemented** | Search field currently shows a feedback message rather than performing a search |

## Technology stack

| Layer | Technology used in this repository |
| --- | --- |
| App and UI | **Flutter**, **Dart**, Material 3 |
| State and navigation | `StatefulWidget`, `ChangeNotifier`, bottom navigation, sheets and dialogs |
| Geolocation | `geolocator` |
| HTTP and attraction discovery | `http`; Wikipedia GeoSearch API |
| Additional attraction information | OpenStreetMap **Nominatim** and Wikipedia REST summary |
| Persistent local data | `shared_preferences`; app document storage for review photos via `path_provider` |
| Images and reviews | `cached_network_image`, `image_picker` |
| Android reminders | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
| Tests and code checks | `flutter_test`, `flutter_lints`, `flutter analyze` |

The `pubspec.yaml` specifies **Dart SDK `^3.13.3`**. Use an installed Flutter version whose bundled Dart SDK meets that constraint; `flutter --version` will show the local version. The Android project uses Kotlin Gradle configuration and Gradle wrapper files already included under `travelbuddy/android/`.

## Get started

TravelBuddy is developed with Flutter and Dart. The **required evaluation target is Android**, and the project can be built from either **macOS** or **Windows** using Android Studio and an Android emulator or physical Android device.

### Prerequisites (both platforms)

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed, with `flutter/bin` on your system `PATH`. Use a Flutter release bundling Dart compatible with the project's `^3.13.3` constraint in `pubspec.yaml`.
- [Android Studio](https://developer.android.com/studio), with the **Flutter** and **Dart** plugins, Android SDK, command-line tools, and a configured **Android Virtual Device (AVD)**.
- [Git](https://git-scm.com/downloads) to clone the repository (not needed if running from the submitted ZIP).
- Internet access to download packages and load attraction information/images; location services enabled to test nearby discovery.

> **Project directory:** The repository contains a nested Flutter application. Open and run commands from **`Mobile_Devices_TravelBuddy/travelbuddy/`**, the folder containing `pubspec.yaml`—not from the repository root.
>
> **Part 2 submission ZIP:** If you received the course submission instead of cloning GitHub, extract it and open **`code/`** (the directory containing `pubspec.yaml`). Skip the `git clone` command.

### macOS — Installation and launch

**1. Prepare Flutter and Android Studio**

1. Install the Flutter SDK using the [official macOS instructions](https://docs.flutter.dev/get-started/install/macos) and add its `bin` directory to your shell's `PATH`. Restart Terminal if you changed `PATH`.
2. Install Android Studio and its Flutter/Dart plugins. In **Tools → Device Manager**, create or select an Android emulator (for example, a Pixel device) and start it with the play button.
3. Open **Terminal** (or Android Studio's built-in terminal) and verify your setup:

   ```bash
   flutter --version
   flutter doctor
   flutter doctor --android-licenses
   ```

   Accept the Android SDK licences when prompted. Address any Android toolchain problems shown by `flutter doctor`.

**2. Clone and open the project**

```bash
cd ~
git clone https://github.com/EbaadAwan/Mobile_Devices_TravelBuddy.git
cd Mobile_Devices_TravelBuddy/travelbuddy
flutter pub get
```

If the repository is already cloned, **skip `git clone`** and open the existing `travelbuddy` folder instead. You can also select **Open** in Android Studio and choose that folder.

**3. Run on an Android emulator or device**

```bash
flutter devices
flutter run
```

Choose the Android emulator/device if Flutter lists multiple targets. To specify it directly, use the device ID returned by `flutter devices`, for example:

```bash
flutter run -d emulator-5554
```

`emulator-5554` is only an example; your ID may differ. In Android Studio you can alternatively choose the emulator in the device dropdown (not **macOS desktop**), open `lib/main.dart`, and click **Run ▶**.

### Windows — Installation and launch

**1. Prepare Flutter and Android Studio**

1. Install the Flutter SDK using the [official Windows instructions](https://docs.flutter.dev/get-started/install/windows). Extract it into a normal writable folder (for example, `C:\src\flutter`) and add `C:\src\flutter\bin` to your Windows user **Path** environment variable. Reopen PowerShell or Android Studio after changing Path.
2. Install Android Studio and its Flutter/Dart plugins. Open **Tools → Device Manager**, create or select an Android emulator, and start it with the play button.
3. Open **PowerShell** (or Android Studio's terminal with PowerShell selected) and verify your setup:

   ```powershell
   flutter --version
   flutter doctor
   flutter doctor --android-licenses
   ```

   Accept the Android SDK licences when prompted. Address any Android toolchain problems shown by `flutter doctor`.

**2. Clone and open the project**

```powershell
cd $HOME
git clone https://github.com/EbaadAwan/Mobile_Devices_TravelBuddy.git
cd .\Mobile_Devices_TravelBuddy\travelbuddy
flutter pub get
```

If you already have the repository, **skip `git clone`** and navigate to your existing `travelbuddy` folder. You can also open that folder through Android Studio's **Open** action.

**3. Run on an Android emulator or device**

```powershell
flutter devices
flutter run
```

Choose an Android target when prompted. To select a device directly, replace the example ID with the one reported by `flutter devices`:

```powershell
flutter run -d emulator-5554
```

Alternatively, select the emulator in Android Studio's device dropdown, open `lib/main.dart`, and click **Run ▶**.

### Running on a physical Android phone (macOS or Windows)

Enable **Developer options → USB debugging** on the phone, connect it by USB, approve the debugging prompt on the phone, and confirm it appears in `flutter devices`. Then run `flutter run -d DEVICE_ID`, replacing `DEVICE_ID` with its actual ID. Location and notification permissions should be allowed when testing those features.

### Optional browser preview (macOS or Windows)

```bash
flutter run -d chrome --web-port=3000
```

If compilation succeeds, open `http://localhost:3000`. This is useful for checking supported interface elements, but **Android local notifications must be tested on an Android emulator or phone**. Other plugin behavior may differ on the web.

### Troubleshooting

| Symptom | Suggested check |
| --- | --- |
| `flutter` is not recognized | Confirm the Flutter SDK `bin` folder is in your `PATH` and restart the terminal |
| `git` is not recognized | Install Git and reopen Terminal/PowerShell; alternatively use the extracted submission ZIP |
| No Android device listed | Start the emulator in Android Studio, rerun `flutter devices`, and check `flutter doctor` |
| Gradle cannot build | Check free disk space, Android SDK installation, and toolchain configuration; retry after resolving the reported error |
| Location discovery is empty or fails | Enable device location, grant permission, and check the emulator's location and internet connection |
| No scheduled notification | Enable Android notification permission and check the trip time and notification settings; inexact alarms may be delayed |
| Place information or images are missing | Wikipedia/Nominatim and network images may return incomplete data; the app includes fallbacks |

## Test account and permissions

**No login or registration is implemented in this checkpoint build. No test credentials are needed:** launch the app and use the main tabs directly. 

| Access | Why it is requested | What to do during evaluation |
| --- | --- | --- |
| Location | Find geographically nearby attractions | Enable location and allow access when prompted |
| Internet | Fetch Wikipedia/Nominatim responses and network images | Keep the device online |
| Android notifications | Show favourite alerts and planned-visit reminders | Allow when prompted; inspect the notification shade |
| Camera/photo library | Attach an optional image to a review | Grant access only when testing photo attachments |

**No API key is configured in the uploaded project** for its Wikipedia/Nominatim requests. These public services can be unavailable, incomplete, or subject to usage policies; there is no guarantee that a particular attraction will return full details. The current Nominatim User-Agent identification should be reviewed by the team before wider distribution.

## Suggested evaluation walkthrough

A short path through the currently implemented functionality:

1. Open **Home** to view sample destination cards; optionally tap **Find Nearby Attractions** to exercise location permission and HTTP requests.
2. Tap an attraction to inspect details, reviews, and the activity panel. Set **Busy** and confirm the label says **DEMO**.
3. Save an attraction with its heart icon; visit **Favourites** and look for the SnackBar / Android local notification.
4. Open **Trip Planner**; tap **Create a Visit**. Test an empty title/destination to observe validation, then select a future date and time, confirm, and save.
5. Edit or delete the visit; restart the app to check local persistence. The **Send test notification** control is available in Trip Planner for Android notification testing.
6. Open the top-right menu to inspect navigation choices. **Adjustable UI settings are still a known gap**, so do not present them as complete.

For the assignment's **two-minute demo video**, record the **actual submitted Android version** with readable on-screen captions and realistic sample data. The report and demo are **separate required deliverables**; this README does not replace either one.

## Project structure

The top-level GitHub repository contains a `travelbuddy/` Flutter application:

```text
Mobile_Devices_TravelBuddy/
├── README.md                     # Repository overview and setup (this file)
└── travelbuddy/
    ├── lib/
    │   ├── main.dart              # App theme, shell, tabs, destination cards/details
    │   ├── features/
    │   │   ├── trips/             # Visit model, editor, storage, planner screen
    │   │   └── activity/          # Crowd-status state and demo UI
    │   ├── screens/               # Review screens
    │   ├── services/              # Nearby search, place details, reviews,
    │   │                          # favourites, Android notifications
    │   └── widgets/               # Place details and review widgets
    ├── test/                      # Widget, trip-model and activity-status tests
    ├── android/                   # Android app manifest and Gradle configuration
    ├── ios/                       # Flutter platform scaffolding
    ├── web/                       # Flutter web scaffolding
    ├── linux/                     # Flutter platform scaffolding
    ├── macos/                     # Flutter platform scaffolding
    ├── windows/                   # Flutter platform scaffolding
    └── pubspec.yaml               # Dependencies and Dart SDK constraint
```

The coursework's required execution target is **Android**. Other platform folders are part of the Flutter project, but their presence does **not** mean every feature has been verified on those platforms.

## Testing

From the `travelbuddy/` directory:

```bash
flutter analyze
flutter test
```

To run the two focused model/status tests individually:

```bash
flutter test test/trip_plan_test.dart test/activity_status_service_test.dart
```

The checked-in tests cover trip JSON serialization, editing without changing visit identity, activity-status defaults, and demo-status labelling. A basic widget test also checks for the application shell/tabs. **Native notification delivery, permission prompts, API responses, and the full user journey require manual Android testing**; passing unit tests does not establish those outcomes.

## Data sources and limitations

- **Nearby results:** Wikipedia GeoSearch uses current device coordinates; seeded example cards are shown before searching. Results can vary by location and internet access.
- **Ratings and images:** Some API-result ratings are **illustrative values** computed in the current implementation; default card images can be reused placeholders. They should not be interpreted as verified public ratings or photos of every returned place.
- **Details:** Nominatim/Wikipedia provide data when available. Place details are cached using in-memory and local mechanisms, but **complete offline browsing is not promised**.
- **Reviews and favourites:** User-created content is saved **on the device**, not synced to a shared server or another user's account.
- **Reminders:** Notifications are **local Android notifications**, not Firebase Cloud Messaging or email. Current scheduling normally uses a two-day lead time for distant visits and a short lead time for near-term demo visits; Android can delay inexact alarms.
- **Crowd information:** The current **Quiet / Moderate / Busy** controls are **simulated**. Connecting a trustworthy external crowd-data source is future work.
- **Still in progress:** Keyword search; an app drawer with user-adjustable UI settings; production-grade crowd data; additional backend/cloud features and cross-device validation.

## Team and development status

The original project proposal assigned responsibility areas as follows; the team should confirm any updates to its **current** ownership in the separate progress report.

| Contributor | Original responsibility area |
| --- | --- |
| Abdul Jawad Syed | Location permissions, nearby discovery, external APIs |
| Brandon D'sa | Trip Planner, trip/favourite notifications, activity status |
| Daniel Grgic | Reviews, ratings and attraction details |
| Ebaadurrub Awan | Favourites, local storage and offline support |
| Levent Cakir | UI/UX, navigation and attraction presentation |

**Current milestone:** Part 2 check-in — November 9, 2026. **Final project deadline:** December 6, 2026. The separate progress report should document completed and outstanding tasks, changes from the proposal, known issues, and each member's actual contributions.

## Part 2 submission notes

The course guide requires **one ZIP file** containing a root-level README, a PDF progress report, an MP4 demo (maximum two minutes), and the runnable Flutter project:

```text
GroupXX_TravelBuddy_Part2.zip
├── README.md
├── report/
│   └── GroupXX_ProgressReport.pdf
├── video/
│   └── GroupXX_Demo.mp4
└── code/
    ├── lib/
    ├── test/
    ├── android/
    ├── ios/ ...                  # Any other included Flutter platform folders
    └── pubspec.yaml
```

Replace **`XX`** with the group's actual number; the uploaded source does not establish that number. To assemble the package, copy the **contents** of `travelbuddy/` (not a second nested parent folder) into `code/`. Run `flutter clean` from the Flutter project before packaging to exclude generated `build/` and `.dart_tool/` directories. If screenshots are added to this README, also include their referenced `docs/screenshots/` files in the ZIP. Verify the extracted package builds on another Android-capable computer before submitting. **Only one group member submits for the team.**

## Generative AI acknowledgement

In accordance with the course policy, AI assistance is disclosed here. The authors remain responsible for understanding, checking, testing and maintaining submitted material.
