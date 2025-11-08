//
//  DateFormatters.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/8/25.
//

import Foundation

enum DateFormatters {
    /// ISO8601 형식의 날짜 문자열을 파싱하기 위한 포맷터
    /// - 형식: "yyyy-MM-dd'T'HH:mm:ss.SSSZ" (예: "2025-11-08T03:05:03.422Z")
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO8601 형식 (초 단위, 밀리초 없음)
    /// - 형식: "yyyy-MM-dd'T'HH:mm:ssZ" (예: "2025-11-08T03:05:03Z")
    static let iso8601WithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
