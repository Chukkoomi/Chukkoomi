//
//  EditVideoFeature.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/15/25.
//

import ComposableArchitecture
import Foundation
import Photos

@Reducer
struct EditVideoFeature {

    // MARK: - State
    struct State: Equatable {
        let videoAsset: PHAsset

        init(videoAsset: PHAsset) {
            self.videoAsset = videoAsset
        }
    }

    // MARK: - Action
    @CasePathable
    enum Action: Equatable {
        case nextButtonTapped
    }

    // MARK: - Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nextButtonTapped:
                // TODO: 영상 편집 완료 후 다음 단계로 이동
                return .none
            }
        }
    }
}
