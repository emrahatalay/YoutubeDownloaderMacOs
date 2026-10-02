//
//  SectionCaption.swift
//  YoutubeDownloader
//
//  Atom: bir form alanının veya kartın üstünde görünen küçük başlık metni.
//

import SwiftUI

struct SectionCaption: View {
    let title: String
    var symbol: String? = nil

    var body: some View {
        Group {
            if let symbol {
                Label(title, systemImage: symbol)
            } else {
                Text(title)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
}
