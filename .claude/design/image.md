# 이미지 — 상세

`Image` 토큰 레퍼런스. 단일 소스는 [Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본: Figma «icon» 시트 (node 1941-7000).

## 사용법

```swift
Image.Cancel.white24         // 아이콘 — 패밀리 enum . 색변형+크기
Image.Feedback.body20
Image.Left.default           // 크기가 하나뿐인 패밀리는 크기 생략
Image.Img.micError           // 일러스트 — 크기·변형 없이 이름만
```

## 이름 규칙

- **enum = Figma 아이콘 패밀리** (`cancel` → `Cancel`, `skip l` → `SkipL`). 에셋 카탈로그도 같은 폴더 구조(`cancel/cancelWhite24.imageset`).
- **멤버 = 색변형 + 크기** (`white24`·`default16`·`green34`). **크기 접미사는 그 패밀리에 크기가 여러 개일 때만** — 하나뿐이면 뺀다(`Coupon.default`, `Up.white`). 새 크기가 들어와 복수가 되면 그때 기존 멤버에도 크기를 붙인다.
- Figma 의 `~ default` 꼬리는 뗀다(`white default` → `white`), 오타·표기는 교정한다(`balck` → `black`, `grey` → `gray`).
- **색은 에셋에 구워진 그대로 쓴다 — `foregroundStyle` 틴트 금지.** 색변형이 전부 별도 에셋이라 template 렌더링을 쓰지 않는다.
- 일러스트(크기 변형 없는 큰 그림 — book·link·micError·networkError)는 `Img` 패밀리로.

## 패밀리 — 생김새로 찾기

**「이렇게 생긴 아이콘 있나?」 로 찾는 역매핑 표.** 변형·크기 전수는 코드가 단일 소스라 반복하지 않는다 — 패밀리를 찾았으면 [Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 의 해당 enum 에서 고른다. 새 변형이 늘어도 이 표는 안 바뀐다(새 **패밀리**가 생길 때만 알파벳순 제자리에 행 추가).

| 패밀리 | 생김새 | 주 용도 |
|---|---|---|
| `Ai` | 반짝이(4점 별), 초록 | AI 기능 표시 |
| `Cancel` | 맨 X (배경 없음) | 닫기·취소 |
| `CancelMini` | 원 배경 + X (회색 원/검정 원) | 입력 클리어·행 제거 |
| `Check` | 맨 체크 ✓ 12×11 (초록/회색) | `HilitCheckboxStyle` 내부 체크 표시 |
| `Coupon` | 티켓 모양 | 이용권 |
| `Down` / `Up` | 쉐브론 ∨ / ∧ | 펼침·접힘 |
| `Edit` | 연필 + 사각 모서리 | 수정 |
| `Expand` | 네 모서리 바깥 화살표 | 전체화면·확대 |
| `Feedback` | 태도 픽토그램 5종 — body(자세)·eyes(시선)·face(표정)·hand(손동작)·voice(목소리) | 태도 평가 축 |
| `File` | 문서 낱장 (모서리 접힘) | 첨부·포트폴리오 |
| `HilitAnalyze` | 36px 원형 배지 3종 — aiSparkle·problem·success | 분석 결과 항목 머리 |
| `Info` | 원 안 i (빨강 = error·청록 = positive 변형) | 안내 |
| `Issue` | 원 안 느낌표 (빨강 = 채운 원 + 흰 글리프인 error 변형) | 오류·경고 · `InfoField(.error)` 아이콘 |
| `Left` / `Right` | 쉐브론 ‹ / › | 뒤로·앞으로 |
| `Loading` | 진행 링(ing)·대기 링(wait)·기본 링(접두사 없음) | 단계 진행 표시 |
| `Logo` | kakao 말풍선(노랑)·apple 사과 — with-bg/no-bg (+`…WithBg24` 는 24px 판) · hilit 워드마크 57×24 | 소셜 로그인 · 네비바 logo 변형 |
| `Pause` | 세로 막대 2개 ‖ | 일시정지 |
| `Play` | 왼쪽 세로 막대 + 삼각형 2개 — **순수 ▷ 가 아니다** | 영상 재생 |
| `Plus` | + | 추가 |
| `Profile` | 사람 실루엣 | 프로필 |
| `Q` | 사각 안 Q | 질문 표시 |
| `Script` | 가로줄 3개 (대본) | 대본·스크립트 토글 |
| `SkipL` / `SkipR` | 막대+윤곽 화살표 (좌/우 대칭) | 되감기·빨리감기 |
| `Success` | 원 안 체크 — default/black/gray/green | 완료·성공 |
| `Timer` | 스톱워치 | 시간 제한 |
| `Undo` | 반시계 화살표 ↺ | 되돌리기 |
| `Upload` | 검은 원(44pt) 안 위 화살표 | 업로드 CTA |
| `Video` | 사각 화면 + 재생 표시 | 영상 |
| `Img` | 일러스트 — book(책)·feedback(214px)·finish·link(사슬)·micError(다크 타일+마이크+빨간 배지)·networkError(다크 타일+네트워크)·oppO/oppX/oppEllipsis(74px o·X·…)·person·reportEmpty·success(100px)·talk·tooltipTail(말풍선 꼬리 97×11) | 빈 상태·에러 화면·말풍선 |

**주의 — `Img` 안에 일러스트가 아닌 것**: `person`·`talk` 은 일러스트가 아니라 **완성형 40×40 아이콘 타일**이다 — b800 판 + 초록 24pt 글리프가 에셋에 구워져 있고 모서리 0. Figma `person/40px`(435:656)·`talk/40px`(435:652), 게스트 온보딩 가이드 행 그래픽이다. **다른 타일로 감싸거나 틴트하지 말 것** — 판이 이미 에셋 안에 있다. 이름으로 아이콘 패밀리를 뒤지면 못 찾는다(`Img` 로 분류돼 있다).

**주의 — Figma 와 이름이 다른 곳**: `Img.tooltipTail` 은 Figma «icon» 시트에 없는 별도 에셋이다. `Check` 도 시트에 없다 — «Checkbox» 컴포넌트(3768:16630) 내부 벡터를 떼어 온 것. `Info.error` 도 시트에 없다 — 디자이너가 «info-field/red» 안에서 인스턴스에 e500 을 덮어썼을 뿐이라, 틴트 금지 규칙상 같은 도형을 e500 으로 칠한 에셋으로 넣었다.

**주의 — 2026-07-29 전량 재수출에서 드러난 것** (변형 이름이 `dark`→`white`, `grey`→`gray` 로 바뀐 판):

- **옛 `Play`/`Stop` 이 서로 바뀌어 있었다** — ‖(막대 2개)를 `Play` 로, 막대+삼각형을 `Stop` 으로 부르고 있었다. 재수출이 ‖ = `Pause` 로 교정했고 토큰·카탈로그를 그에 맞췄다. 옛 이름으로 짠 코드를 옮길 땐 **이름이 아니라 그림을 보고** 고를 것.
- `Play` 글리프가 왼쪽 막대 + 삼각형 2개다(순수 ▷ 아님) — 이름과 그림이 어긋나 보인다. **디자이너 확인 대기**, 시안대로 뒀다.
- `Profile.defaultAlt` — 디자이너가 이름을 안 붙인 둘째 default(`default-1`). `default` 와 다른 그림(각진 실루엣)이고 색은 같은 b800 이라 어느 쪽을 쓸지 근거가 없다. **확인 대기.**
- 옛 `Loading` 의 `success…` 계열은 `Success` 패밀리로 옮겨졌고 `loading` 에 green 변형은 없다 — 옛 이름 엉킴(동명 2개)이 이 재수출로 해소됐다.
- `Left`·`Timer` 24px 은 같은 이름이지만 **다시 그려졌다**(옛 파일과 바이트가 다르다).

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Assets.xcassets`(패밀리 폴더 / `<패밀리><변형><크기>.imageset`), 로드는 Tuist 생성 접근자 `SharedDesignSystemInterfaceAsset.Assets.<name>.swiftUIImage` ([Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 가 `Asset` 으로 축약해 감싼다). 에셋을 지우거나 이름을 바꾸면 토큰에서 컴파일 에러가 난다.
- **SVG 단일 스케일 + `preserves-vector-representation`** — 1x/2x/3x 슬롯에 넣지 않는다(래스터화됨).
- **크기별 별도 에셋인 이유**: Figma 아이콘이 크기마다 다시 그려져 있다(optical sizing — 예: plus 24px 획비 1/5 vs 16px 1/6). 한 크기를 `.frame` 으로 늘리면 획 두께가 어긋난다. **디자인된 크기 그대로 쓴다.**
