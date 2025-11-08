//
//  CommentListResponseDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 댓글 목록 응답 DTO
struct CommentListResponseDTO: Decodable {
    let data: [CommentDTO]
}

extension CommentListResponseDTO {
    var toModel: [Comment] {
        return data.map { Comment(dto: $0) }
    }
}

/// 댓글 (대댓글 포함)
struct CommentDTO: Decodable {
    let id: String
    let content: String
    let createdAt: String
    let creator: CreatorDTO
    let replies: [CommentDTO]?

    enum CodingKeys: String, CodingKey {
        case id = "comment_id"
        case content, createdAt, creator, replies
    }
}

extension CommentDTO {
    var toModel: Comment {
        return Comment(dto: self)
    }
}
