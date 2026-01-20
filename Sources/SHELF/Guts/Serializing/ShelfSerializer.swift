//
// ShelfSerializer.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import OSLog



/// Something whose only job is to read/write SHELF objects to/from a SHELF object store
internal protocol ShelfSerializer: Sendable {
    
    /// Attempts to find the raw data of the SHELF object with the given ID.
    ///
    /// Types conforming to this protocol are required to implement this, but callers interacting with this protocol are discouraged from using it.
    /// Instead, callers should use ``read(objectWithId:)``, which deals with typechecked objects rather than raw data
    ///
    /// - Parameter id: The ID of the object to search for
    /// - Returns: The raw data of the object with the given ID, or `nil` if no such object is present in the store
    /// - Throws: A ``ReadError`` if any error occurs while attempting to read the raw data from the store
    @available(*, renamed: "read(objectWithId:)", message: "Direct usage of this function is discouraged. Instead, use `read(objectWithId:)`, which automatically manages deserialization & identifier juggling")
    func __read(rawDataForObjectWithId id: ShelfId) async throws(Shelf.ReadError) -> Data?
    
    
    /// Attempts to write the given pre-serialized SHELF object to the store.
    ///
    /// Types conforming to this protocol are required to implement this, but callers interacting with this protocol are discouraged from using it.
    /// Instead, callers should use ``write(object:)``, which deals with typechecked objects rather than raw data
    ///
    /// - Attention: The given data _**MUST**_ be a serialized `ShelfData` instance.
    ///     SHELF assumes this, and can break if that's not true.
    ///     Because of this, We recommend you **use ``write(object:)`` instead** of using this function directly.
    ///
    /// - Parameters:
    ///   - rawObjectData: The raw data content of the object to save in the store. This _**must always**_ be pre-serialized ``ShelfData``
    ///   - id:            The ID of the object to store. This will also be duplicated in the `objectData` because `objectData` _**must always**_ be serialized ``ShelfData``
    /// - Throws: A ``WriteError`` if any error occurs while attempting to write the data to the store
    @available(*, renamed: "write(object:)", message: "Direct usage of this function is discouraged. Instead, use `write(object:)`, which automatically manages serialization & identifier juggling")
    mutating func __write(rawObjectData: Data, withId id: ShelfId) async throws(Shelf.WriteError)
    
    
    /// Attempts to update the raw data of a SHELF object with the given ID.
    ///
    /// Types conforming to this protocol are required to implement this, but callers interacting with this protocol are discouraged from using it.
    /// Instead, callers should use ``update(objectWithId:by:onObjectNotFound:)``, which deals with typechecked objects rather than raw data
    ///
    /// - Parameters:
    ///   - id:        The ID of the object to update
    ///   - transform: This function is passed the raw data within the store.
    ///                If it's passed `nil`, then the store did not contain anything at `id`.
    ///                If it returns `nil`, then no action will be taken on the data at `id`.
    ///                **Important:** Returnning `nil` DOESN'T mean "delete this object"; it means "do nothing".
    ///                To delete an object, use the ``delete(objectWithId:)`` function.
    @available(*, renamed: "update(objectWithId:_:)", message: "Direct usage of this function is discouraged. Instead, use `read(objectWithId:)`, which automatically manages deserialization & identifier juggling")
    mutating func __update(rawDataForObjectWithId id: ShelfId, by transform: @Sendable (Data?) async throws(Shelf.UpdateError) -> Data?) async throws(Shelf.UpdateError)
    
    
    /// Attempts to delete the a SHELF object from the store with the given ID.
    ///
    /// - Parameters:
    ///   - id: The ID of the object to delete
    ///
    /// - Throws: A ``DeleteError`` if any error occurs while attempting to delete the object from the store
    mutating func delete(objectWithId id: ShelfId) async throws(Shelf.DeleteError)
    
    
    /// Attempts to delete the entire object store database.
    ///
    /// - Attention: You _**MUST**_ use `delete_all_data__DANGEROUS__()` instead of this function.
    ///
    /// - Throws: A ``WholeDatabaseDeleteError`` if an attempt to delete the whole database failed
    @available(*, renamed: "delete_all_data__DANGEROUS__()", message: "Direct usage of this function is not allowed. Instead, use `delete_all_data__DANGEROUS__()` if you must delete the database.")
    @MainActor
    mutating func __deleteAllData() throws(Shelf.WholeDatabaseDeleteError)
}



// MARK: - C

internal extension ShelfSerializer {
    /// Attempts to write the given SHELF object to the store.
    ///
    /// - Parameter object: The object to save in the store.
    /// - Throws: A ``WriteError`` if any error occurs while attempting to write the object from the store
    mutating func write<Object: ShelfData>(object: Object) async throws(Shelf.WriteError) {
        let data: Data
        
        do {
            data = try object.jsonData()
        }
        catch {
            throw .couldNotSerializeObject(cause: error)
        }
        
        try await __write(rawObjectData: data, withId: object.id)
    }
}



// MARK: - R

internal extension ShelfSerializer {
    /// Attempts to find & parse the SHELF object with the given ID
    ///
    /// - Parameter id: The ID of the object to search for
    /// - Returns: The object with the given ID, or `nil` if no such object is present in the store
    /// - Throws: A ``ReadError`` if any error occurs while attempting to read the object from the store
    func read<Object: ShelfData>(objectWithId id: ShelfId) async throws(Shelf.ReadError) -> Object? {
        guard let rawData = try await __read(rawDataForObjectWithId: id) else {
            return nil
        }
        
        do {
            return try Object(jsonData: rawData)
        }
        catch {
            throw .couldNotParseObject(cause: error)
        }
    }
}



