//
//  FileUploadDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/10/25.
//

import Foundation

/// 파일 업로드 DTO
/// 요청에 대한 응답도 동일한 형태로 오기 때문에 Codable로 정의
struct FileUploadDTO: Codable {
    let files: [String]
}
