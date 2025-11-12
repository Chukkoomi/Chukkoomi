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
        case imageDownloaded(id: String, data: Data)
        case postTapped(String)
    }

    // MARK: - Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true

                // 임시 picsum 이미지 데이터 생성
                let dummyPosts = (1...30).map { index in
                    PostItem(id: "\(index)", imagePath: "https://picsum.photos/400/400?random=\(index)")
                }

                return .run { send in
                    await send(.postsLoaded(dummyPosts))

                    // 각 이미지 다운로드
                    for post in dummyPosts {
                        if let url = URL(string: post.imagePath),
                           let data = try? Data(contentsOf: url) {
                            await send(.imageDownloaded(id: post.id, data: data))
                        }
                    }
                }

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

            case .imageDownloaded(let id, let data):
                if let index = state.posts.firstIndex(where: { $0.id == id }) {
                    state.posts[index].imageData = data
                }
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
