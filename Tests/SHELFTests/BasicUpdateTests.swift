//
// BasicUpdateTests.swift
//
// Written by Ky on 2025-11-23.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import Testing

import SHELF


struct BasicUpdateTests {
    
    /// Ensure basic writing & updating from a database works
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation()),
    ] as [ShelfConfig.StorageLocation])
    func writeAndUpdateSimpleData(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        let testObject_arc = SimpleObject(name: "Arc")
        try await shelf.save(testObject_arc)
        try await shelf.update(objectWithId: testObject_arc.id, ofType: SimpleObject.self) {
            $0.name = "Arcanum"
        }
        onObjectNotFound: {
            Issue.record("Failed to find an object to update")
        }
        var retrieved: SimpleObject = try #require(try await shelf.object(withId: testObject_arc.id))
        #expect(retrieved.name == "Arcanum")
        
        let testObject_chris = SimpleObject(name: "Chris")
        try await shelf.save(testObject_chris)
        try await shelf.update(objectWithId: testObject_chris.id, ofType: SimpleObject.self) {
            $0.name = "Christopher"
        }
        onObjectNotFound: {
            Issue.record("Failed to find an object to update")
        }
        retrieved = try #require(try await shelf.object(withId: testObject_chris.id))
        #expect(retrieved.name == "Christopher")
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
            let reversedString = String(difficultString.reversed())
            try await shelf.update(objectWithId: testObject.id, ofType: SimpleObject.self) {
                $0.name = reversedString
            }
            onObjectNotFound: {
                Issue.record("Failed to find an object to update")
            }
            retrieved = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrieved.name == reversedString)
        }
        
        for i in (0...10_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
            let changedName = "Updated Name for Generated Test Object #\(i)"
            try await shelf.update(objectWithId: testObject.id, ofType: SimpleObject.self) {
                $0.name = changedName
            }
            onObjectNotFound: {
                Issue.record("Failed to find an object to update")
            }
            retrieved = try #require(try await shelf.object(withId: testObject.id))
            #expect(retrieved.name == changedName)
        }
    }
    
    
    /// Ensure complex writing & updating from a database works
    @Test(arguments: [
        ShelfConfig.StorageLocation.onlyInMemory,
        .local(.newTestLocation()),
    ])
    func writeAndUpdateComplexData(storageLocation: ShelfConfig.StorageLocation) async throws {
        print(storageLocation)
        var shelf = await Shelf(at: storageLocation)
        
        for i in 0..<1_000 {
            // Generate a new random object and save it
            let initialObject = ComplexObject.random()
            let id = initialObject.id
            try await shelf.save(initialObject)
            
            // Prepare the values we’ll apply inside the closure
            let newInteger          = initialObject.integer + 1
            let newString           = initialObject.string.appending("_updated")
            let newOptionalString   = Bool.random() ? "Now" : nil
            let newArray            = Array(initialObject.arrayOfInts.reversed())
            let newDictionary       = initialObject.dictionaryOfStrings.merging(["newKey": "newValue"], uniquingKeysWith: { $1 })
            let newSet              = initialObject.setOfDoubles.union([999.99])
            let newNested           = ComplexObject.NestedStruct(name: "Replaced", value: 42.0, metadata: ["key": "value"])
            let newEnum             = ComplexObject.NestedEnum.complex(name: "EnumUpdated", count: i)
            let newBoolean          = !initialObject.boolean
            
            // Run the update in place
            try await shelf.update(objectWithId: initialObject.id, ofType: ComplexObject.self) {
                $0.integer             = newInteger
                $0.string              = newString
                $0.optionalString      = newOptionalString
                $0.arrayOfInts         = newArray
                $0.dictionaryOfStrings = newDictionary
                $0.setOfDoubles        = newSet
                $0.nestedStruct        = newNested
                $0.enumValue           = newEnum
                $0.boolean             = newBoolean
            }
            onObjectNotFound: {
                Issue.record("Failed to find the test object with id \(id)")
            }
            
            // Fetch and verify that everything changed as expected
            let updatedObject: ComplexObject = try #require(try await shelf.object(withId: initialObject.id))
            
            #expect(updatedObject.integer == newInteger)
            #expect(updatedObject.string == newString)
            #expect(updatedObject.optionalString == newOptionalString)
            #expect(updatedObject.arrayOfInts == newArray)
            #expect(updatedObject.dictionaryOfStrings == newDictionary)
            #expect(updatedObject.setOfDoubles == newSet)
            #expect(updatedObject.nestedStruct == newNested)
            #expect(updatedObject.enumValue == newEnum)
            #expect(updatedObject.boolean != initialObject.boolean)  // we flipped the bool
        }
        
        for i in (0...10_000) {
            let largeObject = ComplexObject.random()
            try await shelf.save(largeObject)
            
            // Update just the `integer` and the `string` for variety
            let newInt   = largeObject.integer + 999
            let newStr   = largeObject.string + "_\(i)"
            
            try await shelf.update(objectWithId: largeObject.id, ofType: ComplexObject.self) {
                $0.integer = newInt
                $0.string  = newStr
            } onObjectNotFound: {
                Issue.record("Failed to find object at iteration \(i)")
            }
            
            // Quick sanity check
            let latest: ComplexObject = try #require(try await shelf.object(withId: largeObject.id))
            #expect(latest.integer == newInt)
            #expect(latest.string  == newStr)
        }
    }
}
