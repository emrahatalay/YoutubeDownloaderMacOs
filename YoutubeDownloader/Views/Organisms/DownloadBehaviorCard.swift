//
//  DownloadBehaviorCard.swift
//  YoutubeDownloader
//
//  Organizma: indirme sonrası davranışları (Finder'da gösterme,
//  metadata/kapak gömme) yöneten ayarlar kartı.
//

import SwiftUI

struct DownloadBehaviorCard: View {
    @Binding var revealAfterDownload: Bool
    @Binding var embedMetadata: Bool
    @Binding var embedThumbnail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title: "İndirme", symbol: "arrow.down.circle")
            Toggle("Bitince Finder'da göster", isOn: $revealAfterDownload)
            Toggle("Metadata göm (başlık, sanatçı…)", isOn: $embedMetadata)
            Toggle("Kapak görseli göm (MP3/MP4)", isOn: $embedThumbnail)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .cardStyle()
    }
}
