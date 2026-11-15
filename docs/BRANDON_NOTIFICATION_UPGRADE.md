# TravelBuddy — Trip Reminder Upgrade (Brandon)

**Scope:** Trip Planner, trip reminder notifications, in-app banners, and upcoming visit countdown.

## What was added

| Feature | Implementation | Where to test |
| --- | --- | --- |
| Three scheduled reminders | 60 minutes (or 90), 30 minutes, and 5 minutes before a visit | Trip Planner → Create a Visit; inspect the save message |
| Per-visit preferences | Toggle each reminder and select 60 or 90 for the first one | Create or edit a visit |
| Persistence | Preferences are saved as part of each visit in existing `TripStore` JSON | Save, restart, edit the visit |
| Rescheduling / cancellation | Stable IDs; old reminders and new slots are cancelled on edit/delete | Edit time, turn off a reminder, delete visit |
| Heads-up request | Separate Android notification channel with high prominence, sound and vibration | Trip Planner → Send test notification; Android settings |
| Native notification action | **View trip** opens the Trip Planner and highlights its visit | Tap a scheduled reminder or its View trip action |
| Foreground banner | Dismissible, eight-second in-app banner; tap **View trip** | Trip Planner → Preview in-app reminder banner |
| Countdown | Human-readable time until the visit | Trip Planner upcoming visit cards |
| Automated tests | Scheduling, IDs, defaults, JSON migration, countdown text | `flutter test` |

**No changes to teammates' attraction discovery, review, or favourites implementation.** The main app has only one import and one wrapper around the existing shell. The Android manifest has one action receiver registration. All other integration edits are in Brandon's trip and notification files.

## Files added

- `travelbuddy/lib/features/trips/reminder_preferences.dart` — immutable reminder preferences
- `travelbuddy/lib/features/reminders/reminder_schedule.dart` — pure reminder scheduling calculations
- `travelbuddy/lib/features/reminders/reminder_banner.dart` — in-app foreground alert and preview
- `travelbuddy/lib/features/reminders/trip_focus_controller.dart` — highlight a requested visit
- `travelbuddy/lib/features/reminders/visit_countdown.dart` — time-remaining display
- `travelbuddy/test/reminder_schedule_test.dart` — reminder calculation and persistence unit tests
- `travelbuddy/test/visit_countdown_test.dart` — countdown test
- `docs/BRANDON_NOTIFICATION_UPGRADE.md` — this record

## Existing files with small integration changes

- `travelbuddy/lib/features/trips/trip_plan.dart` — store preferences within each visit's existing JSON
- `travelbuddy/lib/features/trips/trip_editor_dialog.dart` — selectable reminder times and multi-reminder scheduling after save
- `travelbuddy/lib/features/trips/trip_planner_screen.dart` — preview button, countdown, notification focus/highlight
- `travelbuddy/lib/services/travel_notification_service.dart` — new high-importance channel, three notification schedules, stable cancellation and actions
- `travelbuddy/lib/main.dart` — wraps unchanged `TravelBuddyShell` with foreground banner overlay
- `travelbuddy/android/app/src/main/AndroidManifest.xml` — registers native notification action receiver

## Design / compatibility notes

1. **Local reminders, not cloud push.** Android delivers OS notifications even if the app is in the background. The in-app banner needs the Flutter process to be active and in the foreground.
2. **Inexact Android alarms.** Reminders target 60/90, 30, and 5 minutes before a visit, but Android power management can delay delivery. This upgrade does not request restricted exact-alarm permission.
3. **Heads-up is not guaranteed.** The new channel ID `travelbuddy_trip_heads_up_v2` requests maximum importance, alert sound and vibration. The user/device retains control; check **Settings → Apps → TravelBuddy → Notifications → Upcoming visit alerts** for allowed pop-on-screen notifications and sound. Do Not Disturb can suppress banners.
4. **Legacy scheduled events.** Editing and saving a visit cancels its previous single reminder and registers the new slots. Existing visits saved before this change are not automatically migrated until saved again.
5. **No duplicate scheduled IDs for the same visit.** Save first cancels every old/new reminder ID before scheduling enabled future slots. The foreground banner and Android system alert are independent, however, so both may appear while the app is in the foreground on some devices.
6. **No changes to favourites channel.** Favourites notifications keep their previous behaviour, while trip alerts use the new channel.
7. **Review the integration patch before applying.** This was produced against the earlier supplied ZIP snapshot, not an automatically refreshed copy of GitHub `main`. If teammates changed the same files after that snapshot, `git apply --check` may fail; do not force or overwrite them.
8. **Testing status:** Static patch application can be checked locally; Flutter compilation and emulator delivery must still be tested on a Mac/Windows development system with Flutter installed.

## Recommended Android emulator walkthrough

Run from the repository's `travelbuddy/` directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d emulator-5554
```

Use the actual device ID from `flutter devices` if different.

**Tests to record:**

1. Tap **Send test notification** in Trip Planner; confirm the new channel's system notification appears and check its sound and heads-up behaviour.
2. Tap **Preview in-app reminder banner**; check cyan styling, automatic dismissal after eight seconds, manual dismissal, and **View trip**.
3. Create a visit at least 95 minutes ahead with all three reminder options enabled. Verify its save message reports three scheduled reminders. This checks registration, not delivery.
4. Create a visit about 6–8 minutes ahead to observe the five-minute reminder without waiting an hour. Keep the app open to inspect the in-app banner. The operating system may still delay its own inexact alarm.
5. Test a visit ~36 minutes ahead to target the 30-minute notification. A visit ~66 minutes ahead targets the default 60-minute notification. Use ~96 minutes for the 90-minute option.
6. Edit an upcoming visit and turn off one or more reminders, change 60→90, and change its time. Confirm the save count, check no notifications arrive at the old times, and inspect the selected values after app restart.
7. Delete a visit. Check that no reminders for it arrive later.
8. Tap a native reminder's body or its **View trip** action; TravelBuddy should open the Trip Planner and highlight/scroll to the relevant visit.
9. Repeat favourite-save notification and attraction discovery/reviews to confirm teammates' features continue working.
10. Repeat with TravelBuddy in background and, if practical, after a device restart. Inexact alarms may be delayed.

**Additional screenshots for group evidence:** checkbox settings, 3 scheduled save message, countdown, visible Android heads-up alert, in-app banner, highlighted visit after tapping notification, test result output.

## Group README recommendation

Use this dedicated development log to record individual contributions; it is more appropriate than adding a long implementation diary to the root `README.md`. Once the team reviews and merges the feature, add one concise line under README feature status linking to [`docs/BRANDON_NOTIFICATION_UPGRADE.md`](docs/BRANDON_NOTIFICATION_UPGRADE.md). The code must be tested before marking these improvements as complete.

## Known follow-up work

- Validate actual delivery times, Android permissions, channel presentation, app launch routing and cold starts on a physical device or emulator.
- Optionally add a native foreground-delivery event bridge if the team wants to deduplicate OS alerts and the app banner completely while TravelBuddy is open.
- Continue Live Activity Status work separately; this patch intentionally does not change simulated crowd data.
