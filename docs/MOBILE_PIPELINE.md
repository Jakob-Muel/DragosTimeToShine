# Mobile build pipeline

## Current position

The repository already supports a GitHub Pages PWA. The native game can use the same Godot
project and UI; it does **not** need to be rewritten as an Xcode app. Xcode is the final
iOS packaging, signing, capability, and device-testing layer.

The iOS HealthKit step plugin is implemented, packaged, and enabled. Android remains
optional provider source work.

## Recommended progression

### 1. Keep the PWA as the fast review build

Every push to `main` exports the web build through GitHub Actions. Use this for quick
gameplay and layout feedback. Web browsers cannot provide the HealthKit/Health Connect
access required for real incubation steps, so the web build keeps the test-step fallback.

### 2. iOS HealthKit plugin

The project includes debug and release XCFrameworks under
`ios/plugins/step_counter/`. Its descriptor registers `StepCounterPlugin`, links
`HealthKit.framework`, and injects the step-read usage description. The iOS export
preset enables it and injects `com.apple.developer.healthkit`.

The native code:

- requests read-only access to `HKQuantityTypeIdentifierStepCount`;
- runs an `HKStatisticsQuery` with cumulative-sum semantics from incubation start;
- emits permission, result, and error signals on the main thread;
- stores no raw HealthKit samples.

See [`native/README.md`](../native/README.md) for the bridge contract and rebuild
instructions. Godot's
[iOS plugin guide](https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html)
documents the packaging model.

### 3. Export and run on an iPhone

Prerequisites: macOS, Xcode, Godot export templates, an Apple developer team, a unique
bundle identifier, and an iPhone with Developer Mode enabled.

1. Fully quit and reopen Godot after pulling export-preset changes, then set the Team
   ID and bundle identifier in the iOS preset.
2. Run `tools/export_ios.sh debug`. This writes to `build/ios` and verifies the
   signed app still contains the HealthKit entitlement, privacy text, and plugin.
3. Open the generated `.xcodeproj` in Xcode.
4. Confirm the generated target shows the **HealthKit** capability. The export
   preset supplies it, so it should not need to be added manually.
5. Confirm `NSHealthShareUsageDescription` is present in the generated Info.plist.
6. Choose the connected iPhone and run once from Xcode so signing/provisioning settles.
7. Handle the step-read sheet when the egg screen requests it, then test denial, approval,
   app restart, and a real walking session.

Godot's [iOS export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
and [one-click deployment guide](https://docs.godotengine.org/en/latest/tutorials/export/one-click_deploy.html)
cover the Xcode hand-off and device setup. Do not place game logic directly in the generated
Xcode project because a later Godot export can regenerate it.

### 4. Add TestFlight

When local device builds are reliable:

1. Use a Release export and archive it in Xcode.
2. Validate and upload the archive to App Store Connect.
3. Add internal testers in TestFlight.
4. Keep signing values in local/CI secrets, never in the repository.

Apple's [distribution guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
covers archive and TestFlight distribution.

### 5. Package Android in parallel

1. Create a Godot Android v2 plugin/AAR around
   `native/android/.../StepHealthProvider.kt`.
2. Enable Godot's custom Gradle build for the Android preset.
3. Add the Health Connect client dependency and `READ_STEPS` permission.
4. Request Health Connect permission from the plugin and forward results to Godot.
5. Test Android 14+ and the Health Connect app flow on supported older devices.
6. Produce an Android App Bundle for Play testing.

The relevant primary references are Godot's
[Android plugin guide](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html),
[Android export guide](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_android.html),
and Android's [Health Connect setup](https://developer.android.com/health-and-fitness/health-connect/get-started)
and [aggregate steps](https://developer.android.com/health-and-fitness/health-connect/aggregate-data)
documentation.

## Release automation later

Keep GitHub Pages automatic now. Add native CI only after one manual signed build works:

- pull requests: import project, run smoke test, validate translations;
- `main`: deploy PWA;
- version tag: unsigned Android/iOS export checks;
- manual protected workflow: signed TestFlight/Play upload using repository secrets.

Native signing automation too early makes certificate and plugin failures harder to
diagnose. A successful manual device pipeline should be the template for CI.

## Definition of native step-counting complete

- permission prompt appears only in the egg flow;
- denial leaves the game usable and can be retried;
- the query returns steps since that egg's incubation timestamp;
- progress never decreases;
- restart preserves incubation progress;
- no raw health samples are written to the save;
- both plugin errors and unavailable services have visible, translated feedback.
