//
//  SettingsScreen.swift
//  YoutubeDownloader
//
//  Sayfa (Screen): uygulama ayarlarını gruplu kartlar halinde sunar.
//  `DownloadViewModel`'e bağımlılık bu katmanda durur; her kart kendi
//  parametrelerini alır, view model'i doğrudan bilmez.
//

import SwiftUI

struct SettingsScreen: View {
    @Bindable var viewModel: DownloadViewModel

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var quickFolderOptions: [DownloadFolderCard.QuickFolderOption] {
        [
            option(title: "İndirilenler", directory: .downloadsDirectory),
            option(title: "Masaüstü", directory: .desktopDirectory),
            option(title: "Müzik", directory: .musicDirectory),
            option(title: "Filmler", directory: .moviesDirectory)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DownloadFolderCard(
                path: viewModel.downloadDirectory.path,
                quickOptions: quickFolderOptions,
                onChoose: { viewModel.chooseDownloadFolder() },
                onSelectQuick: { viewModel.setDownloadFolder($0) }
            )

            DownloadBehaviorCard(
                revealAfterDownload: $viewModel.revealAfterDownload,
                embedMetadata: $viewModel.embedMetadata,
                embedThumbnail: $viewModel.embedThumbnail
            )

            GeneralSettingsCard(launchAtLogin: $viewModel.launchAtLogin)

            ToolsStatusCard(resolvedTools: viewModel.resolvedTools) {
                viewModel.checkTools()
            }

            HStack {
                Spacer()
                Text("Sürüm \(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
    }

    private func option(title: String, directory: FileManager.SearchPathDirectory) -> DownloadFolderCard.QuickFolderOption {
        let isSelected = FileManager.default.urls(for: directory, in: .userDomainMask).first?.path
            == viewModel.downloadDirectory.path
        return .init(title: title, directory: directory, isSelected: isSelected)
    }
}
