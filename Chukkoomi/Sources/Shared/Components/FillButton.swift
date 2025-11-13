//
//  FillButton.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/13/25.
//

import SwiftUI

struct FillButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.appSubTitle)
                .foregroundStyle(.white)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(AppColor.primary)
                .customRadius()
        }
    }
}
