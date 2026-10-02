//
//  CopyableCommandChip.swift
//  YoutubeDownloader
//
//  Molekül: bir terminal komutunu salt okunur biçimde gösterip, yanındaki
//  Liquid Glass ikon düğmesiyle panoya kopyalanmasını sağlar.
//

import SwiftUI

struct CopyableCommandChip: View {
    let command: String

    var body: some View {
        HStack {
            InfoChip(text: command, monospaced: true)
            GlassIconButton(systemImage: "doc.on.doc", help: "Komutu kopyala", size: 14) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(command, forType: .string)
            }
        }
    }
}
