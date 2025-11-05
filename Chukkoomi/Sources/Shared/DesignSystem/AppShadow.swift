//
//  AppShadow.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/4/25.
//

import SwiftUI

enum AppShadow {
    /// 어디 쓸지??
    case strong
    /// 어디 쓸지??
    case medium
    /// 어디 쓸지??
    case light
    
    var style: AppShadowStyle {
        switch self {
        case .strong:
            return AppShadowStyle(radius: 12, y: 6, opacity: 0.2)
        case .medium:
            return AppShadowStyle(radius: 8, y: 4, opacity: 0.15)
        case .light:
            return AppShadowStyle(radius: 4, y: 2, opacity: 0.1)
        }
    }
}

struct AppShadowStyle {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double
}

extension View {
    /// ex)  Text("").customShadow(.large)
    func customShadow(_ shadow: AppShadow) -> some View {
        let style = shadow.style
        return self.shadow(color: .black.opacity(style.opacity), radius: style.radius, y: style.y)
    }
}
