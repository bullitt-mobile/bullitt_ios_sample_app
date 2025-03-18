//
//  BluetoothScanningView.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/14/25.
//
import BullittSdkFoundation
import SwiftUI

extension BSBlePeripheral: @retroactive Hashable {
    public static func == (lhs: BSBlePeripheral, rhs: BSBlePeripheral) -> Bool {
        lhs.satDevice.id == rhs.satDevice.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(satDevice.id)
    }
}

struct BluetoothScanningView: View {
    @Environment(ConnectionViewModel.self) var connectionVM
    @Environment(\.dismiss) var dismiss

    @State var userIdInput = String(Constants.SELF_USER_ID)
    @State var showUserIdInput = false

    @State var showInvalidUserIdAlert = false

    @State var scannedPeripherals: Set<BSBlePeripheral> = []
    @State var scanTask: Task<Void, Never>?
    @State var connectingTask: Task<Void, Never>?

    var canScan: Bool {
        scanTask == nil
    }

    var isConnecting: Bool {
        connectingTask != nil
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(scannedPeripherals), id: \.satDevice.id) { peripheral in
                    bluetoothItem(peripheral: peripheral.satDevice)
                        .onTapGesture {
                            showUserIdInput = true
                        }
                        .alert("Enter Your User ID", isPresented: $showUserIdInput) {
                            TextField("User ID", text: $userIdInput)
                                .textContentType(.telephoneNumber)
                            Button("Cancel", role: .cancel) {}
                            Button("Next") {
                                connect(peripheral, with: userIdInput)
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if canScan {
                        Button {
                            scan()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
        }
        .onAppear(perform: scan)
        .overlay {
            if isConnecting {
                OpaqueLoadingOverlay {
                    Text("Loading...")
                }
            }
        }
        .alert("Invalid User ID: \(userIdInput)", isPresented: $showInvalidUserIdAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func bluetoothItem(peripheral: BSSatDevice) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(peripheral.name ?? "Unknown")
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("ID: \(peripheral.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    func scan() {
        guard canScan else {
            return
        }

        scanTask = Task {
            defer { scanTask = nil }
            scannedPeripherals.removeAll()

            let scanStream = await BullittSdk.shared.getApi().listDevices().filter { peripheral in
                peripheral.satDevice.name != nil
            }

            do {
                for try await device in scanStream {
                    scannedPeripherals.insert(device)
                }

                Logger.shared.bsError("Scan ended because of timeout")
            } catch {
                Logger.shared.bsError("Error in scanning \(error)")
            }
        }
    }

    func connect(_ peripheral: BSBlePeripheral, with userId: String) {
        connectingTask = Task {
            defer { connectingTask = nil }

            guard let parsedUserId = BSSmpUserId(userId) else {
                showInvalidUserIdAlert = true
                return
            }

            do {
                try await connectionVM.link(peripheral, with: parsedUserId)
                dismiss()
            } catch {
                Logger.shared.bsError("Cannot connect to \(peripheral): \(error)")
            }
        }
    }
}
