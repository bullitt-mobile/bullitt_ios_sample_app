//
//  ConnectionViewModelTrait.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/14/25.
//

import SwiftData
import SwiftUI

struct ConnectionViewModelModifier: PreviewModifier {
    static func makeSharedContext() async throws -> ConnectionViewModel {
        return ConnectionViewModel(modelContainer: SwiftDataPreviewStorageModifier.previewContainer)
    }

    func body(content: Content, context: ConnectionViewModel) -> some View {
        content.environment(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor
    static let connectionVM: Self = .modifier(ConnectionViewModelModifier())
}
