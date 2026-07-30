//
//  CatalogButtonView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 버튼 체계 — `ButtonLarge`(View) + ButtonStyle 4종(medium·mini·miniSub·tag).
/// 상태(pressed·disabled)는 넘기는 축이 아니라 SwiftUI 가 주는 것이라, disabled 는 `.disabled(true)` 로만 보여준다.
/// `mini`·`tag` 는 판(light/dark)에 따라 팔레트가 바뀌어 어두운 판 묶음을 따로 둔다.
struct CatalogButtonView: View {
    var body: some View {
        CatalogPage("버튼") {
            largeSingle
            largePair
            medium
            mini
            miniSub
            darkSurface
        }
    }

    private var largeSingle: some View {
        CatalogGroup("ButtonLarge 단일 — .bottom / .modal · .filled / .outlined") {
            VStack(spacing: .ds(.p8)) {
                ButtonLarge("피드백 시작하기", .bottom) {}
                ButtonLarge("다시 연습하기", .bottom, style: .outlined) {}
                ButtonLarge("확인", .modal) {}
                ButtonLarge("비활성", .bottom) {}.disabled(true)
                ButtonLarge("전송 중", .bottom) {}.hilitButtonLoading(true)
            }
        }
    }

    private var largePair: some View {
        CatalogGroup("ButtonLarge 2버튼 — tone .dark / .gray / .twoColor") {
            VStack(spacing: .ds(.p8)) {
                ButtonLarge(.bottom, tone: .dark) {
                    Button("아니오") {}
                } trailing: {
                    Button("네") {}
                }
                ButtonLarge(.bottom, tone: .gray) {
                    Button("취소") {}
                } trailing: {
                    Button("확인") {}
                }
                ButtonLarge(.bottom, tone: .twoColor) {
                    Button("나중에") {}
                } trailing: {
                    Button("계속하기") {}
                }
                ButtonLarge(.modal, tone: .dark) {
                    Button("닫기") {}
                } trailing: {
                    Button("저장") {}.disabled(true)   // 한쪽만 비활성 = 그 자식에 .disabled
                }
            }
        }
    }

    private var medium: some View {
        CatalogGroup(".medium(_:layout:) — 색 6종 · .hug / .fill") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                ForEach(MediumButtonStyle.Tone.allCases, id: \.self) { tone in
                    Button(String(describing: tone)) {}
                        .buttonStyle(.medium(tone))
                }
                Button("비활성") {}.buttonStyle(.medium()).disabled(true)
                HStack(spacing: .ds(.p8)) {
                    Button("아쉬웠어요") {}.buttonStyle(.medium(.red, layout: .fill))
                    Button("좋았어요") {}.buttonStyle(.medium(.blue, layout: .fill))
                }
            }
        }
    }

    private var mini: some View {
        CatalogGroup(".mini(_:layout:) — 밝은 판") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                ForEach(MiniButtonStyle.Tone.allCases, id: \.self) { tone in
                    Button(String(describing: tone)) {}
                        .buttonStyle(.mini(tone))
                }
                Button {
                } label: {
                    HStack(spacing: .ds(.p8)) {
                        Image.Video.default16
                        Text("영상 다시보기")
                    }
                }
                .buttonStyle(.mini(.gray, layout: .withIcon))
                Button("비활성") {}.buttonStyle(.mini()).disabled(true)
            }
        }
    }

    private var miniSub: some View {
        CatalogGroup(".miniSub(_:) — white / black / none") {
            HStack(spacing: .ds(.p8)) {
                ForEach(MiniSubButtonStyle.Tone.allCases, id: \.self) { tone in
                    Button(String(describing: tone)) {}
                        .buttonStyle(.miniSub(tone))
                }
            }
        }
    }

    /// `.hilitSurface(.dark)` 는 화면이 한 번 선언하면 하위 mini·tag 팔레트가 따라 바뀐다.
    private var darkSurface: some View {
        CatalogGroup(".hilitSurface(.dark) — mini · tag(다크 판 전용)") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                ForEach(MiniButtonStyle.Tone.allCases, id: \.self) { tone in
                    Button(String(describing: tone)) {}
                        .buttonStyle(.mini(tone))
                }
                Button("비활성") {}.buttonStyle(.mini()).disabled(true)
                HStack(spacing: .ds(.p8)) {
                    ForEach(TagButtonStyle.Phase.allCases, id: \.self) { phase in
                        Button("지인피드백") {}.buttonStyle(.tag(phase))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.ds(.p16))
            .background(Color.HilitBlack.b900)
            .hilitSurface(.dark)
        }
    }
}

#Preview {
    NavigationStack { CatalogButtonView() }
}
