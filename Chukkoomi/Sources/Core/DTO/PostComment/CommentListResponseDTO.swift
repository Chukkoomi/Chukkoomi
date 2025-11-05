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

/// 댓글 (대댓글 포함)
struct CommentDTO: Decodable {
    let commentID: String
    let content: String
    let createdAt: String
    let creator: CreatorDTO
    let replies: [ReplyDTO]?  // 대댓글에는 replies가 포함되지 않음

    enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case content, createdAt, creator, replies
    }
}

/// 대댓글
struct ReplyDTO: Decodable {
    let commentID: String
    let content: String
    let createdAt: String
    let creator: CreatorDTO

    enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case content, createdAt, creator
    }
}
