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
/// 표출·딤·상단 고정 오프셋은 라우터(GuestFeedbackView)의 onboardingPhase 가 건다.
/// 키보드가 올라와도 패널 상단은 그대로 — CTA 만 키보드 위로 밀리고 Spacer 가 압축된다.
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestNicknameView: View {
    @Bindable var store: StoreOf<GuestFeedbackFeature>
    @FocusState private var fieldFocused: Bool

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

            PrimaryButton("다음") {
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

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("레포트에 표시될 당신의")
                    .dsTypography(.head4)
                    .foregroundStyle(Color.GrayScale.g900)
                HStack(spacing: 0) {
                    // 그린 형광펜 마커 — DS HighlightedText(Figma highlighted-text), 온보딩과 동일.
                    HighlightedText("이름", typography: .head4)
                    Text("을 알려주세요")
                        .dsTypography(.head4)
                        .foregroundStyle(Color.GrayScale.g900)
                }
            }
            Text("이름은 피드백 레포트에만 반영이 됩니다")
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g500)
        }
    }

    // MARK: - Name field (중앙 정렬 · 텍스트 폭 밑줄)

    private var nameField: some View {
        VStack(spacing: .ds(.p8)) {
            TextField(
                "",
                text: $store.nickname,
                // prompt 는 비어 있을 때만 — 남겨두면 입력 후에도 TextField 이상적 폭이 플레이스홀더
                // 폭으로 잡혀, hug 되는 밑줄이 텍스트 길이를 따라가지 못한다(시안2 는 텍스트 폭 밑줄).
                prompt: store.nickname.isEmpty
                    ? Text("이름을 알려주세요").foregroundStyle(Color.GrayScale.g500)
                    : nil
            )
            .dsTypography(.head4)
            .foregroundStyle(Color.GrayScale.g900)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($fieldFocused)
            .onSubmit {
                guard !store.nickname.isEmpty else { return }
                send(.nicknameNextTapped)
            }
            // outline-large(4pt) 밑줄 — 입력 전 gray100(dsSeparator), 입력 시 green600(Figma 시안2 8636).
            Rectangle()
                .fill(store.nickname.isEmpty ? Color.GrayScale.g100 : Color.HilitGreen.g600)
                .frame(height: .ds(.large))
        }
        // Figma NameField(node 2192:5330)는 내용 폭만큼 hug — 밑줄이 텍스트를 따라가고 패널 중앙에 놓인다.
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity)
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
