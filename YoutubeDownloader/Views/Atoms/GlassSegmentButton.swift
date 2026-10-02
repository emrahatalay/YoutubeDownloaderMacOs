//
//  GlassSegmentButton.swift
//  YoutubeDownloader
//
//  Atom: bir segmentli seçicideki (veya hızlı seçim grubundaki) tek bir
//  segment. Seçili durumda `.glassProminent`, değilse `.glass` stiline
//  geçer. İçeriğini jenerik olarak alır, hiçbir domain tipini bilmez.
//

import SwiftUI

struct GlassSegmentButton<Content: View>: View {
    let isSelected: Bool
    var tint: Color = .red
    var isDisabled: Bool = false
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        if isSelected {
            Button(action: action) { content }
                .buttonStyle(.glassProminent)
                .tint(tint)
                .disabled(isDisabled)
        } else {
            Button(action: action) { content }
                .buttonStyle(.glass)
                .disabled(isDisabled)
        }
    }
}
