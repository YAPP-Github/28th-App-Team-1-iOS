---
name: tca-preview
description: TCA Feature 화면의 시나리오별 SwiftUI #Preview(캔버스 탭) 생성·갱신. 사용자가 화면·뷰·피쳐 이름을 대며 "프리뷰 만들어/추가해/갱신해" 라고 하면 반드시 이 스킬을 사용한다. "프리뷰"라는 단어가 없어도 "OO 화면 로딩/선택/에러 상태를 눈으로 보고 싶다", "OO 화면 케이스별로 확인하고 싶다" 처럼 화면의 여러 상태를 시각적으로 확인하려는 요청이면 이 스킬이다. 리듀서 State·의존성과 View 분기를 분석해 시각적으로 구별되는 케이스만 골라 이름 있는 #Preview 블록을 View 파일에 추가하고 컴파일까지 검증한다.
---

# TCA 시나리오 프리뷰 생성

지정된 화면의 View 파일 하단에 리듀서 상태별 `#Preview("이름")` 블록들을 추가한다. 블록 하나가 Xcode 캔버스에서 탭 하나가 된다 — 목표는 "이 화면이 가질 수 있는 모습 전부"를 탭으로 한눈에 훑게 하는 것.

## 1. 파일 찾기

화면 이름 X(예: "Onboarding", "OnboardingView", "온보딩 화면")가 주어지면:

- View: `Projects/Feature/Feature*/Sources/*View.swift` glob 으로 찾는다. 한국어로 말하면("온보딩") 파일명·주석을 grep 해서 매핑한다.
- Reducer: 같은 디렉토리의 `*Feature.swift`.
- 후보가 여럿이고 애매하면 가장 그럴듯한 것을 골라 진행하고, 결과 보고에 어떤 파일을 골랐는지 명시한다 (중간에 묻지 않는다).

## 2. 케이스 도출 — View 분기에서 나온다, State 조합이 아니라

State 프로퍼티의 조합을 열거하면 반드시 과해진다. "과하지 않게 모든 케이스"의 기준은 **캔버스에서 다르게 보이는가** 하나다:

1. View body 의 조건 분기를 찾는다 — `if`/`switch`/삼항/`.disabled`/`.opacity`/빈 배열 `ForEach` 등 렌더링이 달라지는 지점.
2. 시각적으로 구별되는 화면마다 프리뷰 1개. 똑같이 보이는 State 조합은 만들지 않는다.
3. Reducer 를 읽고 각 분기에 도달하는 State 값·의존성 조건을 역산한다.
4. 상한은 화면당 5개 — 넘으면 대표적인 것만 남긴다.
5. **View 에 UI 가 없는 상태는 만들지 않는다.** 예: 리듀서에 `loadFailed` 액션이 있어도 View 에 에러 표시가 없으면 에러 프리뷰는 빈 화면일 뿐이다. 건너뛰고 보고에 남긴다.

전형적 결과 세트: 기본(데이터 로드됨) / 로딩 중 / 빈 데이터 / 선택·활성 상태.

## 3. State 에 특정 값 넣기

- init 파라미터에 없는 프로퍼티는 **직접 세팅한다** — 프리뷰는 리듀서와 같은 모듈이라 `var` 프로퍼티에 접근 가능하고, 명시적 `return` 을 쓰면 `#Preview` 클로저 안에 문장을 둘 수 있다:

  ```swift
  #Preview("직군 선택됨") {
      var state = OnboardingFeature.State(userName: "은서")
      state.jobs = Job.previews
      state.selectedJobID = 3
      return OnboardingView(store: Store(initialState: state) { OnboardingFeature() })
  }
  ```

- 데이터를 State 에 미리 넣으면 onAppear 의 fetch 가드(`jobs.isEmpty` 등)를 자연히 통과 못 해 로드가 안 도는 경우가 많다 — 의존성 스텁 없이도 결정적인 프리뷰가 된다. 리듀서의 가드 조건을 읽고 판단한다.
- **State·Reducer 코드는 절대 고치지 않는다.** 기존 init/프로퍼티로 표현 불가능한 케이스는 건너뛰고 결과 보고에 남긴다 (구조 변경 제안은 보고에만).

## 4. 의존성 스텁

- 기본 케이스는 스텁이 필요 없다 — 프리뷰는 `.preview` 컨텍스트라 `@Dependency` 가 `previewValue` 로 자동 해석된다 (모든 Domain Client Interface 가 previewValue 를 가진다).
- 샘플 데이터는 Interface 의 공용 샘플(`Job.previews` 같은 `static let previews`)을 재사용한다. 화면 특성이 안 드러나면(예: flow 레이아웃인데 샘플이 적어 줄바꿈이 안 보임) 파일 하단에 `private let` 샘플을 만들어 쓴다.
- **로딩 탭**: State 값 세팅만으로는 라이브 프리뷰에서 effect 가 즉시 성공해 로딩이 사라질 수 있다. 값 세팅 + 끝나지 않는 스텁을 함께 쓴다:

  ```swift
  } withDependencies: {
      $0.jobClient = JobClient(jobs: { try await Task.never() })
  }
  ```

  `Task.never()` 는 ConcurrencyExtras 소속(TCA 가 재노출). 컴파일이 안 되면 `try await Task.sleep(for: .seconds(86_400)); return []` 로 대체.
- **에러 탭** (View 에 에러 UI 가 있을 때만): `throw` 하는 스텁을 주입한다.

## 5. 작성 규칙

- `#Preview("한국어 이름")` — 캔버스 탭 이름이므로 케이스를 설명하는 짧은 한국어 ("기본", "로딩 중", "직군 선택됨").
- 순서: 기본 → 상태 변형 → 로딩/에러. View 파일 맨 아래 `// MARK: - Previews` 섹션에 둔다.
- 기존 `#Preview` 가 있으면 지우지 말고 케이스 체계에 흡수한다 — 이름을 붙이고, 새 케이스와 중복이면 교체한다.

## 6. 검증

편집 후 해당 Feature 스킴을 컴파일한다 (프리뷰 캔버스가 여는 것과 같은 타겟):

```bash
xcodebuild build -workspace Hilit.xcworkspace -scheme Feature{X} \
  -destination 'generic/platform=iOS Simulator' -quiet
```

- 워크스페이스나 스킴이 없으면 `make generate` 먼저.
- 실패하면 고쳐서 통과할 때까지 반복한다. 통과 전엔 완료 보고하지 않는다.

## 결과 보고 형식

- 추가한 탭 목록: 이름 + 무엇이 보이는지 한 줄씩.
- 건너뛴 케이스와 이유 (예: "에러 — View 에 에러 UI 없음, 디자인 확정 시 추가").
- 컴파일 결과와 캔버스 여는 법 (해당 Feature 스킴 선택 → View 파일 열기).
