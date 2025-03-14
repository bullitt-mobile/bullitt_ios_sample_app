//
//  BullittSdkDemoApp.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//

import SwiftData
import SwiftUI

@main
struct BullittSdkDemoApp: App {
    var sharedModelContainer: ModelContainer
    @State var connectionVM: ConnectionViewModel

    init() {
        let modelContainer = {
            let schema = Schema([
                Message.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()

        sharedModelContainer = modelContainer
        _connectionVM = State(initialValue: ConnectionViewModel(modelContainer: modelContainer))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(connectionVM)
    }
}
