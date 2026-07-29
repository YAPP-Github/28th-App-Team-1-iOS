# 이미지 — 상세

`Image` 토큰 레퍼런스. 단일 소스는 [Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본: Figma «icon» 시트 (node 1941-7000).

## 사용법

```swift
Image.Cancel.dark24          // 아이콘 — 패밀리 enum . 색변형+크기
Image.Feedback.body20
Image.Left.default           // 크기가 하나뿐인 패밀리는 크기 생략
Image.Img.micError           // 일러스트 — 크기·변형 없이 이름만
```

## 이름 규칙

- **enum = Figma 아이콘 패밀리** (`cancel` → `Cancel`, `skip l` → `SkipL`). 에셋 카탈로그도 같은 폴더 구조(`cancel/cancelDark24.imageset`).
- **멤버 = 색변형 + 크기** (`dark24`·`default16`·`green34`). **크기 접미사는 그 패밀리에 크기가 여러 개일 때만** — 하나뿐이면 뺀다(`Coupon.default`, `Up.dark`). 새 크기가 들어와 복수가 되면 그때 기존 멤버에도 크기를 붙인다.
- Figma 의 `~ default` 꼬리는 뗀다(`dark default` → `dark`), 오타는 교정한다(`balck` → `black`).
- **색은 에셋에 구워진 그대로 쓴다 — `foregroundStyle` 틴트 금지.** 색변형이 전부 별도 에셋이라 template 렌더링을 쓰지 않는다.
- 일러스트(크기 변형 없는 큰 그림 — book·link·micError·networkError)는 `Img` 패밀리로.

## 패밀리 — 생김새로 찾기

**「이렇게 생긴 아이콘 있나?」 로 찾는 역매핑 표.** 변형·크기 전수는 코드가 단일 소스라 반복하지 않는다 — 패밀리를 찾았으면 [Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 의 해당 enum 에서 고른다. 새 변형이 늘어도 이 표는 안 바뀐다(새 **패밀리**가 생길 때만 알파벳순 제자리에 행 추가).

| 패밀리 | 생김새 | 주 용도 |
|---|---|---|
| `Ai` | 반짝이(4점 별), 초록 | AI 기능 표시 |
| `Analyze` | 36pt 말풍선 픽토그램 3종 — question(물음표)·success(체크)·problem(느낌표) | 리포트 분석 카드 |
| `Cancel` | 맨 X (배경 없음) | 닫기·취소 |
| `CancelMini` | 원 배경 + X (회색 원/검정 원) | 입력 클리어·행 제거 |
| `Coupon` | 티켓 모양 | 이용권 |
| `Down` / `Up` | 쉐브론 ∨ / ∧ | 펼침·접힘 |
| `Edit` | 연필 + 사각 모서리 | 수정 |
| `Expand` | 네 모서리 바깥 화살표 | 전체화면·확대 |
| `Feedback` | 태도 픽토그램 5종 — body(자세)·eyes(시선)·face(표정)·hand(손동작)·voice(목소리) | 태도 평가 축 |
| `File` | 문서 낱장 (모서리 접힘) | 첨부·포트폴리오 |
| `Info` | 원 안 i | 안내 |
| `Issue` | 원 안 느낌표 (빨강 = error 변형) | 오류·경고 |
| `Left` / `Right` | 쉐브론 ‹ / › | 뒤로·앞으로 |
| `Loading` | 진행 링(ing)·대기 링(wait)·체크 원(success) | 단계 진행 표시 |
| `Logo` | kakao 말풍선(노랑)·apple 사과 — with-bg/no-bg | 소셜 로그인 |
| `Pause` | 세로 막대 2개 ‖ | 재생 중 표시 — 누르면 멈춤 |
| `Play` | 막대 + 속 빈 삼각형 ▷ | 멈춘 상태 표시 — 누르면 재생 |
| `Plus` | + | 추가 |
| `Profile` | 사람 실루엣 | 프로필 |
| `Q` | 사각 안 Q | 질문 표시 |
| `Script` | 가로줄 3개 (대본) | 대본·스크립트 토글 |
| `SkipL` / `SkipR` | ◁+막대 / 막대+▷ | 되감기·빨리감기 |
| `Success` | 원 안 체크 (초록 = green 변형) | 완료·성공 |
| `Timer` | 스톱워치 | 시간 제한 |
| `Undo` | 반시계 화살표 ↺ | 되돌리기 |
| `Upload` | 검은 원(44pt) 안 위 화살표 | 업로드 CTA |
| `Video` | 사각 화면 + 재생 표시 | 영상 |
| `Img` | 일러스트 — book(책)·link(사슬)·micError(다크 타일+마이크+빨간 배지)·networkError(다크 타일+네트워크)·tooltipTail(말풍선 꼬리 97×11)·tooltipTailDark(다크 꼬리 gray900) | 빈 상태·에러 화면·말풍선 |

**주의 — Figma 와 이름이 다른 곳**: `Loading` 3종(`successGreen24`·`ingGreen24`·`successDark24`)은 Figma 원본 이름이 엉켜 있어(동명 2개·variant 문자열 노출) 그림 내용으로 명명했다 — Figma 에서 같은 이름을 찾지 말 것(디자이너 정리 요청 중). `Img.tooltipTail` 은 Figma «icon» 시트에 없는 별도 에셋이다.

**주의 — `Pause`/`Play` 는 Figma 이름을 따르지 않는다**: Figma 는 세로 막대 2개를 «play», 재생 삼각형을 «stop» 으로 불러 이름과 그림이 뒤집혀 있다. 토큰은 **그림 기준**으로 다시 담았다 — 막대 2개 = `Pause`(green34·dark34·default24), 삼각형 = `Play`(같은 3종). «stop» 계열은 없앴다(정지 ■ 글리프는 애초에 없다). Figma 에서 같은 이름을 찾지 말 것 — 디자이너 정정 요청 대상.

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Assets.xcassets`(패밀리 폴더 / `<패밀리><변형><크기>.imageset`), 로드는 Tuist 생성 접근자 `SharedDesignSystemInterfaceAsset.Assets.<name>.swiftUIImage` ([Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 가 `Asset` 으로 축약해 감싼다). 에셋을 지우거나 이름을 바꾸면 토큰에서 컴파일 에러가 난다.
- **SVG 단일 스케일 + `preserves-vector-representation`** — 1x/2x/3x 슬롯에 넣지 않는다(래스터화됨).
- **크기별 별도 에셋인 이유**: Figma 아이콘이 크기마다 다시 그려져 있다(optical sizing — 예: plus 24px 획비 1/5 vs 16px 1/6). 한 크기를 `.frame` 으로 늘리면 획 두께가 어긋난다. **디자인된 크기 그대로 쓴다.**
