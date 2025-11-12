//
//  PostFeature.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/12/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct PostFeature {

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var postCells: IdentifiedArrayOf<PostCellFeature.State> = []
        var isLoading: Bool = false

        init() {
            self.loadMockData()
        }

        private mutating func loadMockData() {
            // 목업 데이터
            let mockPosts = [
                Post(
                    teams: .total,
                    title: "즐겁게 이겨 안보면 바보",
                    price: 0,
                    content: "2025시즌 K리그 1 2라운드 리뷰",
                    files: ["mock_image_1"]
                ),
                Post(
                    teams: .total,
                    title: "2025년 K리그 여름 이적시장 정리",
                    price: 0,
                    content: "여름 이적시장 정리",
                    files: ["mock_image_2"]
                )
            ]

            postCells = IdentifiedArray(
                uniqueElements: mockPosts.map { PostCellFeature.State(post: $0) }
            )
        }
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case loadPosts
        case postCell(IdentifiedActionOf<PostCellFeature>)
    }

    // MARK: - Reducer
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadPosts)

            case .loadPosts:
                // TODO: API 호출
                print("📱 게시글 로드")
                return .none

            case let .postCell(.element(id, .delegate(delegateAction))):
                return handleCellDelegate(id: id, action: delegateAction)

            case .postCell:
                return .none
            }
        }
        .forEach(\.postCells, action: \.postCell) {
            PostCellFeature()
        }
    }

    // MARK: - Delegate Handler
    private func handleCellDelegate(id: PostCellFeature.State.ID, action: PostCellFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .postTapped(postId):
            print("📄 게시글 탭: \(postId)")
            return .none

        case let .likePost(postId):
            print("❤️ 좋아요 탭: \(postId)")
            // TODO: API 호출 - 좋아요 토글
            return .none

        case let .commentPost(postId):
            print("💬 댓글 탭: \(postId)")
            // TODO: 댓글 화면으로 이동
            return .none

        case let .sharePost(postId):
            print("📤 공유 탭: \(postId)")
            // TODO: 공유 시트 표시
            return .none

        case let .bookmarkPost(postId):
            print("🔖 북마크 탭: \(postId)")
            // TODO: API 호출 - 북마크 토글
            return .none

        case let .followUser(userId):
            print("➕ 팔로우 탭: \(userId)")
            // TODO: API 호출 - 팔로우 토글
            return .none
        }
    }
}
