//
//  SearchFeature.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/12/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {

    // MARK: - State
    struct State: Equatable {
        var searchText: String = ""
        var posts: [PostItem] = []
        var isLoading: Bool = false
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case searchTextChanged(String)
        case search
        case clearSearch
        case postsLoaded([PostItem])
        case postTapped(String)
    }

    // MARK: - Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 임시 picsum 이미지 데이터 생성
                let dummyPosts = (1...30).map { index in
                    PostItem(id: "\(index)", imagePath: "https://picsum.photos/400/400?random=\(index)")
                }

                state.posts = dummyPosts
                state.isLoading = false
                return .none

            case .searchTextChanged(let text):
                state.searchText = text
                return .none

            case .search:
                // TODO: 검색 실행
                return .none

            case .clearSearch:
                state.searchText = ""
                return .none

            case .postsLoaded(let posts):
                state.posts = posts
                state.isLoading = false
                return .none

            case .postTapped:
                // TODO: 게시물 상세 화면으로 이동
                return .none
            }
        }
    }
}

// MARK: - Models
extension SearchFeature {
    struct PostItem: Equatable, Identifiable {
        let id: String
        let imagePath: String
        var imageData: Data?
        let isVideo: Bool

        init(id: String, imagePath: String, imageData: Data? = nil) {
            self.id = id
            self.imagePath = imagePath
            self.imageData = imageData
            self.isVideo = MediaTypeHelper.isVideoPath(imagePath)
        }
    }
}
