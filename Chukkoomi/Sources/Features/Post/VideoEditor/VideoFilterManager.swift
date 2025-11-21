//
//  VideoFilterManager.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/15/25.
//

import UIKit
import AVFoundation
@preconcurrency import CoreImage
import Vision
import CoreML
import Metal

/// 비디오 필터 타입
enum VideoFilter: String, CaseIterable, Equatable {
    case blackAndWhite = "흑백"
    case warm = "따뜻한"
    case cool = "차갑게"
    case animeGANHayao = "그림"

    var displayName: String {
        return rawValue
    }
}

/// 비디오 필터 관리자
struct VideoFilterManager {

    /// 비디오에 필터를 적용한 AVVideoComposition 생성
    /// - Parameters:
    ///   - asset: 원본 비디오 AVAsset
    ///   - filter: 적용할 필터
    ///   - targetSize: 목표 크기 (nil이면 원본 크기 사용)
    /// - Returns: 필터가 적용된 AVVideoComposition (필터가 없으면 nil)
    static func createVideoComposition(
        for asset: AVAsset,
        filter: VideoFilter?,
        targetSize: CGSize? = nil
    ) async -> AVVideoComposition? {
        // 필터가 없으면 nil 반환
        guard let filter = filter else {
            return nil
        }

        // 비디오 트랙 가져오기
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }

        let naturalSize = try? await videoTrack.load(.naturalSize)
        let preferredTransform = try? await videoTrack.load(.preferredTransform)

        guard let naturalSize = naturalSize else {
            return nil
        }

        // 회전 각도 확인
        let correctedTransform = preferredTransform ?? .identity
        let videoAngleInDegree = atan2(correctedTransform.b, correctedTransform.a) * 180 / .pi

        // targetSize가 있으면 회전을 고려한 renderSize 계산
        var renderSize = naturalSize
        if let targetSize = targetSize, targetSize != naturalSize {
            switch Int(videoAngleInDegree) {
            case 90, -270:
                // 세로 영상의 경우 width/height 뒤집기
                renderSize = CGSize(width: targetSize.height, height: targetSize.width)
            default:
                renderSize = targetSize
            }
        }

        // aspect-fit 스케일 계산
        let scaleX = renderSize.width / naturalSize.width
        let scaleY = renderSize.height / naturalSize.height
        let scale = min(scaleX, scaleY)

        // 중앙 정렬을 위한 offset 계산
        let scaledWidth = naturalSize.width * scale
        let scaledHeight = naturalSize.height * scale
        let offsetX = (renderSize.width - scaledWidth) / 2
        let offsetY = (renderSize.height - scaledHeight) / 2

        // AVVideoComposition 생성 (필터 + 리사이즈를 CIImage로 처리)
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage

                // 필터 적용
                let filtered = applyFilter(filter, to: source, originalImage: source, targetSize: nil)

                // aspect-fit 리사이징 및 중앙 정렬
                let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                let translateTransform = CGAffineTransform(translationX: offsetX, y: offsetY)
                let finalTransform = scaleTransform.concatenating(translateTransform)

                let resized = filtered.transformed(by: finalTransform)

                // renderSize 영역으로 crop
                let output = resized.cropped(to: CGRect(origin: .zero, size: renderSize))

                // GPU 가속 컨텍스트를 명시적으로 전달
                request.finish(with: output, context: VideoFilterHelper.gpuContext)
            }
        )

        composition.renderSize = renderSize

        return composition
    }

    // MARK: - Private Helper Methods

    /// CIImage에 필터 적용 (VideoFilterHelper 사용)
    private static func applyFilter(_ filter: VideoFilter, to image: CIImage, originalImage: CIImage, targetSize: CGSize? = nil) -> CIImage {
        return VideoFilterHelper.applyFilter(filter, to: image, originalImage: originalImage, targetSize: targetSize)
    }

    /// 비디오 orientation 확인 헬퍼
    private static func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false

        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }

        return (assetOrientation, isPortrait)
    }
}
