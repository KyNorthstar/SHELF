//
// test conveniences.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import SHELF



struct SimpleObject: ShelfData, Equatable {
    let id: ShelfId
    var name: String?
    
    init(id: ShelfId) {
        self.id = id
        self.name = nil
    }
    
    init(id: ShelfId = .init(), name: String) {
        self.id = id
        self.name = name
    }
}
