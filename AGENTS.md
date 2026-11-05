# AGENTS.md

This file is the entry point for every AI agent working in this repository.
Keep it short. Detailed rules live in the documents linked below.

## Profile
- Scale: small
- Type: Mobile
- Server: yes
- Service language: ja
- Template version: 1.0.0

## Project Overview
就職・転職活動のための模擬面接アプリ

See [README.md](README.md) for details.

## Language Policy
| Target | Language |
|---|---|
| AGENTS.md, README.md, docs/common/* | English |
| All other documents (TASK.md, DONE.md, docs/system-design/*, docs/ui-design/*) | Korean |
| Conversation and reports to the user | Korean |
| Commit messages, PR titles and bodies, code comments | Korean |
| Code identifiers (variables, functions, file names) | English |
| Text the end user sees in the product (UI labels, messages, i18n resources) | Service language (ja) |

The service language applies only to text the end user sees in the product. Even when the product is in English or Japanese, every other row stays as listed: documents, conversation, commits, PRs, and code comments remain in Korean.

## Documentation Map
| Document | Purpose | Read when | Update when |
|---|---|---|---|
| [docs/common/FEEDBACK.md](docs/common/FEEDBACK.md) | Corrections the user has given to agents | Every session, before any work | Immediately when the user corrects you — append one line |
| [TASK.md](TASK.md) | Current tasks and status | Every session start | A task starts, finishes, or is blocked |
| [DONE.md](DONE.md) | Archive of finished tasks | Only when past history is needed | When 완료 in TASK.md exceeds 10 entries |
| [docs/common/TASK_GUIDE.md](docs/common/TASK_GUIDE.md) | How to write TASK.md | Before editing TASK.md | Never (template-owned) |
| [docs/common/GIT_STRATEGY.md](docs/common/GIT_STRATEGY.md) | Branch, commit, PR, release rules | Before any git operation | Never (template-owned) |
| [docs/system-design/ARCHITECTURE.md](docs/system-design/ARCHITECTURE.md) | Stack, structure, design decisions | Before structural changes | Structure or a key decision changes |
| [docs/system-design/DATA.md](docs/system-design/DATA.md) | Entities, schema, migrations | Before touching the data layer | Schema changes |
| [docs/system-design/OPERATIONS.md](docs/system-design/OPERATIONS.md) | Run, build, deploy, env vars | Before running or deploying | Commands or env vars change |
| [docs/ui-design/SITE_MAP.md](docs/ui-design/SITE_MAP.md) | Screens, routes, flows | Before UI work | Screens or routes change |

## Workflow
1. Read FEEDBACK.md, then TASK.md.
2. Confirm which task to work on. If the user asks for work that is not in TASK.md, add it to TASK.md first — split into a task with sub-tasks as TASK_GUIDE.md describes — and record what it changes in the relevant design documents. If the task is unclear, ask before starting.
3. Investigate, then propose a plan: approach, files to change, risks. Wait for explicit approval before changing any code.
4. If the plan must change significantly during implementation, stop and re-confirm.
5. Follow GIT_STRATEGY.md for branches and commits.
6. Before reporting done: tests pass, and TASK.md and every affected document in the map above are updated — inside the commits themselves, as GIT_STRATEGY.md describes.
7. Report in Korean: what changed, which files, and what was not done.

Updating TASK.md and FEEDBACK.md as part of this workflow does not require approval.

## Communication
- **Important:** when reporting or explaining anything, assume the user has no prior knowledge of the topic. Use plain words, define terms the first time they appear, and never rely on unexplained jargon.
- Be brief and clear by default. When the user asks for more detail, go deeper, but keep it just as easy to understand.

## Working Principles
- Do only what the task asks. No unrequested features or refactors.
- Prefer the smallest change that solves the problem. Match existing patterns.
- Do not add dependencies without asking.
- Keep comments minimal. Explain why, not what.
- Never report a task as done without verifying it works.

## Project-Specific Rules
- Layout: this repository holds the SwiftUI app in `ios/` and the shared design documents. The Hono API on Cloudflare Workers with D1 is a separate private Git repository checked out at `api/` and ignored by this repository. Run server Git commands inside `api/`, commit there separately, and follow that repository's own rules. Commands are in docs/system-design/OPERATIONS.md.
- The design documents here are the single source for the API contract and data model. When either changes, update them here and report what `api/` must change.
- Respect the layer directions in docs/system-design/ARCHITECTURE.md section 5.
- Before every commit that changes the app, build and test with `xcodebuild` and lint with `swift format lint -r ios`.
- This is a public repository. The Claude API key lives only on the server. Never commit `ios/Config/Local.xcconfig` or any real secret, and never put a secret in the app.
- The app must handle `503 AI_DISABLED` by explaining that AI is off and keeping past results usable. Automated tests must mock the server and never spend real API credit.
- Never turn the production AI switch on or off, deploy, upload a TestFlight build, or apply remote migrations unless the user asks.
- Sign in with Apple is a build setting that is off by default, because free Apple accounts are expected to lack it. Every feature must work for guests. Send identity tokens only to the server, and never store the Apple email or name.
- Never send or store camera video or microphone audio. Gaze and head tracking stay on the device; only numeric results and the transcript go to the server. Never log transcripts or device tokens.
- Face tracking needs a physical iPhone with Face ID. Say so in the report when a change could not be verified on one.
- User-facing strings are Japanese and go through String Catalogs. AI prompts must request Japanese questions and feedback.

## Hard Rules
- Never force-push to main (or develop).
- Never commit secrets, credentials, or .env files.
- Never install libraries, tools, or packages globally (outside the project) without the user's approval.
- Never run destructive commands (rm -rf, DROP, git reset --hard, history rewrites) without explicit confirmation.
- Do not edit template-owned documents (docs/common/*) unless the user asks. FEEDBACK.md is the exception.
