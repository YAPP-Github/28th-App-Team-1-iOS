# Commit Message 가이드

커밋 메시지 작성 규칙.

## Overview

본 프로젝트의 모든 커밋은 아래 형식을 따른다. CI 가 강제하지는 않지만 리뷰어가
변경 의도를 빠르게 파악할 수 있도록 일관성을 유지한다.

```
<type>: <subject>_<detail>

- <본문1: 첫 번째 주요 변경 사항>
- <본문2: 두 번째 주요 변경 사항>
- <본문3: 세 번째 주요 변경 사항>

<footer>
```

본문 작성 규칙:

- 각 항목은 `-` (하이픈)으로 시작하여 bullet point 형식으로 작성한다.
- 주요 변경 사항을 위에서 아래로 순서대로 나열한다.
- 구체적이고 명확한 변경 내역을 적는다.
- 본문은 생략 가능하며 여러 줄로 작성한다.

## Type 키워드

| 키워드 | 사용 시점 |
| --- | --- |
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `!BREAKING CHANGE` | 커다란 API 변경의 경우 |
| `!HOTFIX` | 급하게 치명적인 버그를 고쳐야 하는 경우 |
| `docs` | 문서 수정 |
| `style` | 코드 포맷 변경, 세미콜론 누락, 코드 수정이 없는 경우 |
| `design` | 사용자 UI 디자인 변경 (DesignSystemKit 등) |
| `refactor` | 버그를 수정하거나 기능을 추가하지 않는 코드 변경 |
| `comment` | 필요한 주석 추가 및 변경 |
| `test` | 누락된 테스트 추가 또는 기존 테스트 수정 |
| `chore` | 폴더 수정, 빌드 업무, 패키지 매니저 수정, 패키지 관리자 구성 등. Production Code 변경 없음 |
| `release` | 버전 릴리즈 |
| `rename` | 파일 혹은 폴더명을 수정 |
| `remove` | 파일을 삭제 |

## Footer 키워드

| 키워드 | 사용 시점 |
| --- | --- |
| `resolves` | 이슈를 해결한 경우 |
| `ref` | 참조할 이슈가 있는 경우 |
| `related to` | 현재 커밋과 관련된 이슈가 있는 경우 (미해결 상태) |

## 예시

```
feat: 회원가입_로그인 API 개발

- 신규 간편 이메일/모바일 회원가입 기능 구현
- OTP 코드 재발송 API 추가
- 회원가입 유효성 검증 로직 적용

resolves: #123
ref: #456
related to: #78, #90
```

본 프로젝트의 실제 커밋 예시:

```
feat: ProfileFeature_화면 간 값 전달 3가지 패턴 구현

- ProfileClient Dependency 추가 (live/preview/test)
- Case A — id 만 전달 후 화면에서 fetch
- Case B — User 객체 전체 전달 (기존)
- Case C — 저장 결과를 delegate 로 부모에 반환

ref: #42
```

```
docs: DocC 카탈로그_튜토리얼·아티클 추가

- AddingFeature / NavigationPatterns 아티클 작성
- AddingFeatureTutorial / NavigationPatternsTutorial 추가
- 모든 public 심볼에 /// 주석 부착
```

## 작성 팁

**언제 쓰는가** — 모든 커밋. PR 제목도 같은 형식을 따른다.
**어떻게 쓰는가** — `type` 은 위 표에서 정확히 하나만 고른다. 두 개에 걸치면 커밋 자체를 쪼개라는 신호다. `subject` 는 한 줄에 무엇을 건드렸는지 명사 위주로, `detail` 은 주요 수정 내역을 짧게 덧붙인다.
**주의할 점** — `chore` 와 `refactor` 는 자주 헷갈리는데, 코드 의미가 바뀌었으면 `refactor`, 빌드/툴/메타 파일만 만졌으면 `chore` 다. 본문 bullet 은 "무엇을 했는가" 가 아니라 "무엇이 바뀌었는가" 를 적는 편이 리뷰어에게 더 유용하다.

## See Also

- <doc:AddingFeature>
- <doc:NavigationPatterns>
