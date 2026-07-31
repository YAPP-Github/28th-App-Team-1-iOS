# 공용 컴포넌트 — 인덱스

코드는 `SharedDesignSystem/Interface/Component/`, 파일 하나당 컴포넌트 하나, 전부 `public` + `#Preview`. 독스트링에 Figma 컴포넌트 노드 근거 보존. **커스텀 UI 를 새로 만들기 전에 이 목록을 먼저 훑는다.** 단일 소스는 코드 — 표와 어긋나면 코드가 우선.

**이 문서엔 API 를 적지 않는다** — 이름·한 줄 용도·어느 영역 문서냐만. 값·시그니처·시안 근거는 영역 문서 몫이다.

## 영역 분류 기준

| 영역 | 기준 | 문서 |
|---|---|---|
| 버튼 | 탭하면 **액션이 실행**된다 (action 클로저). 버튼의 팔레트·상태를 다루는 모디파이어(`.hilitSurface`·`.hilitButtonLoading`)도 여기 — 액션은 없지만 API 근거가 버튼 문서에 있다 | `component/button.md` |
| 입력 | 값을 **바인딩으로 주고받는다** + 필드에 붙는 안내/에러 줄 | `component/input.md` |
| 표시 | 값을 받아 **보여주기만** 한다 | `component/display.md` |
| 내비게이션 | **화면·영역 전환**이나 진행 위치를 다룬다 (바인딩을 받아도 이쪽이 이긴다) | `component/navigation.md` |

## 카탈로그

**알파벳순 유지** — 새 행을 끝에 붙이지 말고 제자리에 끼워 넣는다(동시 추가 시 git 이 자동 병합). 모디파이어 앞의 `.` 은 정렬에서 무시하고 이름으로 끼운다.

| 컴포넌트 | 한 줄 | 영역 |
|---|---|---|
| `BubbleField` | 말풍선 / 꼬리 없는 변형이 토스트 | 표시 |
| `ButtonLarge` | 화면 하단·모달 큰 버튼 (단일·2버튼) | 버튼 |
| `ButtonStyle` 4종 | `.medium` `.mini` `.miniSub` `.tag` 크기 티어 | 버튼 |
| `ChoiceChip` | N지선다 등폭 척도 칩 | 버튼 |
| `CountdownCard` | 남은 시간 다크 카드 | 표시 |
| `DashIndicator` | 진행 단계 대시 | 내비게이션 |
| `FieldSubText` | 필드 아래 서브 텍스트 한 줄 | 입력 |
| `HighlightedText` | 형광펜 마커 텍스트 | 표시 |
| `.hilitBottomSheet` | 바텀시트 딤 오버레이 표출 — 껍데기만, 시트 판은 호출부 (모디파이어) | 표시 |
| `.hilitButtonLoading` | 버튼 로딩 오버레이 (시안에 없음) | 버튼 |
| `HilitCheckboxStyle` | 체크박스 (`ToggleStyle`) | 입력 |
| `.hilitLogoNavigationBar` | 내비바 — 루트 브랜드 판(로고·프로필) | 내비게이션 |
| `.hilitModal` | 모달 딤 오버레이 표출 (모디파이어) | 표시 |
| `.hilitNavigationBar` | 내비바 — push 화면(스택 안) | 내비게이션 |
| `.hilitPresentedNavigationBar` | 내비바 — present 단독 화면(스택 밖) | 내비게이션 |
| `.hilitSurface` | 화면 판 톤 선언 → 하위 팔레트 전환 | 버튼 |
| `HilitTextEditor` | 여러 줄 입력 박스 | 입력 |
| `HilitTextField` | 한 줄 입력 필드 | 입력 |
| `HilitToggleStyle` | 스위치 토글 (`ToggleStyle`) | 입력 |
| `InfoField` | 안내/에러 줄 (판 있음) | 입력 |
| `Modal` | 모달 카드 + 하단 버튼 슬롯 | 표시 |
| `NameField` | 이름 밑줄 입력란 | 입력 |
| `Parallelogram` | 하이라이트 배경 `Shape` | 표시 |
| `QuoteField` | 작성된 코멘트 인용 줄 | 표시 |
| `SaveIndicator` | 자동 저장 상태 | 표시 |
| `TabSelector` | 밑줄 텍스트 탭 줄 | 내비게이션 |
| `TagLabel` | 소형 사각 태그 | 표시 |
| `TitleBox` | 화면 머리글 (뱃지·타이틀·서브) | 표시 |

## 승격 규칙 (Feature → Shared)

세 조건을 모두 만족할 때만 승격한다: ① Figma 에서 이름 붙은 DS 컴포넌트와 1:1 ② 도메인 타입·스토어 무의존(primitive 파라미터만) ③ 두 번째 사용처가 실재. 승격 시 도메인 어휘를 뺀 중립 이름으로 바꾸고 시각 값은 그대로 옮긴다(픽셀 동일).

승격하면 **인덱스 한 줄 + 영역 문서 한 행** 둘 다 추가한다. 영역 문서만 고치면 카탈로그에서 사라진다.
