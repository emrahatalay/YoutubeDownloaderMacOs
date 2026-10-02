//
//  InfoChip.swift
//  YoutubeDownloader
//
//  Atom: düz metni standart (cam olmayan) bir malzeme üzerinde küçük
//  yuvarlatılmış bir "chip" içinde gösterir. Dosya yolu, komut satırı gibi
//  içerik-katmanı öğeleri için kullanılır — Apple'ın Liquid Glass
//  kurallarına göre içerik katmanında cam malzeme kullanılmaz, bu yüzden
//  burada standart `.quinary` malzemesi tercih edilir.
//

import SwiftUI

struct InfoChip: View {
    let text: String
    var monospaced: Bool = false

    var body: some View {
        Text(text)
            .font(monospaced ? .system(.caption, design: .monospaced) : .caption)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 9))
    }
}
