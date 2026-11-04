# example-native-implementations

Monorepo:

- `packages/call_state`: Flutter plugin (Android + iOS) to detect active calls.
  - `MethodChannel` `call_state/methods` -> `getCallStatus` (`idle` | `ringing` | `active`)
  - `EventChannel` `call_state/events` -> stream of status changes
  - Android: `TelephonyManager` (`TelephonyCallback` on API 31+, `PhoneStateListener` below). Permission `READ_PHONE_STATE` requested from Dart via `permission_handler`.
  - iOS: CallKit `CXCallObserver` (no permission needed).
- `apps/call_state_app`: example app, depends on the plugin via `path: ../../packages/call_state`.

## Setup

The platform folders of the app are not committed. Generate them once:

```sh
cd apps/call_state_app
flutter create . --project-name call_state_app --platforms=android,ios
```

Then in the app:

- Android: `android/app/src/main/AndroidManifest.xml` gets `READ_PHONE_STATE` merged from the plugin automatically.
- iOS: add to `ios/Podfile` (inside `post_install`, for `permission_handler`):
  `config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_PHONE=1']`
  (only needed if you use `Permission.phone` on iOS; this plugin skips it on iOS, so optional.)

```sh
flutter pub get
flutter run
```

Notes: iOS CallKit only reports calls the system knows about (cellular, FaceTime, CallKit VoIP apps); it cannot see third-party calls that do not use CallKit.
