//
// WholeDatabaseDeletionTests.swift
//
// Written by Ky on 2024-11-24.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import Testing

import SHELF



struct WholeDatabaseDeletionTests {
    
    /// Ensure the golden-path whole-database deletion succeeds
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation(named: "DELETEME")),
    ] as [ShelfConfig.StorageLocation])
    func deleteWholeDatabase(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
        }
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
        }
        
        try await MainActor.run {
            var token = try shelf.nuke_whole_database_DANGEROUS()
            token.imSure(oath: """
            I understand that this action will permanently delete all data in this SHELF database.
            This cannot be undone once I pass this token back.
            I vow that this decision is the most correct for this situation, and there is no better choice I could make in this moment.
            
            Black sphinx of quartz, judge my vow.
            """)
            
            try shelf.nuke_whole_database_DANGEROUS(token: token)
        }
    }
    
    
    /// If the dev doesn't provide the proper oath, the delete operation fails
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation(named: "DELETEME")),
    ] as [ShelfConfig.StorageLocation])
    func failToDeleteWholeDatabase_badOath(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
        }
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
        }
        
        try await MainActor.run {
            var token = try shelf.nuke_whole_database_DANGEROUS()
            token.imSure(oath: """
            Not the right oath!
            """)
            
            try #require(throws: Shelf.WholeDatabaseDeleteError.self) {
                try shelf.nuke_whole_database_DANGEROUS(token: token)
            }
        }
    }
    
    
    /// If the dev makes it so more than 60 seconds pass before sending the token back, the delete operation fails
    @Test(arguments: [
            .onlyInMemory,
            .local(.newTestLocation(named: "DELETEME")),
          ] as [ShelfConfig.StorageLocation])
    func failToDeleteWholeDatabase_tookTooLong(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
        }
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
        }
        
        try await MainActor.run {
            var token = try shelf.nuke_whole_database_DANGEROUS()
            token.imSure(oath: """
            I understand that this action will permanently delete all data in this SHELF database.
            This cannot be undone once I pass this token back.
            I vow that this decision is the most correct for this situation, and there is no better choice I could make in this moment.
            
            Black sphinx of quartz, judge my vow.
            """)
            
            Thread.sleep(forTimeInterval: 65)
            
            try #require(throws: Shelf.WholeDatabaseDeleteError.self) {
                try shelf.nuke_whole_database_DANGEROUS(token: token)
            }
        }
    }
    
    
    /// If a token is created and properly filled-out in-time, but another one was created an improperly handled in the meantime, the good token should fail too.
    @Test(arguments: [
        .onlyInMemory,
        .local(.newTestLocation(named: "DELETEME")),
    ] as [ShelfConfig.StorageLocation])
    func failToDeleteWholeDatabase_failureInterruptions(storageLocation: ShelfConfig.StorageLocation) async throws {
        var shelf = await Shelf(at: storageLocation)
        
        for difficultString in difficultStrings {
            let testObject = SimpleObject(name: difficultString)
            try await shelf.save(testObject)
        }
        
        for i in (0...1_000) {
            let testObject = SimpleObject(name: "Generated Test Object #\(i)")
            try await shelf.save(testObject)
        }
        
        try await MainActor.run {
            var badOathToken = try shelf.nuke_whole_database_DANGEROUS()
            var perfectToken = try shelf.nuke_whole_database_DANGEROUS()
            badOathToken.imSure(oath: """
            Nor the right oath!
            """)
            perfectToken.imSure(oath: """
            I understand that this action will permanently delete all data in this SHELF database.
            This cannot be undone once I pass this token back.
            I vow that this decision is the most correct for this situation, and there is no better choice I could make in this moment.
            
            Black sphinx of quartz, judge my vow.
            """)
            
            try #require(throws: Shelf.WholeDatabaseDeleteError.self) {
                try shelf.nuke_whole_database_DANGEROUS(token: badOathToken)
            }
            
            try #require(throws: Shelf.WholeDatabaseDeleteError.self) {
                try shelf.nuke_whole_database_DANGEROUS(token: perfectToken)
            }
        }
    }
}
