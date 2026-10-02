//
//  DownloadActionArea.swift
//  YoutubeDownloader
//
//  Organizma: indirme akışının anlık durumuna (boşta/indiriliyor/
//  başarılı/hatalı) göre doğru aksiyon düğmelerini ve ilerleme
//  göstergesini sunar.
//

import SwiftUI

struct DownloadActionArea: View {
    let status: DownloadStatus
    let canStart: Bool
    let onStart: () -> Void
    let onCancel: () -> Void
    let onReveal: (URL) -> Void
    let onReset: () -> Void

    var body: some View {
        switch status {
        case .idle:
            startButton

        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 8) {
                if progress > 0 {
                    ProgressView(value: progress) {
                        Text("İndiriliyor… %\(Int(progress * 100))")
                            .font(.caption)
                    }
                } else {
                    ProgressView {
                        Text("Hazırlanıyor…")
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                }
                GlassActionButton(title: "İptal", isProminent: false, tint: .red, action: onCancel)
            }

        case .success(let url):
            VStack(alignment: .leading, spacing: 8) {
                Label("İndirme tamamlandı", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    GlassActionButton(title: "Finder'da Göster", systemImage: "folder") {
                        onReveal(url)
                    }
                    GlassActionButton(title: "Yeni", isProminent: false, fullWidth: false, action: onReset)
                }
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                startButton
            }
        }
    }

    private var startButton: some View {
        GlassActionButton(title: "İndir", systemImage: "arrow.down.to.line", tint: .red, action: onStart)
            .disabled(!canStart)
    }
}
