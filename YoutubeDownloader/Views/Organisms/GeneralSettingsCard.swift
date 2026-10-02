//
//  GeneralSettingsCard.swift
//  YoutubeDownloader
//
//  Organizma: uygulamanın genel davranışını (girişte otomatik başlatma)
//  yöneten ayarlar kartı.
//

import SwiftUI

struct GeneralSettingsCard: View {
    @Binding var launchAtLogin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title: "Genel", symbol: "macwindow")
            Toggle("Girişte otomatik başlat", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .cardStyle()
    }
}
