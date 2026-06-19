# 팀 컨벤션 (2인 협업 · iOS / Tuist µFeature)

> 「개발 요청 문서」 §1 의 결정 기록. 작업 세부 규칙은 `CLAUDE.md`, 제품/도메인 지식은 `lat.md/` 참고.

## 1.1 브랜치
- **전략**: GitHub Flow — `main` + 짧은 수명 `feature/*`.
- **보호**: `main` 직접 push 금지 · force push 금지 · PR 필수.
- **수명**: 며칠 내 머지. 길어지면 잘게 쪼갠다.

## 1.2 네이밍 / 커밋 / PR
- **브랜치명**: `{type}/{짧은-설명}` — `feature/` `fix/` `refactor/` `experiment/` `chore/`.
- **커밋**: `type: 설명_부연` — **제목 1줄 한국어**. type ∈ feat/fix/refactor/docs/test/chore. (기존 규칙 유지, Conventional Commits 미채택) 두 type 에 걸치면 커밋을 쪼갠다 — `chore`(빌드/툴/메타만) vs `refactor`(코드 의미 변경) 구분. 본문 bullet 은 "무엇이 바뀌었는가"를 적고 필요할 때만.
  - 예: `feat: ProfileFeature_화면 간 값 전달 3가지 패턴` · `docs: DocC 카탈로그_튜토리얼·아티클 추가`
- **PR**: `.github/pull_request_template.md` 사용 — 요약 / 영향 모듈(@lat) / 테스트 방법 / 체크리스트.
- **PR 크기**: **1 모듈 단위 권장** (µFeature 라 자연히 작아짐). 리뷰 어려우면 쪼갠다.

## 1.3 리뷰 / 머지 / 릴리즈
- **리뷰**: 승인 **1인 = 상대 개발자**(2인이라 자동). 1차 리뷰 영업일 1일 내 권장(강제 X).
- **머지**: **Squash merge** (PR 1개 = 커밋 1개).
- **릴리즈**: App Store 제출 시 SemVer 태그 `vMAJOR.MINOR.PATCH`.

## 1.4 배포 / 권한 / 시크릿 / 롤백
- **환경**: Debug/Release 스킴 · TestFlight(staging) · App Store(prod).
- **권한**: 2인 모두 빌드/배포 가능. **prod(App Store 제출)은 합의 후**.
- **시크릿**: API 키 등은 `.xcconfig`(gitignore) 또는 환경변수. **코드 하드코딩 금지.** (현재 외부 키 없음 → 키 추가 시점에 발효)
- **롤백**: iOS 는 즉시 롤백 불가(심사). → 직전 태그로 핫픽스 빌드 재제출. 가능 시 App Store 단계적 출시로 노출 차단.
