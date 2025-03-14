//
//  Message.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//

import BullittSdkFoundation
import Foundation
import SwiftData

enum SendingState: Codable {
    case sending
    case sent
    case received

    var string: String {
        switch self {
        case .sending: "sending"
        case .sent: "sent"
        case .received: "received"
        }
    }
}

@Model
final class Message {
    #Unique<Message>([\.messageId])

    var messageId: String
    var timestamp: Date
    var content: String
    var partner: SmpUserId
    var isSending: Bool
    var sendingState: SendingState

    init(
        messageId: String,
        timestamp: Date = .now,
        content: String,
        partner: SmpUserId,
        isSending: Bool,
        sendingState: SendingState
    ) {
        self.messageId = messageId
        self.timestamp = timestamp
        self.content = content
        self.partner = partner
        self.isSending = isSending
        self.sendingState = sendingState
    }
}
