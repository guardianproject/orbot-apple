#  Orbot Apple Changelog

## 1.6.4
- Improved reliability of Snowflake:
  - Updated built-in bridge list (incl. Snowflake configuration).
  - iOS: Keep iOS from killing the VPN, when the start takes longer.
  - iOS: Increased default `MaxMemInQueues` from 5 to 10 MB, as it looks like we have more headroom now due to the Tor patch. 

## 1.6.3
- Updated Tor to latest 0.4.8.4 with a patch to keep RAM usage under control when it starts with a warm cache.
- iOS: Removed automatic cache clearing before every start.
- iOS: Reintroduced a manual "Clear Tor Cache" button in settings menu.

## 1.6.2
- Updated Tor to 0.4.7.14, updated Snowflake and Obfs4proxy now known as "Lyrebird".
- iOS: Always clear Tor cache on startup to increase reliability. Removed explicit buttons to clear the cache.
- macOS: No RAM limit there, so removed unneeded `MaxMemInQueues` limitation.
- Allow to override `MaxMemInQueues`, so advanced users can experiment with it.
- Added Arabic translation.
- Content blocker: Persist changes right away.
- Removed LZMA library to save some RAM.

## 1.6.1
- Workaround for problems on iOS 16.5: Added watchdog which tries to start again, if start failed.
- Added a prominent "Clear Tor Cache" button for easier access to remedy problems easier.
- Remote Control: Improved reliability of other apps starting Tor.
- Remote Control: Allow authorized apps to stop Tor.
- Added Tor status widget. (Reliability limited due to iOS limitations!)

## 1.6.0
- Improved Smart Connect: Don't stop, if auto-config server cannot be reached.
- Improved Smart Connect UI.
- Improved manual bridge configuration UI.
- Added configurable Smart Connect timeout for user testing.
- Updated Obfs4proxy and Snowflake libraries.
- Support multiple Snowflake bridges.
- Added setting: Switch back to the last VPN after Tor stops.
- New app icon.
- New illustrations.
- Improved access request scene.
- Updated translations. 
- Updated Tor to 0.4.7.13.


## 1.5.0
- Introduced new design including our new maskot "Orbie"!
- Added "Smart Connect" feature to aid in finding a working connection.
- Added exit-node country selector.
- Updated Tor to 0.4.7.12.

## 1.4.2
- Applied yet another fix for onion-only mode.

## 1.4.1
- Updated Tor to 0.4.7.11.
- Fixed translation bugs in macOS version.
- "Restart on error" now defaults to true, if never changed.
- Fixed onion-only mode on iOS 16.

## 1.4.0
- Updated Tor to 0.4.7.10.
- Updated Obfs4proxy to 0.0.14.
- Updated Snowflake to 2.3.1.
- Added a native macOS version.
- Updated Russian translation.
- Added option to automatically restart on error.
- Added option to clear the Tor cache.
- Added pluggable transports (bridges) log.

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
