//
//  ToolsStatusCard.swift
//  YoutubeDownloader
//
//  Organizma: yt-dlp ve ffmpeg araçlarının kurulum durumunu gösteren ve
//  yeniden kontrol edilmesini sağlayan ayarlar kartı.
//

import SwiftUI

struct ToolsStatusCard: View {
    let resolvedTools: YTDLPService.ResolvedTools?
    let onRecheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title: "Araçlar", symbol: "wrench.and.screwdriver")

            if let resolvedTools {
                ToolStatusRow(name: "yt-dlp", path: resolvedTools.ytdlp)
                ToolStatusRow(name: "ffmpeg", path: resolvedTools.ffmpeg)
            } else {
                Label("Araçlar bulunamadı", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            GlassActionButton(
                title: "Tekrar Kontrol Et",
                systemImage: "arrow.clockwise",
                isProminent: false,
                fullWidth: false,
                controlSize: .small,
                action: onRecheck
            )
        }
        .cardStyle()
    }
}
