//
//  Post.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/5/25.
//

import Foundation

struct Post {
    let id: String
    var category: PostCategory
    var title: String
    var price: Int
    var content: String
    #warning("value에 대한 값 구체화 필요")
    let value1, value2, value3, value4, value5: String
    let value6, value7, value8, value9, value10: String
    var files: [String]
    var creator: UserSummary?
    var commentCount: Int
    var likes: [String]
    var likes2: [String]
    var buyers: [String]
    var hashTags: [String]
    
    init(dto: PostResponseDTO) {
        self.id = dto.postID
        self.category = PostCategory(rawValue: dto.category) ?? .total
        self.title = dto.title
        self.price = dto.price
        self.content = dto.content
        self.value1 = dto.value1
        self.value2 = dto.value2
        self.value3 = dto.value3
        self.value4 = dto.value4
        self.value5 = dto.value5
        self.value6 = dto.value6
        self.value7 = dto.value7
        self.value8 = dto.value8
        self.value9 = dto.value9
        self.value10 = dto.value10
        self.files = dto.files
        #warning("User 통합 필요")
        self.creator = UserSummary(
            id: dto.creator.userID,
            nick: dto.creator.nick,
            profileImage: dto.creator.profileImage
        )
        self.commentCount = dto.commentCount
        self.likes = dto.likes
        self.likes2 = dto.likes2
        self.buyers = dto.buyers
        self.hashTags = dto.hashTags
        
    }
}

enum PostCategory: String {
    case total = "전체"
}

// TODO: User로 합치기
struct UserSummary {
    let id: String
    let nick: String
    let profileImage: String
}

extension Post {
    var toDTO: PostRequestDTO {
        return PostRequestDTO(model: self)
    }
}
