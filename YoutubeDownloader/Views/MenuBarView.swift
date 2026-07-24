//
//  MenuBarView.swift
//  YoutubeDownloader
//
//  Menü çubuğu ikonuna tıklanınca açılan ana arayüz.
//  Ana ekran ve ayarlar aynı pencere içinde animasyonlu geçişle gösterilir.
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var viewModel: DownloadViewModel

    /// Pencere içinde gösterilen ekran.
    private enum Screen {
        case main
        case settings
    }

    @State private var screen: Screen = .main

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            // Ekranlar aynı pencerede yatay kayma + solma animasyonuyla değişir.
            ZStack {
                switch screen {
                case .main:
                    mainScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .settings:
                    SettingsScreen(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.snappy(duration: 0.25), value: screen)
        }
        .padding(16)
        .frame(width: 340)
        .task { viewModel.checkTools() }
    }

    // MARK: - Başlık

    private var header: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
            Text(screen == .settings ? "Ayarlar" : "YouTube İndirici")
                .font(.headline)
                .contentTransition(.opacity)
            Spacer()

            Button {
                screen = (screen == .main) ? .settings : .main
            } label: {
                Image(systemName: screen == .settings ? "chevron.left" : "gearshape")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .help(screen == .settings ? "Geri" : "Ayarlar")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Çıkış")
        }
    }

    // MARK: - Ana Ekran

    @ViewBuilder
    private var mainScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch viewModel.toolStatus {
            case .checking:
                checkingView
            case .missing(let missing):
                MissingToolsView(missing: missing) {
                    viewModel.checkTools()
                }
            case .ready:
                downloadForm
            }

            if !viewModel.history.isEmpty {
                Divider()
                HistorySection(viewModel: viewModel)
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

    // MARK: - İndirme Formu

    private var downloadForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bağlantı alanı
            VStack(alignment: .leading, spacing: 4) {
                Text("YouTube Bağlantısı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://youtube.com/watch?v=…", text: $viewModel.urlString)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isDownloading)
                    .onSubmit(startIfPossible)
            }

            // Format seçimi
            VStack(alignment: .leading, spacing: 4) {
                Text("Format")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Format", selection: $viewModel.format) {
                    ForEach(DownloadFormat.allCases) { format in
                        Label(format.displayName, systemImage: format.symbolName)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(viewModel.isDownloading)
            }

            // Kalite: MP4'te videonun sunduğu çözünürlükler, ses formatlarında bit hızı.
            if viewModel.format == .mp4 {
                videoQualitySection
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ses Kalitesi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Ses Kalitesi", selection: $viewModel.audioQuality) {
                        ForEach(AudioQuality.allCases) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .disabled(viewModel.isDownloading)
                }
            }

            // Aksiyon + durum
            actionArea
        }
        .animation(.snappy(duration: 0.2), value: viewModel.format)
        .animation(.snappy(duration: 0.2), value: viewModel.videoQualityState)
    }

    /// MP4 için videonun sunduğu çözünürlüklerin listelendiği bölüm.
    @ViewBuilder
    private var videoQualitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Video Kalitesi")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch viewModel.videoQualityState {
            case .idle:
                Text("Kaliteler, bağlantı girildiğinde listelenir.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

            case .fetching:
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Mevcut kaliteler alınıyor…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .loaded(let heights):
                Picker("Video Kalitesi", selection: $viewModel.selectedVideoHeight) {
                    Text("En İyi (\(heights.first.map { "\($0)p" } ?? "otomatik"))")
                        .tag(Optional<Int>.none)
                    ForEach(heights, id: \.self) { height in
                        Text("\(height)p").tag(Optional(height))
                    }
                }
                .labelsHidden()
                .disabled(viewModel.isDownloading)

            case .failed:
                HStack(spacing: 6) {
                    Text("Kaliteler alınamadı; en iyi kalite kullanılacak.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Button {
                        viewModel.scheduleQualityFetch(debounce: false)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Tekrar dene")
                }
            }
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch viewModel.status {
        case .idle:
            downloadButton

        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 8) {
                if progress > 0 {
                    ProgressView(value: progress) {
                        Text("İndiriliyor… %\(Int(progress * 100))")
                            .font(.caption)
                    }
                } else {
                    ProgressView {
                        Text("Hazırlanıyor…")
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                }
                Button(role: .cancel) {
                    viewModel.cancelDownload()
                } label: {
                    Text("İptal")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }

        case .success(let url):
            VStack(alignment: .leading, spacing: 8) {
                Label("İndirme tamamlandı", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    Button {
                        viewModel.revealInFinder(url)
                    } label: {
                        Label("Finder'da Göster", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Yeni")
                    }
                }
                .controlSize(.large)
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                downloadButton
            }
        }
    }

    private var downloadButton: some View {
        Button(action: startIfPossible) {
            Label("İndir", systemImage: "arrow.down.to.line")
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.urlString.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func startIfPossible() {
        guard !viewModel.urlString.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.startDownload()
    }
}

// MARK: - Eksik Araçlar Uyarısı

private struct MissingToolsView: View {
    let missing: [String]
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Gerekli araçlar eksik", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline.bold())

            Text("Şu araç(lar) bulunamadı: \(missing.joined(separator: ", ")). Terminal'de aşağıdaki komutla kurabilirsiniz:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("brew install yt-dlp ffmpeg")
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString("brew install yt-dlp ffmpeg", forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Komutu kopyala")
            }

            Button(action: onRetry) {
                Label("Tekrar Kontrol Et", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
        }
    }
}

// MARK: - Geçmiş Bölümü

private struct HistorySection: View {
    @Bindable var viewModel: DownloadViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Son İndirilenler")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Temizle") {
                    viewModel.clearHistory()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            ForEach(viewModel.history) { entry in
                Button {
                    if let fileURL = entry.fileURL {
                        viewModel.revealInFinder(fileURL)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: entry.format.symbolName)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.title)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(entry.format.displayName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(entry.fileURL != nil ? "Finder'da göster" : entry.sourceURL)
            }
        }
    }
}

// MARK: - Ayarlar Ekranı

private struct SettingsScreen: View {
    @Bindable var viewModel: DownloadViewModel

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // İndirme klasörü
            SettingsSection(title: "İndirme Klasörü", symbol: "folder") {
                HStack {
                    Text(viewModel.downloadDirectory.path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Button("Değiştir…") {
                        viewModel.chooseDownloadFolder()
                    }
                    .controlSize(.small)
                }

                // Hızlı seçim
                HStack(spacing: 6) {
                    QuickFolderButton(title: "İndirilenler", directory: .downloadsDirectory, viewModel: viewModel)
                    QuickFolderButton(title: "Masaüstü", directory: .desktopDirectory, viewModel: viewModel)
                    QuickFolderButton(title: "Müzik", directory: .musicDirectory, viewModel: viewModel)
                    QuickFolderButton(title: "Filmler", directory: .moviesDirectory, viewModel: viewModel)
                }
            }

            Divider()

            // İndirme davranışı
            SettingsSection(title: "İndirme", symbol: "arrow.down.circle") {
                Toggle("Bitince Finder'da göster", isOn: $viewModel.revealAfterDownload)
                Toggle("Metadata göm (başlık, sanatçı…)", isOn: $viewModel.embedMetadata)
                Toggle("Kapak görseli göm (MP3/MP4)", isOn: $viewModel.embedThumbnail)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            Divider()

            // Genel
            SettingsSection(title: "Genel", symbol: "macwindow") {
                Toggle("Girişte otomatik başlat", isOn: $viewModel.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }

            Divider()

            // Araç durumu
            SettingsSection(title: "Araçlar", symbol: "wrench.and.screwdriver") {
                if let tools = viewModel.resolvedTools {
                    ToolRow(name: "yt-dlp", path: tools.ytdlp)
                    ToolRow(name: "ffmpeg", path: tools.ffmpeg)
                } else {
                    Label("Araçlar bulunamadı", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Button {
                    viewModel.checkTools()
                } label: {
                    Label("Tekrar Kontrol Et", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .controlSize(.small)
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
}

/// Ayarlar ekranındaki başlıklı bölüm düzeni.
private struct SettingsSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content
        }
    }
}

/// Sık kullanılan klasörler için hızlı seçim butonu.
private struct QuickFolderButton: View {
    let title: String
    let directory: FileManager.SearchPathDirectory
    let viewModel: DownloadViewModel

    private var isSelected: Bool {
        FileManager.default.urls(for: directory, in: .userDomainMask).first?.path
            == viewModel.downloadDirectory.path
    }

    var body: some View {
        Button(title) {
            viewModel.setDownloadFolder(directory)
        }
        .font(.caption2)
        .controlSize(.small)
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : nil)
    }
}

/// Bulunan bir aracın adını ve yolunu gösteren satır.
private struct ToolRow: View {
    let name: String
    let path: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text(name)
                .font(.system(.caption, design: .monospaced).bold())
            Text(path)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
