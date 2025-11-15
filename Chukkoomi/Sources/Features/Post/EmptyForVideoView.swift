//
//  EmptyForVideoView.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/15/25.
//

import SwiftUI
import ComposableArchitecture

struct EmptyForVideoView: View {
    @State private var showGalleryPicker = false

    var body: some View {
        Button {
            showGalleryPicker = true
        } label: {
            Text("Edit Video")
        }
        .fullScreenCover(isPresented: $showGalleryPicker) {
            NavigationStack {
                GalleryPickerView(
                    store: Store(
                        initialState: GalleryPickerFeature.State(pickerMode: .post)
                    ) {
                        GalleryPickerFeature()
                    }
                )
            }
        }
    }
}

#Preview {
    EmptyForVideoView()
}
