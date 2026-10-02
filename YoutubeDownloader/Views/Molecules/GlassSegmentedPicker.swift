//
//  GlassSegmentedPicker.swift
//  YoutubeDownloader
//
//  Molekül: `.pickerStyle(.segmented)` macOS'ta klasik düz NSSegmentedControl
//  görünümünü kullanır ve gerçek Liquid Glass malzemesi almaz. Bu bileşen
//  aynı segmentli seçim davranışını, her seçeneği ayrı bir `GlassSegmentButton`
//  atomu olarak oluşturup tek bir `GlassEffectContainer` içinde birleştirerek
//  tam native cam görünümüyle sağlar.
//

import SwiftUI

struct GlassSegmentedPicker<Value: Hashable, SegmentLabel: View>: View {
    let options: [Value]
    @Binding var selection: Value
    var tint: Color = .red
    var isDisabled: Bool = false
    @ViewBuilder let label: (Value) -> SegmentLabel

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    GlassSegmentButton(
                        isSelected: option == selection,
                        tint: tint,
                        isDisabled: isDisabled,
                        action: { selection = option }
                    ) {
                        label(option)
                            .font(.caption)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: selection)
    }
}
