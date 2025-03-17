# Bullitt iOS SDK Integration Guide

## Overview

The Bullitt SDK for iOS provides functionality for satellite device discovery, pairing, and communication. This guide demonstrates how to integrate the BullittSdkFoundation framework into your iOS application.

## Documentation

The documentation is hosted on [docs.bullitt.com/ios](https://docs.bullitt.com/ios).

## Pre-requisites

- **Xcode**: Latest stable version for development
- Physical iOS Device: Running iOS 15.0 or higher
- Satellite Device: A Bullitt-compatible satellite device with:
  - A provisioned satellite connection
  - An activated satellite service plan
- Access credentials for the Bullitt SDK repository

For satellite connection activation assistance, please contact the Bullitt support team at <support@bullitt.com> or through your provided account representative.

## Installation

### Swift Package Manager

Add the BullittSdkFoundation package to your project:

1. In Xcode, select `File > Add Packages...`
2. Enter the Bullitt SDK repository URL (<https://github.com/bullitt-mobile/bullitt_ios_sdk_binary>)
3. Select the appropriate version
4. Click Add Package

## Glossary

- **IMSI**: International Mobile Subscriber Identity, a unique identifier for a satellite device.
- **Pairing**: refers to connecting to a satellite device via Bluetooth. This happens before linking.
- **Linking**: refers to the process of confirming the satellite device can be used. This happens after pairing, and _only a linked device_ is valid for further interaction such as sending messages.

## Initialization

To initialize the SDK, use `BullittSdk.shared.initialize`, by passing in a `BSLogger` instance, and optionally a closure to handle the events emitted by the SDK. You can always access the event publisher by calling `BullittSdk.shared.getApi().globalEvents()`.

`ConnectionViewModel.swift` provides and example of how initialization can be used.

## Permissions

Add the required permissions to your Info.plist. We use bluetooth permission to connect to the satellite devices, and location permission to automatically handle location requirement of check-in and SOS messages triggered from the physical buttons on the satellite devices.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to satellite devices.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses location to send check-in and SOS messages.</string>
<key>
```

## Core Features

### 1. Device Discovery

Scan for available satellite devices:

```swift
func scanForDevices() {
    Task {
        let scanStream = await BullittSdk.shared.getApi().listDevices()

        do {
            for try await device in scanStream {
                // Handle discovered device
                // device is a BlePeripheral instance
            }
        } catch {
            Logger.shared.bsError("Error scanning: \(error)")
        }
    }
}
```

### 2. Device Pairing

Pairing comes in two stages: request pairing and confirmation. The client application should first call `requestDevicePairing` to initiate the pairing process. The function returns the IMSI of the satellite device. After validating that the user has the correct device, the client application should call `confirmDeviceLinking` to complete the pairing process.

```swift
func link(_ peripheral: BlePeripheral, with userId: SmpUserId) async throws {
    // Request device pairing
    let imsi = try await BullittSdk.shared.getApi()
        .requestDevicePairing(
            peripheral: peripheral,
            config: .init(
                userId: userId,
                checkInMessage: "Check In Message",
                checkInNumber: userId
            )
        )

    // Validate IMSI if needed
    // ...

    // Confirm device linking
    connection = try await BullittSdk.shared.getApi().confirmDeviceLinking()
}
```

### 3. Device Management

You can always get the currently linked device:

```swift
func getLinkedDevice() async {
    do {
        let device = try await BullittSdk.shared.getApi().getLinkedDevice()
        // Handle connected device
    } catch {
        // Handle no linked device
    }
}
```

, or remove a linked device:

```swift
func forgetDevice() async {
    await BullittSdk.shared.getApi().removeLinkedDevice()
}
```

### 4. Sending Messages

To send a satellite message, the client should first create a content bundle using the `createContentBundle` function. The client can then send the message using the `sendMessage` function.

```swift
func sendTextMessage(to partnerId: SmpUserId, content: String) async throws {
    // confirm we have a satellite device connection
    guard let connection = connection else {
        throw CustomError.noConnection
    }

    // Create a content bundle
    let messageBundle = connection.createContentBundle(.text(.init(
        partnerId: partnerId,
        textMessage: content
    )))

    // Send the message
    let result = try await connection.sendMessage(messageBundle).get()

    // Handle result
    if result.result {
        // Message sent successfully
    } else {
        // Message sending failed
    }
}
```

### 5. Receiving Messages

Incoming messages are notified through the global event publisher. You may find the following filter helpful:

```swift
globalEvents
    .compactMap { event in
        if case let .message(connection: _, event: event) = event,
            case let .messageBundleReceived(bundle) = event {
            return bundle
        }
        return nil
    }
    .sink { bundle in
        handleMessage(bundle)
    }
```

where `handleMessage` is a function that processes the incoming message:

```swift
private func handleMessage(_ bundle: ContentBundle) {
    let header = bundle.smpHeader

    if case let .text(textContent) = bundle.content {
        // Process text message
        let textMessage = textContent.textMessage
        let senderId = textContent.partnerId

        // Handle the received message in your application
    } else {
        Logger.shared.bsWarning("Unhandled content type: \(bundle.content)")
    }
}
```

## Error Handling

The SDK uses Swift's `Result` type for operation results:

- `Result.success`: Operation completed successfully
- `Result.failure`: Operation failed with an error

## Best Practices

1. Always check if a device is connected before attempting to send messages
2. Implement proper error handling for all SDK operations
3. Implement a timeout mechanism for operations that might hang

## UI Integration Examples

### Connection Control View

```swift
struct ConnectionControlView: View {
    @Environment(ConnectionViewModel.self) var connectionVM
    @State var showScanningSheet = false

    var body: some View {
        VStack {
            if connectionVM.isLinked {
                // Show connected device information
                Text("Device Connected")

                Button("Disconnect") {
                    Task { await connectionVM.forgetDevice() }
                }
            } else {
                // Show scan button
                Button("Scan for Devices") {
                    showScanningSheet = true
                }
            }
        }
        .sheet(isPresented: $showScanningSheet) {
            DeviceScanningView()
        }
    }
}
```

### Device Scanning View

```swift
struct DeviceScanningView: View {
    @Environment(ConnectionViewModel.self) var connectionVM
    @Environment(\.dismiss) var dismiss

    @State var scannedDevices: [BlePeripheral] = []
    @State var isScanning = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(scannedDevices, id: \.satDevice.id) { device in
                    Button {
                        // Connect to device
                        Task {
                            try await connectionVM.link(device, with: yourUserId)
                            dismiss()
                        }
                    } label: {
                        Text(device.satDevice.name ?? "Unknown Device")
                    }
                }
            }
            .navigationTitle("Available Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isScanning ? "Stop" : "Scan") {
                        if isScanning {
                            stopScanning()
                        } else {
                            startScanning()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    func startScanning() {
        isScanning = true
        scannedDevices = []

        Task {
            let scanStream = await BullittSdk.shared.getApi().listDevices()

            do {
                for try await device in scanStream {
                    if !scannedDevices.contains(where: { $0.satDevice.id == device.satDevice.id }) {
                        scannedDevices.append(device)
                    }
                }
            } catch {
                // Handle scanning error
            }

            isScanning = false
        }
    }

    func stopScanning() {
        // Cancel scanning task
        isScanning = false
    }
}
```

## Troubleshooting

Common issues and solutions:

1. **Device not found during scanning**
   - Ensure Bluetooth is enabled on the iOS device
   - Check that the satellite device is powered on and in pairing mode
   - Verify Bluetooth permissions are granted

2. **Pairing failure**
   - Ensure the satellite device is in pairing mode
   - Verify the user ID is valid
   - Check that the satellite device has an active service plan

3. **Message sending failure**
   - Verify the device is still connected
   - Check that the partner ID is valid
   - Ensure the satellite device has a clear view of the sky

4. **SDK initialization failure**
   - Verify the SDK is properly imported
   - Check for any framework version compatibility issues

## Sample Implementation

Refer to the demo app implementation for a complete example of SDK integration and usage patterns. The demo showcases:

- Proper SDK initialization
- Device discovery and pairing
- Message sending and receiving
- Error handling
- UI integration

## Next Steps

After successful integration, consider implementing:

- Message persistence
- Offline operation capabilities
- User authentication
- Advanced error recovery
- Background operation support
- Power optimization strategies

For additional support, contact the Bullitt development team or refer to the comprehensive SDK documentation.
