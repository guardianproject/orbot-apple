#  Orbot iOS

Torifies your iOS device running iOS 15 and newer.

Provides a "VPN" which tunnels all your device network traffic through Tor.

- Supports Obfs4 and Snowflake bridges, fully configurable.
- Supports Onion v3 service authentication.
- Supports Tor's `EntryNodes`, `ExitNodes`, `ExcludeNodes` and `StrictNodes` options.
- Tor 0.4.6.9
- OpenSSL 1.1.1m
- Obfs4proxy 0.0.13
- Snowflake 2.1.0


## Build

### Prerequisits:
- MacOS Big Sur or later
- Xcode 13 or later
- [Homebrew](https://brew.sh)

```sh
brew install cocoapods bartycrouch fastlane rustup-init automake autoconf libtool gettext
rustup-init -y
rustup target add aarch64-apple-ios aarch64-apple-sim x86_64-apple-ios
cargo install cargo-lipo cbindgen
git clone git@github.com:guardianproject/orbot-ios.git
cd orbot-ios
git submodule update --init --recursive
pod update
open Orbot.xcworkspace
```

Configure your code signing credentials in [`Config.xcconfig`](Shared/Config.xcconfig)!

You will need to manually create App IDs, a group ID, and profiles.

[Network Extensions](https://developer.apple.com/documentation/networkextension)
can only run on real devices, not in the simulator.


## Localization

Localization is done with [BartyCrouch](https://github.com/Flinesoft/BartyCrouch),
licensed under [MIT](https://github.com/Flinesoft/BartyCrouch/blob/main/LICENSE).

Just add new `NSLocalizedStrings` calls to the code. After a build, they will 
automatically show up in [`Localizable.strings`](Shared/en.lproj/Localizable.strings).

Don't use storyboard and xib file localization. That just messes up everything.
Localize these by explicit calls in the code.


## IPC / Use with Other Apps

Orbot registers the scheme handler "orbot".

These URIs are available to interact with Orbot from other apps:

- `orbot:show`
  Will just start the Orbot app.
  
- `orbot:show.settings`
  Will show the `SettingsViewController`, where users can edit their Tor node configuration.

- `orbot:show.bridges`
  Will show the `BridgeConfViewController`, where users can change their bridge configuration.

- `orbot:show.auth`
  Will show the `AuthViewController`, where users can edit their v3 onion service authentication tokens.

- `orbot:add.auth?url=http%3A%2F%2Fexample23472834zasd.onion&key=12345678examplekey12345678`
  Will show the `AuthViewController`, which will display a prefilled "Add" dialog.
  The user can then add that auth key.
  You don't need to provide all pieces. E.g. for the URL the second-level domain would be enough.
  Orbot will do its best to sanitize the arguments.
  
You can call these URIs like this:

```swift
	UIApplication.shared.open(URL(string: "orbot:show.bridges")!, options: [:])
```


## Direct Dependencies

- [leaf](https://github.com/eycorsican/leaf), licensed under [Apache 2.0](https://github.com/eycorsican/leaf/blob/master/LICENSE)
- [Tor.framework](https://github.com/iCepa/Tor.framework), licensed under [MIT](https://github.com/iCepa/Tor.framework/blob/master/LICENSE)
- [IPtProxyUI](https://github.com/tladesignz/IPtProxyUI-ios), licensed under [MIT](https://github.com/tladesignz/IPtProxyUI-ios/blob/master/LICENSE)
- [ReachabilitySwift](https://github.com/ashleymills/Reachability.swift), licensed under [MIT](https://github.com/ashleymills/Reachability.swift/blob/master/LICENSE)
- [Eureka](https://github.com/xmartlabs/Eureka), licensed under [MIT](https://github.com/xmartlabs/Eureka/blob/master/LICENSE)


## Acknowledgements

These people helped with translations. Thank you so much, folks!

- French: 
  yahoe.001
- Spanish:
  Fabiola.mauriceh
- Ukrainian
  Kataphan

## Author, License

Benjamin Erhart, [Die Netzarchitekten e.U.](https://die.netzarchitekten.com)

Under the authority of [Guardian Project](https://guardianproject.info)
with friendly support from [The Tor Project](https://torproject.org).

Licensed under [MIT](LICENSE).

Artwork taken from [Orbot Android](https://github.com/guardianproject/orbot),
licensed under [BSD-3](https://github.com/guardianproject/orbot/blob/master/LICENSE).
