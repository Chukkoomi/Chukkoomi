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
    @ObservableState
    struct State: Equatable {
        let videoAsset: PHAsset
        var isPlaying: Bool = false
        var currentTime: Double = 0.0
        var duration: Double = 0.0
        var seekTrigger: SeekDirection? = nil

        init(videoAsset: PHAsset) {
            self.videoAsset = videoAsset
        }
    }

    enum SeekDirection: Equatable {
        case forward
        case backward
    }

    // MARK: - Action
    @CasePathable
    enum Action: Equatable {
        case playPauseButtonTapped
        case seekBackward
        case seekForward
        case seekCompleted
        case updateCurrentTime(Double)
        case updateDuration(Double)
        case nextButtonTapped
    }

    // MARK: - Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .playPauseButtonTapped:
                state.isPlaying.toggle()
                return .none

            case .seekBackward:
                state.seekTrigger = .backward
                return .none

            case .seekForward:
                state.seekTrigger = .forward
                return .none

            case .seekCompleted:
                state.seekTrigger = nil
                return .none

            case .updateCurrentTime(let time):
                state.currentTime = time
                return .none

            case .updateDuration(let duration):
                state.duration = duration
                return .none

            case .nextButtonTapped:
                // TODO: 영상 편집 완료 후 다음 단계로 이동
                return .none
            }
        }
    }
}
