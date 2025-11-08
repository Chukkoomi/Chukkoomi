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
    let creator: User
    
    init(dto: CommentDTO) {
        self.id = dto.id
        self.content = dto.content
        self.createdAt = DateFormatters.iso8601.date(from: dto.createdAt) ?? Date()
        self.creator = User(userId: dto.creator.user_id, nickname: dto.creator.nick, profileImage: dto.creator.profileImage)
    }
}

extension Comment {
    var toDTO: CommentRequestDTO {
        return CommentRequestDTO(content: content)
    }
}

