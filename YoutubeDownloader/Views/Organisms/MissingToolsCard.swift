//
//  MissingToolsCard.swift
//  YoutubeDownloader
//
//  Organizma: gerekli komut satırı araçları (yt-dlp, ffmpeg) bulunamadığında
//  gösterilen uyarı kartı.
//

import SwiftUI

struct MissingToolsCard: View {
    let missing: [String]
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Gerekli araçlar eksik", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline.bold())

            Text("Şu araç(lar) bulunamadı: \(missing.joined(separator: ", ")). Terminal'de aşağıdaki komutla kurabilirsiniz:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            CopyableCommandChip(command: "brew install yt-dlp ffmpeg")

            GlassActionButton(title: "Tekrar Kontrol Et", systemImage: "arrow.clockwise", action: onRetry)
        }
        .cardStyle()
    }
}
