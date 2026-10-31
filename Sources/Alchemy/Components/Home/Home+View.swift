import Granite
import SwiftUI

extension Home: View {
    public var view: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            WordsPatch(draft: center.$state.binding.draft, translate: translate)
            SamplesPatch(
                text: muse.state.text,
                samples: muse.state.samples,
                sampleRate: muse.state.sampleRate,
                error: muse.state.lastError,
                stitching: isStitching)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                Brand.linen
                LinenTexture()
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Alchemy")
                .font(Brand.serif(34, weight: .semibold))
                .embroidered(Brand.ink)
            StitchLine()
                .stitched(Brand.rust, length: 5, gap: 3, width: 1.4)
                .frame(width: 132, height: 4)
            Text("Words, stitched into sound.")
                .font(Brand.serif(13))
                .embroidered(Brand.sepia)
        }
    }

    /// Words sent, and the samples on hand are not of them yet.
    private var isStitching: Bool {
        guard let requested = center.state.requested else { return false }
        return requested != muse.state.text
    }

    private func translate() {
        let text = center.state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        center.$state.binding.requested.wrappedValue = text
        muse.translate(text)
    }
}
