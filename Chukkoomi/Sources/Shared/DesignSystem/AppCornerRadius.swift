//
//  AppCornerRadius.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/4/25.
//

import SwiftUI

enum AppCornerRadius: CGFloat {
    /// 어디 쓸지 ?? ex) 셀 배경
    case large = 24
    /// 어디 쓸지 ?? ex) 버튼
    case medium = 16
    /// 어디 쓸지 ??
    case small = 8
}


extension View {
    /// ex)  Text("").customRadius(.large)
    /// -> 나중에 Button Modifier, Text Modifier 등으로 만들면 좋을 듯
    func customRadius(_ radius: AppCornerRadius) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius.rawValue))
    }
}
