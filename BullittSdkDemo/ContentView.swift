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
    @Query private var items: [Message]

    var body: some View {
        NavigationStack {
            ConnectionControlView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Message.self, inMemory: true)
}
