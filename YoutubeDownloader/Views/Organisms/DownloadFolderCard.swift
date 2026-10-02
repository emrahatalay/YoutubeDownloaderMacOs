//
//  DownloadFolderCard.swift
//  YoutubeDownloader
//
//  Organizma: indirme klasörünü gösteren ve değiştirilmesini sağlayan
//  ayarlar kartı. Dosya sistemiyle doğrudan konuşmaz; hazırlanmış seçenek
//  listesini ve aksiyon kapanışlarını dışarıdan alır.
//

import SwiftUI

struct DownloadFolderCard: View {
    struct QuickFolderOption {
        let title: String
        let directory: FileManager.SearchPathDirectory
        let isSelected: Bool
    }

    let path: String
    let quickOptions: [QuickFolderOption]
    let onChoose: () -> Void
    let onSelectQuick: (FileManager.SearchPathDirectory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title: "İndirme Klasörü", symbol: "folder")

            HStack {
                InfoChip(text: path)
                GlassActionButton(title: "Değiştir…", isProminent: false, fullWidth: false, controlSize: .small, action: onChoose)
            }

            HStack(spacing: 6) {
                ForEach(quickOptions, id: \.title) { option in
                    QuickFolderChip(title: option.title, isSelected: option.isSelected) {
                        onSelectQuick(option.directory)
                    }
                }
            }
        }
        .cardStyle()
    }
}
