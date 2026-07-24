//
//  DownloadViewModel.swift
//  YoutubeDownloader
//
//  Arayüz durumunu yöneten MVVM katmanı. Araç kontrolü, indirme akışı,
//  geçmiş ve ayarların (indirme klasörü, girişte başlatma) yönetiminden sorumludur.
//

import Foundation
import Observation
import ServiceManagement
import AppKit

@MainActor
@Observable
final class DownloadViewModel {

    // MARK: - Kullanıcı Girdileri

    var urlString: String = ""
    var format: DownloadFormat = .mp4
    var audioQuality: AudioQuality = .high

    // MARK: - Durum

    private(set) var status: DownloadStatus = .idle
    private(set) var toolStatus: ToolStatus = .checking
    private(set) var history: [HistoryEntry] = []

    /// Araçların (yt-dlp/ffmpeg) kurulum durumu.
    enum ToolStatus: Equatable {
        case checking
        case ready
        case missing([String])
    }

    /// Şu anda bir indirme sürüyor mu?
    var isDownloading: Bool {
        if case .downloading = status { return true }
        return false
    }

    // MARK: - Ayarlar

    /// İndirilen dosyaların kaydedileceği klasör.
    var downloadDirectory: URL {
        didSet { UserDefaults.standard.set(downloadDirectory.path, forKey: Keys.downloadDirectory) }
    }

