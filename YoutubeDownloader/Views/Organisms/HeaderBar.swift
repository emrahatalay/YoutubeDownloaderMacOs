//
//  HeaderBar.swift
//  YoutubeDownloader
//
//  Organizma: pencerenin üst başlık çubuğu. Uygulama ikonu + başlık ve
//  sağda Liquid Glass konteyner içinde gruplanmış ayarlar/çıkış aksiyonları.
//  Hangi ekranda olduğumuzu değil, yalnızca gösterilecek durumu bilir.
//

import SwiftUI

struct HeaderBar: View {
    let title: String
    let isShowingSettings: Bool
    let onToggleSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.headline)
                .contentTransition(.opacity)
            Spacer()

            // Başlık çubuğu aksiyonları, Liquid Glass konteynerinde birlikte
            // yorumlanarak tek bir cam parçası gibi görünür.
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    GlassIconButton(
                        systemImage: isShowingSettings ? "chevron.left" : "gearshape",
                        help: isShowingSettings ? "Geri" : "Ayarlar",
                        action: onToggleSettings
                    )
                    GlassIconButton(systemImage: "power", help: "Çıkış", action: onQuit)
                }
            }
        }
    }
}
