//
//  ConnectionSideBar.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//
import SwiftUI

struct ConnectionControlView: View {
    @Environment(ConnectionViewModel.self) var connectionVM
    @State var showScanningSheet = false

    var body: some View {
        List {
            actionButtonsSection
                .listRowBackground(EmptyView())

            deviceInfoSection
        }
        .sheet(isPresented: $showScanningSheet) {
            BluetoothScanningView()
        }
    }

    @ViewBuilder
    private var deviceInfoSection: some View {
        Section {
            InfoRow(
                title: "Bluetooth Connection",
                value: connectionVM.connection == nil ? "Not Connected" : "Connected"
            )
            if let details = connectionVM.connectionDetails {
                InfoRow(title: "Satellite Connection", value: String(describing: details.satConnectionStatus))
            }
        } header: {
            Text("Connection Information")
        }

        if let linkedDevice = connectionVM.linkedDevice {
            InfoRow(title: "Name", value: linkedDevice.name ?? "Unknown")
            InfoRow(title: "ID", value: linkedDevice.id.uuidString)
        }

        if let info = connectionVM.connection?.deviceInfo {
            Section {
                InfoRow(title: "IMSI", value: info.imsi)
                InfoRow(title: "Firmware Version", value: info.osVersion)
                InfoRow(title: "Serial Number", value: info.serialNumber)
            } header: {
                Text("Device Information")
            }
        }
    }

    private var actionButtonsSection: some View {
        Section {
            if connectionVM.isLinked {
                Button {
                    Task { await connectionVM.forget() }
                } label: {
                    Text("Forget")
                }
                .buttonStyle(.glassProminent)
            } else {
                Button {
                    showScanningSheet = true
                } label: {
                    Text("Scan")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .listRowSeparator(.hidden)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
