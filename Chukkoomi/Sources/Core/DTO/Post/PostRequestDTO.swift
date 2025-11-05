//
//  PostRequestDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 작성 / 수정 요청 DTO
struct PostRequestDTO: Codable {
    let category: String
    let title: String
    let price: Int
    let content: String
    let value1: String
    let value2: String
    let value3: String
    let value4: String
    let value5: String
    let value6: String
    let value7: String
    let value8: String
    let value9: String
    let value10: String
    let files: [String]
    let longitude: Double  // 옵셔널 가능한지 확인 필요 (테스트에서 계속 Loading)
    let latitude: Double  // 옵셔널 가능한지 확인 필요 (테스트에서 계속 Loading)
}
