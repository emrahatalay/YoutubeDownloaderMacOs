//
//  FormatQualityCard.swift
//  YoutubeDownloader
//
//  Organizma: format seçimini ve buna bağlı kalite seçimini (video
//  çözünürlüğü ya da ses bit hızı) tek bir gruplu kart içinde birleştirir.
//

import SwiftUI

struct FormatQualityCard: View {
    @Binding var format: DownloadFormat
    @Binding var audioQuality: AudioQuality
    let videoQualityState: DownloadViewModel.VideoQualityState
    @Binding var selectedVideoHeight: Int?
    var isDisabled: Bool = false
    let onRetryVideoQuality: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SectionCaption(title: "Format")
                GlassSegmentedPicker(options: DownloadFormat.allCases, selection: $format, isDisabled: isDisabled) { option in
                    Label(option.displayName, systemImage: option.symbolName)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                if format == .mp4 {
                    SectionCaption(title: "Video Kalitesi")
                    VideoQualityPicker(
                        state: videoQualityState,
                        selection: $selectedVideoHeight,
                        isDisabled: isDisabled,
                        onRetry: onRetryVideoQuality
                    )
                } else {
                    SectionCaption(title: "Ses Kalitesi")
                    GlassSegmentedPicker(options: AudioQuality.allCases, selection: $audioQuality, isDisabled: isDisabled) { option in
                        Text(option.displayName)
                    }
                }
            }
        }
        .cardStyle()
        .animation(.snappy(duration: 0.2), value: format)
        .animation(.snappy(duration: 0.2), value: videoQualityState)
    }
}
