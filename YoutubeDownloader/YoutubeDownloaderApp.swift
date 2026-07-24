//
//  YoutubeDownloaderApp.swift
//  YoutubeDownloader
//
//  Menü çubuğunda yaşayan (Dock'ta görünmeyen) bir agent uygulaması.
//  Uygulama tek bir MenuBarExtra sahnesinden ibarettir.
//

import SwiftUI

@main
struct YoutubeDownloaderApp: App {
    /// Tüm arayüzün paylaştığı tek ViewModel örneği.
    @State private var viewModel = DownloadViewModel()

    var body: some Scene {
        MenuBarExtra("YouTube İndirici", systemImage: "arrow.down.circle") {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
