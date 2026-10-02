//
//  HistoryRow.swift
//  YoutubeDownloader
//
//  Molekül: geçmiş listesindeki tek bir indirme kaydını gösteren,
//  tıklanabilir satır. `HistoryEntry` modelini değil, yalnızca gösterime
//  hazır ilkel değerleri bilir.
//

import SwiftUI

struct HistoryRow: View {
    let title: String
    let formatSymbol: String
    let formatName: String
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: formatSymbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(formatName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}
