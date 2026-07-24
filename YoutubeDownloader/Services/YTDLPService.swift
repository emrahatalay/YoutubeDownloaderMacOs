//
//  YTDLPService.swift
//  YoutubeDownloader
//
//  yt-dlp ve ffmpeg komut satırı araçlarını `Process` ile çalıştıran servis katmanı.
//  Tüm ağır işler ana aktör dışında (nonisolated) yürütülür; ilerleme geri bildirimi
//  @Sendable bir closure ile üst katmana iletilir.
//

import Foundation

/// Komut satırı araçlarını yöneten, async/await ile çalışan servis.
///
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ayarı nedeniyle tip `nonisolated`
/// olarak işaretlenmiştir; böylece `Process` çağrıları ana aktörü bloklamaz.
nonisolated enum YTDLPService {

    /// Sistemde bulunmuş araçların mutlak yolları.
    struct ResolvedTools: Sendable {
        let ytdlp: String
        let ffmpeg: String
    }

    // MARK: - Araç Tespiti

    /// Verilen komutu (örn. "yt-dlp") sistemde arar ve mutlak yolunu döndürür.
    /// Önce yaygın Homebrew konumlarına, ardından login shell PATH'ine bakar.
    static func locate(_ name: String) -> String? {
        let candidates = [
            "/opt/homebrew/bin/\(name)", // Apple Silicon
            "/usr/local/bin/\(name)",    // Intel
            "/usr/bin/\(name)"
        ]
        let fileManager = FileManager.default
        for path in candidates where fileManager.isExecutableFile(atPath: path) {
            return path
        }
        return locateViaLoginShell(name)
    }

    /// Login shell'in PATH'ini kullanarak `which` ile arama yapar.
    private static func locateViaLoginShell(_ name: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "which \(name)"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty,
              FileManager.default.isExecutableFile(atPath: output) else {
            return nil
        }
        return output
    }

    /// yt-dlp ve ffmpeg'in her ikisini de bulmayı dener.
    /// Başarılıysa yolları, değilse eksik araçları içeren hatayı döndürür.
    static func resolveTools() -> Result<ResolvedTools, DownloadError> {
        let ytdlp = locate("yt-dlp")
        let ffmpeg = locate("ffmpeg")

        var missing: [String] = []
        if ytdlp == nil { missing.append("yt-dlp") }
        if ffmpeg == nil { missing.append("ffmpeg") }

        guard let ytdlp, let ffmpeg else {
            return .failure(.toolsNotInstalled(missing: missing))
        }
        return .success(ResolvedTools(ytdlp: ytdlp, ffmpeg: ffmpeg))
    }

    // MARK: - İndirme

    /// Verilen bağlantıyı seçilen formatta indirir.
    /// - Parameter progress: 0...100 aralığında yüzde ilerlemesini bildiren closure.
    /// - Returns: İndirilen (ve dönüştürülen) dosyanın URL'i.
    static func download(
        url: String,
        format: DownloadFormat,
        quality: AudioQuality,
        outputDirectory: URL,
        tools: ResolvedTools,
        videoHeight: Int? = nil,
        embedMetadata: Bool = true,
        embedThumbnail: Bool = false,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {

        let process = Process()
        process.executableURL = URL(fileURLWithPath: tools.ytdlp)
        process.arguments = await buildArguments(
            url: url,
            format: format,
            quality: quality,
            outputDirectory: outputDirectory,
            ffmpegPath: tools.ffmpeg,
            videoHeight: videoHeight,
            embedMetadata: embedMetadata,
            embedThumbnail: embedThumbnail
        )

        // Alt sürecin ffmpeg vb. araçları bulabilmesi için PATH'i genişletiyoruz.
        var environment = ProcessInfo.processInfo.environment
        let extraPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        environment["PATH"] = extraPaths + ":" + (environment["PATH"] ?? "")
        process.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let collector = OutputCollector()

        // stdout: ilerleme yüzdesi ve çıktı dosya yolu buradan okunur.
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            for line in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
                let lineString = String(line)
                if let percent = parseProgress(lineString) {
                    progress(percent)
                }
                collector.trackOutputPath(lineString)
            }
        }

        // stderr: hata mesajları burada toplanır.
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            collector.appendError(text)
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                process.terminationHandler = { finishedProcess in
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    if collector.isCancelled {
                        continuation.resume(throwing: DownloadError.cancelled)
                        return
                    }

                    if finishedProcess.terminationStatus == 0 {
                        if let path = collector.resolvedOutputPath {
                            continuation.resume(returning: URL(fileURLWithPath: path))
                        } else {
                            continuation.resume(throwing: DownloadError.outputNotFound)
                        }
                    } else {
                        continuation.resume(throwing: DownloadError.processFailed(
                            code: finishedProcess.terminationStatus,
                            message: collector.errorText
                        ))
                    }
                }

                do {
                    try process.run()
                } catch {
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            collector.markCancelled()
            process.terminate()
        }
    }

    // MARK: - Kalite Sorgulama

    /// Videonun sunduğu çözünürlükleri (yükseklik, örn. 1080) büyükten küçüğe döndürür.
    /// `yt-dlp -j` çıktısındaki `formats` dizisinden video içeren formatların
    /// yükseklikleri toplanır.
    static func fetchVideoQualities(
        url: String,
        tools: ResolvedTools
    ) async throws -> [Int] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tools.ytdlp)
        process.arguments = ["-j", "--no-playlist", url]

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (environment["PATH"] ?? "")
        process.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let buffer = DataBuffer()
        let errorCollector = OutputCollector()

        // JSON çıktısı 64KB'lık pipe tamponundan büyük olabileceği için sürekli okunmalı.
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            buffer.append(data)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            errorCollector.appendError(text)
        }

        let jsonData: Data = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                process.terminationHandler = { finishedProcess in
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    // Süreç kapanırken tamponda kalan son veriyi de al.
                    buffer.append(outputPipe.fileHandleForReading.readDataToEndOfFile())

                    if errorCollector.isCancelled {
                        continuation.resume(throwing: DownloadError.cancelled)
                    } else if finishedProcess.terminationStatus == 0 {
                        continuation.resume(returning: buffer.data)
                    } else {
                        continuation.resume(throwing: DownloadError.processFailed(
                            code: finishedProcess.terminationStatus,
                            message: errorCollector.errorText
                        ))
                    }
                }
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            errorCollector.markCancelled()
            process.terminate()
        }

        return parseHeights(from: jsonData)
    }

    /// `-j` JSON çıktısından benzersiz video yüksekliklerini ayıklar.
    private static func parseHeights(from data: Data) -> [Int] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let formats = json["formats"] as? [[String: Any]] else {
            return []
        }
        var heights = Set<Int>()
        for format in formats {
            let vcodec = format["vcodec"] as? String ?? "none"
            guard vcodec != "none", let height = format["height"] as? Int, height > 0 else { continue }
            heights.insert(height)
        }
        return heights.sorted(by: >)
    }

    // MARK: - Argüman İnşası

    /// Seçilen formata göre yt-dlp argümanlarını üretir.
    @MainActor private static func buildArguments(
        url: String,
        format: DownloadFormat,
        quality: AudioQuality,
        outputDirectory: URL,
        ffmpegPath: String,
        videoHeight: Int?,
        embedMetadata: Bool,
        embedThumbnail: Bool
    ) -> [String] {
        let outputTemplate = outputDirectory
            .appendingPathComponent("%(title)s.%(ext)s")
            .path

        var arguments: [String]

        switch format {
        case .mp4:
            // Kullanıcı belirli bir çözünürlük seçtiyse yükseklik filtresi uygulanır;
            // seçmediyse mevcut en iyi kalite indirilir.
            let heightFilter = videoHeight.map { "[height<=\($0)]" } ?? ""
            arguments = [
                "-f", "bestvideo\(heightFilter)[ext=mp4]+bestaudio[ext=m4a]/best\(heightFilter)[ext=mp4]/best\(heightFilter)",
                "--merge-output-format", "mp4"
            ]
        case .mp3:
            arguments = [
                "-x",
                "--audio-format", "mp3",
                "--audio-quality", quality.ytdlpValue
            ]
        case .wav:
            arguments = [
                "-x",
                "--audio-format", "wav"
            ]
        }

        if embedMetadata {
            arguments.append("--embed-metadata")
        }
        // Kapak görseli gömme: WAV kapsayıcısı kapak desteklemediği için hariç tutulur.
        if embedThumbnail && format != .wav {
            arguments.append("--embed-thumbnail")
        }

        arguments.append(contentsOf: [
            "--ffmpeg-location", ffmpegPath,
            "--no-playlist",   // Tek video indir (oynatma listesi değil)
            "--newline",       // İlerlemeyi ayrı satırlar hâlinde yaz
            "-o", outputTemplate,
            url
        ])

        return arguments
    }

    // MARK: - Çıktı Ayrıştırma

    /// `[download]  45.2% ...` satırından yüzdeyi çıkarır.
    private static let progressRegex = try! NSRegularExpression(
        pattern: #"\[download\]\s+(\d+(?:\.\d+)?)%"#
    )

    private static func parseProgress(_ line: String) -> Double? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = progressRegex.firstMatch(in: line, range: range),
              let valueRange = Range(match.range(at: 1), in: line),
              let value = Double(line[valueRange]) else {
            return nil
        }
        return value
    }
}

