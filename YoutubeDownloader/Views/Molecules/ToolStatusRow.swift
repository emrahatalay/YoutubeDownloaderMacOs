//
//  ToolStatusRow.swift
//  YoutubeDownloader
//
//  Molekül: bulunan bir komut satırı aracının adını ve yolunu gösteren satır.
//

import SwiftUI

struct ToolStatusRow: View {
    let name: String
    let path: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text(name)
                .font(.system(.caption, design: .monospaced).bold())
            Text(path)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
