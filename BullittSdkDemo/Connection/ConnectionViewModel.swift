//
//  ConnectionViewModel.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//
import BullittSdkFoundation
import Combine
import SwiftData
import SwiftUI

struct Logger: BSLogger {
    static let shared = Logger()
    private init() {}

    func bsTrace(_ log: LogMessage) {
        print("TRACE \(log)")
    }

    func bsDebug(_ log: LogMessage) {
        print("DEBUG \(log)")
    }

    func bsInfo(_ log: LogMessage) {
        print("INFO \(log)")
    }

    func bsWarning(_ log: LogMessage) {
        print("WARNING \(log)")
    }

    func bsError(_ log: LogMessage) {
        print("ERROR \(log)")
    }
}

@Observable
@MainActor
class ConnectionViewModel {
    private(set) var connection: BSPeripheralConnection?
    private(set) var connectionDetails: BSBleDeviceStatus?
    private nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        try? BullittSdk.shared.initialize(logger: Logger.shared) { globalEvents, cancellables in
            globalEvents
                .map { event in
                    switch event {
                    case let .deviceLinked(connection),
                         .deviceUpdate(connection: let connection, status: _),
                         .message(connection: let connection, event: _):
                        return connection
                    case .deviceUnlinked:
                        return nil
                    @unknown default:
                        print("Unknown event: \(event)")
                        return nil
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (connection: BSPeripheralConnection?) in
                    self?.connection = connection
                    if connection == nil {
                        self?.connectionDetails = nil
                    }
                }
                .store(in: &cancellables)

            globalEvents
                .compactMap { event in
                    if case let .deviceUpdate(connection: _, status: status) = event {
                        return status
                    }
                    return nil
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.connectionDetails = status
                }
                .store(in: &cancellables)

            globalEvents
                .compactMap { event in
                    if case let .message(connection: _, event: event) = event,
                       case let .contentBundleReceived(bundle) = event {
                        return bundle
                    }
                    return nil
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (bundle: BSContentBundle) in
                    self?.handleMessage(bundle)
                }
                .store(in: &cancellables)
        }

        Task {
            self.connection = try BullittSdk.shared.getApi().getLinkedDevice()
        }
    }

    var isLinked: Bool {
        connection != nil
    }

    var isConnected: Bool {
        connectionDetails?.bleConnectionStatus == .connected
    }

    private func handleMessage(_ bundle: BSContentBundle) {
        let header = bundle.smpHeader
        if case let .text(textContent) = bundle.content {
            let message = Message(
                messageId: header.generateMessageId().string,
                content: textContent.textMessage,
                partner: textContent.partnerId,
                isSending: false,
                sendingState: .received
            )
            modelContainer.mainContext.insert(message)
            try? modelContainer.mainContext.save()
        } else {
            Logger.shared.bsError("Not handling \(bundle.content)")
        }
    }

    func link(_ peripheral: BSBlePeripheral, with userId: BSSmpUserId) async throws(BSBleError) {
        let imsi = try await BullittSdk.shared.getApi()
            .requestDevicePairing(
                peripheral: peripheral,
                config: .init(
                    userId: userId,
                    checkInMessage: "Check In Message",
                    checkInNumber: userId
                )
            )

        // TODO: Confirm if user can connect with the imsi
        Logger.shared.bsInfo("Linking peripheral with IMSI: \(imsi)")

        connection = try await BullittSdk.shared.getApi().confirmDeviceLinking()
    }

    func forget() async {
        await BullittSdk.shared.getApi().removeLinkedDevice()
    }
}
