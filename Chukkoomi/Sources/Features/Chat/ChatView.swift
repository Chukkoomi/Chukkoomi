//
//  ChatView.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/12/25.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

struct ChatView: View {

    let store: StoreOf<ChatFeature>
    @State private var opponentProfileImage: UIImage?
    @State private var selectedPhotosItems: [PhotosPickerItem] = []
    @State private var isProcessingPhotos: Bool = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // onAppear 트리거용 투명 뷰
                Color.clear
                    .frame(height: 0)
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
                    .task {
                        // 프로필 이미지 한 번만 로드
                        await loadOpponentProfileImage(
                            opponent: viewStore.opponent
                        )
                    }

                // 메시지 리스트
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 페이지네이션 로딩 인디케이터
                            if viewStore.isLoading && viewStore.cursorDate != nil {
                                ProgressView()
                                    .padding(.vertical, 8)
                            }

                            // 메시지 목록
                            ForEach(Array(viewStore.messages.enumerated()), id: \.element.chatId) { index, message in
                                // 날짜 구분선 표시 (첫 메시지이거나 이전 메시지와 날짜가 다를 때)
                                if index == 0 || shouldShowDateSeparator(currentMessage: message, previousMessage: viewStore.messages[index - 1]) {
                                    DateSeparatorView(dateString: message.createdAt)
                                        .padding(.vertical, 12)
                                }

                                MessageRow(
                                    message: message,
                                    isMyMessage: isMyMessage(message, myUserId: viewStore.myUserId),
                                    opponentProfileImage: opponentProfileImage
                                )
                                .id(message.chatId)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewStore.messages.count) {
                        // 새 메시지가 추가되면 스크롤을 최하단으로
                        if let lastMessage = viewStore.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.chatId, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // 초기 로드 후 스크롤을 최하단으로
                        if let lastMessage = viewStore.messages.last {
                            scrollProxy.scrollTo(lastMessage.chatId, anchor: .bottom)
                        }
                    }
                }

                Divider()

                // 메시지 입력창
                HStack(spacing: 12) {
                    // 이미지 선택 버튼
                    PhotosPicker(selection: $selectedPhotosItems, maxSelectionCount: 5, matching: .images) {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                            .font(.system(size: 22))
                    }
                    .onChange(of: selectedPhotosItems) { oldValue, newValue in
                        handlePhotosSelection(newValue: newValue, viewStore: viewStore)
                    }
                    .disabled(viewStore.isUploadingFiles || isProcessingPhotos)

                    TextField("메시지를 입력하세요", text: viewStore.binding(
                        get: \.messageText,
                        send: { .messageTextChanged($0) }
                    ))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                    Button(action: {
                        viewStore.send(.sendMessageTapped)
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(viewStore.messageText.isEmpty ? .gray : .blue)
                            .font(.system(size: 20))
                    }
                    .disabled(viewStore.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewStore.isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay {
                    // 업로드 중 로딩 표시
                    if viewStore.isUploadingFiles {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                    }
                }
            }
            .navigationTitle(opponentNickname(chatRoom: viewStore.chatRoom, opponent: viewStore.opponent, myUserId: viewStore.myUserId))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }

    // 현재 사용자의 메시지인지 확인
    private func isMyMessage(_ message: ChatMessage, myUserId: String?) -> Bool {
        guard let myUserId = myUserId else {
            return false
        }
        return message.sender.userId == myUserId
    }

    // 상대방 닉네임 추출
    private func opponentNickname(chatRoom: ChatRoom?, opponent: ChatUser, myUserId: String?) -> String {
        guard let chatRoom = chatRoom else {
            // 채팅방이 아직 생성되지 않은 경우 opponent 정보 사용
            return opponent.nick
        }

        guard let myUserId = myUserId else {
            return chatRoom.participants.first?.nick ?? "채팅"
        }

        // 내가 아닌 participant 찾기
        if let opponent = chatRoom.participants.first(where: { $0.userId != myUserId }) {
            return opponent.nick
        }

        // 나 자신과의 채팅방인 경우 (모든 participant가 나)
        return chatRoom.participants.first?.nick ?? "채팅"
    }

    // 날짜 구분선을 표시할지 확인
    private func shouldShowDateSeparator(currentMessage: ChatMessage, previousMessage: ChatMessage) -> Bool {
        return DateFormatters.isDifferentDay(previousMessage.createdAt, currentMessage.createdAt)
    }

    // 상대방 프로필 이미지를 한 번만 로드
    private func loadOpponentProfileImage(opponent: ChatUser) async {
        guard let path = opponent.profileImage else {
            return
        }

        do {
            let imageData: Data

            if path.hasPrefix("http://") || path.hasPrefix("https://") {
                guard let url = URL(string: path) else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                imageData = data
            } else {
                imageData = try await NetworkManager.shared.download(
                    MediaRouter.getData(path: path)
                )
            }

            if let uiImage = UIImage(data: imageData) {
                opponentProfileImage = uiImage
            }
        } catch {
            // 프로필 이미지 로드 실패 시 기본 아이콘 표시
        }
    }

    // 사진 선택 처리
    private func handlePhotosSelection(newValue: [PhotosPickerItem], viewStore: ViewStoreOf<ChatFeature>) {
        guard !newValue.isEmpty, !isProcessingPhotos else { return }

        // 즉시 초기화해서 중복 트리거 방지
        let itemsToProcess = newValue
        selectedPhotosItems = []
        isProcessingPhotos = true

        Task {
            var filesData: [Data] = []

            for item in itemsToProcess {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    filesData.append(data)
                }
            }

            // 메인 스레드에서 상태 업데이트
            await MainActor.run {
                isProcessingPhotos = false

                if !filesData.isEmpty {
                    viewStore.send(.uploadAndSendFiles(filesData))
                }
            }
        }
    }

    // 이미지 URL을 절대 경로로 변환
    private func fullImageURL(_ path: String) -> URL? {
        let fullURL: String
        if path.hasPrefix("http") {
            fullURL = path
        } else {
            fullURL = APIInfo.baseURL + path
        }
        return URL(string: fullURL)
    }
}

// MARK: - 날짜 구분선
struct DateSeparatorView: View {
    let dateString: String

    var body: some View {
        Text(DateFormatters.formatChatDateSeparator(dateString))
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - 메시지 Row
struct MessageRow: View {

    let message: ChatMessage
    let isMyMessage: Bool
    let opponentProfileImage: UIImage?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMyMessage {
                Spacer(minLength: 60)

                // 내 메시지: 시간이 왼쪽
                Text(DateFormatters.formatChatMessageTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                messageContent
            } else {
                // 상대방 프로필 이미지
                if let profileImage = opponentProfileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        )
                }

                messageContent

                // 받은 메시지: 시간이 오른쪽
                Text(DateFormatters.formatChatMessageTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Spacer(minLength: 60)
            }
        }
    }

    // 메시지 내용 부분
    private var messageContent: some View {
        VStack(alignment: isMyMessage ? .trailing : .leading, spacing: 4) {
            // 메시지 내용
            if let content = message.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(isMyMessage ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMyMessage ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(16)
            }

            // 이미지 파일
            if !message.files.isEmpty {
                ForEach(message.files, id: \.self) { filePath in
                    AsyncMediaImageView(
                        imagePath: filePath,
                        width: 200,
                        height: 200
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
}