// MARK: - U

internal extension ShelfSerializer {
    /// Attempts to find & update the SHELF object with the given ID via the given function
    ///
    /// - Parameters:
    ///   - id:               The ID of the object to update
    ///   - transform:        Called if the object was found. This function is passed the object, allowed to mutate it, and then returns nothing
    ///   - onObjectNotFound: Called if the object was not found. This function returns a value describing how the situation should be handled.
    ///
    /// - Throws: An ``UpdateError`` if any error occurs while attempting to update the object
    mutating func update<Object: ShelfData>(
        objectWithId id: ShelfId,
        by transform: Shelf.ObjectUpdateFunction<Object>,
        onObjectNotFound: Shelf.ObjectNotFoundFunction<Object>)
    async throws(Shelf.UpdateError) {
        @Sendable
        func swiftCompilerSatiation(oldRawData: Data?) async throws(Shelf.UpdateError) -> Data? {
            
            // Check if an object was found
            
            guard let oldRawData else {
                let noObjectHandlingApproach: Shelf.ObjectNotFoundResponse<Object>
                
                do {
                    noObjectHandlingApproach = try await onObjectNotFound()
                }
                catch {
                    throw Shelf.UpdateError.updateFunctionThrewSomeError(error)
                }
                
                switch noObjectHandlingApproach {
                case .doNothing: return nil
                case .saveNewObject(let newObject):
                    do {
                        return try newObject.jsonData()
                    }
                    catch {
                        throw Shelf.UpdateError.couldNotWriteObject(cause: Shelf.WriteError.couldNotSerializeObject(cause: error))
                    }
                }
            }
            
            
            // Parse the existing object
            
            var object: Object
            
            do {
                object = try Object(jsonData: oldRawData)
            }
            catch {
                throw .couldNotReadObject(cause: .couldNotParseObject(cause: error))
            }
            
            do {
                try await transform(&object)
            }
            catch {
                throw .updateFunctionThrewSomeError(error)
            }
            
            
            // Save the transformed object
            
            let newRawData: Data
            
            do {
                newRawData = try object.jsonData()
            }
            catch {
                throw .couldNotWriteObject(cause: .couldNotSerializeObject(cause: error))
            }
            
            return newRawData
        }
        
        
        try await __update(rawDataForObjectWithId: id, by: swiftCompilerSatiation)
    }
}



// MARK: - D

// MARK: Whole-database deletion

internal extension ShelfSerializer {
    /// 🛑 Deletes all the data in this SHELF object store database.
    ///
    /// This function returns a token for database deletion.
    /// You must then call `imSure(oath:)` on that token, and pass it the following oath as a static string in your source code file:
    /// ```
    /// I understand that this action will permanently delete all data in this SHELF database.
    /// This cannot be undone once I pass this token back.
    /// I vow that this decision is the most correct for this situation, and there is no better choice I could make in this moment.
    ///
    /// Black sphinx of quartz, judge my vow.
    /// ```
    ///
    /// After you've given your oath to the token, pass the token back to `delete_all_data__DANGEROUS__(token:)` within 60 seconds.
    ///
    /// If you've properly created the token with this function, said the oath to the token, and passed the token back within 60 seconds, then the database will be deleted.
    ///
    /// - Attention: If you do not complete this ritual perfectly the first time, a `.fault`-level message will be logged describing the reason the ritual failed
    @MainActor
    mutating func delete_all_data__DANGEROUS__() throws(Shelf.WholeDatabaseDeleteError) -> WholeDatabaseDeletionConfirmationToken {
        let token = WholeDatabaseDeletionConfirmationToken()
        wholeDatabaseDeleteConfirmationTokens.insert(token)
        return token
    }
    
    
    /// 🛑 Deletes all the data in this SHELF object store database.
    ///
    /// See the documentation for `delete_all_data__DANGEROUS__()` to understand how this function works.
    @MainActor
    mutating func delete_all_data__DANGEROUS__(token: WholeDatabaseDeletionConfirmationToken) throws(Shelf.WholeDatabaseDeleteError) {
        defer { wholeDatabaseDeleteConfirmationTokens = [] }
        
        // Ensure that the token was created by `delete_all_data__DANGEROUS__()`
        guard wholeDatabaseDeleteConfirmationTokens.contains(token) else {
            Logger().log(level: .fault, "Dev attempted to delete all data in a SHELF store without using a valid delete token.")
            throw .badDeleteToken
        }
        
        // Ensure that the developer has taken the oath
        guard token.oath?.description == """
            I understand that this action will permanently delete all data in this SHELF database.
            This cannot be undone once I pass this token back.
            I vow that this decision is the most correct for this situation, and there is no better choice I could make in this moment.
            
            Black sphinx of quartz, judge my vow.
            """
        else {
            Logger().log(level: .fault, "Dev attempted to delete all data in a SHELF store without taking the oath.")
            throw .badDeleteToken
        }
        
        // Ensure that it's been less than 60 seconds since the token was created
        guard Date.now.timeIntervalSince(token.dateCreated) < 60 else {
            Logger().log(level: .fault, "Dev attempted to delete all data in a SHELF store with an expired token.")
            throw .badDeleteToken
        }
        
        // Dev has passed all checks. Actually delete. 🫡
        try __deleteAllData()
    }
}



public struct WholeDatabaseDeletionConfirmationToken: Hashable {
    private let id = UUID()
    fileprivate let dateCreated = Date.now
    fileprivate var oath: StaticString?
    
    
    public mutating func imSure(oath: StaticString) {
        self.oath = oath
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}



@MainActor
private var wholeDatabaseDeleteConfirmationTokens: Set<WholeDatabaseDeletionConfirmationToken> = []
