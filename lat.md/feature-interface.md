# TCA × 모듈러 아키텍처 — Feature 인터페이스가 충돌하는 이유

> TCA(The Composable Architecture)와 모듈러 아키텍처(TMA / µFeature)를 같이 쓸 때, **Feature 모듈을 Interface/Implementation 으로 쪼개는 게 왜 안 맞는지**를 언어/매크로 레벨에서 정리한 문서.
> 결정 자체(Feature Interface 폐기)는 [`architecture.md`](architecture.md) D3 에 있고, 이 문서는 그 **"왜"** 를 담는다.

## TL;DR

- 모듈러 아키텍처는 *"다른 모듈은 Interface(추상)에 의존하라"* 고 한다.
- TCA 의 `@Reducer` 매크로 + `some Reducer` 합성은 **컴파일 시점에 구체 타입을 못박는다.**
- 그래서 **A Feature 가 B Feature 의 reducer 를 자기 상태 트리에 담아 실행(embed)하려는 순간**, B 의 구체 타입이 강제되고 → Interface(추상)로는 못 끼운다. = 충돌.
- 단, **데이터 전달은 충돌이 아니다.** 충돌은 "reducer 를 embed/run" 할 때만. → 그래서 **코디네이터(delegate) 로 우회**한다.
- **Client/Dependency 의 Interface/Live 분리는 충돌 없음** (reducer 가 아니라 클로저 struct 라서). 그건 유지한다.

---

## 1. 문제

모듈러 아키텍처(TMA / µFeature)의 핵심 규칙:

> Feature A 가 Feature B 에 의존할 때는 B 의 **Interface** 에만 의존한다. B 의 Implementation(구현)은 숨긴다.
> → 결합 ↓, 클린 빌드 시 의존 모듈의 *인터페이스만* 컴파일하면 됨.

이 규칙은 보통 잘 통한다. 근데 **TCA Feature 에 적용하려는 순간 막힌다.** 왜?

## 2. 충돌의 본질 — reducer 는 "값"이 아니라 "동작"

핵심 두 가지:

1. **reducer 는 실제로 돌아가는 코드(동작)다.** 실행하려면 진짜 구현(body)이 있어야 한다. 인터페이스는 "설명서"일 뿐, 코드가 없어 돌릴 수 없다.
2. **TCA 는 상태를 한 트리로 합친다.** 부모 A 는 자식 B 의 `State` 를 *자기 State 구조체 안에 물리적으로 담는다.* 자리를 만들려면 B State 의 **정확한 모양(타입)** 을 알아야 한다.

> **자판기 비유**
> - 인터페이스 = 자판기 *사용 설명서* ("동전 넣으면 콜라 나옴")
> - 구체 타입 = 진짜 *자판기 기계* (회로 + 재고 + 작동부품)
>
> A 가 B 를 품으려면 → ① B 기계를 캐비닛에 넣을 자리(크기=State 모양)가 필요하고 ② 콜라를 뽑으려면 진짜 기계(코드=body)가 필요하다. **설명서로는 둘 다 안 된다.**

## 3. 왜 인터페이스(추상)로 못 가리나 — `some` vs `any`

| | 일반 OOP 인터페이스(프로토콜) | TCA reducer 합성 |
|---|---|---|
| 자식을 어떻게 들고 있나 | 박스(포인터)로 → 실제 타입을 런타임까지 숨김 | 부모 구조체 안에 직접 박음 → **모양을 컴파일 때 알아야** |
| 자식 동작을 언제 정하나 | 런타임에 찾아 실행 (동적 디스패치, `any`) | 컴파일 때 못박음 (정적, `some`) → **코드를 컴파일 때 알아야** |
| 인터페이스로 가능? | ✅ | ❌ (둘 다 막힘) |

```swift
// TCA 기본 — 정적. 'some' = 컴파일 타임에 한 구체 타입으로 확정.
var body: some ReducerOf<Self> {
    Scope(state: \.b, action: \.b) {
        BFeature()              // ← 구체 reducer(body 있음) 필요. 여기서 정적으로 박힘
    }
}
```

`@Reducer` 매크로는 **파일을 "불러오는" 게 아니라, 컴파일 시점에 코드를 펼쳐서(생성해서)** 자식의 `State`/`Action`/`body` 를 정적으로 참조하는 코드를 만든다. 그 자리에 `BFeatureInterface`(body 없는 껍데기)를 주면 — "그래서 *어떤* reducer 를 돌리라고?" 가 안 정해져 컴파일러가 거부한다.

> 정리: **"구체 타입을 요구한다" ≡ "추상 타입을 못 받는다"** — 같은 제약의 양면이지, 두 개의 별개 원인이 아니다.

## 4. 충돌 트리거를 정확히 — "embed/run" vs "데이터 전달"

흔한 오해: *"A 가 B 에 데이터를 넘기는 순간 충돌"* → **아니다.**

```
"B 의 reducer 를 참조(embed)해서 돌린다"   →  ⚡ 충돌 O
"B 에게 데이터를 전달한다"                  →  ✅ 충돌 X   ← 완전히 다른 행위
```

데이터 전달은 reducer 를 참조하지 않고도 된다. A 는 **원시값/Model 만 위로(delegate) 던지고**, 코디네이터가 B 를 만든다:

```swift
// A(UsersFeature): id(데이터)만 위로. ProfileFeature 를 전혀 모름.
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    return .send(.delegate(.editProfile(id: id)))

// 코디네이터(AppFeature, B 를 알아도 되는 자리): 데이터로 B 를 만든다.
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)   // 여기서만 B 구체 타입
```

