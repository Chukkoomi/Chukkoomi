//
//  PostRequestDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 작성 / 수정 요청 DTO
struct PostRequestDTO: Codable {
    let category: String
    let title: String
    let price: Int
    let content: String
    let value1: String
    let value2: String
    let value3: String
    let value4: String
    let value5: String
    let value6: String
    let value7: String
    let value8: String
    let value9: String
    let value10: String
    let files: [String]
    let longitude: Double
    let latitude: Double
    
    init(model: Post) {
        self.category = model.category.rawValue
        self.title = model.title
        self.price = model.price
        self.content = model.content
        self.value1 = model.value1
        self.value2 = model.value2
        self.value3 = model.value3
        self.value4 = model.value4
        self.value5 = model.value5
        self.value6 = model.value6
        self.value7 = model.value7
        self.value8 = model.value8
        self.value9 = model.value9
        self.value10 = model.value10
        self.files = model.files
        self.longitude = 0.0
        self.latitude = 0.0
    }
}
