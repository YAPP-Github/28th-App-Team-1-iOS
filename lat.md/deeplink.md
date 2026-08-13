# Deeplink 도메인 — 유니버설 링크 수신 (DeeplinkClient)

지인 피드백 공유 링크가 앱을 여는 경로. 링크 도메인·AASA·deferred 는 SaaS(ChottuLink, FDL 대체)가 맡고 앱은 **수신만** 한다. 진입 판정 자체는 이 도메인 밖(파서)에 있다 — 여기 있는 건 «어떤 URL 이 어떻게 도착하는가» 뿐이다. 링크 형식은 [[feedback#진입로와 닫기]].

## 두 경로

도착 경로가 둘이고, **둘의 신뢰도가 다르다**.

- **설치 상태** — iOS 가 Associated Domains 로 판정해 쿼리 원본째 `onOpenURL` 에 꽂는다. SDK 도, 네트워크도 개입하지 않는다. `HilitApp` 은 이 URL 을 그대로 `deeplinkReceived` 로 보내고, SDK 에는 클릭 어트리뷰션 목적으로 따로 넘긴다(결과를 기다리지 않는다 — 서드파티 왕복을 화면 진입의 선행조건으로 만들지 않는다).
- **deferred** — 앱이 없어 스토어를 다녀온 첫 실행. 원본 URL 이 존재하지 않으므로 SDK 델리게이트가 유일한 재료다. `DeeplinkClient.resolvedLinks` 스트림으로 도착하고 `AppFeature.startUpEffects` 가 구독한다.

**SDK 가 통째로 죽어도 설치 상태 진입은 산다** — 잃는 건 deferred 와 통계뿐이다. 그래서 API 키가 비어도 `AppSecrets` 는 assert 하지 않는다.

## 해석 후보

SDK 콜백은 URL 을 둘 준다: `link`(대시보드에 등록한 destination — **고정값이라 토큰이 없을 수 있다**)와 metadata `shortLinkRaw`(«파라미터가 그대로인 딥링크»). 어느 쪽에 토큰이 실려 오는지 SDK 계약이 못 박지 않았다.

**2026-08-13 실기기 확인 — deferred 재설치에서 `shortLinkRaw` 에 파라미터가 살아 온다.** 그래도 한쪽만 고르지 않는다: 계약이 아니라 관찰이고, SDK 버전이 오르면 조용히 바뀔 수 있는 종류의 사실이다. 틀렸을 때 대가가 «deferred 진입 전멸» 인데 실패는 재설치한 지인 쪽에서만 드러나 개발 중엔 안 보인다. 그래서 `DeeplinkResolution.candidates` 가 **둘 다** 흘리고(raw 우선, 중복 제거) 판정은 파서에 맡긴다 — 후보를 하나 더 흘리는 비용은 파싱 한 번이다.

여러 URL 이 와도 화면이 겹치지 않는 건 `presentGuestFeedback` 이 진행 중 평가를 덮지 않기 때문이다 → [[app#Cross-feature Routing]].

## 경계

`DomainDeeplinkImplementation` 밖으로 SDK 타입이 새지 않는다 — Interface 는 `URL` 만 말한다. 링크 **생성** API 는 쓰지 않는다: 대시보드에 링크 하나를 등록해 두고 토큰만 쿼리로 갈아끼우므로 조립은 문자열뿐이고, 그건 `GuestFeedbackShareLink` 몫이다.

- SDK 배포물은 XCFramework(동적) — `Tuist/Package.swift` 의 `productTypes` 스위치가 닿지 않아 정적 아카이브 모드에서도 «앱에 한 벌 임베드» 로 같게 끝난다.
- 델리게이트 브리지는 싱글턴이다. SDK 가 델리게이트를 오래 붙잡아 준다는 보장이 없어, 지역 인스턴스면 초기화 직후 사라져 deferred 콜백이 아무 데도 도착하지 않는다.
- `start` 는 `HilitApp.init` — 화면이 뜬 뒤면 재설치 직후 매칭이 첫 실행에 안 걸린다.