    /// Uygulama girişte otomatik başlasın mı?
    var launchAtLogin: Bool = false {
        didSet {
            guard launchAtLogin != oldValue else { return }
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    /// İndirilen dosyaya başlık/sanatçı gibi metadata gömülsün mü?
    var embedMetadata: Bool = true {
        didSet { UserDefaults.standard.set(embedMetadata, forKey: Keys.embedMetadata) }
    }

    /// MP3/MP4 dosyalarına video küçük resmi kapak olarak gömülsün mü?
    var embedThumbnail: Bool = false {
        didSet { UserDefaults.standard.set(embedThumbnail, forKey: Keys.embedThumbnail) }
    }

    /// İndirme bitince dosya otomatik olarak Finder'da gösterilsin mi?
    var revealAfterDownload: Bool = false {
        didSet { UserDefaults.standard.set(revealAfterDownload, forKey: Keys.revealAfterDownload) }
    }

    // MARK: - Özel Alanlar

    private var currentTask: Task<Void, Never>?
    /// Bulunan araç yolları; ayarlar ekranında da gösterilir.
    private(set) var resolvedTools: YTDLPService.ResolvedTools?
    private let historyLimit = 10

    private enum Keys {
        static let downloadDirectory = "downloadDirectory"
        static let history = "downloadHistory"
        static let embedMetadata = "embedMetadata"
        static let embedThumbnail = "embedThumbnail"
        static let revealAfterDownload = "revealAfterDownload"
    }

    // MARK: - Yaşam Döngüsü

    init() {
        // Kayıtlı indirme klasörü yoksa varsayılan olarak ~/Downloads kullanılır.
        if let saved = UserDefaults.standard.string(forKey: Keys.downloadDirectory) {
            downloadDirectory = URL(fileURLWithPath: saved)
        } else {
            downloadDirectory = FileManager.default
                .urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser
        }

        launchAtLogin = (SMAppService.mainApp.status == .enabled)

        let defaults = UserDefaults.standard
        // Bool ayarlar: kayıt yoksa varsayılan değerler korunur.
        if defaults.object(forKey: Keys.embedMetadata) != nil {
            embedMetadata = defaults.bool(forKey: Keys.embedMetadata)
        }
        if defaults.object(forKey: Keys.embedThumbnail) != nil {
            embedThumbnail = defaults.bool(forKey: Keys.embedThumbnail)
        }
        if defaults.object(forKey: Keys.revealAfterDownload) != nil {
            revealAfterDownload = defaults.bool(forKey: Keys.revealAfterDownload)
        }

        loadHistory()
    }

    // MARK: - Araç Kontrolü

    /// yt-dlp ve ffmpeg'in kurulu olup olmadığını arka planda kontrol eder.
    func checkTools() {
        toolStatus = .checking
        Task {
            let result = await Task.detached { YTDLPService.resolveTools() }.value
            switch result {
            case .success(let tools):
                self.resolvedTools = tools
                self.toolStatus = .ready
            case .failure(.toolsNotInstalled(let missing)):
                self.resolvedTools = nil
                self.toolStatus = .missing(missing)
            case .failure:
                self.resolvedTools = nil
                self.toolStatus = .missing(["yt-dlp", "ffmpeg"])
            }
        }
    }

    // MARK: - İndirme

    func startDownload() {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidYouTubeURL(trimmedURL) else {
            status = .error(message: DownloadError.invalidURL.localizedDescription)
            return
        }
        guard let tools = resolvedTools else {
            status = .error(message: DownloadError.toolsNotInstalled(missing: ["yt-dlp", "ffmpeg"]).localizedDescription)
            return
        }

        status = .downloading(progress: 0)

        let selectedFormat = format
        let selectedQuality = audioQuality
        let directory = downloadDirectory

        currentTask = Task {
            do {
                let fileURL = try await YTDLPService.download(
                    url: trimmedURL,
                    format: selectedFormat,
                    quality: selectedQuality,
                    outputDirectory: directory,
                    tools: tools,
                    embedMetadata: embedMetadata,
                    embedThumbnail: embedThumbnail
                ) { percent in
                    // Arka plan kuyruğundan gelen ilerleme; ana aktöre taşınır.
                    Task { @MainActor in
                        if case .downloading = self.status {
                            self.status = .downloading(progress: percent / 100.0)
                        }
                    }
                }

                self.status = .success(url: fileURL)
                self.addToHistory(
                    title: fileURL.deletingPathExtension().lastPathComponent,
                    sourceURL: trimmedURL,
                    format: selectedFormat,
                    fileURL: fileURL
                )
                if self.revealAfterDownload {
                    self.revealInFinder(fileURL)
                }
            } catch let error as DownloadError {
                if case .cancelled = error {
                    self.status = .idle
                } else {
                    self.status = .error(message: error.localizedDescription)
                }
            } catch {
                self.status = .error(message: error.localizedDescription)
            }
            self.currentTask = nil
        }
    }

    /// Süren indirmeyi iptal eder.
    func cancelDownload() {
        currentTask?.cancel()
    }

    /// Durumu başlangıç konumuna döndürür (yeni indirmeye hazırlanmak için).
    func reset() {
        status = .idle
    }

    // MARK: - Finder

    /// Verilen dosyayı Finder'da seçili gösterir.
    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Klasör Seçimi

    /// NSOpenPanel ile indirme klasörü seçtirir. Panel ayrı bir sistem penceresi
    /// olduğundan menü çubuğu penceresi kapansa bile seçim kaydedilir.
    func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = downloadDirectory
        panel.prompt = "Seç"
        panel.message = "İndirilen dosyaların kaydedileceği klasörü seçin"

        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url
        }
    }

    /// Sık kullanılan sistem klasörlerinden birini indirme klasörü yapar.
    func setDownloadFolder(_ directory: FileManager.SearchPathDirectory) {
        if let url = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            downloadDirectory = url
        }
    }

    // MARK: - Geçmiş

    private func addToHistory(title: String, sourceURL: String, format: DownloadFormat, fileURL: URL?) {
        let entry = HistoryEntry(title: title, sourceURL: sourceURL, format: format, fileURL: fileURL)
        history.insert(entry, at: 0)
        if history.count > historyLimit {
            history.removeLast(history.count - historyLimit)
        }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Keys.history),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return
        }
        history = decoded
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: Keys.history)
    }

    // MARK: - Girişte Başlatma

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Değişiklik uygulanamadıysa arayüzü gerçek durumla eşitle.
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    // MARK: - Doğrulama

    /// Bağlantının geçerli bir YouTube adresi olup olmadığını kontrol eder.
    private func isValidYouTubeURL(_ string: String) -> Bool {
        guard !string.isEmpty,
              let components = URLComponents(string: string),
              let host = components.host?.lowercased() else {
            return false
        }
        let allowedHosts = ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be", "music.youtube.com"]
        return allowedHosts.contains(host)
    }
}
