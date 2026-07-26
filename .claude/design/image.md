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

## 토큰 목록

패밀리 30개 · 토큰 134개 — 전수 목록은 코드가 단일 소스라 여기 반복하지 않는다. [Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 를 직접 본다. 패밀리: Ai · Cancel · CancelMini · Coupon · Down · Edit · Expand · Feedback · File · Info · Issue · Left · Loading · Logo · Play · Plus · Profile · Q · Right · Script · SkipL · SkipR · Stop · Success · Timer · Undo · Up · Upload · Video · Img (+ 아래 Ic).

### Loading — Figma 이름이 엉켜 있던 3종

Figma 원본에 동명 심볼 2개·variant 문자열 노출 1개가 있어 그림 내용으로 판정해 명명했다: `Loading.successGreen24`(초록 원+흰 체크) · `Loading.ingGreen24`(초록 진행 링) · `Loading.successDark24`(검정 원+초록 체크). 디자이너에게 Figma 측 정리 요청 상태.

### Ic — 구세대 토큰 (마이그레이션 대기)

초기 8종(`Ic.close`·`Ic.cancelMini`·`Ic.cancelSmall`·`Ic.info`·`Ic.error`·`Ic.success`·`Ic.upload`·`Img.tooltipTail`)은 호출처 21곳이 물려 있어 유지 중. 신규 체계와 겹치므로(`Ic.close`≈`Cancel.default24`) **새 코드에서 쓰지 않는다.** 전량 교체 후 삭제 예정.

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Assets.xcassets`(패밀리 폴더 / `<패밀리><변형><크기>.imageset`), 로드는 Tuist 생성 접근자 `SharedDesignSystemInterfaceAsset.Assets.<name>.swiftUIImage` ([Image+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Image/Image+Extension.swift) 가 `Asset` 으로 축약해 감싼다). 에셋을 지우거나 이름을 바꾸면 토큰에서 컴파일 에러가 난다.
- **SVG 단일 스케일 + `preserves-vector-representation`** — 1x/2x/3x 슬롯에 넣지 않는다(래스터화됨).
- **크기별 별도 에셋인 이유**: Figma 아이콘이 크기마다 다시 그려져 있다(optical sizing — 예: plus 24px 획비 1/5 vs 16px 1/6). 한 크기를 `.frame` 으로 늘리면 획 두께가 어긋난다. **디자인된 크기 그대로 쓴다.**
