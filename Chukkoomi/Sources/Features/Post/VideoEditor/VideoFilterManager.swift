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
    case animeGANHayao = "Hayao"

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
    /// - Returns: 필터가 적용된 AVVideoComposition (필터가 없으면 nil)
    static func createVideoComposition(
        for asset: AVAsset,
        filter: VideoFilter?
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

        // AVVideoComposition 생성 (GPU 가속 컨텍스트 사용)
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage
                let clampedSource = source.clampedToExtent()

                // 필터별로 CIFilter 생성 및 적용 (원본과 clamped 버전 모두 전달)
                let output = applyFilter(filter, to: clampedSource, originalImage: source)

                // GPU 가속 컨텍스트를 명시적으로 전달
                request.finish(with: output, context: VideoFilterHelper.gpuContext)
            }
        )

        // naturalSize 설정
        if let naturalSize = naturalSize {
            composition.renderSize = naturalSize
        }

        // Transform 처리 (회전, 플립 등)
        if let preferredTransform = preferredTransform {
            let videoInfo = orientation(from: preferredTransform)
            var isPortrait = false
            switch videoInfo.orientation {
            case .up, .upMirrored, .down, .downMirrored:
                isPortrait = false
            case .left, .leftMirrored, .right, .rightMirrored:
                isPortrait = true
            @unknown default:
                isPortrait = false
            }

            if isPortrait, let naturalSize = naturalSize {
                composition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            }
        }

        return composition
    }

    // MARK: - Private Helper Methods

    /// CIImage에 필터 적용 (VideoFilterHelper 사용)
    private static func applyFilter(_ filter: VideoFilter, to image: CIImage, originalImage: CIImage) -> CIImage {
        return VideoFilterHelper.applyFilter(filter, to: image, originalImage: originalImage)
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
