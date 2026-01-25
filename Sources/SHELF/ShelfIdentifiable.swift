//
//  ShelfIdentifiable.swift
//  SHELF
//
//  Created by Ky on 2026-01-24.
//

import Foundation



/// An object which is identifiable on a SHELF
public protocol ShelfIdentifiable: Identifiable {
    
    /// The identifier for this object.
    ///
    /// This must be universally-unique; SHELF is an object-storage framework so all objects are equal in its eyes
    var id: ShelfId { get }
}
