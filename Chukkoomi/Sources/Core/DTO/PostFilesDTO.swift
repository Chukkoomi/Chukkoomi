//
//  PostDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 파일 업로드 DTO
struct PostFilesDTO: Encodable {
    let files: [String]
}
