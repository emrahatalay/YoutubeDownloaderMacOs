# YouTube İndirici (macOS Menü Çubuğu Uygulaması)

macOS menü çubuğunda yaşayan, YouTube videolarını **MP4 / MP3 / WAV** formatında indirip
dönüştüren bir SwiftUI uygulaması. Arka planda `yt-dlp` ve `ffmpeg` araçlarını kullanır.

## Özellikler

- Menü çubuğu ikonu (Dock'ta görünmez, agent uygulaması)
- YouTube bağlantısı yapıştırıp format seçme (MP4 / MP3 / WAV)
- MP3/WAV için ses kalitesi seçimi (128 / 192 / 320 kbps)
- Canlı ilerleme çubuğu (yt-dlp çıktısı regex ile ayrıştırılır)
- "Finder'da Göster" ve başarı/hata mesajları
- Son 10 indirmenin geçmişi
- Ayarlar: indirme klasörünü değiştirme, girişte otomatik başlatma (`SMAppService`)

## Mimari (MVVM)

| Katman | Dosya | Sorumluluk |
|--------|-------|------------|
| Model | `Models/DownloadModels.swift` | Format, kalite, durum, geçmiş, hata tipleri |
| Service | `Services/YTDLPService.swift` | `Process` çağrıları, async/await, ilerleme ayrıştırma |
| ViewModel | `ViewModels/DownloadViewModel.swift` | Durum yönetimi, geçmiş, ayarlar |
| View | `Views/MenuBarView.swift` | SwiftUI arayüzü |
| App | `YoutubeDownloaderApp.swift` | `MenuBarExtra` sahnesi |

## Bağımlılıkların Kurulumu

Uygulama, sistemde kurulu `yt-dlp` ve `ffmpeg` araçlarını kullanır:

```sh
brew install yt-dlp ffmpeg
```

Araçlar `/opt/homebrew/bin` (Apple Silicon), `/usr/local/bin` (Intel) veya login
shell PATH'i üzerinden otomatik bulunur. Bulunamazsa uygulama içinde kurulum talimatı gösterilir.

## Gerekli Proje Ayarları (Xcode'da elle yapılmalı)

Harici komut satırı araçlarını çalıştırabilmek ve Dock'ta görünmemek için hedefin
(target) **Build Settings** / **Signing & Capabilities** sekmesinde iki ayar gerekir:

1. **App Sandbox = KAPALI** — Signing & Capabilities sekmesinde "App Sandbox"
   capability'sini kaldırın (veya Build Settings'te `ENABLE_APP_SANDBOX = NO`).
   Sandbox açıkken `Process` ile harici ikili çalıştırılamaz.
2. **LSUIElement = YES** — Build Settings'te `INFOPLIST_KEY_LSUIElement = YES`
   ekleyin (Info sekmesinde "Application is agent (UIElement)" = YES). Dock ikonunu gizler.

> Not: Bu iki ayar `project.pbxproj` dosyasında yapılır; Xcode açıkken bu dosya
> otomatik araçlarla düzenlenemediği için manuel eklenmesi gerekir.

## Çalıştırma

1. Yukarıdaki iki proje ayarını yapın.
2. `brew install yt-dlp ffmpeg` ile araçları kurun.
3. Xcode'da Run (⌘R). Menü çubuğunda ok simgesi belirir.
4. Simgeye tıklayın, bir YouTube bağlantısı yapıştırın, format seçip **İndir**'e basın.
