# ios-ota-updater

This is a small template pretended to be shared with my ios projects, main reason is a update apps distributed outside store and testflight. Because Apple is a company of fucking faggots i need to develop some fucking dirty shit just to have a default simple things like: "Hey bro, i wrote a new funny app, check it". NO! That will be too boring, let's buy a fucking 100$ shitty subscription, each year, tell all my friends how to get their iFart UUID (LAPTOP NEEDED!!1), generate a new fucking profile, each time i added new UUID, sign, sign, sign, sign this crap more, i need to resign all ma apps yeary because they will turn into a pumpkin, into a crappy pumpkin, after a year of usage on all my friend's devices. 

## App side
```swift
import OTAUpdater

let updater = OTAUpdater(feedURL: URL(string: "https://user.github.io/App/update.json")!)
updater.checkOnLaunch { window.rootViewController }
updater.checkNow(from: settingsViewController)
```
Add the package in Xcode via File > Add Package Dependencies with this repository URL

## Release side
`scripts/import_signing.py` - for CI, it reads `P12_BASE64`, `P12_PASSWORD`, `PROFILE_BASE64` envs, creates a temporary keychain, imports the fucking certificate and the fucking provisioning profile, then writes `team_id`, `profile_name`, `keychain` to github output.

`scripts/make_feed.py` renders templates into a directory ready for static hosting:

```bash
scripts/make_feed.py --out build/ota --ipa build/ipa/App.ipa \
    --base-url https://user.github.io/App --bundle-id com.example.App \
    --version 1.2.0 --build 57 --title App --notes notes.md
```
