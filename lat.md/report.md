# report

AI 면접 리포트 Feature(`FeatureReport`)의 도메인 노드. 화면 4종(리포트 메인·영상 플레이어·피드백·최종)의 코디네이터 골격만 세운 상태 — 레이아웃·실제 플로우는 Figma 연결 시 확정한다. 기획 매핑은 [ai-interview-report](../docs/work/ai-interview-report.md), 서버 연동은 [[api#Interview Report]].

## 코디네이터

`ReportFeature` — 리포트 메인을 루트로 두고 영상 플레이어·피드백·최종을 `path`(StackState)로 push 한다. 각 화면의 delegate 만 매칭해 전환한다(D5). 완료·이탈은 `delegate(.finished/.closeRequested)`로 부모(AppFeature)에 올린다 — dismiss·후속 전환은 부모 몫.

전환 순서(메인 → 영상 → 피드백 → 최종)는 디자인 확정 전 임시 선형 플로우다. 실제 진입 구조(예: 메인에서 항목별 분기)가 정해지면 delegate 신호와 push 규칙을 여기와 같이 갱신한다.

## 리포트 메인

`ReportMainFeature` — 플로우 루트(1/4). 리포트 진입 화면 예정. 현재 자리표시 — 골격(내비바·CTA)만 있다.

## 영상 플레이어

`ReportVideoPlayerFeature` — 2/4. 면접 영상 재생 화면 예정. 현재 자리표시.

## 피드백

`ReportFeedbackFeature` — 3/4. 피드백 열람 화면 예정. 현재 자리표시.

## 최종

`ReportFinalFeature` — 4/4. 플로우 마지막 화면 예정. `continueRequested` 를 코디네이터가 `finished` 로 번역해 부모에 올린다. 현재 자리표시.
