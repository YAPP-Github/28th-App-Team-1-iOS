# Architecture — 시스템 설계 & 핵심 결정

> SwiftUI + TCA · Tuist 멀티프로젝트 µFeature. 이 문서는 **시스템 전체 그림과 "왜 이렇게 했는가"**만 담는다.
> 작업 규칙은 `CLAUDE.md`, 심볼/API 레퍼런스는 `Projects/App/Documentation/Architecture.docc` 를 본다. (중복 작성 금지)

## 레이어 & 의존 방향

```
App → AppFeature → *Feature → *ClientInterface → Models
        (코디네이터)   (화면)      (Repository 계약)
전 모듈 → DesignSystemKit
```

- **App**: composition root. `*ClientLive` 를 link 해 `liveValue` 활성화.
- **AppFeature**: 탭 코디네이터 + cross-feature 라우팅. → [[app#Cross-feature Routing]]
- **Feature**: 화면 도메인. 단일 모듈(+Testing/Tests/Example).
- **Client**: 외부 IO. `Interface` / `Live` 분리. → [[clients]]

## 핵심 결정 (Trade-off 기록)

### D1. Feature → Feature 의존 = 0 (delegate-only)
다른 Feature 로의 전환은 `delegate` 신호만 올리고, 조립은 **AppFeature 에서만** 한다.
- **이유**: 결합 0, 컴파일 격리, 피쳐 단독(Example) 실행.
- **비용**: cross-feature 의존이 **import 에 안 보인다** → 변경 영향 추적이 어려움. → 이 약점을 `@lat depends-on` 라벨로 메운다. (lat.md 도입 제1 명분)

### D2. 단일 코디네이터 (AppFeature)
피쳐별 sub-coordinator 대신 AppFeature 하나가 모든 cross-feature 를 중재.
- **이유**: 2인 / 모듈 ~10개 규모에선 분산 코디네이터의 빌드격리 이득이 거품.
- **재검토 임계점**: 피쳐 15개↑ 또는 다단계 cross-feature 네비가 일상화되면 sub-coordinator + Feature Interface 로 전환 검토.

### D3. Client 만 Interface/Live 분리 (Feature Interface 폐기)
Feature 는 인터페이스를 두지 않는다. (git: `Phase 3_Feature Interface 폐기`)
- **이유**: TCA 단일 트리에선 Feature Interface 가 State 를 통째로 public 노출시켜 캡슐화 이득이 절반인데 보일러플레이트는 4겹. 실험(`experiment/feature-interface-tma` 브랜치)으로 비용 재확인 후 폐기.
- **왜(언어/매크로 레벨 근거)**: `@Reducer` 매크로 + `some` 정적 합성이 구체 타입을 강제 → 인터페이스로 못 가린다. 상세 → [[feature-interface]]

## 디자인 시스템
`DesignSystemKit` 토큰 우선: `Color.dsPrimary` / `Font.dsBody` / `CGFloat.dsL` / `PrimaryButton`. 하드코딩 지양.
