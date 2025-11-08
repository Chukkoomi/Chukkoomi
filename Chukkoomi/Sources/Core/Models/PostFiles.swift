//
//  PostFiles.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/7/25.
//

import Foundation

struct PostFiles {
    let files: [String]
}

extension PostFiles {
    var toDTO: PostFilesDTO {
        return PostFilesDTO(files: files)
    }
}
