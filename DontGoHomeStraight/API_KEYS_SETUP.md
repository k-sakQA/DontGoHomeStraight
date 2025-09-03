# API Keys Setup

## Feature Flags

Add the following optional key to `Config.plist` to enable the system waypoint picker (defaults to OFF):

- DETOUR_SYSTEM_PICKER: Boolean (true to enable)

## Ads (AdMob)

To enable AdMob native ads:

- Add these keys to `DontGoHomeStraight/App/Config/Config.plist` (or use the provided defaults in `Config.sample.plist`):
  - `ADS_ENABLED`: Boolean (true to show ads)
  - `ADMOB_APP_ID`: String (your AdMob App ID)
  - `ADMOB_NATIVE_AD_UNIT_ID`: String (your Native Advanced ad unit ID)

You also need to set `GADApplicationIdentifier` in `Info.plist`. This project references `$(ADMOB_APP_ID)` from build settings or `Config.plist` via `Environment`. For development, Google sample IDs in `Config.sample.plist` are used by default.