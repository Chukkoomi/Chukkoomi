//
//  Like.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/7/25.
//

import Foundation

struct Like {
    let likeStatus: Bool
}

extension Like {
    var toDTO: LikeRequestDTO {
        return LikeRequestDTO(likeStatus: likeStatus)
    }
}
