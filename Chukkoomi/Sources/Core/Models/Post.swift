//
//  Post.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/5/25.
//

import Foundation

struct Post {
    var categopry: Category
    var title: String
    var price: Int
    var content: String
}

enum Category {
    
}

/*
{
  "category": "sesac",
  "title": "같이 앱만드실 분",
  "price": 100,
  "content": "오늘도 파이팅! #영등포 #청취사 #새싹 #iOS #swift #⭐️ #sesac",
  "value1": "false",
  "value2": "10",
  "value3": "3시간",
  "value4": "미정",
  "value5": "LSLP 같이 하실분",
  "value6": "추가 정보 6",
  "value7": "추가 정보 7",
  "value8": "추가 정보 8",
  "value9": "추가 정보 9",
  "value10": "추가 정보 10",
  "files": [
    "/data/posts/sesac_1712739634962.png"
  ],
  "longitude": 126.886417,
  "latitude": 37.517682
}
*/
