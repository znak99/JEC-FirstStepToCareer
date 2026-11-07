# 就活一歩

就職・転職活動のための模擬面接アプリ

An iPhone app for practicing Japanese job interviews. It is a personal, non-commercial project that is not on the App Store. Anyone can install it through TestFlight or build it from this public repository.

## Features
- Practice interviews by voice with an AI interviewer that reacts to each answer and asks the next question, like a real interview
- A score for each answer's structure, logic, gaze, and head movement, plus overall feedback
- On-device tracking of gaze and head movement during answers
- Charts showing how scores and tracking results change over time
- Start without an account, or sign in with Apple to keep your data across devices

## Tech Stack
- App: Swift 6, SwiftUI, ARKit, Speech, AVFoundation, Swift Charts (iOS 18+)
- Server: TypeScript, Hono, Cloudflare Workers (private repository, not needed to build the app)
- Database: Cloudflare D1 (SQLite)
- Sign-in: Sign in with Apple (optional)
- AI: Claude API

## Getting Started
The app is not available yet, so the steps below describe the planned setup.

### Install with TestFlight
Install the free TestFlight app from the App Store, then open the public link. The link will be added here when it is ready.

### Build from source

#### Prerequisites
- A Mac with Xcode 27 or later
- An Apple account (free accounts work, but the installed app stops launching after 7 days until you install it again)
- A physical iPhone running iOS 18 or later. Gaze and head tracking require a model with Face ID.

#### Install
```bash
git clone https://github.com/znak99/JEC-FirstStepToCareer.git
cd JEC-FirstStepToCareer
cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig
```
Set your Apple team ID and uncomment `APP_BUNDLE_ID` with a unique value in `ios/Config/Local.xcconfig`. Leave `APPLE_SIGN_IN_ENABLED` as `NO` unless you have a paid Apple Developer Program membership; you can still use every feature without signing in.

#### Run
Open `ios/FirstStepToCareer.xcodeproj` in Xcode, select your iPhone, and press Run.

### Availability
AI features work only while the developer has turned them on. Past results remain available when AI is off.

## Privacy
- Camera video and microphone audio are not stored or sent to the server.
- Answers are transcribed with Apple's speech recognition. It runs on the iPhone when supported; otherwise Apple may process the audio on its servers under Apple's privacy policy.
- Transcribed answers and tracking counts are stored on the server under an anonymous device token or an Apple account identifier. The server operator can read them.
- Your Apple email and name are not stored.
- Transcribed answers are sent to the Claude API for evaluation.
- You can delete all of your data from the menu at any time.
- Without signing in, data cannot be recovered if the device token is lost. Signing in with Apple lets you reach it again from the same build on another device.

## Documentation
| Document | What it covers |
|---|---|
| [AGENTS.md](AGENTS.md) | Rules for AI agents working in this repository |
| [TASK.md](TASK.md) | Current tasks |
| [docs/common/GIT_STRATEGY.md](docs/common/GIT_STRATEGY.md) | Branching and commits |
| [docs/system-design/ARCHITECTURE.md](docs/system-design/ARCHITECTURE.md) | Architecture and design decisions |
| [docs/system-design/DATA.md](docs/system-design/DATA.md) | Data model |
| [docs/system-design/OPERATIONS.md](docs/system-design/OPERATIONS.md) | Running, building, deploying |
| [docs/ui-design/SITE_MAP.md](docs/ui-design/SITE_MAP.md) | Screens and flows |

## License
<!-- TODO: fill in, or delete this section -->
