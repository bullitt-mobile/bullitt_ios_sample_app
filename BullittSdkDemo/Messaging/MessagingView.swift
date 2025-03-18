//
//  MessagingView.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//
import BullittSdkFoundation
import SwiftData
import SwiftUI

struct MessagingView: View {
    @State var partnerId = Constants.PARTNER_USER_ID
    @State var messageDraft = ""
    @State var sendingTask: Task<Void, Never>?

    @State var showEditPartnerId = false

    @Environment(ConnectionViewModel.self) var connectionVM
    @Environment(\.modelContext) var modelContext

    @Query
    private var messages: [Message]

    init() {
        partnerId = partnerId
        _messages = .init(
            filter: #Predicate<Message> {
                $0.partner == partnerId
            },
            sort: \.timestamp,
            order: .forward
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputArea
        }
        .padding(.bottom, 4)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditPartnerId = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .principal) {
                Text(String(partnerId))
            }
        }
        .navigationDestination(isPresented: $showEditPartnerId) {
            SetUserId(userId: $partnerId)
        }
    }

    @ViewBuilder
    var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var inputArea: some View {
        HStack {
            TextField("Satellite Message", text: $messageDraft)
                .lineLimit(5)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .clipShape(.circle)
            .disabled(!connectionVM.isConnected)
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
    }

    func sendMessage() {
        sendingTask = Task {
            defer { sendingTask = nil }

            do {
                try await sendInternal()
            } catch {
                Logger.shared.bsError("Failed to send message: \(error)")
            }
        }
    }

    func sendInternal() async throws {
        guard let connection = connectionVM.connection else {
            return
        }

        let messageContent = messageDraft
        messageDraft = ""

        let messageBundle = connection.createContentBundle(.text(.init(
            partnerId: partnerId,
            textMessage: messageContent
        )))

        let message = Message(
            messageId: messageBundle.smpHeader.generateMessageId().string,
            timestamp: .now,
            content: messageContent,
            partner: partnerId,
            isSending: true,
            sendingState: .sending
        )
        modelContext.insert(message)
        try modelContext.save()

        let result = try await connection.sendMessage(messageBundle).get()

        Logger.shared.bsInfo("Sent successful: \(result.result)")
    }
}

private struct SetUserId: View {
    @Binding var userId: BSSmpUserId
    @State var userIdInput: String
    @State var showInvalidUserIdAlert = false
    @Environment(\.dismiss) var dismiss

    init(userId: Binding<BSSmpUserId>) {
        _userId = userId
        _userIdInput = State(initialValue: String(userId.wrappedValue))
    }

    var body: some View {
        List {
            TextField("User ID", text: $userIdInput)
                .textContentType(.telephoneNumber)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    if let newUserId = BSSmpUserId(userIdInput) {
                        userId = newUserId
                        dismiss()
                    } else {
                        showInvalidUserIdAlert = true
                    }
                }
            }
        }
        .alert("Invalid User ID", isPresented: $showInvalidUserIdAlert) {
            Button("Try Again", role: .cancel) {}
        }
    }
}

#Preview("Chats", traits: .swiftData, .connectionVM) {
    NavigationStack {
        MessagingView()
    }
}
