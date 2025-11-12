//
//  PostView.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/5/25.
//

import SwiftUI
import ComposableArchitecture

struct PostView: View {
    let store: StoreOf<PostFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        store.scope(state: \.postCells, action: \.postCell)
                    ) { cellStore in
                        PostCellView(store: cellStore)
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("게시글")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}


#Preview {
    PostView(
        store: Store(
            initialState: PostFeature.State()
        ) {
            PostFeature()
        }
    )
}
