//
//  ChatFeature.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/12/25.
//

import ComposableArchitecture
import Foundation
import RealmSwift

struct ChatFeature: Reducer {

    // MARK: - Cancel ID
    enum CancelID {
        case webSocket
    }

    // MARK: - State
    struct State: Equatable {
        var chatRoom: ChatRoom?  // 옵셔널로 변경 (첫 메시지 전송 시 생성)
        let opponent: ChatUser   // 상대방 정보
        let myUserId: String?
        var messages: [ChatMessage] = []
        var messageText: String = ""
        var isLoading: Bool = false
        var isSending: Bool = false
        var isUploadingFiles: Bool = false
        var cursorDate: String?
        var hasMoreMessages: Bool = true
        var pendingFileUploads: [String: [Data]] = [:]  // localId: filesData
        var selectedTheme: ChatTheme = .default
        var isThemeSheetPresented: Bool = false
        var isWebSocketConnected: Bool = false

        init(chatRoom: ChatRoom?, opponent: ChatUser, myUserId: String?) {
            self.chatRoom = chatRoom
            self.opponent = opponent
            self.myUserId = myUserId

            // roomId가 있으면 저장된 테마 불러오기
            if let roomId = chatRoom?.roomId {
                self.selectedTheme = ChatThemeStorage.loadTheme(for: roomId)
            }
        }
    }

    enum ChatTheme: String, CaseIterable, Equatable {
        case `default` = "기본 테마"
        case theme1 = "테마1"
        case theme2 = "테마2"
        case theme3 = "테마3"
        case theme4 = "테마4"

        var imageName: String? {
            switch self {
            case .default: return "기본 테마"
            case .theme1: return "테마1"
            case .theme2: return "테마2"
            case .theme3: return "테마3"
            case .theme4: return "테마4"
            }
        }
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case onDisappear
        case loadMessages
        case messagesLoaded([ChatMessage], hasMore: Bool)
        case messagesLoadedFromRealm([ChatMessage])
        case messageTextChanged(String)
        case sendMessageTapped
        case messageSent(ChatMessage, localId: String?)
        case chatRoomCreated(ChatRoom)
        case loadMoreMessages
        case messageLoadFailed(String)
        case messageSendFailed(String, localId: String)

        // 파일 업로드
        case uploadAndSendFiles([Data])
        case filesUploaded([String], localId: String)
        case fileUploadFailed(String, localId: String?)
        case uploadTimeout(localId: String)

        // 메시지 재전송 및 취소
        case retryMessage(localId: String)
        case cancelMessage(localId: String)

        // 테마 선택
        case themeButtonTapped
        case themeSelected(ChatTheme)
        case dismissThemeSheet

        // WebSocket
        case connectWebSocket
        case webSocketConnected
        case webSocketDisconnected
        case webSocketMessageReceived([ChatMessage])
        case webSocketError(String)
    }

    // MARK: - Reducer
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            print("[ChatFeature] 👀 onAppear called")
            print("[ChatFeature] chatRoom: \(state.chatRoom?.roomId ?? "nil")")

            // 채팅방이 없으면 (첫 메시지 전송 전) 로딩하지 않음
            guard let roomId = state.chatRoom?.roomId else {
                print("[ChatFeature] ⚠️ No roomId, skipping WebSocket connection")
                return .none
            }

