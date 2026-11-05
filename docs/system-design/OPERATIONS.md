# OPERATIONS

## 1. 환경 구성
| 환경 | 용도 | 접근 경로 | 비고 |
|---|---|---|---|
| local | 개발 | http://localhost:8787 | `wrangler dev`, 로컬 D1 |
| production | 실제 사용 | Workers URL (서버 첫 배포 때 기록) | 공개 저장소에 적히는 공개 주소 |

## 2. 환경 변수
실제 값은 커밋하지 않는다. 로컬 서버는 `api/.dev.vars`, 운영 서버는 Wrangler secret을 쓴다.

### 서버
| 이름 | 설명 | 필수 | local 기본값 |
|---|---|---|---|
| ANTHROPIC_API_KEY | Claude API 비밀 키 | 예 | 없음 |
| ANTHROPIC_MODEL | 사용할 모델 ID. 비용 조절을 위해 코드 수정 없이 변경 | 아니오 | claude-opus-5-5 |
| APPLE_BUNDLE_IDS | Apple 로그인을 허용할 번들 ID 목록(쉼표 구분). 비어 있으면 Apple 로그인 거부 | 아니오 | 없음 |

### 앱 (`Config/`)
| 이름 | 설명 | 필수 | local 기본값 |
|---|---|---|---|
| API_BASE_URL | 서버 주소. `Shared.xcconfig`에 커밋 | 예 | http://localhost:8787 |
| DEVELOPMENT_TEAM | 빌드하는 사람의 Apple 팀 ID. `Local.xcconfig`에 작성. 실제 iPhone 설치에 필요하고 시뮬레이터에는 불필요 | 실제 기기만 | 없음 |
| APP_BUNDLE_ID | 번들 ID. 다른 Apple 계정으로 빌드할 때는 `Local.xcconfig`에서 고유한 값으로 덮어씀 | 예 | cloud.znak99.FirstStepToCareer |
| APPLE_SIGN_IN_ENABLED | Apple 로그인 버튼과 권한 사용 여부. `Local.xcconfig`에 작성 | 아니오 | NO |

## 3. 실행·빌드·테스트
앱 명령은 실행해 확인했다. 서버 명령은 서버 골격을 만들 때 확인하고 다르면 고친다. Node.js 버전은 mise로 `api/`에만 고정한다.

### 서버 (`api/`에서 실행)
| 작업 | 명령 |
|---|---|
| 의존성 설치 | `npm ci` |
| 개발 실행 | `npm run dev` |
| 빌드 | `npm run typecheck` |
| 테스트 | `npm test` |
| 린트·포맷 | `npm run lint` |

### 앱 (저장소 최상위에서 실행)
| 작업 | 명령 |
|---|---|
| 의존성 설치 | 없음 |
| 개발 실행 | Xcode에서 `JobHuntFirstStep.xcodeproj`를 열고 실행. 시선·머리 측정은 실제 iPhone 필요 |
| 빌드 | `xcodebuild build -project JobHuntFirstStep.xcodeproj -scheme JobHuntFirstStep -destination 'generic/platform=iOS Simulator'` |
| 테스트 | `xcodebuild test -project JobHuntFirstStep.xcodeproj -scheme JobHuntFirstStep -destination 'platform=iOS Simulator,name=iPhone 17'` |
| 린트·포맷 | `swift format lint -r JobHuntFirstStep JobHuntFirstStepTests` |

시선·머리 측정은 시뮬레이터에서 동작하지 않으므로 Face ID가 있는 실제 iPhone에서 확인한다.

## 4. 배포
- 서버 방법: `api/`에서 `npx wrangler deploy`
- 앱 방법 1, TestFlight: 개발자가 빌드를 올리고 공개 링크를 공유한다. 받는 사람은 TestFlight 앱을 설치한 뒤 링크를 연다.
- 앱 방법 2, 소스 직접 빌드: 사용자가 저장소를 받아 `Local.xcconfig`를 작성하고 Xcode로 직접 설치한다. 무료 Apple 계정으로 설치한 앱은 7일 뒤 실행되지 않으므로 같은 계정으로 다시 설치한다.

### TestFlight
개발자의 번들 ID와 Apple 로그인을 켠 설정으로 빌드한다. 구체적인 명령과 절차는 TestFlight 배포 설정 태스크에서 실제로 진행하며 채운다.
1. App Store Connect에 앱을 등록한다.
2. Xcode에서 Archive해 빌드를 업로드한다.
3. 외부 테스트 그룹을 만들어 베타 심사를 받고 공개 링크를 켠다.
4. 빌드는 90일이 지나면 만료되므로 그 전에 새 빌드를 올린다.

베타 심사 중에는 심사자가 기능을 시험할 수 있도록 AI 스위치를 켜 둔다. 끝나면 끈다.

### Apple 로그인
무료 Apple 계정으로 빌드할 때는 `APPLE_SIGN_IN_ENABLED`를 `NO`로 두고 로그인 없이 사용한다. 켜려면 다음을 모두 해야 한다.
1. Apple Developer Program에 가입한다.
2. 앱의 App ID에 Sign in with Apple 기능을 켠다.
3. `Local.xcconfig`에서 `APPLE_SIGN_IN_ENABLED = YES`로 설정한다.
4. 그 번들 ID를 서버의 `APPLE_BUNDLE_IDS`에 추가한다.

### AI 스위치
`api/`에서 실행한다. Cloudflare 대시보드의 D1 콘솔에서 같은 SQL을 실행해도 된다. 다시 배포할 필요는 없다.

| 작업 | 명령 |
|---|---|
| 켜기 | `npx wrangler d1 execute <DB 이름> --remote --command "UPDATE app_setting SET value = '1', updated_at = datetime('now') WHERE key = 'ai_enabled'"` |
| 끄기 | `npx wrangler d1 execute <DB 이름> --remote --command "UPDATE app_setting SET value = '0', updated_at = datetime('now') WHERE key = 'ai_enabled'"` |

### 비용 안전장치
서버 주소는 공개 저장소에 있으므로, 스위치가 켜진 동안에는 앱 사용자가 아닌 사람도 API를 호출할 수 있다.
- 시연이 끝나면 스위치를 끈다.
- Claude Console에서 월 사용 한도를 설정한다.
- 서버는 입력 길이와 질문 수를 제한해 요청 한 건의 비용을 묶어 둔다.

## 5. 로그
- 콘솔 출력. 운영 서버는 `npx wrangler tail`로 확인한다.
- 답변 원문과 기기 토큰은 로그에 남기지 않는다.
