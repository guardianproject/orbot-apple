#  Orbot iOS Changelog

## 1.4.0
- Updated Tor to 0.4.7.10.
- Updated Obfs4proxy to 0.0.14.
- Updated Snowflake to 2.3.1.
- Added a native macOS version.
- Updated Russian translation.
- Added option to automatically restart on error.
- Added option to clear the Tor cache.

## 1.3.1
- Updated Tor to 0.4.7.8.
- Added status to poll response, so `OrbotKit` doesn't have to ask and catches 
  the transition between `starting` and `started`.
- Removed explicit bypass setting. Bypass now only gets activated, if there's an app registered, which needs it. 
  Will be switched off again, after all bypass apps were removed.
- Fixed rare crash.

## 1.3.0
- Updates:
  - Tor 0.4.7.7
  - Snowflake 2.2.0
  - German, French, Russian, Spanish, Ukrainian translations
- Added button to replace currently built circuits with fresh ones.
- Added possibility to add any Tor configuration option.
- Grouped all settings in a drop-down menu.
- Added a "Content Blocker" extension with an editor for custom rules.
- Added a (dangerous!) "onion-only mode".
- Added a (secured) bypass feature for e.g. apps with their own Tor.
- Added bridges auto-configuration option.
- Extended remote control possibilities. 

## 1.2.0
- Updates:
  - Leaf 0.4.2
  - Tor 0.4.6.10
- Improved accessibility/screen reader compatibility.
- Added UI to configure Tor's `EntryNodes`, `ExitNodes`, `ExcludeNodes` and `StrictNodes` options.
- Fixed GeoIP support. 
- Added French, Russian, Spanish and Ukrainian translation.

## 1.1.0

- Updates:
  - Tor 0.4.6.9
  - OpenSSL 1.1.1m
  - Obfs4proxy 0.0.13
  - Snowflake 2.1.0
  - Leaf
- Release under Tor Project

## 1.0.0

- First release.
