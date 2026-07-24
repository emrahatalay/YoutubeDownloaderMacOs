//
//  DownloadModels.swift
//  YoutubeDownloader
//
//  Uygulama genelinde kullanılan temel model tipleri:
//  indirme formatı, ses kalitesi, indirme durumu, geçmiş kaydı ve hata tipi.
//

import Foundation

// MARK: - İndirme Formatı

/// Kullanıcının seçebileceği çıktı formatları.
enum DownloadFormat: String, CaseIterable, Identifiable, Codable {
    case mp4
    case mp3
    case wav

    var id: String { rawValue }

    /// Arayüzde gösterilecek isim.
    var displayName: String {
        switch self {
        case .mp4: return "MP4"
        case .mp3: return "MP3"
        case .wav: return "WAV"
        }
    }

    /// Format yalnızca ses mi içeriyor? (mp3/wav için ses çıkarımı yapılır.)
    var isAudioOnly: Bool { self != .mp4 }

    /// Uygun SF Symbol simgesi.
    var symbolName: String {
        switch self {
        case .mp4: return "film"
        case .mp3, .wav: return "music.note"
        }
    }
}

// MARK: - Ses Kalitesi

/// MP3/WAV için opsiyonel ses kalitesi (bit hızı).
enum AudioQuality: String, CaseIterable, Identifiable, Codable {
    case low = "128"
    case medium = "192"
    case high = "320"

    var id: String { rawValue }

    var displayName: String { "\(rawValue) kbps" }

    /// yt-dlp'ye geçirilecek `--audio-quality` değeri (örn. "320K").
    var ytdlpValue: String { "\(rawValue)K" }
}

// MARK: - İndirme Durumu

/// İndirme akışının anlık durumu. ViewModel bunu yayınlar, arayüz buna göre şekillenir.
enum DownloadStatus: Equatable {
    case idle
    case downloading(progress: Double) // 0.0 ... 1.0
    case success(url: URL)
    case error(message: String)
}

// MARK: - Geçmiş Kaydı

/// Son indirilenler listesinde tutulan basit kayıt.
struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let sourceURL: String
    let format: DownloadFormat
    let fileURL: URL?
    let date: Date

    init(id: UUID = UUID(),
         title: String,
         sourceURL: String,
         format: DownloadFormat,
         fileURL: URL?,
         date: Date = Date()) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.format = format
        self.fileURL = fileURL
        self.date = date
    }
}

// MARK: - Hata Tipi

/// İndirme akışında oluşabilecek, kullanıcıya anlaşılır mesajlarla sunulan hatalar.
enum DownloadError: LocalizedError, Equatable {
    /// Gerekli komut satırı araçları kurulu değil (eksik olanların adları).
    case toolsNotInstalled(missing: [String])
    /// Girilen bağlantı geçersiz veya YouTube bağlantısı değil.
    case invalidURL
    /// Süreç sıfır olmayan bir kodla sonlandı.
    case processFailed(code: Int32, message: String)
    /// İndirme başarılı görünüyor ama çıktı dosyası tespit edilemedi.
    case outputNotFound
    /// Kullanıcı indirmeyi iptal etti.
    case cancelled

    var errorDescription: String? {
        switch self {
        case .toolsNotInstalled(let missing):
            let list = missing.joined(separator: ", ")
            return "Gerekli araç(lar) bulunamadı: \(list). Homebrew ile kurabilirsiniz."
        case .invalidURL:
            return "Geçersiz bağlantı. Lütfen geçerli bir YouTube bağlantısı yapıştırın."
        case .processFailed(_, let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "İndirme sırasında bir hata oluştu." : trimmed
        case .outputNotFound:
            return "İndirme tamamlandı ancak çıktı dosyası bulunamadı."
        case .cancelled:
            return "İndirme iptal edildi."
        }
    }
}
