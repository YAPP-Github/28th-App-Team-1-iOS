# Feedback — 지인 피드백

지인(게스트)이 사용자의 면접 영상을 보고 태도 항목을 4단계 척도로 평가하는 도메인. MVP 범위는 G4(게스트 평가) — 무인증 공유 토큰으로 진입해 영상·지정 항목·질문 경계를 받고 제출한다. 도메인 모듈은 `DomainGuestFeedback`(서버 계약 [[api#Guest Feedback]] + 로컬 임시저장).

사용자측 F4(공유 설정)·R1 지인 섹션은 후속. 스펙: docs/superpowers/specs/2026-07-20-guest-feedback-design.md.

## G4 게스트 평가

FeatureGuestFeedback 의 단일 리듀서 GuestFeedbackFeature. phase(loading→onboarding→starting→evaluating→summary→completed / gateClosed) 하나로 화면을 전환한다 — 선형 플로우라 StackState 를 두지 않는다. 닉네임 입력만 phase 가 아니라 온보딩 위 오버레이 패널(isEnteringNickname 로 구동)다.

GuestFeedbackView 가 phase 로 라우팅하는 화면 순서 — GuestOnboardingView(온보딩)→GuestStartingView(시작 로딩 연출)→GuestEvaluationView(영상+축 평가)→GuestSummaryView(요약)→GuestGateView(completed/gateClosed 공용, 문구만 분기). GuestStartingView 는 별도 화면이 아니라 평가 화면 위 블러 오버레이다 — starting·evaluating 이 한 스위치 케이스(evaluationPhase)로 묶여 GuestEvaluationView 가 계속 살아 있고, starting 동안 그 위에 다크 스크림(블랙 60%+블러, 시안 node 1855:8702)이 얹히며 터치를 차단한다. videoReady 로 evaluating 이 되면 프로토타입 Flow 1(1855:8702→1855:9821)대로 오버레이 페이드아웃 + 축 세그먼트 바·하단 그라디언트 스크림(몰입 모드 전용, 위 투명→아래 블랙 42%) 슬라이드업이 같은 0.35s easeOut 커브로 동시에 진행된다 — 케이스를 가르면 뷰 정체성이 끊겨 이 크로스페이드가 안 되는 게 묶은 이유다. 요약은 최종 시안(node 2101:8781)대로 «평가 항목» 헤더 + «영상 다시보기» 버튼과 카드 리스트로 구성되며, 카드 탭(summaryCardTapped)이 해당 축 평가 카드 모드로, 영상 다시보기(rewatchTapped)가 몰입 시청으로 각각 evaluating 에 되돌아간다 — 선형 플로우의 유일한 역방향 간선. 닉네임(GuestNicknameView)은 온보딩 위 커스텀 오버레이 — 딤(블랙 80%) + 상단을 화면 230/812 지점에 고정한 풀블리드 각진 패널 — 로 올라온다. 키보드는 두 계층으로 다룬다: 배경(온보딩+딤)은 키보드 세이프에어리어를 무시해 고정하고, 패널만 시스템 키보드 회피에 참여해 CTA 가 키보드 위로 도킹하며 이름 입력란 상하 Spacer 가 균등 압축된다(수동 키보드 높이 계산 없음). 시스템 `.sheet` 는 키보드가 뜨면 시트 전체가 밀려 높이가 변하고 양옆 여백이 생겨 폐기했다(시안2 는 키보드 시 CTA 만 위로 밀림). "피드백 시작하기" 탭이 표출(isEnteringNickname=true), "다음"(이름 입력 시 활성)이 확정→starting, 딤 탭은 취소(nicknameSheetDismissed)로 온보딩에 머문다.

GuestEvaluationView 는 시트가 아니라 자유전환이다 — 최초 진입은 몰입 모드(풀블리드 영상 + 하단 축 세그먼트만, 시안 «영상 전체 보기»)로 열리고, 축을 탭하면 카드 모드(라운드 영상 카드 + 흰 카드)로 내려온다. 카드 영상의 확대(⛶) 버튼이 몰입 복귀 — AVPlayer 는 뷰 로컬로 두 모드가 공유해 재생이 안 끊긴다. 카드 모드에선 AxisSegmentedBar 로 축을 탭 전환하고, 흰 카드에서 AxisLevelChip(4단계)을 고르고 필요하면 AxisCommentCard 오버레이로 축별 코멘트를 남긴다. 저장된 코멘트는 접힌 행에 그린 액센트 바(4pt)+한 줄 tail 말줄임+«수정» 링크로 표시되고, 비어 있으면 점선 진입 버튼(button-optional)이다 — 어느 상태든 탭이 편집 진입. 코멘트 오버레이는 2계층 키보드 패턴(«[4] 서술형», 묶음 node 2227:5014) — 딤은 화면 고정, 카드+«다음» CTA 아일랜드(px20/py14)만 키보드 위에 도킹하고 등장 즉시 포커스한다. 도킹은 시스템 세이프에어리어 회피가 아니라 키보드 프레임 노티피케이션 실측 — 시스템 회피는 한국어 후보 바(input accessory) 높이를 빼고 계산해 CTA 가 후보 바 뒤에 남는다(닉네임 패널 "수동 계산 없음" 원칙의 유일한 예외). CTA 는 `ButtonLarge(.bottom)`(세이프에어리어 번짐)이 아니라 대칭 py16 모달 변형 `ButtonLarge(.modal)` 이다. 축명·척도 카피는 Figma 확정 짧은 문구(손동작·목소리, 잘 맞춤/꽤 맞춤 류 — GAZE·VOICE 확정, 표정·자세·손동작 척도는 잠정)로 한 줄을 유지한다. 이전 시트 기반 AxisRatingSheet 는 폐기됐다.

AxisLevelChip 은 Figma «button-medium»(node 2150:7297·2192:5191) 1:1 직사각형(radius 0) — 기본은 흰 필+gray100 테두리, 선택 시 Tone 분기로 1~2단계(좋았어요 쪽)는 positive(cyan) 200/500/800, 3~4단계(아쉬웠어요 쪽)는 error(red) 200/500 필·테두리·텍스트를 쓴다. questionRow 우측엔 축별 저장 인디케이터가 붙는다(node 2555:7558) — State.savingAxisCode(축 코드)로 구동해 없음(미평가)→«저장 중 ...»(스피너, levelSelected 로 세팅)→«저장됨»(그린 체크, 500ms debounce 로컬 draft 저장이 끝나 Inner.draftSaved 가 axisCode 를 nil 로 해제)순으로 표시한다.

지정 항목 전부를 4단계 척도(1=좋았어요~4=아쉬웠어요)로 채워야 제출이 활성화되고, 항목 코멘트(100자)·전반 피드백(300자)은 선택이다. 전반 피드백은 서버 제출 스키마(`{nickname, ratings}`)에 필드가 없어 로컬 draft 전용 휴면 상태다 — 서버 협의 전까지 payload 에 담지 않는다. 마지막 축을 채우는 전이 순간에는 완료 토스트 «모든 평가가 끝났어요!»(Figma BubbleField, node 2555:7543 — 폭 274·b800 직각 박스, CTA 위 10pt)가 뜨고 2초 뒤 자동 해제된다(State.isCompletionToastVisible + Inner.completionToastExpired) — 이미 전부 평가된 뒤 레벨만 바꾸면 다시 뜨지 않는다.

- 제출은 확정 — DS `Modal` 확인(«제출하기»/«취소», `.hilitModal` 오버레이) 1회 후 수정 불가. 성공 시 임시저장 삭제.
- 제출 중 409 는 게이트 전환으로 흡수: closed→비공개 차단, capacityFull→시청 전용 강등, alreadySubmitted→기제출 안내.
- 허용 문자셋(국문·영문·공백·숫자·`! - ~ ? . , / [ ] < >`)과 길이 제한은 binding 단계에서 sanitize.
- 하단 CTA 는 SharedDesignSystem `ButtonLarge(.bottom)`(블랙 풀블리드) 공통 — 온보딩·닉네임·평가·요약 화면에서 재사용한다.

## 게이트 판정

진입 GET 의 gate 로 화면을 분기한다 — OPEN(평가 진행) / PRIVATE(비공개·무효) / EXPIRED(영상 만료) / FULL(정원 4명 마감, 영상 시청만 가능) / ALREADY_SUBMITTED(이 기기 제출 완료).

gate 는 닫힌 raw-String enum — 서버가 새 게이트 값을 추가하면 디코딩이 실패해 entryLoaded(.failure)→재시도 알럿으로 흐른다(unknown 방어 케이스 없음). FULL 은 submissionOpen=false 로 평가 입력만 막고 시청은 허용한다. Feature 내부 GateReason.unknown 은 엔트리 없이 차단해야 하는 경우(진입 실패의 정원 마감 등) 전용이다.

- 진입 실패의 영구 도메인 에러도 같은 차단 화면으로 매핑한다 — closed→비공개, 기제출→기제출(임시저장 삭제), 정원 마감→일반 차단(엔트리 없이는 시청 전용 불가).

## Client 계약

`DomainGuestFeedback` 의 GuestFeedbackClient(entry·submit)가 Feature 의 유일한 접근 계약 — 상세 명세·에러 매핑 표는 [[api#Guest Feedback]] 이 단일 소스다. 두 메서드 모두 deviceId 를 명시 인자로 받는다(Feature 가 GuestFeedbackLocalStore.deviceID() 를 전달).

무인증 API 라 AuthorizedNetworkClient 가 아닌 NetworkClient 를 쓴다 — [[domain.map#네트워킹 인프라]]. 서버 에러 코드는 Implementation 이 GuestFeedbackError 로 흡수해 Feature 에 코드 문자열이 새지 않는다.

- GuestFeedbackError 케이스: tokenNotFound·shareClosed·capacityFull·alreadySubmitted·invalid(message:)·networkFailure·serverUnavailable·unexpected.
- 사용자 노출 문구(userMessage)는 표현 관심사라 Feature(GuestFeedbackSupport)가 소유한다.
- 응답 모델은 옵셔널 필드(axes·videoUrl·submissionOpen 등) — Feature 어댑터(axisList·videoURL)가 화면 형태로 좁힌다.

## 임시저장과 Device-Id

GuestFeedbackLocalStore(`DomainGuestFeedback`)가 게스트 로컬 상태를 담당한다(UserDefaults). Device-Id 는 deviceID() 최초 호출 시 UUID 를 생성해 영속하고, Feature 의 effect 가 client.entry·submit 의 명시 인자로 전달한다 — 역할은 같은 기기 중복 제출 방지 하나뿐(PRD §2-5).

임시저장(이어하기)은 토큰별 draft 로 저장하고 제출 성공 시 지운다.

- draft 쓰기는 latest-wins — 500ms debounce 저장과 즉시 저장(saveDraftNow)이 같은 취소 ID 를 공유해, 대기 중 stale 스냅샷이 뒤늦게 완료돼 최신 쓰기(예: 코멘트 확정)를 덮지 않는다. 즉시 저장도 draftSaved 를 보내 저장 인디케이터를 해제한다.
- 서버 저장 전환(PRD 🔴협의 3)이 확정되면 이 계약 뒤만 교체한다.

## 영상 보관 연장

클라 관점의 보관 사이클 접점 두 곳 — 지인 최초 조회(entry)가 +7일, 첫 제출(submit)이 +30일 연장을 서버에서 유발한다. 클라는 트리거를 호출할 뿐 계산하지 않는다. 만료되면 gate=EXPIRED 로 시청·평가가 차단되고 "보관 기간이 지나 영상이 삭제되었어요" 를 보여준다.
