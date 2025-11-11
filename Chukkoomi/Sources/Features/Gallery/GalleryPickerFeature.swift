//
//  GalleryPickerFeature.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/10/25.
//

import ComposableArchitecture
import Foundation
import Photos
import UIKit

struct GalleryPickerFeature: Reducer {

    // MARK: - State
    struct State: Equatable {
        var mediaItems: [MediaItem] = []
        var selectedItem: MediaItem?
        var selectedImage: UIImage?
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
        var isLoading: Bool = false
        var allowsVideo: Bool = false
        var presentationMode: PresentationMode = .push
    }

    // MARK: - PresentationMode
    enum PresentationMode: Equatable {
        case push
        case modal
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case requestPhotoLibraryAccess
        case authorizationStatusReceived(PHAuthorizationStatus)
        case loadMediaItems
        case mediaItemsLoaded([MediaItem])
        case mediaItemSelected(MediaItem)
        case selectedImageLoaded(UIImage)
        case confirmSelection
        case cancel
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didSelectImage(Data)
        }
    }

    // MARK: - Reducer
    @Dependency(\.dismiss) var dismiss

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            state.authorizationStatus = status

            if status == .authorized || status == .limited {
                return .send(.loadMediaItems)
            } else if status == .notDetermined {
                return .send(.requestPhotoLibraryAccess)
            }
            return .none

        case .requestPhotoLibraryAccess:
            return .run { send in
                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                await send(.authorizationStatusReceived(status))
            }

        case .authorizationStatusReceived(let status):
            state.authorizationStatus = status
            if status == .authorized || status == .limited {
                return .send(.loadMediaItems)
            }
            return .none

        case .loadMediaItems:
            state.isLoading = true
            return .run { [allowsVideo = state.allowsVideo] send in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 100

                let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                var mediaItems: [MediaItem] = []

                fetchResult.enumerateObjects { asset, _, _ in
                    // allowsVideo가 false면 사진만 필터링
                    if !allowsVideo && asset.mediaType != .image {
                        return
                    }
                    mediaItems.append(MediaItem(asset: asset))
                }

                await send(.mediaItemsLoaded(mediaItems))
            }

        case .mediaItemsLoaded(let items):
            state.mediaItems = items
            state.isLoading = false
            return .none

        case .mediaItemSelected(let item):
            state.selectedItem = item

            return .run { send in
                let image = await loadImage(from: item.asset)
                if let image = image {
                    await send(.selectedImageLoaded(image))
                }
            }

        case .selectedImageLoaded(let image):
            state.selectedImage = image
            return .none

        case .confirmSelection:
            guard let selectedImage = state.selectedImage,
                  let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                return .none
            }

            return .run { send in
                await send(.delegate(.didSelectImage(imageData)))
                await self.dismiss()
            }

        case .cancel:
            return .run { _ in
                await self.dismiss()
            }

        case .delegate:
            return .none
        }
    }

    // MARK: - Helper
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - Models
extension GalleryPickerFeature {
    struct MediaItem: Equatable, Identifiable {
        let id: String
        let asset: PHAsset
        let mediaType: PHAssetMediaType
        let duration: TimeInterval?

        init(asset: PHAsset) {
            self.id = asset.localIdentifier
            self.asset = asset
            self.mediaType = asset.mediaType
            self.duration = asset.mediaType == .video ? asset.duration : nil
        }

        static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
            lhs.id == rhs.id
        }
    }
}
