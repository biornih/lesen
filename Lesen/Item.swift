//
//  Item.swift
//  Lesen
//
//  Created by Biorni on 12.08.26.
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
