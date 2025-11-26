//
// BasicReadWriteTests.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import Testing

import SHELF



struct BasicReadWriteTests {
    
    /// Ensure basic writing & reading from a database works
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation()),
    ] as [ShelfConfig.StorageLocation])
    func writeAndReadSimpleData(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        let testObject_arc = SimpleObject(name: "Arc")
        try await shelf.save(testObject_arc)
        var retrieved: SimpleObject = try #require(try await shelf.object(withId: testObject_arc.id))
        #expect(retrieved == testObject_arc)
        
        let testObject_chris = SimpleObject(name: "Chris")
        try await shelf.save(testObject_chris)
        retrieved = try #require(try await shelf.object(withId: testObject_chris.id))
        #expect(retrieved == testObject_chris)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
            retrieved = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrieved == testObject)
        }
        
        for i in (0...10_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
            retrieved = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrieved == testObject)
        }
    }
    
    
    /// Ensure complex writing & reading from a database works
    @Test(arguments: [
        ShelfConfig.StorageLocation.onlyInMemory,
        .local(.newTestLocation()),
    ])
    func writeAndReadComplexData(storageLocation: ShelfConfig.StorageLocation) async throws {
        print(storageLocation)
        var shelf = await Shelf(at: storageLocation)
        
        var retrievedComplex: ComplexObject
        
        for _ in (0...10_000) {
            let testObject = ComplexObject()
            try await shelf.save(testObject)
            retrievedComplex = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrievedComplex == testObject)
        }
        
        
        var retrievedSimple: SimpleObject
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
            retrievedSimple = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrievedSimple == testObject)
        }
        
        for i in (0...10_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
            retrievedSimple = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrievedSimple == testObject)
        }
    }
}