이 프로젝트에서 데이터(`id: Int`, `Profile`)는 셋 다 흐르지만(편집 요청 → 저장 완료 → 목록 반영), **어느 Feature 도 다른 Feature 의 reducer/State 를 참조하지 않는다.** 데이터는 공유 `Models` 모듈 타입으로 오간다.

## 5. embed 는 TCA 의 핵심 합성 메커니즘 (= 자주 생긴다)

부모가 자식 reducer 를 소유/실행하는 방법 = 사실상 아래 전부:

| 메커니즘 | 쓰임 |
|---|---|
| `Scope` | 상시 임베드 (탭 컨테이너, 대시보드 위젯) |
| `ifLet` + `@Presents` | 모달 (sheet / popover / alert) |
| `forEach` + `StackState` | push 스택 (List→Detail) |
| `forEach` + `IdentifiedArray` | 리스트 행이 각각 feature |
| `enum Destination` | 여러 모달 목적지 묶음 |

**핵심: 충돌은 "embed 한다"가 아니라 "다른 *모듈* 을 embed 한다"에서 난다.**

```
Scope/ifLet/forEach 인데 자식이 같은 모듈   → ✅ 충돌 없음 (UsersFeature 안 List→Detail)
Scope/ifLet/forEach 인데 자식이 다른 모듈   → ⚡ 충돌 (Users→Profile)
```

→ Feature 안에 화면이 여러 개인 건 **전혀 문제 없다.** 같은 모듈 안 화면들끼리는 그냥 `Path` 로 embed 된다. (화면 개수는 변수가 아니다. **모듈 경계가 변수다.**)

## 6. 다른 모듈 feature 를 embed 하고 싶어지는 실제 상황

1. **여러 도메인을 한 플로우에** — 결제 `Cart→Shipping→Payment`, 온보딩 N단계
2. **다른 도메인을 모달로** — Profile 에서 Settings 를 sheet 로
3. **화면에 다른 도메인을 상시 임베드** — 홈 대시보드 위젯, 댓글 리스트
4. **리스트 행이 그 자체로 feature** — 피드의 PostFeature
5. **탭/컨테이너** — 탭바가 여러 도메인 feature 를 동시 보유

## 7. 반전 — 우리는 이미 embed 하고 있다 (그게 정답)

`AppFeature` 는 4개 Feature 를 전부 embed 해서 돌린다:

```swift
Scope(state: \.home,  action: \.home)  { HomeFeature() }
Scope(state: \.users, action: \.users) { UsersFeature() }
Scope(state: \.profile, action: \.profile) { ProfileFeature() }
.ifLet(\.$editProfile, action: \.editProfile) { ProfileFeature() }   // 모달
```

충돌이 없는 이유: AppFeature 가 **composition root(코디네이터) — 자식을 구체 타입으로 알아도 되는 자리**라서.

> 전략은 *"embed 를 없애기"가 아니라 "embed 를 한 곳(코디네이터/컨테이너)에 몰아넣기"* 다. embed 자체는 불가피하니까.

## 8. 실전 규칙

상황을 두 종류로 나눈다:

**① 전환(navigation) — push/modal 로 다른 feature 로 *넘어가는* 경우**
→ leaf 가 직접 embed 하지 말고 **코디네이터로 hoist** (delegate 로 신호만). 충돌 회피.

**② 구조적 합성 — 다른 feature 를 화면에 *상시 끼워넣는* 경우**
→ hoist 불가(전환이 아니라 "항상 거기 있음"). 그 자식 상태를 누군가는 소유·실행해야 함. 그래서:
- 그 임베더를 **"그 자식들의 owner(컨테이너/코디네이터)"로 인정** → 구체 의존 허용 (AppFeature 가 그렇듯)
- 또는 공유되는 작은 자식이면 **더 아래 모듈로 내려서** 여러 곳이 쓰게

```
embed(Scope/ifLet/forEach)은 TCA 에서 피할 수 없다.
같은 모듈 embed          = 공짜.
다른 모듈 embed 중 '전환'  = 코디네이터로 hoist (충돌 회피)
다른 모듈 embed 중 '상시'  = 그 임베더가 곧 owner = 구체 의존 허용 (몰아넣기)
leaf 끼리 서로 embed      = 금지 ← 이게 우리가 막은 케이스
```

**핵심: embed 가 나쁜 게 아니라, leaf feature 끼리 서로 embed 하는 게 나쁘다.** owner 노드(코디네이터/컨테이너) 한 곳으로 모으면 된다.

## 9. 비대칭 — Client/Dependency 는 Interface/Live 가 잘 맞는다

같은 "Interface/구현 분리"라도 **Client(`@Dependency`)는 분리가 유효**하다. Client 는 *클로저 묶음 struct* 라 소비자는 "모양(Interface)"만 알면 되고, Live 가 클로저 본문을 채운다. "reducer 를 합성한다"는 문제가 없다.

```
Interface 분리가 유효:  Dependency / Client (closure struct — 모양만 알면 됨)
Interface 분리가 어색:  TCA Feature reducer (합성하려면 구현이 필요)
```

→ 그래서 이 프로젝트는 **Client 만 Interface/Live 로 쪼개고, Feature 는 단일 모듈**로 둔다.

## 10. 이 프로젝트의 결정

- **D1.** Feature → Feature 의존 0 (delegate-only). cross-feature 조립은 AppFeature 에서만.
- **D2.** 단일 코디네이터(AppFeature). 피쳐 15개↑ / 다단계 cross-feature 가 일상화되면 sub-coordinator 검토.
- **D3.** Client 만 Interface/Live, Feature Interface 폐기 (위 2~9 가 그 근거).

상세 trade-off 는 [`architecture.md`](architecture.md), 작업 규칙은 [`.claude/CLAUDE.md`](../.claude/CLAUDE.md) 참고.
