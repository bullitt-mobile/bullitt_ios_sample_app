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

    func bsTrace(_ log: LogMessage, file: String, function _: String, line: UInt) {
        print("TRACE [\(file):\(line)] \(log)")
    }

    func bsDebug(_ log: LogMessage, file: String, function _: String, line: UInt) {
        print("DEBUG [\(file):\(line)] \(log)")
    }

    func bsInfo(_ log: LogMessage, file: String, function _: String, line: UInt) {
        print("INFO [\(file):\(line)] \(log)")
    }

    func bsWarning(_ log: LogMessage, file: String, function _: String, line: UInt) {
        print("WARNING [\(file):\(line)] \(log)")
    }

    func bsError(_ log: LogMessage, file: String, function _: String, line: UInt) {
        print("ERROR [\(file):\(line)] \(log)")
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
                        connection
                    case .deviceUnlinked:
                        nil
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
                       case let .messageBundleReceived(bundle) = event {
                        return bundle
                    }
                    return nil
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (bundle: ContentBundle) in
                    self?.handleMessage(bundle)
                }
                .store(in: &cancellables)
        }

        Task {
            self.connection = try await BullittSdk.shared.getApi().getLinkedDevice()
        }
    }

    var isLinked: Bool {
        connection != nil
    }

    var isConnected: Bool {
        connectionDetails?.connectionStatus == .connected
    }

    private func handleMessage(_ bundle: ContentBundle) {
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

    func link(_ peripheral: BlePeripheral, with userId: SmpUserId) async throws(BleError) {
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
