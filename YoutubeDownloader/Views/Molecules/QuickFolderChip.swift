//
//  QuickFolderChip.swift
//  YoutubeDownloader
//
//  Molekül: sık kullanılan bir klasör kısayolunu temsil eden, duruma göre
//  vurgulu veya düz Liquid Glass görünümüne sahip düğme. Dosya sistemiyle
//  veya bir view model'le doğrudan bağı yoktur; yalnızca seçili olup
//  olmadığını ve tetiklenecek bir aksiyonu bilir (Bağımlılığın Tersine
//  Çevrilmesi — çağıran taraf somut veri kaynağını sağlar).
//

import SwiftUI

struct QuickFolderChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        GlassSegmentButton(isSelected: isSelected, tint: .accentColor, action: action) {
            Text(title)
                .font(.caption2)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
    }
}
