//
//  ChatWebSocketManager.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/21/25.
//

import Foundation
import SocketIO

final class ChatWebSocketManager {
    static let shared = ChatWebSocketManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentRoomId: String?

    // 콜백 클로저
    var onMessageReceived: (([ChatMessage]) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?

    private init() {}

    // MARK: - WebSocket 연결
    func connect(roomId: String, onMessageReceived: @escaping ([ChatMessage]) -> Void) {
        print("[ChatWebSocketManager] 🔌 Connecting to room: \(roomId)")

        // 이미 같은 방에 연결되어 있으면 무시
        if currentRoomId == roomId, socket?.status == .connected {
            print("[ChatWebSocketManager] ⚠️ Already connected to room: \(roomId)")
            return
        }

        // 기존 연결 해제
        disconnect()

        currentRoomId = roomId
        self.onMessageReceived = onMessageReceived

        // Socket.IO URL: {baseURL}:{port}/chats-{room_id}
        // baseURL에서 포트 번호 추출 (예: http://lslp.sesac.co.kr:30279)
        guard let url = URL(string: APIInfo.baseURL) else {
            print("[ChatWebSocketManager] ❌ Invalid base URL")
            return
        }

        let namespace = "/chats-\(roomId)"

        // 헤더 설정 (SeSACKey, Authorization, ProductId)
        let accessToken = KeychainManager.shared.load(for: .accessToken) ?? ""

        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .extraHeaders([
                "SeSACKey": APIInfo.apiKey,
                "Authorization": accessToken,
                "ProductId": APIInfo.productId
            ])
        ]

        // SocketManager 생성
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: namespace)

        setupSocketHandlers()

        // 연결 시작
        socket?.connect()
    }

    // MARK: - WebSocket 연결 해제
    func disconnect() {
        print("[ChatWebSocketManager] 🔌 Disconnecting...")
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        currentRoomId = nil
        onMessageReceived = nil
    }

    // MARK: - Socket 이벤트 핸들러 설정
    private func setupSocketHandlers() {
        // 연결 성공
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("[ChatWebSocketManager] ✅ SOCKET IS CONNECTED", data, ack)
            self?.onConnectionChanged?(true)
        }

        // 연결 해제
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("[ChatWebSocketManager] ❌ SOCKET IS DISCONNECTED", data, ack)
            self?.onConnectionChanged?(false)
        }

        // 연결 에러
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("[ChatWebSocketManager] ⚠️ SOCKET ERROR", data, ack)
            if let errorData = data.first as? [String: Any],
               let message = errorData["message"] as? String {
                let error = NSError(domain: "ChatWebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
                self?.onError?(error)
            }
        }

        // "chat" 이벤트로 메시지 수신
        socket?.on("chat") { [weak self] dataArray, ack in
            print("[ChatWebSocketManager] 📨 CHAT RECEIVED", dataArray, ack)

            guard let self = self else { return }

            // dataArray를 ChatMessage로 파싱
            var messages: [ChatMessage] = []

            for data in dataArray {
                if let json = data as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: json)
                        let decoder = JSONDecoder()
                        let messageDTO = try decoder.decode(ChatMessageResponseDTO.self, from: jsonData)
                        messages.append(messageDTO.toDomain)
                        print("[ChatWebSocketManager] ✅ Parsed message: \(messageDTO.chatId)")
                    } catch {
                        print("[ChatWebSocketManager] ❌ Failed to parse message: \(error)")
                    }
                }
            }

            if !messages.isEmpty {
                print("[ChatWebSocketManager] 📤 Calling onMessageReceived with \(messages.count) messages")
                self.onMessageReceived?(messages)
            }
        }
    }
}
