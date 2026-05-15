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
public protocol ShelfData: Codable, Sendable, ShelfIdentifiable {
    
    /// The identifier for this data.
    ///
    /// This must be universally-unique; SHELF is an object-storage framework so all objects are equal in its eyes
    var id: ShelfId { get }
}
