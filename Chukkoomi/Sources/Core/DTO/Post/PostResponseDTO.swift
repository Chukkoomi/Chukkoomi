//
//  PostResponseDTO.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/6/25.
//

import Foundation

/// 게시글 조회 응답 DTO
struct PostResponseDTO: Decodable {
    let postID: String
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
    let createdAt: String
    let creator: CreatorDTO
    let files: [String]
    let likes: [String]
    let likes2: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int
    let geolocation: GeolocationDTO?
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case category, title, price, content
        case value1, value2, value3, value4, value5, value6, value7, value8, value9, value10
        case createdAt, creator, files, likes, likes2, buyers, hashTags
        case commentCount = "comment_count"
        case geolocation, distance
    }
}

extension PostResponseDTO {
    var toModel: Post {
        return Post(dto: self)
    }
}

/// 작성자 정보
struct CreatorDTO: Decodable {
    let userID: String
    let nick: String
    let profileImage: String
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick, profileImage
    }
}

/// 위치 정보
struct GeolocationDTO: Decodable {
    let longitude: Double
    let latitude: Double
}
