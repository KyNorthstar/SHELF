//
// ShelfIdentifiable.swift
//
// Written by Ky on 2026-01-24.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// An object which is identifiable on a SHELF
public protocol ShelfIdentifiable: Identifiable {
    
    /// The identifier for this object.
    ///
    /// This must be universally-unique; SHELF is an object-storage framework so all objects are equal in its eyes
    var id: ShelfId { get }
}
