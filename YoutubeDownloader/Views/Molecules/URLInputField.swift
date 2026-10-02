//
//  URLInputField.swift
//  YoutubeDownloader
//
//  Molekül: bağlantı girişi için ikonlu metin alanı. Yalnızca bağlı olduğu
//  değeri ve davranışı bilir; ekran durumuna (indiriliyor mu vb.) doğrudan
//  bağımlı değildir, bu bilgi dışarıdan parametre olarak verilir.
//

import SwiftUI

struct URLInputField: View {
    @Binding var text: String
    var isDisabled: Bool = false
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .foregroundStyle(.tertiary)
                .font(.caption)

            // `Text("…")` bir string literalini `LocalizedStringKey` olarak yorumlar
            // ve Markdown otomatik-bağlantı tespiti yapar; URL desenine uyan metni
            // kendi `foregroundStyle`'ımızdan önce gelen bağlantı (mavi) rengiyle
            // boyar. `Text(verbatim:)` kullanarak bu yorumlamayı devre dışı
            // bırakıyoruz ki placeholder her zaman temaya uygun kalsın.
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(verbatim: "https://youtube.com/watch?v=…")
                        .foregroundStyle(.placeholder)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("YouTube Bağlantısı")
                    .disabled(isDisabled)
                    .onSubmit(onSubmit)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 9))
    }
}
