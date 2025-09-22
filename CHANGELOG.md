#  Orbot Apple Changelog

## 1.8.1
- Added UPnP/NAT-PMP support to allow unrestricted Snowflake Proxy access.
- Replaced "Meek Azure" with "Meek" as suggested by Tor Project.
- Updated translations.
- Updated Tor to latest version 0.4.8.18.
- Improved VoiceOver accessibility support.
- MacOS: Disable window minimization for modal windows, because that deadlocks the app when used. 

## 1.8.0

- Added Kindness Mode. (Provides a Snowflake Proxy to help others.)
- Added Farsi translation.

## 1.7.7
- Updated Tor to latest version 0.4.8.17.

## 1.7.6
- Updated Tor to latest version 0.4.8.16.
- Updated Snowflake to latest version 2.11.0. (Affects macOS only.)
- Updated Lyrebird to latest version 0.6.1. (Affects macOS only.)
- Minor localization updates.

## 1.7.5
- Updated Tor to latest version 0.4.8.14.
- Fixed widget on iOS 17 and up.
- Fixed crash on config change.

## 1.7.4
- Fixed issue with finding the correct circuit for onion domains. (Affects other apps which use the Orbot API.) 
- Updated Tor to latest version 0.4.8.13.
- Updated leaf to latest version 0.11.0.
- Updated Snowflake to latest version 2.10.1. (Affects macOS only.)
- Updated Lyrebird to latest version 0.5.0. (Affects macOS only.)

## 1.7.3
- Fixed Webtunnel support.

## 1.7.2
- Updated Tor to latest version 0.4.8.12.

## 1.7.1
- Updated Tor to latest version 0.4.8.11.
- Updated translations.
- Fixed issue with still selected bridges on iOS where we had to remove bridge support.
- Added WebTunnel support to macOS version.
- Fixed crash when deleting block items.

## 1.7.0
- Removed support for Obfs4proxy and Snowflake on iOS to reduce RAM usage.
- Added toggle to disable GeoIP which reduces RAM usage on iOS.
- Updated leaf dependency used for routing traffic.
- Updated Snowflake support for macOS.

## 1.6.7
- Updated Tor to latest version 0.4.8.10.
- Updated Snowflake to latest version 2.8.0.
- Updated Ukrainian translation.

## 1.6.6
- Added Croatian translation.
- Updated Spanish translation.
- Updated Snowflake to latest version 2.7.0.
- Fixed Snowflake AMP support.
- Updated Tor to latest version 0.4.8.7.
- Show new circuit type "CONFLUX_LINKED" in circuits list. 

## 1.6.5
- Brought back "Clear Cache" button on the home screen.
- Added setting to always clear the cache automatically before start.
- Reduced `MaxMemInQueues` to 5 MB again.
- Updated Snowflake configuration to make it work again.
- Added Meek Azure support, since it still works, albeight often slowly.
- Removed deprecated CAPTCHA support which is now completely replaced by automatic configuration.
- Improved "Ask Tor" auto-configuration:
  - Update built-in Obfs4 and Snowflake configuration on the fly without the need for a new app release.
  - Store private Obfs4 bridges for later use if we happen to receive any. 
- Fixed minor issue where the "strict nodes" setting didn't show its real state.
- Improved minor details in edge cases.

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
