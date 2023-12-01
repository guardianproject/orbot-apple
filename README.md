#  Orbot iOS / macOS

Torifies your iOS / macOS device running iOS 15 or macOS 11 and newer.

Find links to official releases, beta tests etc. here: https://orbot.app/download

Provides a "VPN" which tunnels all your device network traffic through Tor.

- Supports Obfs4 and Snowflake bridges, fully configurable.
- Supports Onion v3 service authentication.
- Supports Tor's `EntryNodes`, `ExitNodes`, `ExcludeNodes` and `StrictNodes` options.
- Tor 0.4.7.12
- OpenSSL 1.1.1s
- Obfs4proxy 0.0.14
- Snowflake 2.3.1


## Build

### Prerequisits:
- MacOS Big Sur or later
- Xcode 13 or later
- [Homebrew](https://brew.sh)

```sh
brew install cocoapods bartycrouch fastlane rustup-init automake autoconf libtool gettext
rustup-init -y
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios aarch64-apple-darwin x86_64-apple-darwin
cargo install cbindgen
git clone git@github.com:guardianproject/orbot-ios.git
cd orbot-ios
git submodule update --init --recursive
pod update
leaf-ffi-orbot/build-leaf.sh
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

Orbot registers to handle the scheme `orbot` and associates the domain https://orbot.app.

Using the associated domain is preferred, as it protects against other apps trying 
to hijack the `orbot` scheme and it provides a nice fallback for users who don't 
have Orbot installed, yet.

The following URIs are available to interact with Orbot from other apps:

- `https://orbot.app/rc/show` OR `orbot:show` 
  Will just start the Orbot app.
  
- `https://orbot.app/rc/start` OR `orbot:start`
  Will start the Network Extension, if not already started. 
  (NOTE: There's no "stop" for security reasons!)

- `https://orbot.app/rc/show/settings` OR `orbot:show/settings`
  Will show the `SettingsViewController`, where users can edit their Tor configuration.

- `https://orbot.app/rc/show/bridges` OR `orbot:show/bridges`
  Will show the `BridgeConfViewController`, where users can change their bridge configuration.

- `https://orbot.app/rc/show/auth` OR `orbot:show/auth`
  Will show the `AuthViewController`, where users can edit their v3 onion service authentication tokens.

- `https://orbot.app/rc/add/auth?url=http%3A%2F%2Fexample23472834zasd.onion&key=12345678examplekey12345678`
  OR `orbot:add/auth?url=http%3A%2F%2Fexample23472834zasd.onion&key=12345678examplekey12345678`
  Will show the `AuthViewController`, which will display a prefilled "Add" dialog.
  The user can then add that auth key.
  You don't need to provide all pieces. E.g. for the URL the second-level domain would be enough.
  Orbot will do its best to sanitize the arguments.
  
You can call these URIs like this:

```swift
	UIApplication.shared.open(URL(string: "https://orbot.app/rc/start")!)
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
  yahoe.001, Guirlandia

- Russian:
  ViktorOnlin, ktchr, Ifti, Pihjun, ZiPERR, anm, dianazryn, foxing29, keelzhanke,
  neocaching, sloncocs, userNameIsBoris, emedvedev

- Spanish:
  Fabiola.mauriceh, Aetheria, Fitoschido, Maria_Jose, NorwegianFox, cacu, kodachi,
  lenazun, m_rey, nosense, strel, supermigue2000, vareli, zakooch, Elos, antonela_,
  arielbarbosa, emmapeel

- Ukrainian:
  Kataphan, Herenko, MykolaBubelich, Pihjun, gr3ttle, lyubomyr
  
- Arabic:
  AboShanab, BNasr, Bild96, Hujairi, Israel.K, LU_er, MissPeace, Souffex, 
  ahmedessamdev, nouribram, zer0x, mada19
  
- Croatian:
  paranatox, tomislav.capan, milotype
  

## Tech Stuff

Figma template used to create rounded MacOS icons:
https://www.figma.com/community/file/857303226040719059

### How to use experimental Onionmasq/Arti
- Change the reference to Tor in the Podfile to `Tor/Onionmasq` and use the `:git` master or download 
  into another directory and reference that. Run `pod update` after that.
- Change the key `NSExtensionPrincipalClass` from `$(PRODUCT_MODULE_NAME).LeafPTProvider` 
  to `$(PRODUCT_MODULE_NAME).OnionmasqPTProvider` in `TorVPN/Info.plist` and/or `TorVPN Mac/Info.plist`.
- Configure your code signing credentials in [`Config.xcconfig`](Shared/Config.xcconfig).

=> You should be good to go. 

Look out for `USE_ONIONMASQ` references in the code: there you'll find the 
special handling necessary for Onionmasq.

NOTE: No bridge support, yet! iOS 50 MB memory limit might crash Onionmasq. 
There's no limit on macOS. 


## Further reading

https://tordev.guardianproject.info


## Author, License

Benjamin Erhart, [Die Netzarchitekten e.U.](https://die.netzarchitekten.com)

Under the authority of [Guardian Project](https://guardianproject.info)
with friendly support from [The Tor Project](https://torproject.org).

Licensed under [MIT](LICENSE).

Artwork taken from [Orbot Android](https://github.com/guardianproject/orbot),
licensed under [BSD-3](https://github.com/guardianproject/orbot/blob/master/LICENSE).
