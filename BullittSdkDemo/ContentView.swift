//
//  ContentView.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab {
                NavigationStack {
                    ConnectionControlView()
                }
            } label: {
                Label("Device", systemImage: "personalhotspot")
            }

            Tab {
                NavigationStack {
                    MessagingView()
                }
            } label: {
                Label("Messaging", systemImage: "message")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Message.self, inMemory: true)
}
