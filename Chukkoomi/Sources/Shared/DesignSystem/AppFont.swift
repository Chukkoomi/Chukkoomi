//
//  AppFont.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/4/25.
//

import SwiftUI

/// ex) Text("제목").font(.appTitle)
extension Font {
    /// 큰 제목 (Navigation Title 등)
    static var appLargeTitle: Font = .system(size: 32, weight: .bold)
    /// 일반 제목
    static var appTitle: Font = .system(size: 22, weight: .semibold)
    /// 부제목
    static var appSubTitle: Font = .system(size: 16, weight: .medium)
    /// 본문
    static var appBody: Font = .system(size: 14, weight: .regular)
    /// 캡션, 보조 설명
    static var appCaption: Font = .system(size: 12, weight: .regular)
    /// 아주 작은 텍스트
    static var appSmall: Font = .system(size: 10, weight: .light)
}
