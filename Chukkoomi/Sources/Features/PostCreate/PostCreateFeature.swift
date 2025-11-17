//
//  PostCreateFeature.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/16/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct PostCreateFeature {

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var selectedCategory: FootballTeams = .all
        var hashtagInput: String = ""
        var hashtags: [String] = []
        var content: String = ""
        var selectedImageData: Data?
        var isUploading: Bool = false
        var errorMessage: String?
        var showSuccessAlert: Bool = false

        // 수정 모드
        var isEditMode: Bool = false
        var editingPostId: String?

        // 원본 데이터 (변경 감지용)
        var originalCategory: FootballTeams?
        var originalContent: String?
        var originalImageUrl: String?

        // 갤러리 피커
        @Presents var galleryPicker: GalleryPickerFeature.State?

        // 네비게이션 타이틀
        var navigationTitle: String {
            isEditMode ? "게시글 수정" : "게시글 작성"
        }

        // 데이터 변경 여부 확인
        var hasChanges: Bool {
            guard isEditMode else { return true }

            // 카테고리 변경 체크
            if selectedCategory != originalCategory {
                return true
            }

            // 컨텐츠 변경 체크
            if content != originalContent {
                return true
            }

            // 이미지 변경 체크 (새 이미지를 선택했거나, 원본 이미지를 제거한 경우)
            if selectedImageData != nil || originalImageUrl == nil {
                return true
            }

            return false
        }

        // 업로드 가능 여부
        var canUpload: Bool {
            // 수정 모드일 때는 변경사항이 있어야 함
            if isEditMode {
                return hasChanges &&
                       (selectedImageData != nil || originalImageUrl != nil) &&
                       !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            // 작성 모드일 때는 이미지와 본문이 있어야 함
            return selectedImageData != nil &&
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // 수정 모드 생성자
        init(post: Post) {
            self.isEditMode = true
            self.editingPostId = post.id
            self.selectedCategory = post.teams
            self.originalCategory = post.teams

            // content에서 해시태그 제외한 본문만 추출
            let words = post.content.split(separator: " ")
            let contentWords = words.filter { !$0.hasPrefix("#") }
            let contentWithoutHashtags = contentWords.joined(separator: " ")

            self.content = contentWithoutHashtags
            self.originalContent = contentWithoutHashtags

            // 해시태그 추출
            self.hashtags = post.hashTags

            // 원본 이미지 URL 저장
            self.originalImageUrl = post.files.first

            // 나머지는 기본값
            self.hashtagInput = ""
            self.selectedImageData = nil
            self.isUploading = false
            self.errorMessage = nil
            self.showSuccessAlert = false
            self.galleryPicker = nil
        }

        // 기본 생성자 (작성 모드)
        init() {
            self.selectedCategory = .all
            self.hashtagInput = ""
            self.hashtags = []
            self.content = ""
            self.selectedImageData = nil
            self.isUploading = false
            self.errorMessage = nil
            self.showSuccessAlert = false
            self.isEditMode = false
            self.editingPostId = nil
            self.originalCategory = nil
            self.originalContent = nil
            self.originalImageUrl = nil
            self.galleryPicker = nil
        }
    }

    // MARK: - Action
    enum Action: Equatable {
        case categorySelected(FootballTeams)
        case hashtagInputChanged(String)
        case addHashtag
        case removeHashtag(String)
        case contentChanged(String)
        case selectImageTapped
        case removeImage
        case uploadButtonTapped
        case uploadResponse(Result<PostResponseDTO, Error>)
        case dismissSuccessAlert

        // 갤러리 피커
        case galleryPicker(PresentationAction<GalleryPickerFeature.Action>)

        // Delegate
        case delegate(Delegate)

        enum Delegate: Equatable {
            case postCreated
            case postUpdated
        }

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case let (.categorySelected(lhsCategory), .categorySelected(rhsCategory)):
                return lhsCategory == rhsCategory
            case let (.hashtagInputChanged(lhsText), .hashtagInputChanged(rhsText)):
                return lhsText == rhsText
            case (.addHashtag, .addHashtag):
                return true
            case let (.removeHashtag(lhsTag), .removeHashtag(rhsTag)):
                return lhsTag == rhsTag
            case let (.contentChanged(lhsContent), .contentChanged(rhsContent)):
                return lhsContent == rhsContent
            case (.selectImageTapped, .selectImageTapped):
                return true
            case (.removeImage, .removeImage):
                return true
            case (.uploadButtonTapped, .uploadButtonTapped):
                return true
            case (.uploadResponse, .uploadResponse):
                return true
            case (.dismissSuccessAlert, .dismissSuccessAlert):
                return true
            case (.galleryPicker, .galleryPicker):
                return true
            case let (.delegate(lhs), .delegate(rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    // MARK: - Reducer
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .categorySelected(category):
                state.selectedCategory = category
                return .none

            case let .hashtagInputChanged(text):
                // 띄어쓰기 제거
                state.hashtagInput = text.replacingOccurrences(of: " ", with: "")
                return .none

            case .addHashtag:
                let trimmed = state.hashtagInput.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmed.isEmpty else {
                    return .none
                }

                // # 제거 (사용자가 입력했을 수도 있으므로)
                let tag = trimmed.replacingOccurrences(of: "#", with: "")

                // 중복 체크
                guard !state.hashtags.contains(tag) else {
                    state.hashtagInput = ""
                    return .none
                }

                // 해시태그 추가
                state.hashtags.append(tag)
                state.hashtagInput = ""
                return .none

            case let .removeHashtag(tag):
                state.hashtags.removeAll { $0 == tag }
                return .none

            case let .contentChanged(content):
                state.content = content
                return .none

            case .selectImageTapped:
                // 갤러리 피커 열기 (게시물 모드)
                state.galleryPicker = GalleryPickerFeature.State(pickerMode: .post)
                return .none

            case .removeImage:
                // 선택된 이미지 제거
                state.selectedImageData = nil
                return .none

            case .uploadButtonTapped:
                // 유효성 검증
                if !state.isEditMode {
                    guard state.selectedImageData != nil else {
                        state.errorMessage = "이미지를 선택해주세요"
                        return .none
                    }
                } else {
                    guard state.selectedImageData != nil || state.originalImageUrl != nil else {
                        state.errorMessage = "이미지를 선택해주세요"
                        return .none
                    }
                }

                guard !state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.errorMessage = "내용을 입력해주세요"
                    return .none
                }

                state.isUploading = true
                state.errorMessage = nil

                let logPrefix = state.isEditMode ? "게시글 수정 시작" : "게시글 업로드 시작"
                print(logPrefix)
                print("   카테고리: \(state.selectedCategory.rawValue)")
                print("   해시태그: \(state.hashtags)")
                print("   내용: \(state.content)")

                // 수정 모드인지 작성 모드인지에 따라 분기
                if state.isEditMode {
                    // 게시글 수정
                    return .run { [
                        postId = state.editingPostId!,
                        imageData = state.selectedImageData,
                        category = state.selectedCategory,
                        hashtags = state.hashtags,
                        content = state.content
                    ] send in
                        do {
                            // content에 본문과 해시태그를 함께 포함
                            let hashtagString = hashtags.isEmpty ? "" : " " + hashtags.map { "#\($0)" }.joined(separator: " ")
                            let fullContent = content + hashtagString

                            // PostRequestDTO 생성
                            let postRequest = PostRequestDTO(
                                category: category.rawValue,
                                title: "게시글",
                                price: 0,
                                content: fullContent,
                                value1: "",
                                value2: "",
                                value3: "",
                                value4: "",
                                value5: "",
                                value6: "",
                                value7: "",
                                value8: "",
                                value9: "",
                                value10: "",
                                files: [],
                                longitude: GeoLocation.defaultLocation.longitude,
                                latitude: GeoLocation.defaultLocation.latitude
                            )

                            // PostService를 사용해서 게시글 수정
                            let images = imageData != nil ? [imageData!] : []
                            let response = try await PostService.shared.updatePost(
                                postId: postId,
                                post: postRequest,
                                images: images
                            )

                            print("게시글 수정 성공: \(response.postId)")
                            await send(.uploadResponse(.success(response)))
                        } catch {
                            print("게시글 수정 실패: \(error)")
                            await send(.uploadResponse(.failure(error)))
                        }
                    }
                } else {
                    // 게시글 작성
                    return .run { [
                        imageData = state.selectedImageData!,
                        category = state.selectedCategory,
                        hashtags = state.hashtags,
                        content = state.content
                    ] send in
                        do {
                            // content에 본문과 해시태그를 함께 포함
                            let hashtagString = hashtags.isEmpty ? "" : " " + hashtags.map { "#\($0)" }.joined(separator: " ")
                            let fullContent = content + hashtagString

                            // PostRequestDTO 생성
                            let postRequest = PostRequestDTO(
                                category: category.rawValue,
                                title: "게시글",
                                price: 0,
                                content: fullContent,
                                value1: "",
                                value2: "",
                                value3: "",
                                value4: "",
                                value5: "",
                                value6: "",
                                value7: "",
                                value8: "",
                                value9: "",
                                value10: "",
                                files: [],
                                longitude: GeoLocation.defaultLocation.longitude,
                                latitude: GeoLocation.defaultLocation.latitude
                            )

                            // PostService를 사용해서 게시글 생성 (이미지 업로드 포함)
                            let response = try await PostService.shared.createPost(
                                post: postRequest,
                                images: [imageData]
                            )

                            print("게시글 업로드 성공: \(response.postId)")
                            await send(.uploadResponse(.success(response)))
                        } catch {
                            print("게시글 업로드 실패: \(error)")
                            await send(.uploadResponse(.failure(error)))
                        }
                    }
                }

            case let .uploadResponse(.success(response)):
                state.isUploading = false
                let logMessage = state.isEditMode ? "게시글 수정 성공: \(response.postId)" : "게시글 업로드 성공: \(response.postId)"
                print(logMessage)

                // 작성 모드일 때만 상태 초기화
                if !state.isEditMode {
                    state.selectedImageData = nil
                    state.selectedCategory = .all
                    state.hashtags = []
                    state.content = ""
                    state.hashtagInput = ""
                }

                // 성공 알림 표시
                state.showSuccessAlert = true
                return .none

            case .dismissSuccessAlert:
                state.showSuccessAlert = false
                let wasEditMode = state.isEditMode

                // Delegate 액션 전송 (PostFeature에서 게시글 리스트 새로고침 및 화면 닫기)
                if wasEditMode {
                    return .send(.delegate(.postUpdated))
                } else {
                    return .send(.delegate(.postCreated))
                }

            case let .uploadResponse(.failure(error)):
                state.isUploading = false
                state.errorMessage = error.localizedDescription
                let logMessage = state.isEditMode ? "게시글 수정 실패: \(error)" : "게시글 업로드 실패: \(error)"
                print(logMessage)
                return .none

            case let .galleryPicker(.presented(.delegate(.didSelectImage(imageData)))):
                // 갤러리에서 이미지 선택 완료
                state.selectedImageData = imageData
                print("이미지 선택 완료: \(imageData.count) bytes")
                return .none

            case .galleryPicker:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$galleryPicker, action: \.galleryPicker) {
            GalleryPickerFeature()
        }
    }
}
