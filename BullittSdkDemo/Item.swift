//
//  Item.swift
//  BullittSdkDemo
//
//  Created by Larry Zeng on 3/13/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
