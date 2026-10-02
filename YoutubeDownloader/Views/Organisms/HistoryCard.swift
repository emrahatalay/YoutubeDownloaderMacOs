//
//  HistoryCard.swift
//  YoutubeDownloader
//
//  Organizma: son indirilen dosyaları listeleyen, temizlenebilir geçmiş
//  kartı. `HistoryEntry` modelini doğrudan render etmek yerine `HistoryRow`
//  molekülüne ilkel değerler aktarır.
//

import SwiftUI

struct HistoryCard: View {
    let entries: [HistoryEntry]
    let onSelect: (HistoryEntry) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Son İndirilenler")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                GlassActionButton(title: "Temizle", isProminent: false, fullWidth: false, controlSize: .small, action: onClear)
            }

            ForEach(entries) { entry in
                HistoryRow(
                    title: entry.title,
                    formatSymbol: entry.format.symbolName,
                    formatName: entry.format.displayName,
                    helpText: entry.fileURL != nil ? "Finder'da göster" : entry.sourceURL,
                    action: { onSelect(entry) }
                )
            }
        }
        .cardStyle()
    }
}
