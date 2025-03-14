//
//  SwiftDataPreviewStorageTrait.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/14/25.
//

import SwiftData
import SwiftUI

struct SwiftDataPreviewStorageModifier: PreviewModifier {
    static let previewContainer = {
        let schema = Schema([
            Message.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }()

    static func makeSharedContext() async throws -> ModelContainer {
        let context = previewContainer.mainContext

        context.insert(Message(
            messageId: "1",
            content: "Sample Receiving Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: false,
            sendingState: .received
        ))
        context.insert(Message(
            messageId: "2",
            content: "Sample Sending Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: true,
            sendingState: .sent
        ))
        context.insert(Message(
            messageId: "3",
            content: "Sample Sending Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: true,
            sendingState: .sending
        ))

        return previewContainer
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor
    static let swiftData: Self = .modifier(SwiftDataPreviewStorageModifier())
}
