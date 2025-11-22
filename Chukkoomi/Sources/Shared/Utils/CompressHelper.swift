//
//  CompressHelper.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/11/25.
//

import UIKit
import CoreGraphics
import AVFoundation

enum CompressHelper {
    
    static func compressImage(_ imageData: Data, maxSizeInBytes: Int, maxWidth: CGFloat, maxHeight: CGFloat) async -> Data? {
        // 이미지 리사이징
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        var resizedImage = image
        
        if image.size.width > maxWidth || image.size.height > maxHeight {
            let ratio = min(maxWidth / image.size.width, maxHeight / image.size.height)
            let newSize = CGSize(
                width: image.size.width * ratio,
                height: image.size.height * ratio
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let scaledImage = UIGraphicsGetImageFromCurrentImageContext() {
                resizedImage = scaledImage
            }
            UIGraphicsEndImageContext()
        }
        
        // 압축 품질 조정
        var compression: CGFloat = 0.8
        let minCompression: CGFloat = 0.1
        let step: CGFloat = 0.1

        guard var imageData = resizedImage.jpegData(compressionQuality: compression) else {
            return nil
        }

        // 이미 maxSize 이하면 그대로 반환
        if imageData.count <= maxSizeInBytes {
            return imageData
        }
        
        // 압축 품질을 점진적으로 낮추면서 maxSize 이하로 만들기
        while imageData.count > maxSizeInBytes && compression > minCompression {
            compression -= step
            if let compressedData = resizedImage.jpegData(compressionQuality: max(compression, minCompression)) {
                imageData = compressedData
            } else {
                break
            }
        }

        return imageData
    }
    
    /// 원본 픽셀 크기를 받아, 가로 880px 기준으로 비율 유지하여 리사이즈된 사이즈를 반환
    static func resizedSizeForiPhoneMax(originalWidth: CGFloat, originalHeight: CGFloat) -> CGSize {
        let maxWidthPx: CGFloat = 880

        // 원본이 이미 더 작으면 리사이즈할 필요 없음
        guard originalWidth > maxWidthPx else {
            return CGSize(width: originalWidth, height: originalHeight)
        }

        let scale = maxWidthPx / originalWidth
        let targetWidth = maxWidthPx
        let targetHeight = originalHeight * scale

        return CGSize(width: targetWidth, height: targetHeight)
    }

    /// 비디오를 리사이징하기 위한 AVVideoComposition 생성
    /// - Parameters:
    ///   - asset: 원본 비디오 asset
    ///   - targetSize: 목표 크기 (nil이면 resizedSizeForiPhoneMax로 자동 계산)
    ///   - isPortraitFromPHAsset: PHAsset 기준 세로 영상 여부
    /// - Returns: 리사이징 정보가 담긴 AVVideoComposition, 리사이즈 불필요시 nil
    static func createResizeVideoComposition(
        for asset: AVAsset,
        targetSize: CGSize? = nil,
        isPortraitFromPHAsset: Bool
    ) async -> AVVideoComposition? {
        // 비디오 트랙 가져오기
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }

        let naturalSize = try? await videoTrack.load(.naturalSize)
        let preferredTransform = try? await videoTrack.load(.preferredTransform)
        let frameDuration = try? await videoTrack.load(.minFrameDuration)
        
        guard let naturalSize else {
            return nil
        }

        // 디버깅 로그 추가
        print("🔍 [CompressHelper] ====== 비디오 정보 시작 ======")
        print("🔍 [CompressHelper] 원본 naturalSize: \(naturalSize)")
        print("🔍 [CompressHelper] isPortraitFromPHAsset: \(isPortraitFromPHAsset)")

        // naturalSize가 가로 방향인지 확인
        let isNaturalSizePortrait = naturalSize.width < naturalSize.height
        print("🔍 [CompressHelper] isNaturalSizePortrait: \(isNaturalSizePortrait)")

        // 세로 영상인데 naturalSize가 가로로 나온 경우 swap
        let adjustedNaturalSize: CGSize
        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            // 세로 영상인데 naturalSize가 가로 → swap
            adjustedNaturalSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            print("🔍 [CompressHelper] naturalSize swap: \(adjustedNaturalSize)")
        } else {
            adjustedNaturalSize = naturalSize
            print("🔍 [CompressHelper] naturalSize 유지: \(adjustedNaturalSize)")
        }

