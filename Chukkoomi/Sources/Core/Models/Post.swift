//
//  Post.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/5/25.
//

import Foundation

import Foundation

struct Post {
    let id: String
    let teams: FootballTeams
    let title: String
    let price: Int
    let content: String
    #warning("values - 데이터 확정 시 수정 필요")
    let values: [String]
    let createdAt: Date
    let creator: User
    let files: [String]
    let likes: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int
    let location: GeoLocation
    let distance: Double?
}

enum FootballTeams {
    
}

struct GeoLocation {
    let longitude: Double
    let latitude: Double
}
