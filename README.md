# Bullitt iOS SDK Integration Guide

## Overview

The Bullitt SDK for iOS provides functionality for satellite device discovery, pairing, and communication. This guide demonstrates how to integrate the BullittSdkFoundation framework into your iOS application.

## Pre-requisites

- **Xcode**: Latest stable version for development
- Physical iOS Device: Running iOS 15.0 or higher
- Satellite Device: A Bullitt-compatible satellite device with:
  - A provisioned satellite connection
  - An activated satellite service plan
- Access credentials for the Bullitt SDK repository

For satellite connection activation assistance, please contact the Bullitt support team at support@bullitt.com or through your provided account representative.

## Installation

### Swift Package Manager

Add the BullittSdkFoundation package to your project:

1. In Xcode, select File > Add Packages...
2. Enter the Bullitt SDK repository URL
3. Select the appropriate version
4. Click Add Package

### CocoaPods

Add the dependency to your Podfile:

```ruby
pod 'BullittSdkFoundation'
```

Then run:

```bash
pod install
```

## Initialization

Initialize the SDK in your SwiftUI app:

```swift
import BullittSdkFoundation
import SwiftUI

@main
struct YourApp: App {
    @State var connectionVM: ConnectionViewModel
    
    init() {
        // Initialize your connection view model
        _connectionVM = State(initialValue: ConnectionViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(connectionVM)
        }
    }
}
```

Create a connection view model to manage the SDK:

```swift
import BullittSdkFoundation
import Combine
import SwiftUI

// Implement logging
struct Logger: BSLogger {
    static let shared = Logger()
    private init() {}
    
    func bsTrace(_ log: LogMessage, file: String, function: String, line: UInt) {
        print("TRACE [\(file):\(line)] \(log)")
    }
    
    func bsDebug(_ log: LogMessage, file: String, function: String, line: UInt) {
        print("DEBUG [\(file):\(line)] \(log)")
    }
    
    func bsInfo(_ log: LogMessage, file: String, function: String, line: UInt) {
        print("INFO [\(file):\(line)] \(log)")
    }
    
    func bsWarning(_ log: LogMessage, file: String, function: String, line: UInt) {
        print("WARNING [\(file):\(line)] \(log)")
    }
    
    func bsError(_ log: LogMessage, file: String, function: String, line: UInt) {
        print("ERROR [\(file):\(line)] \(log)")
    }
}

@Observable
@MainActor
class ConnectionViewModel {
    private(set) var connection: BSPeripheralConnection?
    private(set) var connectionDetails: BSBleDeviceStatus?
    
    init() {
        try? BullittSdk.shared.initialize(logger: Logger.shared) { globalEvents, cancellables in
            // Set up event handling
            self.setupEventHandling(globalEvents: globalEvents, cancellables: &cancellables)
        }
        
        // Check for existing linked device
        Task {
            self.connection = try await BullittSdk.shared.getApi().getLinkedDevice()
        }
    }
    
    private func setupEventHandling(globalEvents: AnyPublisher<SdkGlobalEvent, Never>, cancellables: inout Set<AnyCancellable>) {
        // Handle device connection events
        globalEvents
            .map { event in
                switch event {
                case let .deviceLinked(connection),
                     let .deviceUpdate(connection: connection, status: _),
                     let .message(connection: connection, event: _):
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
        
        // Handle device status updates
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
        
        // Add more event handlers as needed
    }
    
    var isLinked: Bool {
        connection != nil
    }
    
    var isConnected: Bool {
        connectionDetails?.connectionStatus == .connected
    }
}
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

Pair with a discovered device:

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

Get the currently linked device:

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

Remove a linked device:

```swift
func forgetDevice() async {
    await BullittSdk.shared.getApi().removeLinkedDevice()
}
```

### 4. Sending Messages

Send content to a connected satellite device:

```swift
func sendMessage(to partnerId: SmpUserId, content: String) async throws {
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

Handle incoming messages through the global event handler:

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

## Permissions

Add the required permissions to your Info.plist:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to satellite devices.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to satellite devices.</string>
```

## Error Handling

The SDK uses Swift's `Result` type for operation results:

- `Result.success`: Operation completed successfully
- `Result.failure`: Operation failed with an error

Common errors to handle:

- Bluetooth connectivity issues
- Device pairing failures
- Message sending failures
- Invalid user IDs

Example error handling:

```swift
do {
    try await sendMessage(to: partnerId, content: messageContent)
} catch {
    switch error {
    case BleError.deviceNotFound:
        // Handle device not found
    case BleError.connectionFailed:
        // Handle connection failure
    default:
        // Handle other errors
        Logger.shared.bsError("Error sending message: \(error)")
    }
}
```

## Best Practices

1. Always check if a device is connected before attempting to send messages
2. Handle Bluetooth permission requirements before scanning for devices
3. Implement proper error handling for all SDK operations
4. Use weak references in event handlers to avoid memory leaks
5. Process all events on the main thread when updating UI
6. Store user IDs securely
7. Always validate user IDs before using them
8. Implement a timeout mechanism for operations that might hang

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
