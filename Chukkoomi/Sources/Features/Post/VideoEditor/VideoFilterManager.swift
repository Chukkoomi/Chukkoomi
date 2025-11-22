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
        targetSize: CGSize? = nil,
        isPortraitFromPHAsset: Bool
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

        // 디버깅 로그
        print("🎬 [VideoFilterManager] ====== 필터 적용 시작 ======")
        print("🎬 [VideoFilterManager] 원본 naturalSize: \(naturalSize)")
        print("🎬 [VideoFilterManager] isPortraitFromPHAsset: \(isPortraitFromPHAsset)")
        print("🎬 [VideoFilterManager] targetSize 파라미터: \(targetSize ?? .zero)")

        // naturalSize가 가로 방향인지 확인
        let isNaturalSizePortrait = naturalSize.width < naturalSize.height
        print("🎬 [VideoFilterManager] isNaturalSizePortrait: \(isNaturalSizePortrait)")

        // 세로 영상인데 naturalSize가 가로로 나온 경우 swap
        let adjustedNaturalSize: CGSize
        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            adjustedNaturalSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            print("🎬 [VideoFilterManager] naturalSize swap: \(adjustedNaturalSize)")
        } else {
            adjustedNaturalSize = naturalSize
            print("🎬 [VideoFilterManager] naturalSize 유지: \(adjustedNaturalSize)")
        }

        // renderSize 계산
        let renderSize = targetSize ?? adjustedNaturalSize
        print("🎬 [VideoFilterManager] renderSize: \(renderSize)")

        // 세로 영상인데 naturalSize가 가로였으면 90도 회전 필요
        let correctedTransform: CGAffineTransform
        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            correctedTransform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0)
            print("🎬 [VideoFilterManager] ✅ 세로 영상 - 90도 회전 transform 적용")
        } else {
            correctedTransform = preferredTransform ?? .identity
            print("🎬 [VideoFilterManager] 원본 transform 사용")
        }
        print("🎬 [VideoFilterManager] ====== 필터 적용 종료 ======")


        // aspect-fit 스케일 계산
        let scaleX = renderSize.width / adjustedNaturalSize.width
        let scaleY = renderSize.height / adjustedNaturalSize.height
        let scale = min(scaleX, scaleY)
        print("🎬 [VideoFilterManager] scale: \(scale) (scaleX: \(scaleX), scaleY: \(scaleY))")

        // 중앙 정렬을 위한 offset 계산 (원본 naturalSize 기준)
        let scaledWidth = naturalSize.width * scale
        let scaledHeight = naturalSize.height * scale
        print("🎬 [VideoFilterManager] scaledWidth: \(scaledWidth), scaledHeight: \(scaledHeight)")

        let offsetX: CGFloat
        let offsetY: CGFloat

        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            // 세로 영상이고 회전 필요한 경우: 90도 회전 후 중앙 정렬
            offsetX = (renderSize.width - scaledHeight) / 2
            offsetY = (renderSize.height - scaledWidth) / 2
        } else {
            // 가로 영상 또는 회전 불필요: 일반 중앙 정렬
            offsetX = (renderSize.width - scaledWidth) / 2
            offsetY = (renderSize.height - scaledHeight) / 2
        }
        print("🎬 [VideoFilterManager] offset: (\(offsetX), \(offsetY))")

        // AVVideoComposition 생성 (필터 + 리사이즈를 CIImage로 처리)
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage

                // 필터 적용
                let filtered = applyFilter(filter, to: source, originalImage: source, targetSize: nil)

                // aspect-fit 리사이징 및 회전
                let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                // 회전 적용 (세로 영상인 경우)
                let transformWithRotation = scaleTransform.concatenating(correctedTransform)

                // 중앙 정렬
                let translateTransform = CGAffineTransform(translationX: offsetX, y: offsetY)
                let finalTransform = transformWithRotation.concatenating(translateTransform)

                let transformed = filtered.transformed(by: finalTransform)

                // renderSize 영역으로 crop
                let output = transformed.cropped(to: CGRect(origin: .zero, size: renderSize))

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
