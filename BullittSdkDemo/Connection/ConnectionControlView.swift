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
    @State var showMessagingView = false

    var body: some View {
        List {
            actionButtonsSection
                .listRowBackground(EmptyView())

            deviceInfoSection
        }
        .navigationDestination(isPresented: $showMessagingView) {
            MessagingView()
        }
        .sheet(isPresented: $showScanningSheet) {
            BluetoothScanningView()
        }
    }

    @ViewBuilder
    private var deviceInfoSection: some View {
        if let details = connectionVM.connectionDetails {
            Section {
                InfoRow(title: "Bluetooth Connection", value: String(describing: details.connectionStatus))
                InfoRow(title: "Satellite Connection", value: String(describing: details.satConnectionStatus))
            } header: {
                Text("Connection Information")
            }

            Section {
                InfoRow(title: "Device Name", value: details.satDevice.name ?? "N/A")
                InfoRow(title: "IMSI", value: details.deviceInfo?.imsi ?? "N/A")
                InfoRow(title: "Firmware Version", value: details.deviceInfo?.osVersion ?? "N/A")
                InfoRow(title: "Serial Number", value: details.deviceInfo?.serialNumber ?? "N/A")
            } header: {
                Text("Device Information")
            }
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        Section {
            if connectionVM.isLinked {
                Button {
                    Task { await connectionVM.forget() }
                } label: {
                    Text("Forget")
                        .actionButtonLabelStyled()
                }

                Button {
                    showMessagingView = true
                } label: {
                    Text("Messages")
                        .actionButtonLabelStyled()
                }
            } else {
                Button {
                    showScanningSheet = true
                } label: {
                    Text("Scan")
                        .actionButtonLabelStyled()
                }
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

extension View {
    @ViewBuilder
    func actionButtonLabelStyled() -> some View {
        frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
