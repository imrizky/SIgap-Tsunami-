# Sigap Tsunami Flutter

Flutter/Dart mobile frontend for the existing Sigap Tsunami Laravel API. This app does not replace or modify the React frontend, Laravel backend, or MySQL database.

## Structure

- `lib/main.dart` and `lib/app/app.dart`: app entrypoint, session restore, theme, and root navigation.
- `lib/features/`: separate home, information, profile, auth, and emergency screens.
- `lib/core/config/api_config.dart`: one compile-time API base URL.
- `lib/core/network/api_client.dart`: JSON HTTP client, bearer auth, timeout, and server/network errors.
- `lib/core/storage/token_store.dart`: secure token storage.
- `lib/models/`: user and API record parsing.
- `lib/services/sigap_service.dart`: Laravel endpoint calls separated from widgets.

## Configure and run

Start MySQL in Laragon, then open Laragon Terminal and run:

```powershell
Set-Location 'E:\Magang\laragon\www\sigap-tsunami-api'
php artisan serve --host=0.0.0.0 --port=8000
```

If `php` is not on the PowerShell PATH, run Laragon's PHP directly:

```powershell
Set-Location 'E:\Magang\laragon\www\sigap-tsunami-api'
& 'E:\Magang\laragon\bin\php\php-8.3.33-Win32-vs16-x64\php.exe' artisan serve --host=0.0.0.0 --port=8000
```


The backend `.env` is already configured for MySQL database `sigap_tsunami` on `127.0.0.1:3306`; Flutter talks to Laravel over HTTP and must never connect directly to MySQL. Read-only `php artisan migrate:status` was checked on 2026-10-26; all 10 project migrations are already applied. No migration was run. The default mobile URL is for the Android Emulator; no production URL is configured.

Chrome (local computer):

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Android Emulator (when started manually):

```powershell
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

For a physical Android phone connected by USB, authorize USB debugging, then run these commands in PowerShell (with Laravel still running in another terminal):

```powershell
adb reverse tcp:8000 tcp:8000
flutter run -d 0965737358000377 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

`10.0.2.2` is for the Android Emulator. On a physical phone, use `127.0.0.1` together with `adb reverse`, or use the computer's LAN IP for Wi-Fi testing. A successful build alone does not verify login against MySQL; the Laravel server and database must be running. Do not treat demo seed data as official warnings or verified evacuation destinations. Cleartext HTTP is enabled only in Android debug; use HTTPS for release builds.

For Chrome, Laravel must allow the app's browser origin through its CORS configuration. A browser CORS failure does not by itself mean the API is unavailable. The app requests protected endpoints with a Sanctum bearer token.

## Build APK manually

For a physical Android phone over Wi-Fi, connect the phone and PC to the same trusted Wi-Fi network. The PC's current Wi-Fi IPv4 address is `192.168.1.6` (it can change when the router reconnects). On a private, trusted Wi-Fi only, set the Windows network profile to Private and allow the Laravel/PHP server on Private networks if Windows Firewall asks. Start Laravel with `--host=0.0.0.0` as shown above.

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define=API_BASE_URL=http://192.168.1.6:8000/api
```

Install this APK while USB is connected with `adb install -r "build\app\outputs\flutter-apk\app-debug.apk"`, or transfer the APK to the phone. `adb reverse` is not needed for this Wi-Fi build. If the PC's IP address changes, rebuild with its new address. For an Android Emulator, use `API_BASE_URL=http://10.0.2.2:8000/api` instead. The arm64 debug APK with the Wi-Fi URL built successfully on 2026-11-03 at `build/app/outputs/flutter-apk/app-debug.apk`.

## Backend endpoints verified from `routes/api.php`

Public:

- `POST /api/register` (name, email, password, password_confirmation)
- `POST /api/login` (email, password)

Authenticated with Sanctum:

- `GET /api/user`, `POST /api/logout`
- `GET /api/alerts`
- `GET /api/evacuation-points`
- `POST /api/emergency-reports` (incident_type, latitude, longitude; optional description/address)
- `POST /api/safety-statuses` (status; optional description/location coordinates)

Role protected:

- Petugas: `GET /api/petugas/dashboard` (role middleware: `petugas`)
- Relawan: `GET /api/relawan/tasks`, `PATCH /api/relawan/tasks/{id}/status` (role middleware: `relawan`)

The Laravel routes also expose report/status list and detail endpoints plus staff management endpoints. Those are not all surfaced in the current mobile UI. Backend validation and authorization remain authoritative.

Opening `http://127.0.0.1:8000/api` directly returns 404 because there is no `GET /api` index route. `/api` is only the URL prefix. Use the app login (`POST /api/login`); protected list routes such as `GET /api/alerts` require a bearer token.

## Implemented

- Indonesian Material 3 home, bottom navigation, account, guide, alert and evacuation views.
- Animated welcome screen with working Masuk/Daftar entry buttons and guest browsing.
- Animated boot splash and Android launcher icon use the supplied Sigap Tsunami lighthouse-and-wave logo. The home feed and alert status transition with subtle motion.
- Indonesian device-local date and live clock on the home header, refreshed every second.
- Animated login/registration forms with input validation, loading feedback, server validation errors, and the required password confirmation.
- Secure token persistence, profile restore, bearer requests, and logout.
- Alert and evacuation lists with loading, error, and empty states. No official alerts or evacuation locations are fabricated. Alerts refresh every 30 seconds only while the authenticated alerts tab is visible and the app is in the foreground; returning to the tab or resuming the app also refreshes. Manual refresh is available from the toolbar or pull-to-refresh. If an update fails, existing results stay visible with a stale-data notice.
- Home alert status refreshes every 30 seconds while the authenticated home tab is visible and the app is in the foreground. Evacuation points reload when the authenticated user opens that tab.
- SOS report submission with user confirmation, incident type, automatic foreground GPS capture, optional manual coordinates, and honest success/failure messages. The latest report code and status appear just below the SOS button; older reports can be expanded from the same section.
- Foreground GPS lookup starts when the SOS form opens; users can retry it or edit coordinates manually. The form displays reported accuracy and fix time, requests location only while in use, and sends coordinates only after SOS confirmation.
- Safety status submission.
- Petugas dashboard counts and relawan task list/status transitions gated by the role returned from the authenticated user API.

## Not yet implemented / manual setup

- Map rendering and reverse geocoding are not included. If GPS is unavailable, users can still enter coordinates manually. Emergency contact calling is available for 119, 110, and 113.
- SOS history and petugas report status controls are present in the app. The SOS API stores the report but does not send a push notification or dispatch responders.
- No direct BMKG feed or push notifications exist. Alerts shown are only records returned by this backend and must not be treated as live official warnings.
- Add and configure Laravel CORS for the Chrome development origin if needed; configure a reachable LAN API address for a physical phone.
- Production requires an HTTPS API URL and review of Android cleartext networking configuration.

## Checks

Code checks on 2026-11-03: `flutter analyze` passed with no issues and all 13 Flutter tests passed. The latest-report history behavior passed a widget test using a fake API response. The Wi-Fi arm64 APK rebuilt and installed successfully through ADB on Infinix X669C. The API was not tested live during this UI update. GPS hardware and Android's permission prompt have not been tested on a physical device. No location was sent to Laravel and no MySQL data was changed.








