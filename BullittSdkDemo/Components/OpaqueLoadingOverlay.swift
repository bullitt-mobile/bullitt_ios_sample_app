//
//  OpaqueLoadingOverlay.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/14/25.
//
import SwiftUI

struct OpaqueLoadingOverlay<Content: View>: View {
    @ViewBuilder let content: () -> Content

    init(content: @escaping () -> Content) {
        self.content = content
    }

    init() where Content == EmptyView {
        content = { EmptyView() }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Material.ultraThin)
                .ignoresSafeArea(.all)

            VStack {
                ProgressView()
                    .progressViewStyle(.circular)

                content()
            }
            .padding()
            .frame(minWidth: 128, minHeight: 128)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.thickMaterial)
            }
            .frame(maxWidth: 256)
        }
    }
}
