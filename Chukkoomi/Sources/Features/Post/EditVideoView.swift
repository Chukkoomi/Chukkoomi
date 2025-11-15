//
//  EditVideoView.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/15/25.
//

import SwiftUI
import ComposableArchitecture
import AVKit
import Photos

struct EditVideoView: View {
    let store: StoreOf<EditVideoFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // 비디오 플레이어
                AssetVideoPlayerView(asset: viewStore.videoAsset)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)

                Spacer()

                // 임시 편집 UI 플레이스홀더
                Text("영상 편집 화면")
                    .font(.appTitle)
                    .foregroundStyle(.gray)

                Spacer()
            }
            .navigationTitle("영상 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewStore.send(.closeButtonTapped)
                    } label: {
                        AppIcon.xmark
                            .foregroundStyle(.black)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.nextButtonTapped)
                    } label: {
                        Text("다음")
                            .foregroundStyle(.black)
                    }
                }
            }
        }
    }
}
