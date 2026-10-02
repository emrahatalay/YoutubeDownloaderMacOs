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
            TextField("https://youtube.com/watch?v=…", text: $text)
                .textFieldStyle(.plain)
                .disabled(isDisabled)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 9))
    }
}
