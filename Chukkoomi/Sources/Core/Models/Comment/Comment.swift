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
    
    init(dto: CommentDTO) {
        self.id = dto.id
        self.content = dto.content
        self.createdAt = DateFormatters.iso8601.date(from: dto.createdAt) ?? Date()
        self.creator = UserSummary(dto: dto.creator)
    }
}

extension Comment {
    var toDTO: CommentRequestDTO {
        return CommentRequestDTO(content: content)
    }
}

