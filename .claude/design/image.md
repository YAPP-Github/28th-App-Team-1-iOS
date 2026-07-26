# 이미지 — 상세

`Image` 토큰 레퍼런스. 단일 소스는 [Image+Tokens.swift](../../Projects/Shared/SharedDesignSystem/Interface/Images/Image+Tokens.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. Color 팔레트와 같은 패밀리 enum 접근.

## 사용법

```swift
Image.Ic.close                       // 아이콘 — template 은 foregroundStyle 로 틴트
    .foregroundStyle(Color.HilitBlack.b800)
Image.Img.tooltipTail                // 일러스트 — 원본색 그대로
```

## 토큰

| enum | 토큰 | 크기 | 렌더 | 용도 |
|---|---|---|---|---|
| `Ic` | `close` | 24pt | template | 닫기(X) |
| | `cancelMini` | 24pt | 원본색 | 입력 클리어 (회색 원 + 검정 X) |
| | `cancelSmall` | 20pt | template | 파일 행 제거 버튼 |
| | `info` | 16pt | 원본색 | 안내 |
| | `error` | 16pt | 원본색 | 에러 (빨간 원 + 흰 느낌표) |
| | `success` | 16pt | 원본색 | 성공 (초록 원 + 흰 체크) |
| | `upload` | 20×24 | template | 업로드 화살표 (검은 원 배경은 코드) |
| `Img` | `tooltipTail` | 97×11 | 원본색 | 말풍선 꼬리 |

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Assets.xcassets`(에셋명 = `Ic*`/`Img*` 프리픽스), 로드는 Tuist 생성 접근자 `SharedDesignSystemInterfaceAsset.Assets.<name>.swiftUIImage` ([Image+Tokens.swift](../../Projects/Shared/SharedDesignSystem/Interface/Images/Image+Tokens.swift) 가 `Asset` 으로 축약해 감싼다). 생성 이름은 크기·틴트 여부를 담지 못하므로 그 정보는 토큰 주석이 진다. 에셋을 지우거나 이름을 바꾸면 토큰에서 컴파일 에러가 난다.
- **Ic vs Img**: 아이콘(UI 조작 요소)은 `Ic`, 일러스트·장식 이미지는 `Img`. 새 에셋 추가 시 프리픽스와 패밀리를 맞춘다.
- **template vs 원본색**: 단색 아이콘은 template 렌더링(틴트는 사용처 `foregroundStyle`), 다색 에셋은 원본색 — 각 토큰 doc 주석에 명시.
