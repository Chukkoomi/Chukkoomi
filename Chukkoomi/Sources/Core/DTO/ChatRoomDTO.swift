//
//  ChatRoomDTO.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/6/25.
//

import Foundation

// MARK: - 채팅방 생성 Request
struct CreateChatRoomRequestDTO: Encodable {
    let opponentId: String
    
    enum CodingKeys: String, CodingKey {
        case opponentId = "opponent_id"
    }
}

// MARK: - 채팅방 Response (생성 + 리스트 공통)
struct ChatRoomResponseDTO: Decodable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [Participant]
    let lastChat: LastChat?
    
    struct Participant: Decodable {
        let userId: String
        let nick: String
        let profileImage: String?
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case nick
            case profileImage
        }
    }
    
    struct LastChat: Decodable {
        let chatId: String
        let roomId: String
        let content: String?
        let createdAt: String
        let sender: Participant
        let files: [String]
        
        enum CodingKeys: String, CodingKey {
            case chatId = "chat_id"
            case roomId = "room_id"
            case content
            case createdAt
            case sender
            case files
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

// MARK: - 채팅방 리스트 Response
struct ChatRoomListResponseDTO: Decodable {
    let data: [ChatRoomResponseDTO]
}

// MARK: - DTO -> Entity
extension ChatRoomResponseDTO {
    var toDomain: ChatRoom {
        return ChatRoom(
            roomId: roomId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            participants: participants.map { $0.toDomain },
            lastChat: lastChat?.toDomain
        )
    }
}

extension ChatRoomResponseDTO.Participant {
    var toDomain: ChatUser {
        return ChatUser(
            userId: userId,
            nick: nick,
            profileImage: profileImage
        )
    }
}

extension ChatRoomResponseDTO.LastChat {
    var toDomain: LastChatMessage {
        return LastChatMessage(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            sender: sender.toDomain,
            files: files
        )
    }
}
