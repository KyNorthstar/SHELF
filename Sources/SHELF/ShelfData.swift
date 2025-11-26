//
// ShelfData.swift
//
// Written by Ky on 2024-11-14.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// Apply this to any type you have and SHELF will be able to CRUD it!
public protocol ShelfData: Codable, Sendable {
    
    /// The identifier for this data.
    ///
    /// This must be universally-unique; SHELF is an object-storage framework so all objects are equal in its eyes
    var id: ShelfId { get }
    
    
    /// Changes this data based on the given new data.
    ///
    /// This function is optional, and the default implementation simply assigns `self = newValue`.
    /// Write your own version if you need special behavior (e.g. you're using reference types, so simple assignment won't do).
    ///
    /// The new data probably came from some update to the object store, or from user input or similar.
    /// It's best to handle it with care. Include sanitization steps as you see fit.
    ///
    /// - Parameter newValue: The entire new value. Update this data based on that new value
    mutating func update(to newValue: Self)
}



public extension ShelfData {
    @inlinable
    mutating func update(to newValue: Self) {
        self = newValue
    }
}
