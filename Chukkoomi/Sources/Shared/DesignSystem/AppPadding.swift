//
//  AppPadding.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/4/25.
//

import Foundation

/// ex) Text("").padding(AppSpacing.large)
enum AppPadding {
    /// 어디 쓸지 ?? ex) 가장 바깥 패딩
    static let large: CGFloat = 20
    /// 어디 쓸지 ?? ex) 섹션 구분 패딩
    static let medium: CGFloat = 12
    /// 어디 쓸지 ?? ex) 섹션 내 컴포넌트 패딩
    static let small: CGFloat = 8
}
