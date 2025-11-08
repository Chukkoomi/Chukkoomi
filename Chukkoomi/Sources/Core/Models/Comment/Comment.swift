//
//  Comment.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/8/25.
//

import Foundation

struct Comment {
    let id: String
    let content: String
    let createdAt: Date
    let creator: UserSummary
    let replies: [Comment]?
    
    init(dto: CommentDTO) {
        self.id = dto.id
        self.content = dto.content
        self.creator = UserSummary(dto.creator)
        if let replyDTOs = dto.replies {
            self.replies = replyDTOs.map { Comment(replyDTO: $0) }
        } else {
            self.replies = nil
        }
        if let date = ISO8601DateFormatter().date(from: dto.createdAt) {
            self.createdAt = date
        } else {
            self.createdAt = Date()
        }
    }
    
    init(replyDTO: ReplyDTO) {
        self.id = replyDTO.id
        self.content = replyDTO.content
        self.creator = UserSummary(replyDTO.creator)
        self.replies = nil
        if let date = ISO8601DateFormatter().date(from: replyDTO.createdAt) {
            self.createdAt = date
        } else {
            self.createdAt = Date()
        }
    }
}

extension Comment {
    static func fromListDTO(_ dto: CommentListResponseDTO) -> [Comment] {
        return dto.comments.map { Comment(dto: $0) }
    }
}

