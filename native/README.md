# Native step counter

The game talks only to the `StepCounter` GDScript autoload. On desktop and web it
uses a deterministic mock. iOS now supplies a compiled HealthKit-backed engine
singleton named `StepCounterPlugin`. Android remains provider source only.

## Bridge contract

The compiled Godot plugin must register this API:

| Member | Contract |
| --- | --- |
| `has_permission() -> bool` | Current read-permission state |
| `request_permission()` | Starts the platform permission flow |
| `query_steps_since(start_unix: int)` | Queries steps from the Unix timestamp to now |
| `permission_result(granted: bool)` | Signal emitted when the permission flow finishes |
| `steps_result(start_unix: int, steps: int)` | Signal emitted after a successful query |
| `step_error(message: String)` | Signal emitted for unavailable services or query failures |

The wrapper always dispatches signals on Godot's main thread.

## Platform providers

- `android/.../StepHealthProvider.kt` contains the Health Connect query.
- `ios/plugin/` contains the production Godot 4.6.1 Objective-C++ plugin.
- `ios/StepHealthProvider.swift` keeps the HealthKit logic available as a small,
  independently testable reference provider.

The precompiled debug and release XCFrameworks and their `.gdip` descriptor live
under `ios/plugins/step_counter/`. Godot discovers that directory automatically,
and the iOS export preset enables the plugin, links `HealthKit.framework`, adds
`NSHealthShareUsageDescription`, and adds the HealthKit entitlement.

## iOS behavior

Starting incubation requests read access to HealthKit step-count samples. Once the
authorization sheet has been handled, the game queries a cumulative step total from
the egg's incubation Unix timestamp through the current time. Only that total and
the incubation timestamp enter the save file.

Apple intentionally does not tell an app whether read access was allowed or denied.
For that reason `has_permission()` means “the HealthKit authorization sheet completed
successfully,” not “the user definitely allowed step reads.” If access is denied,
HealthKit returns no readable samples and the game remains usable; access can be
changed later under **Settings → Health → Data Access & Devices**.

HealthKit is available only on supported Apple devices. A physical iPhone is the
authoritative test environment.

## Exporting without losing HealthKit

The tracked iOS export preset is the source of truth for both
`com.apple.developer.healthkit` and `StepCounterPlugin`. If that preset was changed
while the Godot editor was already open, fully quit and reopen Godot once so the
editor does not save an older cached copy over it.

For a guarded debug export, run:

```sh
tools/export_ios.sh debug
```

The command writes to `build/ios/DragosTimeToShine.ipa` and fails if the final
signed app is missing the HealthKit entitlement, privacy explanation, or plugin
registration. Use `release` instead of `debug` for a distribution export.

## Rebuilding the plugin

The checked-in frameworks target Godot 4.6.1 (`14d19694`), iOS 17+, arm64 iPhone,
and arm64 Apple-silicon Simulator. Plugins must be rebuilt when the Godot engine
version changes.

1. Check out the matching Godot source and generate its iOS headers with SCons.
2. Run:

```sh
native/ios/build_step_counter_plugin.sh \
  /path/to/godot-4.6.1-source \
  /empty/output/directory
```

3. Replace the two generated XCFrameworks under
   `ios/plugins/step_counter/`, then perform both debug and release iOS exports.

Only the incubation start timestamp and the resulting step total are saved by the
game. Raw workouts or health samples are never stored.
