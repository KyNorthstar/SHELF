//
// SingleItemDeletionTests.swift
//
// Written by Ky on 2024-11-24.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//


import Testing

import SHELF



struct SingleItemDeletionTests {
    
    /// Ensure the golden-path whole-database deletion succeeds
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation()),
    ] as [ShelfConfig.StorageLocation])
    func deleteOneValue(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        let deletableMe = SimpleObject(name: "Gru")
        try await shelf.save(deletableMe)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
        }
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
        }
        
        try await shelf.delete(objectWithId: deletableMe.id)
        
        let retrieved: SimpleObject? = try await shelf.object(withId: deletableMe.id)
        #expect(nil == retrieved)
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
            let retrieved: SimpleObject? = try await shelf.object(withId: testObject.id)
            #expect(testObject == retrieved)
        }
    }
}