        // 목표 크기 계산 (조정된 naturalSize 기준)
        let finalTargetSize = targetSize ?? resizedSizeForiPhoneMax(
            originalWidth: adjustedNaturalSize.width,
            originalHeight: adjustedNaturalSize.height
        )
        print("🔍 [CompressHelper] finalTargetSize: \(finalTargetSize)")

        // 이미 목표 크기와 같거나 작으면 리사이즈 불필요
        if finalTargetSize == adjustedNaturalSize {
            print("🔍 [CompressHelper] 리사이즈 불필요 - nil 반환")
            return nil
        }

        // AVMutableVideoComposition 생성
        let composition = AVMutableVideoComposition()
        if let frameDuration {
            composition.frameDuration = frameDuration
        }

        // Instruction 생성
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: (try? await asset.load(.duration)) ?? .zero
        )

        // LayerInstruction에 스케일 transform 적용
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        // 세로 영상인데 naturalSize가 가로였으면 90도 회전 필요
        let correctedTransform: CGAffineTransform
        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            // 세로 영상인데 naturalSize가 가로 → 90도 회전
            correctedTransform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0)
            print("🔍 [CompressHelper] ✅ 세로 영상 - 90도 회전 transform 적용")
        } else {
            correctedTransform = preferredTransform ?? .identity
            print("🔍 [CompressHelper] 원본 transform 사용")
        }
        print("🔍 [CompressHelper] correctedTransform: \(correctedTransform)")

        print("🔍 [CompressHelper] ====== 비디오 정보 종료 ======")


        // 비율을 유지하는 스케일 계산 (aspect fit)
        // adjustedNaturalSize와 finalTargetSize 기준으로 계산
        let scaleX = finalTargetSize.width / adjustedNaturalSize.width
        let scaleY = finalTargetSize.height / adjustedNaturalSize.height
        let scale = min(scaleX, scaleY)  // 작은 값 사용하여 비율 유지
        print("🔍 [CompressHelper] scale: \(scale) (scaleX: \(scaleX), scaleY: \(scaleY))")

        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)

        // 최종 변환 = 스케일 → 회전 보정
        let finalTransform = scaleTransform.concatenating(correctedTransform)

        // 중앙 정렬을 위한 이동 계산 (원본 naturalSize 기준)
        let scaledWidth = naturalSize.width * scale
        let scaledHeight = naturalSize.height * scale
        print("🔍 [CompressHelper] scaledWidth: \(scaledWidth), scaledHeight: \(scaledHeight)")

        let tx: CGFloat
        let ty: CGFloat

        if isPortraitFromPHAsset && !isNaturalSizePortrait {
            // 세로 영상이고 회전 필요한 경우: 90도 회전 후 중앙 정렬
            // naturalSize(1920x1080) -> scale -> (1564.8x880) -> rotate -> (880x1564.8)
            // renderSize는 880x1568이므로 중앙 정렬
            tx = (finalTargetSize.width - scaledHeight) / 2 + scaledHeight
            ty = (finalTargetSize.height - scaledWidth) / 2
            print("🔍 [CompressHelper] 세로 영상 (회전) 중앙 정렬 - tx: \(tx), ty: \(ty)")
        } else {
            // 가로 영상 또는 회전 불필요: 일반 중앙 정렬
            tx = (finalTargetSize.width - scaledWidth) / 2
            ty = (finalTargetSize.height - scaledHeight) / 2
            print("🔍 [CompressHelper] 일반 중앙 정렬 - tx: \(tx), ty: \(ty)")
        }

        let translateTransform = CGAffineTransform(translationX: tx, y: ty)
        let finalTransformWithTranslation = finalTransform.concatenating(translateTransform)

        layerInstruction.setTransform(finalTransformWithTranslation, at: .zero)
        instruction.layerInstructions = [layerInstruction]

        composition.instructions = [instruction]
        composition.renderSize = finalTargetSize

        return composition
    }
}

