//
//  MenuBarView.swift
//  YoutubeDownloader
//
//  Kök görünüm: menü çubuğu ikonuna tıklanınca açılan pencere. Atomic
//  Design hiyerarşisinin en üstünde yer alır; yalnızca hangi ekranın
//  (Ana/Ayarlar) gösterileceğine karar verir ve geçişi animasyonlar.
//  Gerçek içerik `Screens/MainScreen` ve `Screens/SettingsScreen`
//  katmanlarında, onların parçaları da `Organisms`, `Molecules` ve
//  `Atoms` klasörlerinde tanımlıdır.
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var viewModel: DownloadViewModel

    private enum Screen {
        case main
        case settings
    }

    @State private var screen: Screen = .main

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderBar(
                title: screen == .settings ? "Ayarlar" : "YouTube İndirici",
                isShowingSettings: screen == .settings,
                onToggleSettings: { screen = (screen == .main) ? .settings : .main },
                onQuit: { NSApplication.shared.terminate(nil) }
            )

            Divider()

            // Ekranlar aynı pencerede yatay kayma + solma animasyonuyla değişir.
            ZStack {
                switch screen {
                case .main:
                    MainScreen(viewModel: viewModel)
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
        .padding(18)
        .frame(width: 360)
        .task { viewModel.checkTools() }
    }
}
