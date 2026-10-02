//
//  MainScreen.swift
//  YoutubeDownloader
//
//  Sayfa (Screen): menü çubuğu penceresinin ana ekranı. Araç durumuna göre
//  uyarı veya indirme formu, altında ise geçmiş listesini gösterir. Bu
//  katman `DownloadViewModel`'i bilen tek yerdir; aşağıdaki organizmalara
//  yalnızca gereken ilkel değerleri ve kapanışları (closures) aktarır.
//

import SwiftUI

struct MainScreen: View {
    @Bindable var viewModel: DownloadViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch viewModel.toolStatus {
            case .checking:
                checkingView
            case .missing(let missing):
                MissingToolsCard(missing: missing) {
                    viewModel.checkTools()
                }
            case .ready:
                downloadForm
            }

            if !viewModel.history.isEmpty {
                HistoryCard(
                    entries: viewModel.history,
                    onSelect: { entry in
                        if let fileURL = entry.fileURL {
                            viewModel.revealInFinder(fileURL)
                        }
                    },
                    onClear: { viewModel.clearHistory() }
                )
            }
        }
    }

    private var checkingView: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Araçlar kontrol ediliyor…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }

    private var downloadForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SectionCaption(title: "YouTube Bağlantısı")
                URLInputField(
                    text: $viewModel.urlString,
                    isDisabled: viewModel.isDownloading,
                    onSubmit: startIfPossible
                )
            }

            FormatQualityCard(
                format: $viewModel.format,
                audioQuality: $viewModel.audioQuality,
                videoQualityState: viewModel.videoQualityState,
                selectedVideoHeight: $viewModel.selectedVideoHeight,
                isDisabled: viewModel.isDownloading,
                onRetryVideoQuality: { viewModel.scheduleQualityFetch(debounce: false) }
            )

            DownloadActionArea(
                status: viewModel.status,
                canStart: !viewModel.urlString.trimmingCharacters(in: .whitespaces).isEmpty,
                onStart: startIfPossible,
                onCancel: { viewModel.cancelDownload() },
                onReveal: { viewModel.revealInFinder($0) },
                onReset: { viewModel.reset() }
            )
        }
    }

    private func startIfPossible() {
        guard !viewModel.urlString.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.startDownload()
    }
}
