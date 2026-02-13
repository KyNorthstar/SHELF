//
// ShelfId + strings.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import StringIntegerAccess
import UuidTools



internal extension ShelfId {
    var shelfStrings: ShelfIdStrings { .init(self) }
}



/// SHELF uses these strings when handling object Ids
internal struct ShelfIdStrings {
    let topFolderName: Substring
    let subFolderName: Substring
    let objectName: String
}



internal extension ShelfIdStrings {
    init(_ id: ShelfId) {
        let string = id.rawValue.uuidString
        topFolderName = string[0...1]
        subFolderName = string[2...3]
        objectName = string
    }
}



internal extension UuidFormat {
    /// The UUID format for Shelf IDs
    @inline(__always)
    static var shelfId: UuidFormat { .truncatedBase64 }
}
