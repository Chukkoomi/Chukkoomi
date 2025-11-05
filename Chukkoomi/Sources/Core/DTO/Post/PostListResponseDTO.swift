//
//  PostResponseDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 목록 조회 응답 DTO
struct PostListResponseDTO: Decodable {
    let data: [PostResponseDTO]
    let nextCursor: String  // 다음 커서 없으면 0
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
