//
//  PostCellView.swift
//  Chukkoomi
//
//  Created by 박성훈 on 11/12/25.
//

import SwiftUI
import ComposableArchitecture

struct PostCellView: View {
    let store: StoreOf<PostCellFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            titleView

            mediaContentView


            actionBarView
        }
        .padding(.vertical, 8)
        .confirmationDialog(
            store: store.scope(state: \.$menu, action: \.menu)
        )
        .alert(
            store: store.scope(state: \.$deleteAlert, action: \.deleteAlert)
        )
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if let profileImagePath = store.post.creator?.profileImage {
                AsyncMediaImageView(
                    imagePath: profileImagePath,
                    width: 40,
                    height: 40,
                    onImageLoaded: { _ in }
                )
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.post.creator?.nickname ?? "사용자")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let createdAt = store.post.createdAt {
                    Text(timeAgoString(from: createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 본인 게시글이면 메뉴 버튼, 아니면 팔로우 버튼
            if store.isMyPost {
                menuButtonView()
            } else {
                followButtonView()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Title
    private var titleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 해시태그 제외한 본문만 표시
            Text(extractContentWithoutHashtags(from: store.post.content))
                .font(Font.appSubBody)

            // 해시태그 표시 (버튼)
            if !store.post.hashTags.isEmpty {
                HashtagFlowLayout(spacing: 8) {
                    ForEach(store.post.hashTags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(Font.appSubBody)
                            .foregroundColor(.blue)
                            .buttonWrapper {
                                store.send(.hashtagTapped(tag))
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Media Content (Image or Video)
    @ViewBuilder
    private var mediaContentView: some View {
        if let firstFile = store.post.files.first {
            GeometryReader { geometry in
                AsyncMediaImageView(
                    imagePath: firstFile,
                    width: geometry.size.width,
                    height: 300
                )
            }
            .frame(height: 300)
        }
    }

    // MARK: - Action Bar
    private var actionBarView: some View {
        HStack(spacing: 16) {
            // 좋아요
            HStack(spacing: 4) {
                Image(systemName: store.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(store.isLiked ? .red : .primary)
                Text("\(store.likeCount)")
                    .font(.caption)
            }
            .buttonWrapper {
                store.send(.likeTapped)
            }

            // 댓글
            HStack(spacing: 4) {
                AppIcon.comment
                    .font(.system(size: 20))
                Text("\(store.post.commentCount ?? 0)")
                    .font(.caption)
            }
            .buttonWrapper {
                store.send(.commentTapped)
            }

            // 공유
            AppIcon.share
                .font(.system(size: 20))
                .buttonWrapper {
                    store.send(.shareTapped)
                }

            Spacer()

            // 북마크
            Image(systemName: store.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 20))
                .foregroundColor(store.isBookmarked ? .blue : .primary)
                .buttonWrapper {
                    store.send(.bookmarkTapped)
                }
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
    }
    
    private func followButtonView() -> some View {
        Text(store.isFollowing ? "팔로잉" : "+ 팔로우")
            .font(.appSubTitle)
            .foregroundColor(.black)
            .frame(width: 80, height: 40)
            .background(
                Capsule()
                    .fill(AppColor.lightGray)
            )
            .buttonWrapper {
                store.send(.followTapped)
            }
    }

    private func menuButtonView() -> some View {
        AppIcon.ellipsis
            .font(.system(size: 20))
            .frame(width: 40, height: 40)
            .foregroundStyle(.black)
            .buttonWrapper {
                store.send(.menuTapped)
            }
    }

    // MARK: - 헬퍼 메서드

    /// 컨텐츠에서 해시태그를 제거하고 본문만 추출
    private func extractContentWithoutHashtags(from fullContent: String) -> String {
        // "#"으로 시작하는 단어들을 제거
        let words = fullContent.split(separator: " ")
        let contentWords = words.filter { !$0.hasPrefix("#") }
        return contentWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 시간 포맷 헬퍼
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return "\(day)일전"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)시간전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분전"
        } else {
            return "방금"
        }
    }
}

// MARK: - HashtagFlowLayout for Hashtags
struct HashtagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = HashtagFlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = HashtagFlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: position, proposal: .unspecified)
        }
    }

    struct HashtagFlowLayoutResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // 다음 줄로
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))

                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview
#Preview {
    PostCellView(
        store: Store(
            initialState: PostCellFeature.State(
                post: Post(
                    teams: .all,
                    title: "테스트 게시글",
                    price: 0,
                    content: "내용",
                    files: ["image1"]
                )
            )
        ) {
            PostCellFeature()
        }
    )
}
