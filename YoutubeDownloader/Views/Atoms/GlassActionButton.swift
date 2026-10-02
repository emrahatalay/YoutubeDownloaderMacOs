//
//  GlassActionButton.swift
//  YoutubeDownloader
//
//  Atom: metin (+ opsiyonel SF Symbol) içeren Liquid Glass aksiyon düğmesi.
//  `isProminent` camın dolgun/vurgulu varyantını (`.glassProminent`), aksi
//  halde düz varyantını (`.glass`) kullanır. İki stil farklı somut tipler
//  döndürdüğünden ternary ile karıştırılamaz; bu yüzden seçim burada ayrı
//  dallara bölünür.
//

import SwiftUI

struct GlassActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isProminent: Bool = true
    var fullWidth: Bool = true
    var tint: Color? = nil
    var controlSize: ControlSize = .large
    let action: () -> Void

    var body: some View {
        Group {
            if isProminent {
                Button(action: action) { label }
                    .buttonStyle(.glassProminent)
                    .tint(tint)
            } else {
                Button(action: action) { label }
                    .buttonStyle(.glass)
                    .tint(tint)
            }
        }
        .controlSize(controlSize)
    }

    @ViewBuilder
    private var label: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
    }
}