            // ===== 🧪 Postman 테스트용 정보 출력 =====
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔌 WebSocket 테스트 정보")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🏠 Room ID: \(roomId)")
            print("👤 상대방 User ID: \(state.opponent.userId)")
            print("📛 상대방 닉네임: \(state.opponent.nick)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // PDF 권장 순서:
            // 1. Realm에서 먼저 로드 (빠른 UI 표시)
            // 2. HTTP로 동기화
            // 3. 모든 동기화 완료 후 WebSocket 연결 (.messagesLoaded에서 처리)
            return .run { send in
                _ = await MainActor.run {
                    do {
                        let realm = try Realm()
                        let messageDTOs = realm.objects(ChatMessageRealmDTO.self)
                            .filter("roomId == %@", roomId)
                            .sorted(byKeyPath: "createdAt", ascending: true)
                        let messages = Array(messageDTOs.map { $0.toDomain })

                        Task {
                            send(.messagesLoadedFromRealm(messages))
                            // Realm 로드 후 HTTP로 동기화
                            send(.loadMessages)
                        }
                    } catch {
                        // Realm 실패 시 HTTP로 직접 로드
                        Task {
                            send(.loadMessages)
                        }
                    }
                }
            }

        case .onDisappear:
            // WebSocket 연결 해제 및 Effect 취소
            ChatWebSocketManager.shared.disconnect()
            return .cancel(id: CancelID.webSocket)

        case .loadMessages:
            // 채팅방이 아직 생성되지 않은 경우 (첫 메시지 전송 전)
            guard let roomId = state.chatRoom?.roomId else {
                state.isLoading = false
                return .none
            }

            return .run { [cursorDate = state.cursorDate] send in
                do {
                    let response = try await NetworkManager.shared.performRequest(
                        ChatRouter.getChatHistory(roomId: roomId, cursorDate: cursorDate),
                        as: ChatMessageListResponseDTO.self
                    )
                    let messages = response.data.map { $0.toDomain }
                    let hasMore = messages.count >= 20 // API가 20개씩 반환한다고 가정
                    await send(.messagesLoaded(messages, hasMore: hasMore))
                } catch {
                    await send(.messageLoadFailed(error.localizedDescription))
                }
            }

        case .messagesLoadedFromRealm(let realmMessages):
            // Realm에서 로드한 메시지를 먼저 표시 (빠른 UX)
            state.messages = realmMessages
            state.isLoading = true  // HTTP 동기화 중임을 표시
            return .none

        case .messagesLoaded(let newMessages, let hasMore):
            state.isLoading = false

            let isInitialLoad = state.cursorDate == nil

            if isInitialLoad {
                // 초기 로드: API에서 받은 순서 그대로 (오래된 메시지가 위, 최신 메시지가 아래)
                // Realm에서 이미 로드했다면 병합 (중복 제거)
                if !state.messages.isEmpty {
                    // 기존 Realm 메시지와 새 메시지 병합 (chatId 기준 중복 제거)
                    let existingIds = Set(state.messages.map { $0.chatId })
                    let uniqueNewMessages = newMessages.filter { !existingIds.contains($0.chatId) }
                    state.messages.append(contentsOf: uniqueNewMessages)
                } else {
                    state.messages = newMessages
                }
            } else {
                // 페이지네이션: 이전 메시지를 위에 추가
                state.messages = newMessages + state.messages
            }

            // 다음 페이지네이션을 위한 커서 설정
            if let oldestMessage = newMessages.last {
                state.cursorDate = oldestMessage.createdAt
            }

            state.hasMoreMessages = hasMore

            // Realm에 저장 + 초기 로드 시 WebSocket 연결
            return .merge(
                // Realm 저장
                .run { send in
                    _ = await MainActor.run {
                        do {
                            let realm = try Realm()
                            try realm.write {
                                for message in newMessages {
                                    let messageDTO = message.toRealmDTO()
                                    realm.add(messageDTO, update: .modified)
                                }
                            }
                        } catch {
                            // Realm 저장 실패
                        }
                    }
                },
                // 초기 로드 완료 후 WebSocket 연결
                isInitialLoad ? .send(.connectWebSocket) : .none
            )

        case .messageTextChanged(let text):
            state.messageText = text
            return .none

        case .sendMessageTapped:
            guard !state.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .none
            }

            state.isSending = true
            let messageContent = state.messageText
            state.messageText = "" // 즉시 입력창 클리어

            // 로컬 임시 메시지 생성 (낙관적 업데이트)
            let localId = UUID().uuidString
            let tempMessage = ChatMessage(
                chatId: "",  // 서버 응답 후 업데이트
                roomId: state.chatRoom?.roomId ?? "",
                content: messageContent,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                sender: ChatUser(
                    userId: state.myUserId ?? "",
                    nick: "",  // UI에서는 내 메시지는 닉네임을 표시하지 않음
                    profileImage: nil
                ),
                files: [],
                sendStatus: .sending,
                localId: localId,
                localImages: nil,
                sharedPost: nil
            )
            state.messages.append(tempMessage)

            // 채팅방이 아직 생성되지 않은 경우 (첫 메시지)
            if state.chatRoom == nil {
                return .run { [opponentId = state.opponent.userId] send in
                    do {
                        // 1. 채팅방 생성
                        let chatRoomResponse = try await NetworkManager.shared.performRequest(
                            ChatRouter.createChatRoom(opponentId: opponentId),
                            as: ChatRoomResponseDTO.self
                        )
                        let chatRoom = chatRoomResponse.toDomain
                        await send(.chatRoomCreated(chatRoom))

                        // 2. 메시지 전송
                        let messageResponse = try await NetworkManager.shared.performRequest(
                            ChatRouter.sendMessage(roomId: chatRoom.roomId, content: messageContent, files: nil),
                            as: ChatMessageResponseDTO.self
                        )
                        await send(.messageSent(messageResponse.toDomain, localId: localId))
                    } catch {
                        await send(.messageSendFailed(error.localizedDescription, localId: localId))
                    }
                }
            } else {
                // 채팅방이 이미 존재하는 경우
                return .run { [roomId = state.chatRoom!.roomId] send in
                    do {
                        let response = try await NetworkManager.shared.performRequest(
                            ChatRouter.sendMessage(roomId: roomId, content: messageContent, files: nil),
                            as: ChatMessageResponseDTO.self
                        )
                        await send(.messageSent(response.toDomain, localId: localId))
                    } catch {
                        await send(.messageSendFailed(error.localizedDescription, localId: localId))
                    }
                }
            }

        case .messageSent(let message, let localId):
            state.isSending = false

            // localId가 있으면 임시 메시지를 교체, 없으면 새로 추가 (페이지네이션으로 로드된 메시지)
            if let localId = localId,
               let index = state.messages.firstIndex(where: { $0.localId == localId }) {
                state.messages[index] = message
                // 파일 Data 정리
                state.pendingFileUploads.removeValue(forKey: localId)
            } else {
                state.messages.append(message)
            }

            // Realm에 저장
            return .run { send in
                _ = await MainActor.run {
                    do {
                        let realm = try Realm()
                        let messageDTO = message.toRealmDTO()
                        try realm.write {
                            realm.add(messageDTO, update: .modified)
                        }
                    } catch {
                        // Realm 저장 실패
                    }
                }
            }

        case .chatRoomCreated(let chatRoom):
            state.chatRoom = chatRoom

            // 채팅방 생성 시 저장된 테마 불러오기
            state.selectedTheme = ChatThemeStorage.loadTheme(for: chatRoom.roomId)

            return .none

        case .loadMoreMessages:
            guard !state.isLoading, state.hasMoreMessages else {
                return .none
            }

            state.isLoading = true
            return .send(.loadMessages)

        case .messageLoadFailed:
            state.isLoading = false
            // TODO: 에러 알림 표시
            return .none

        case .messageSendFailed(_, let localId):
            state.isSending = false

            // localId로 메시지를 찾아서 상태를 .failed로 변경
            if let index = state.messages.firstIndex(where: { $0.localId == localId }) {
                var failedMessage = state.messages[index]
                failedMessage.sendStatus = .failed
                state.messages[index] = failedMessage
            }
            return .none

        case .uploadAndSendFiles(let filesData):
            state.isUploadingFiles = true

            // 로컬 임시 메시지 생성 (낙관적 업데이트)
            let localId = UUID().uuidString
            let tempMessage = ChatMessage(
                chatId: "",
                roomId: state.chatRoom?.roomId ?? "",
                content: nil,  // 파일 메시지는 content를 nil로
                createdAt: ISO8601DateFormatter().string(from: Date()),
                sender: ChatUser(
                    userId: state.myUserId ?? "",
                    nick: "",
                    profileImage: nil
                ),
                files: ["uploading"],  // 업로드 중 표시를 위한 placeholder
                sendStatus: .sending,
                localId: localId,
                localImages: filesData,  // 로컬 이미지 Data 저장
                sharedPost: nil
            )
            state.messages.append(tempMessage)

            // 파일 Data 저장 (재전송 시 사용)
            state.pendingFileUploads[localId] = filesData

            // 채팅방이 아직 생성되지 않은 경우 (첫 메시지)
            if state.chatRoom == nil {
                return .run { [opponentId = state.opponent.userId] send in
                    do {
                        // 1. 채팅방 생성
                        let chatRoomResponse = try await NetworkManager.shared.performRequest(
                            ChatRouter.createChatRoom(opponentId: opponentId),
                            as: ChatRoomResponseDTO.self
                        )
                        let chatRoom = chatRoomResponse.toDomain
                        await send(.chatRoomCreated(chatRoom))

                        // 2. 파일 업로드 재시도
                        await send(.uploadAndSendFiles(filesData))
                    } catch {
                        await send(.fileUploadFailed(error.localizedDescription, localId: localId))
                    }
                }
            }

            return .merge(
                // 실제 파일 업로드
                .run { [roomId = state.chatRoom!.roomId] send in
                    do {
                        // Data를 MultipartFile 배열로 변환
                        let multipartFiles = filesData.enumerated().map { index, data in
                            // 파일 타입 감지 (이미지 vs 영상)
                            let isVideo = isVideoData(data)
                            let fileName: String
                            let mimeType: String

                            if isVideo {
                                fileName = "video_\(index)_\(UUID().uuidString).mp4"
                                mimeType = "video/mp4"
                            } else {
                                fileName = "image_\(index)_\(UUID().uuidString).jpg"
                                mimeType = "image/jpeg"
                            }

                            return MultipartFile(data: data, fileName: fileName, mimeType: mimeType)
                        }

                        // 파일 업로드 (ChatRouter 사용)
                        let response = try await NetworkManager.shared.performRequest(
                            ChatRouter.uploadFiles(roomId: roomId, files: multipartFiles),
                            as: UploadFileResponseDTO.self
                        )

                        // 업로드된 파일 URL로 메시지 전송
                        await send(.filesUploaded(response.files, localId: localId))
                    } catch {
                        await send(.fileUploadFailed(error.localizedDescription, localId: localId))
                    }
                }
                .cancellable(id: localId, cancelInFlight: true),

                // 5초 타임아웃
                .run { send in
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    await send(.uploadTimeout(localId: localId))
                }
                .cancellable(id: "\(localId)-timeout", cancelInFlight: true)
            )

        case .filesUploaded(let fileUrls, let localId):
            state.isUploadingFiles = false

            // 파일 URL로 메시지 전송
            guard let roomId = state.chatRoom?.roomId else {
                return .none
            }

            // 타임아웃 취소
            return .merge(
                .cancel(id: localId),
                .cancel(id: "\(localId)-timeout"),
                .run { send in
                    do {
                        let response = try await NetworkManager.shared.performRequest(
                            ChatRouter.sendMessage(roomId: roomId, content: nil, files: fileUrls),
                            as: ChatMessageResponseDTO.self
                        )
                        await send(.messageSent(response.toDomain, localId: localId))
                    } catch {
                        await send(.messageSendFailed(error.localizedDescription, localId: localId))
                    }
                }
            )

        case .fileUploadFailed(_, let localId):
            state.isUploadingFiles = false

            // localId로 메시지를 찾아서 상태를 .failed로 변경
            if let localId = localId,
               let index = state.messages.firstIndex(where: { $0.localId == localId }) {
                var failedMessage = state.messages[index]
                failedMessage.sendStatus = .failed
                state.messages[index] = failedMessage

                // 타임아웃 취소
                return .merge(
                    .cancel(id: localId),
                    .cancel(id: "\(localId)-timeout")
                )
            }
            return .none

        case .uploadTimeout(let localId):
            state.isUploadingFiles = false

            // localId로 메시지를 찾아서 상태를 .failed로 변경
            if let index = state.messages.firstIndex(where: { $0.localId == localId }) {
                var failedMessage = state.messages[index]
                failedMessage.sendStatus = .failed
                state.messages[index] = failedMessage
            }

            // 업로드 태스크 취소
            return .cancel(id: localId)

        case .retryMessage(let localId):
            // localId로 실패한 메시지를 찾아서 재전송
            guard let index = state.messages.firstIndex(where: { $0.localId == localId }),
                  let roomId = state.chatRoom?.roomId else {
                return .none
            }

            let failedMessage = state.messages[index]

            // 상태를 .sending으로 변경
            var retryingMessage = failedMessage
            retryingMessage.sendStatus = .sending
            state.messages[index] = retryingMessage

            // 파일 업로드가 실패한 경우 (pendingFileUploads에 Data가 있음)
            if let filesData = state.pendingFileUploads[localId] {
                state.isUploadingFiles = true

                return .merge(
                    // 실제 파일 업로드
                    .run { send in
                        do {
                            // Data를 MultipartFile 배열로 변환
                            let multipartFiles = filesData.enumerated().map { index, data in
                                // 파일 타입 감지 (이미지 vs 영상)
                                let isVideo = isVideoData(data)
                                let fileName: String
                                let mimeType: String

                                if isVideo {
                                    fileName = "video_\(index)_\(UUID().uuidString).mp4"
                                    mimeType = "video/mp4"
                                } else {
                                    fileName = "image_\(index)_\(UUID().uuidString).jpg"
                                    mimeType = "image/jpeg"
                                }

                                return MultipartFile(data: data, fileName: fileName, mimeType: mimeType)
                            }

                            // 파일 업로드 (ChatRouter 사용)
                            let response = try await NetworkManager.shared.performRequest(
                                ChatRouter.uploadFiles(roomId: roomId, files: multipartFiles),
                                as: UploadFileResponseDTO.self
                            )

                            // 업로드된 파일 URL로 메시지 전송
                            await send(.filesUploaded(response.files, localId: localId))
                        } catch {
                            await send(.fileUploadFailed(error.localizedDescription, localId: localId))
                        }
                    }
                    .cancellable(id: localId, cancelInFlight: true),

                    // 5초 타임아웃
                    .run { send in
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        await send(.uploadTimeout(localId: localId))
                    }
                    .cancellable(id: "\(localId)-timeout", cancelInFlight: true)
                )
            }

            // 텍스트 메시지 재전송
            let content = failedMessage.content
            let files = failedMessage.files

            return .run { send in
                do {
                    let response = try await NetworkManager.shared.performRequest(
                        ChatRouter.sendMessage(roomId: roomId, content: content, files: files.isEmpty ? nil : files),
                        as: ChatMessageResponseDTO.self
                    )
                    await send(.messageSent(response.toDomain, localId: localId))
                } catch {
                    await send(.messageSendFailed(error.localizedDescription, localId: localId))
                }
            }

        case .cancelMessage(let localId):
            // localId로 실패한 메시지를 찾아서 삭제
            state.messages.removeAll { $0.localId == localId }
            // 파일 Data도 정리
            state.pendingFileUploads.removeValue(forKey: localId)
            return .none

        case .themeButtonTapped:
            state.isThemeSheetPresented = true
            return .none

        case .themeSelected(let theme):
            state.selectedTheme = theme
            state.isThemeSheetPresented = false

            // roomId가 있으면 테마 저장
            if let roomId = state.chatRoom?.roomId {
                ChatThemeStorage.saveTheme(theme, for: roomId)
            }

            return .none

        case .dismissThemeSheet:
            state.isThemeSheetPresented = false
            return .none

        // MARK: - WebSocket Actions
        case .connectWebSocket:
            guard let roomId = state.chatRoom?.roomId else {
                print("[ChatFeature] ⚠️ Cannot connect WebSocket: roomId is nil")
                return .none
            }

            print("[ChatFeature] 🔌 Connecting WebSocket for room: \(roomId)")
            return .run { send in
                // WebSocket 연결 및 콜백 설정
                print("[ChatFeature] 📝 Setting up WebSocket callbacks")

                ChatWebSocketManager.shared.onConnectionChanged = { isConnected in
                    Task { @MainActor in
                        if isConnected {
                            send(.webSocketConnected)
                        } else {
                            send(.webSocketDisconnected)
                        }
                    }
                }

                ChatWebSocketManager.shared.onError = { error in
                    Task { @MainActor in
                        send(.webSocketError(error.localizedDescription))
                    }
                }

                // WebSocket 연결 (콜백을 파라미터로 전달)
                ChatWebSocketManager.shared.connect(roomId: roomId) { messages in
                    print("[ChatFeature] 🎯 onMessageReceived called with \(messages.count) messages")
                    Task { @MainActor in
                        print("[ChatFeature] 📤 Sending .webSocketMessageReceived action")
                        send(.webSocketMessageReceived(messages))
                    }
                }

                // Effect가 즉시 완료되지 않도록 대기 (콜백이 설정된 상태 유지)
                // 채팅 화면이 dismiss될 때 자동으로 cancel됨
                try? await Task.sleep(for: .seconds(3600)) // 1시간 유지
            }
            .cancellable(id: CancelID.webSocket, cancelInFlight: true)

        case .webSocketConnected:
            state.isWebSocketConnected = true
            print("[ChatFeature] WebSocket connected")
            return .none

        case .webSocketDisconnected:
            state.isWebSocketConnected = false
            print("[ChatFeature] WebSocket disconnected")
            return .none

        case .webSocketMessageReceived(let newMessages):
            print("[ChatFeature] 📨 WebSocket message received: \(newMessages.count) messages")
            // 실시간으로 받은 메시지를 추가
            for message in newMessages {
                print("[ChatFeature] 🔍 Checking message: chatId=\(message.chatId), content=\(message.content ?? "nil")")
                // 중복 메시지 체크 (chatId 기준)
                if !state.messages.contains(where: { $0.chatId == message.chatId }) {
                    print("[ChatFeature] ✅ Adding new message to state")
                    state.messages.append(message)

                    // Realm에 저장
                    Task {
                        _ = await MainActor.run {
                            do {
                                let realm = try Realm()
                                let messageDTO = message.toRealmDTO()
                                try realm.write {
                                    realm.add(messageDTO, update: .modified)
                                }
                            } catch {
                                print("[ChatFeature] Failed to save WebSocket message to Realm: \(error)")
                            }
                        }
                    }
                } else {
                    print("[ChatFeature] ⚠️ Message already exists, skipping (chatId=\(message.chatId))")
                }

                // localId로 전송 중인 메시지가 있다면 교체 (내가 보낸 메시지가 서버에서 다시 돌아온 경우)
                if let index = state.messages.firstIndex(where: {
                    $0.localId != nil &&
                    $0.sender.userId == message.sender.userId &&
                    $0.content == message.content &&
                    $0.sendStatus == .sending
                }) {
                    state.messages[index] = message
                }
            }
            return .none

        case .webSocketError(let errorMessage):
            print("[ChatFeature] WebSocket error: \(errorMessage)")
            // TODO: 사용자에게 에러 표시 (필요시)
            return .none
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            self.reduce(into: &state, action: action)
        }
    }
}

// MARK: - Helper Functions
/// Data의 첫 바이트를 확인하여 영상 파일인지 판단
private func isVideoData(_ data: Data) -> Bool {
    guard data.count > 12 else { return false }

    // MP4 시그니처 확인 (ftyp)
    let mp4Signature: [UInt8] = [0x66, 0x74, 0x79, 0x70]  // "ftyp"
    if data.count >= 8 {
        let bytes = [UInt8](data[4..<8])
        if bytes == mp4Signature {
            return true
        }
    }

    // MOV 시그니처 확인 (moov, mdat 등)
    let movSignatures: [[UInt8]] = [
        [0x6D, 0x6F, 0x6F, 0x76],  // "moov"
        [0x6D, 0x64, 0x61, 0x74],  // "mdat"
        [0x77, 0x69, 0x64, 0x65],  // "wide"
    ]

    for signature in movSignatures {
        if data.count >= 8 {
            let bytes = [UInt8](data[4..<8])
            if bytes == signature {
                return true
            }
        }
    }

    return false
}
