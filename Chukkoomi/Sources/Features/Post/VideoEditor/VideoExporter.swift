//
//  VideoExporter.swift
//  Chukkoomi
//
//  Created by 김영훈 on 11/15/25.
//

import UIKit
import Photos
import AVFoundation
import CoreText

/// 비디오 편집을 적용하고 최종 영상을 내보냄
struct VideoExporter {

    enum ExportError: Error, LocalizedError {
        case failedToLoadAsset
        case failedToCreateExportSession
        case exportFailed(Error?)
        case exportCancelled
        case unknownExportStatus

        var errorDescription: String? {
            switch self {
            case .failedToLoadAsset:
                return "비디오를 불러오는데 실패했습니다."
            case .failedToCreateExportSession:
                return "내보내기 세션을 생성하는데 실패했습니다."
            case .exportFailed(let error):
                return "내보내기 실패: \(error?.localizedDescription ?? "알 수 없는 오류")"
            case .exportCancelled:
                return "내보내기가 취소되었습니다."
            case .unknownExportStatus:
                return "알 수 없는 내보내기 상태입니다."
            }
        }
    }

    func export(
        asset: PHAsset,
        editState: EditVideoFeature.EditState,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let avAsset = try await loadAVAsset(from: asset)
        let (composition, videoComposition) = try await applyEdits(to: avAsset, editState: editState)
        let exportedURL = try await exportComposition(
            composition,
            videoComposition: videoComposition,
            progressHandler: progressHandler
        )
        return exportedURL
    }

    // MARK: - Private Methods

    private func loadAVAsset(from asset: PHAsset) async throws -> AVAsset {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let avAsset = avAsset {
                    continuation.resume(returning: avAsset)
                } else {
                    continuation.resume(throwing: ExportError.failedToLoadAsset)
                }
            }
        }
    }

    private func applyEdits(
        to asset: AVAsset,
        editState: EditVideoFeature.EditState
    ) async throws -> (AVAsset, AVVideoComposition?) {
        let composition = AVMutableComposition()

        // 1) Trim
        let trimmedAsset = try await applyTrim(to: asset, editState: editState, composition: composition)

        // 2) Filter와 Subtitles 처리
        let videoComposition: AVVideoComposition?

        if !editState.subtitles.isEmpty {
            // 자막이 있으면: 커스텀 compositor가 필터와 자막을 함께 처리
            videoComposition = try await applySubtitles(
                to: trimmedAsset,
                editState: editState,
                baseVideoComposition: nil
            )
        } else if editState.selectedFilter != nil {
            // 자막이 없고 필터만 있으면: 필터만 적용
            videoComposition = try await applyFilter(to: trimmedAsset, filterType: editState.selectedFilter)
        } else {
            // 필터도 자막도 없으면: nil
            videoComposition = nil
        }

        return (trimmedAsset, videoComposition)
    }

    private func applyTrim(
        to asset: AVAsset,
        editState: EditVideoFeature.EditState,
        composition: AVMutableComposition
    ) async throws -> AVAsset {
        let startTime = CMTime(seconds: editState.trimStartTime, preferredTimescale: 600)

        let assetDuration = try await asset.load(.duration)
        let actualEndTime: CMTime
        if editState.trimEndTime.isInfinite || editState.trimEndTime > assetDuration.seconds {
            actualEndTime = assetDuration
        } else {
            actualEndTime = CMTime(seconds: editState.trimEndTime, preferredTimescale: 600)
        }

        let timeRange = CMTimeRange(start: startTime, end: actualEndTime)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return composition
        }

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            return composition
        }

        try compositionVideoTrack.insertTimeRange(
            timeRange,
            of: videoTrack,
            at: .zero
        )

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try? compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioTrack,
                    at: .zero
                )
            }
        }

        return composition
    }

    private func applyFilter(
        to asset: AVAsset,
        filterType: VideoFilter?
    ) async throws -> AVVideoComposition? {
        return await VideoFilterManager.createVideoComposition(
            for: asset,
            filter: filterType
        )
    }

    private func applySubtitles(
        to asset: AVAsset,
        editState: EditVideoFeature.EditState,
        baseVideoComposition: AVVideoComposition?
    ) async throws -> AVVideoComposition {
        // 비디오 트랙 가져오기
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            // 비디오 트랙이 없으면 기본 composition 반환
            if let baseComposition = baseVideoComposition {
                return baseComposition
            }
            throw ExportError.failedToLoadAsset
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let frameDuration = try await videoTrack.load(.minFrameDuration)
        let duration = try await asset.load(.duration)

        // 커스텀 compositor를 사용하는 AVMutableVideoComposition 생성
        let composition = AVMutableVideoComposition()
        composition.frameDuration = frameDuration
        composition.renderSize = naturalSize
        composition.customVideoCompositorClass = VideoCompositorWithSubtitles.self

        // LayerInstruction 생성
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        // 커스텀 Instruction 생성 (필터와 자막 정보 포함)
        let instruction = SubtitleVideoCompositionInstruction(
            timeRange: CMTimeRange(start: .zero, duration: duration),
            filter: editState.selectedFilter,
            subtitles: editState.subtitles,
            trimStartTime: editState.trimStartTime,
            sourceTrackIDs: [NSNumber(value: videoTrack.trackID)],
            layerInstructions: [layerInstruction]
        )

        composition.instructions = [instruction]

        return composition
    }


    private func exportComposition(
        _ composition: AVAsset,
        videoComposition: AVVideoComposition?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw ExportError.failedToCreateExportSession
        }

        exportSession.shouldOptimizeForNetworkUse = false

        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }

        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw ExportError.failedToCreateExportSession
        }

        let videosCacheDirectory = cachesDirectory.appendingPathComponent("ExportedVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: videosCacheDirectory.path) {
            try? FileManager.default.createDirectory(at: videosCacheDirectory, withIntermediateDirectories: true)
        }

        let outputURL = videosCacheDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        nonisolated(unsafe) let session = exportSession
        let progressTask = Task {
            while !Task.isCancelled {
                progressHandler(Double(session.progress))
                if session.progress >= 1.0 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        await exportSession.export()
        progressTask.cancel()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            throw ExportError.exportFailed(exportSession.error)
        case .cancelled:
            throw ExportError.exportCancelled
        default:
            throw ExportError.unknownExportStatus
        }
    }
}
