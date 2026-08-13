//
//  GuestNicknameView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// @lat: [[feedback#G4 게스트 평가]]
/// 닉네임 입력 패널 콘텐츠(Figma `온보딩 - 닉네임 입력 / 시안2` node 1855:8605, 패널 node 2094:7566).
/// 온보딩 위에 올라오는 흰 풀블리드 패널 — 타이틀(그린 마커 "이름") + 안내 +
/// 중앙 정렬 밑줄 입력 필드(텍스트 폭 hug) + 하단 CTA(빈 입력 시 비활성).
/// 표출·딤·상단 고정 오프셋·키보드 도킹은 라우터(GuestFeedbackView)의 onboardingPhase 가 건다.
/// 키보드가 올라와도 패널 상단은 그대로 — CTA 만 키보드 위로 밀리고 Spacer 가 압축된다.
/// 도킹은 시스템 세이프에어리어 회피가 아니라 키보드 프레임 실측이다([[KeyboardDock]]) — 시스템
/// 회피에 참여시키면 딤 뒤 온보딩까지 같이 올라간다.
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestNicknameView: View {
    @Bindable var store: StoreOf<GuestFeedbackFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBlock
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .ds(.p20))
                .padding(.top, .ds(.p24))   // Figma 패널 상단 padding-24

            // minLength p12 — 키보드가 떠 상하 공간이 압축될 때도 작은 기기에서 콘텐츠가 잘리지 않게.
            Spacer(minLength: .ds(.p12))
            nameField
            Spacer(minLength: .ds(.p12))

            ButtonLarge("다음", .bottom) {
                send(.nicknameNextTapped)
            }
            // 시안2: 이름을 입력해야 다음으로 — 빈 입력은 회색 비활성(ButtonLarge color=disabled).
            .disabled(store.nickname.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.BlackWhite.white)   // 패널 표면은 흰색(#FFFFFF) — 온보딩 라이트 톤과 대비.
        // 자동 포커스 없음 — 사용자가 입력란을 탭해야 키보드가 올라온다.
    }

    // MARK: - Title

    /// DS TitleBox — Figma «title-box»(2094:7312) 1:1, 그린 마커 "이름".
    private var titleBlock: some View {
        TitleBox(
            [
                "레포트에 표시될 당신의",
                TitleBox.Line("이름을 입력해주세요", highlight: "이름")
            ],
            sub: "이름은 피드백 레포트에만 반영이 됩니다"
        )
    }

    // MARK: - Name field (중앙 정렬 · 텍스트 폭 밑줄)

    private var nameField: some View {
        // DS NameField(Figma «name-field» 2192:5331) — 내용 폭 hug 라 밑줄이 글자를 따라가고,
        // maxWidth 로 패널 중앙에 놓인다. 밑줄 색(g100→g600)은 입력값에서 파생된다.
        NameField("이름을 알려주세요", text: $store.nickname)
            .frame(maxWidth: .infinity)
            .onSubmit {
                guard !store.nickname.isEmpty else { return }
                send(.nicknameNextTapped)
            }
    }
}

// 패널 콘텐츠 자체를 미리 본다(라우터의 오버레이 없이 표면만 확인).
#Preview {
    GuestNicknameView(
        store: Store(initialState: GuestFeedbackFeature.State(token: "preview")) {
            GuestFeedbackFeature()
        }
    )
}