// MARK: - Veri Tamponu

/// Arka plan kuyruğundan beslenen, kilitle korunan basit veri tamponu.
private nonisolated final class DataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var _data = Data()

    var data: Data {
        lock.lock(); defer { lock.unlock() }
        return _data
    }

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        _data.append(chunk)
    }
}

// MARK: - Çıktı Toplayıcı

/// stdout/stderr geri çağırmaları farklı arka plan kuyruklarından çağrıldığı için
/// paylaşılan durumu kilitle koruyan iş parçacığı güvenli yardımcı sınıf.
private nonisolated final class OutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var _resolvedOutputPath: String?
    private var _errorText = ""
    private var _cancelled = false

    // Çıktı dosya yolunu tespit etmeye yarayan desenler (sırayla denenir).
    private static let destinationRegex = try! NSRegularExpression(
        pattern: #"Destination:\s*(.+)$"#
    )
    private static let mergerRegex = try! NSRegularExpression(
        pattern: #"Merging formats into \"(.+)\""#
    )
    private static let alreadyDownloadedRegex = try! NSRegularExpression(
        pattern: #"\[download\]\s+(.+) has already been downloaded"#
    )

    var resolvedOutputPath: String? {
        lock.lock(); defer { lock.unlock() }
        return _resolvedOutputPath
    }

    var errorText: String {
        lock.lock(); defer { lock.unlock() }
        return _errorText
    }

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return _cancelled
    }

    func markCancelled() {
        lock.lock(); defer { lock.unlock() }
        _cancelled = true
    }

    func appendError(_ text: String) {
        lock.lock(); defer { lock.unlock() }
        _errorText.append(text)
    }

    /// Bir satırdan olası çıktı dosya yolunu yakalar. En son eşleşen yol tutulur;
    /// böylece ses çıkarımı / birleştirme sonrasındaki nihai dosya kazanır.
    func trackOutputPath(_ line: String) {
        let patterns = [
            Self.mergerRegex,
            Self.destinationRegex,
            Self.alreadyDownloadedRegex
        ]
        for regex in patterns {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let captureRange = Range(match.range(at: 1), in: line) {
                let path = String(line[captureRange]).trimmingCharacters(in: .whitespaces)
                lock.lock()
                _resolvedOutputPath = path
                lock.unlock()
            }
        }
    }
}
