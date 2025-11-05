//
//  LikeRequestDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 좋아요1, 2 요청 DTO
struct LikeRequestDTO: Encodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
