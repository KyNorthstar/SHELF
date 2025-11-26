//
// ShelfConfig + ShelfSerializer.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



internal extension ShelfConfig {
    
    /// Generates a new ``ShelfSerializer`` appropriate for this config.
    ///
    /// Since this returns a brand-new serializer, it should only be called rarely. Ideally, once when the application starts.
    ///
    /// - Note: Some serializers, like ``InMemoryShelfSerializer``, contain no data when first created
    func createNewSerializer() async -> any ShelfSerializer {
        switch storageLocation {
        case .onlyInMemory:             InMemoryShelfSerializer()
        case .local(let driveLocation): LocalDriveShelfSerializer(location: driveLocation)
        }
    }
}
