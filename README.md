# 就活一歩

就職・転職活動のための模擬面接アプリ

An iPhone app for practicing Japanese job interviews. It is a personal, non-commercial project that is not on the App Store. Anyone can build and try it from this public repository.

## Features
- Practice interviews with AI-generated questions, read aloud and answered by voice
- AI evaluation of each answer's structure and logic
- On-device tracking of gaze and head movement during answers
- A calendar for viewing, adding, editing, and deleting interview schedules
- Charts showing how scores and tracking results change over time
- Start without an account, or sign in with Apple to keep your data across devices

## Tech Stack
- App: Swift 6, SwiftUI, ARKit, Speech, AVFoundation, Swift Charts (iOS 18+)
- Server: TypeScript, Hono, Cloudflare Workers (separate repository, link to be added)
- Database: Cloudflare D1 (SQLite)
- Sign-in: Sign in with Apple (optional)
- AI: Claude API

## Getting Started
The project skeleton is not created yet, so the steps below describe the planned setup.

### Prerequisites
- A Mac with Xcode 27 or later
- An Apple account (free accounts work, but the installed app stops launching after 7 days until you install it again)
- A physical iPhone running iOS 18 or later. Gaze and head tracking require a model with Face ID.

### Install
```bash
git clone https://github.com/znak99/JEC-FirstStepToCareer.git
cd JEC-FirstStepToCareer
cp Config/Local.xcconfig.example Config/Local.xcconfig
```
Set your Apple team ID and a unique bundle ID in `Config/Local.xcconfig`. Leave `APPLE_SIGN_IN_ENABLED` as `NO` unless you have a paid Apple Developer Program membership; you can still use every feature without signing in.

### Run
Open `JobHuntFirstStep.xcodeproj` in Xcode, select your iPhone, and press Run.

AI features work only while the developer has turned them on. Schedules and past results remain available when AI is off.

## Privacy
- Camera video and microphone audio are not stored or sent to the server.
- Transcribed answers, tracking numbers, and schedules are stored on the server under an anonymous device token or an Apple account identifier. The server operator can read them.
- Your Apple email and name are not stored.
- Transcribed answers are sent to the Claude API for evaluation.
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
