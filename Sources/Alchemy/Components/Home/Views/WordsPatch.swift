//
//  WordsPatch.swift
//  Alchemy
//
//  WHAT: The words to translate: a stitched field and a button, on a patch.
//  IN:   Home (the draft's binding, and what Translate does)
//  OUT:  translate() on Return or the button
//

import SwiftUI

struct WordsPatch: View {
    @Binding var draft: String
    var translate: () -> Void

    var body: some View {
        EmbroideredPatch("Words") {
            HStack(alignment: .bottom, spacing: 16) {
                StitchedTextField("Write a line to stitch into sound…", text: $draft, onSubmit: translate)
                Button("Translate", action: translate)
                    .buttonStyle(.stitched)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
