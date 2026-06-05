<!-- 커밋 제목 규칙: `type: 설명_부연` (한국어, 1줄). type ∈ feat/fix/refactor/docs/test/chore -->

## 변경 요약
<!-- 무엇을, 왜 바꿨는지 1~3줄 -->


## 영향 모듈 / 도메인
<!-- 건드린 lat.md 도메인. cross-feature 의존이 있으면 반드시 표기 (import 에 안 보이므로) -->
<!-- 예: [[profile#Save]] 변경 → [[users]], [[app]] 영향 / 확인: make lat q=profile -->
- 

## 테스트 방법
<!-- 어떤 스킴/케이스로 확인했는지. 예: make test scheme=UsersFeature -->
- 

## 체크리스트
- [ ] cross-feature 흐름을 바꿨다면 `@lat` / `depends-on` 라벨 갱신
- [ ] 도메인 흐름을 바꿨다면 해당 `lat.md/*.md` 갱신 (같은 PR 안에서)
- [ ] `*ClientInterface` 시그니처를 바꿨다면 Live + 소비 Feature + `testValue` 동시 반영
- [ ] DesignSystemKit 토큰 사용 (색상/타이포/spacing 하드코딩 없음)
- [ ] Squash merge 예정 (히스토리 1커밋)
