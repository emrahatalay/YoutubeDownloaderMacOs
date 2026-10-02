//
//  GlassIconButton.swift
//  YoutubeDownloader
//
//  Atom: tek bir SF Symbol ikonu gösteren, Liquid Glass malzemesiyle
//  çizilen dairesel düğme. Hiçbir ekran/iş mantığı bilmez.
//

import SwiftUI

struct GlassIconButton: View {
    let systemImage: String
    let help: String
    var size: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
        }
        .buttonStyle(.glass)
        .help(help)
    }
}
