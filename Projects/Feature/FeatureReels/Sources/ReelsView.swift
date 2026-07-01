//
//  ReelsView.swift
//  FeatureReels
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import SwiftUI

// 인스타 릴스식 인터랙션: 댓글 시트가 올라오며 영상이 비율대로 축소된다.
// 시스템 .sheet 는 presenter(영상)를 축소하지 못하므로 ZStack + 커스텀 드래그 시트로 직접 구성한다.
// 연속 드래그 값(sheetHeight)은 View-local @State, 이산 상태(isCommentsPresented 등)는 store.
public struct ReelsView: View {
    @Bindable var store: StoreOf<ReelsFeature>

    // 연속 드래그 진행값 — 스토어에 고빈도 방출을 피하려 View 에 둔다.
    @State private var sheetHeight: CGFloat = 0
    @State private var dragBaseHeight: CGFloat?
    @FocusState private var isInputFocused: Bool

    public init(store: StoreOf<ReelsFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geo in
            let containerHeight = geo.size.height
            let target = containerHeight * 0.58
            let progress = min(max(sheetHeight / target, 0), 1)

            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                ReelVideoLayer(store: store)
                    .scaleEffect(1 - progress * 0.38, anchor: .top)
                    .offset(y: progress * 12)
                    .clipShape(RoundedRectangle(cornerRadius: progress * 22, style: .continuous))

                if progress > 0 {
                    Color.black
                        .opacity(Double(progress) * 0.25)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { store.send(.userTappedCloseComments) }
                }

                if sheetHeight > 0 {
                    commentSheet(target: target)
                        .frame(height: sheetHeight, alignment: .top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom))
                }
            }
            .onChange(of: store.isCommentsPresented) { _, open in
                withAnimation(.snappy) { sheetHeight = open ? target : 0 }
                if !open { isInputFocused = false }
            }
            .onAppear { store.send(.onAppear) }
        }
    }

    // MARK: - 댓글 시트

    private func commentSheet(target: CGFloat) -> some View {
        VStack(spacing: 0) {
            grabHandle(target: target)

            HStack {
                Text("댓글 \(store.comments.count)")
                    .font(.headline)
                Spacer()
                Button {
                    store.send(.userTappedCloseComments)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(store.comments) { comment in
                        commentRow(comment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            Divider()
            inputBar
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private func grabHandle(target: CGFloat) -> some View {
        Capsule()
            .fill(Color(.systemGray3))
            .frame(width: 40, height: 5)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture(target: target))
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(comment.authorName.prefix(1)).uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text(comment.createdAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.text)
                    .font(.subheadline)
                if comment.likeCount > 0 {
                    Text("좋아요 \(comment.likeCount)개")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "heart")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("댓글 달기…", text: $store.draftComment)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { store.send(.userTappedSendComment) }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6), in: Capsule())

            Button {
                store.send(.userTappedSendComment)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .buttonStyle(.plain)
            .disabled(store.draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .foregroundStyle(
                store.draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color(.systemGray3) : Color.accentColor
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 드래그 → 시트 높이 스냅

    private func dragGesture(target: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let base = dragBaseHeight ?? sheetHeight
                if dragBaseHeight == nil { dragBaseHeight = base }
                let proposed = base - value.translation.height
                sheetHeight = rubberClamp(proposed, limit: target)
            }
            .onEnded { value in
                dragBaseHeight = nil
                let limit = target
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let shouldOpen: Bool
                if velocity < -300 {
                    shouldOpen = true          // 빠르게 위로
                } else if velocity > 300 {
                    shouldOpen = false         // 빠르게 아래로
                } else {
                    shouldOpen = sheetHeight > limit * 0.4
                }
                withAnimation(.snappy) { sheetHeight = shouldOpen ? limit : 0 }
                if shouldOpen {
                    if !store.isCommentsPresented { store.send(.userTappedCommentButton) }
                } else {
                    isInputFocused = false
                    if store.isCommentsPresented { store.send(.commentsDismissed) }
                }
            }
    }

    private func rubberClamp(_ value: CGFloat, limit: CGFloat) -> CGFloat {
        if value <= 0 { return 0 }
        if value > limit { return limit + (value - limit) * 0.15 }
        return value
    }
}

#Preview {
    ReelsView(
        store: Store(initialState: ReelsFeature.State.sample()) {
            ReelsFeature()
        }
    )
}
