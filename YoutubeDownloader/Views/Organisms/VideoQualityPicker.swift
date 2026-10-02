//
//  VideoQualityPicker.swift
//  YoutubeDownloader
//
//  Organizma: MP4 formatı için videonun sunduğu çözünürlükleri listeleyen
//  seçim alanı. Sorgu durumuna (boşta/sorgulanıyor/yüklendi/başarısız)
//  göre farklı içerik gösterir.
//

import SwiftUI

struct VideoQualityPicker: View {
    let state: DownloadViewModel.VideoQualityState
    @Binding var selection: Int?
    var isDisabled: Bool = false
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            Text("Kaliteler, bağlantı girildiğinde listelenir.")
                .font(.caption)
                .foregroundStyle(.tertiary)

        case .fetching:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Mevcut kaliteler alınıyor…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .loaded(let heights):
            Picker("Video Kalitesi", selection: $selection) {
                Text("En İyi (\(heights.first.map { "\($0)p" } ?? "otomatik"))")
                    .tag(Optional<Int>.none)
                ForEach(heights, id: \.self) { height in
                    Text("\(height)p").tag(Optional(height))
                }
            }
            .labelsHidden()
            .disabled(isDisabled)

        case .failed:
            HStack(spacing: 6) {
                Text("Kaliteler alınamadı; en iyi kalite kullanılacak.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                GlassIconButton(systemImage: "arrow.clockwise", help: "Tekrar dene", size: 14, action: onRetry)
            }
        }
    }
}
