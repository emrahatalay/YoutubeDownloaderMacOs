//
//  CardBackground.swift
//  YoutubeDownloader
//
//  Atom: gruplu kart görünümünü sağlayan ViewModifier. macOS Sistem
//  Ayarları'ndaki gruplu liste kartlarına benzer, standart (cam olmayan)
//  bir malzeme kullanır; Liquid Glass'ı yalnızca kontrollere ayırmak için
//  içerik katmanında düz malzeme tercih edilir.
//

import SwiftUI

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    /// Görünüme gruplu-kart stilini uygular.
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}
