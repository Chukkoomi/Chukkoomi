//
//  User.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/5/25.
//

import Foundation

struct User {
    var userId: String
    var nick: String
    var profileImage: String?
    var instroduce: String?  // info1 -> instroduce
}


/*
{
  "email": "cold_noodles@sesac.com",
  "nick": "냉면조아",
  "profileImage": "/data/profiles/1707716853682.png",
  "phoneNum": "01012341234",
  "gender": "male",
  "birthDay": "99990410",
  "info1": "안녕하세요",
  "info2": "rx공부 같이 하실 분",
  "info3": "문래역",
  "info4": "독서, 러닝",
  "info5": "rxswfit, combine, tca",
  "followers": [
    {
      "user_id": "65c9aa6932b0964405117d97",
      "nick": "jack",
      "profileImage": "/data/profiles/1707716853682.png"
    }
  ],
  "following": [
    {
      "user_id": "65c9aa6932b0964405117d97",
      "nick": "jack",
      "profileImage": "/data/profiles/1707716853682.png"
    }
  ],
  "posts": [
    "65c9aec120e856755623884e"
  ]
}
*/
