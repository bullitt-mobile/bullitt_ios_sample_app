//
//  MessageBubble.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/14/25.
//
import SwiftUI

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isSending {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(message.content)

                Text(message.sendingState.string)
                    .frame(alignment: .bottomTrailing)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .foregroundStyle(message.isSending ? .white : .primary)
            .background(message.isSending ? Color.accentColor : Color.secondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if !message.isSending {
                Spacer()
            }
        }
    }
}

#Preview("Bubble") {
    ScrollView {
        MessageBubble(message: .init(
            messageId: "1",
            content: "Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: false,
            sendingState: .received
        ))
        MessageBubble(message: .init(
            messageId: "2",
            content: "Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: true,
            sendingState: .sending
        ))
        MessageBubble(message: .init(
            messageId: "3",
            content: "Content",
            partner: Constants.PARTNER_USER_ID,
            isSending: true,
            sendingState: .sent
        ))
    }
    .padding(.horizontal, 16)
}
