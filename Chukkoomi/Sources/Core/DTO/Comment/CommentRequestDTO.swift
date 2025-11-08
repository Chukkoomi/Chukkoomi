//
//  CommentRequestDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 댓글/대댓글 작성, 수정 요청 DTO
struct CommentRequestDTO: Encodable {
    let content: String
}
