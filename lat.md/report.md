# report

AI 면접 리포트 Feature(`FeatureReport`)의 도메인 노드. 화면 4개 + 메인 위 바텀시트 1개로 구성한다. 면접 종료 후 채점 결과를 사용자용 리포트로 보여주고, 영상 복기·지인 피드백 요청으로 잇는다. 기획→코드 매핑은 [ai-interview-report](../docs/work/ai-interview-report.md), 서버 계약은 [[api#Interview Report]].

## 코디네이터

`ReportFeature` — 1차 리포트를 루트로 두고 나머지 화면을 `path`(StackState)로 push 한다. 각 화면의 delegate 만 매칭한다(D5). 부모(AppFeature)로 올리는 것은 `retryRequested`(분석 부족 → 다음 면접)·`closeRequested` 둘뿐 — 나머지 전환은 모듈 안에서 끝난다.

**메인이 허브다.** 화면들은 한 줄로 이어지지 않는다: 영상 플레이어는 리포트의 종속 화면이지 지인 피드백의 앞 단계가 아니고, 영상을 보지 않고 바로 지인에게 보낼 수 있어야 한다. 그래서 각 화면 진입은 메인의 개별 delegate(`videoRequested`·`peerFeedbackRequested`)가 트리거한다.

## 1차 리포트

`ReportMainFeature` — 루트이자 상세 화면. 요약 화면을 따로 두지 않는다(이탈 이력). `InterviewReportClient.report` 한 번으로 전 화면 데이터를 받고, `.generating` 이거나 `reportNotFound` 면 폴링한다 — **`reportNotFound`(404)는 에러가 아니라 미생성 상태라서 폴링을 계속한다**.

노출 금지: 종합점수·채용 판정·천장·항목 점수·레드플래그 원문. 사용자 문구는 대부분 서버 소유(`headline`·`redFlagNotices.message`·`card.resolutionNotice`)라 클라가 만들지 않는다 — 클라 하드코딩은 영상 만료·nil 폴백·시트 마무리 문구뿐.

## 하이라이트 상세 시트

`ReportHighlightDetailFeature` — 화면이 아니라 대본 하이라이트를 탭하면 올라오는 바텀시트. 리포트 카드와 영상 플레이어 STT 오버레이 **양쪽이 같은 리듀서를 재사용**한다. 차이는 `[이 장면 영상으로 보기]` 노출 여부 하나(`showsVideoJump`) — 플레이어 안에서 열면 이미 그 장면이라 숨긴다.

레포 최초의 `.sheet` 도입 지점이다(기존 사용처 0). 진단 태그·다음 대비 질문은 서버 확장 대기 — 재료가 비면 그 블록을 렌더하지 않는다.

## 영상 플레이어

`ReportVideoPlayerFeature` — 리포트의 종속 화면. AVPlayer 는 State 에 두지 않고 View-local `@State` 로 소유한다(선례 `GuestVideoPlayerView`). 만료 판정은 플레이어 책임이 아니다 — 리포트가 `playableVideoURL` 에서 걸러 만료 시 진입 자체를 막는다.

STT 오버레이·장면 seek 는 서버 timestamp 확장에 막혀 있다 — `HighlightSpan` 이 문자열 인덱스만 갖고 시간축이 없다.

## 지인 피드백

`ReportPeerFeedbackFeature` — 메인의 `[지인에게 면접 영상 보내기]` 로 진입. Part 4.5 스펙 대기라 현재 자리표시 골격이고 화면 자리·진입 경로만 확정돼 있다.

**평가 독립성**: 지인에게 넘기는 payload 는 영상과 질문 경계까지다. AI 피드백(하이라이트·진단·다음 대비)은 넘기지 않는다 — 지인 평가가 AI 평가에 오염되면 4.6 의 2축 비교가 무의미해진다. 링크 생성 계약은 `DomainFeedbackShare`, 게스트 제출측은 [[feedback]].

## 최종 보고서

`ReportFinalFeature` — 지인 피드백이 도착한 뒤 보는 "지인 vs AI" 2축 보고서. Part 4.6 스펙 대기라 자리표시 골격이다. 데이터는 `InterviewReport.guestFeedback` 로 이미 내려온다. 진입 판정 조건은 미확정.
