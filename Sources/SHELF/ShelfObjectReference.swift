//
// ShelfObjectReference.swift
//
// Written by Ky on 2026-01-27.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// A reference to another SHELF object.
///
/// When saved, this is encoded as an object with a single key-value pair. The key is always the same value (`"ㅅm80uo4mTQVCIsNF7GCD4KQ፠‘"`), and the value is always the SHELF ID of the referenced object.
///
/// For example, a reference to an object with ID `j1ZjJi7pRdO740iC44nwJw` would encode as:
/// ```json
/// {"ㅅm80uo4mTQVCIsNF7GCD4KQ፠‘":"j1ZjJi7pRdO740iC44nwJw"}
/// ```
public struct ShelfObjectReference<ObjectType: ShelfData>: ShelfData { // TODO: Test
    public typealias ObjectType = ObjectType
    public let id: ShelfId
    
    
    public init(id: ShelfId) {
        self.id = id
    }
}



// MARK: - Resolution sugar

public extension ShelfObjectReference {
    /// Resolve this reference into a concrete object.
    ///
    /// This works identical to ``Shelf/object(withId:)``
    ///
    /// - SeeAlso: ``ShelfObjectReference/shelfObjectReference`` to convert the into a reference to the persisted SHELF data
    ///
    /// - Parameter shelf: The Shelf instance which will resolve the object
    /// - Returns: The resolved object
    func resolve(using shelf: Shelf) async throws(Shelf.ReadError) -> ObjectType? {
        try await shelf.object(withId: id)
    }
}



// MARK: - Mutation sugar

public extension ShelfObjectReference {
    
    /// Update the SHELF object that this references
    /// 
    /// - Parameters:
    ///   - shelf:            The Shelf which will perform the update process
    ///   - updater:          The function which specifies the update
    ///   - onObjectNotFound: _optional_ - The function which
    mutating func update(
        in shelf: inout Shelf,
        by updater: Shelf.ObjectUpdateFunction<ObjectType>,
        onObjectNotFound: Shelf.ObjectNotFoundFunction<ObjectType>)
    async throws(Shelf.UpdateError) { // TODO: Test
        try await shelf.update(objectWithId: id, ofType: ObjectType.self, by: updater, onObjectNotFound: onObjectNotFound)
    }
}



// MARK: - Conversion sugar

public extension ShelfData {
    
    /// Converts this to a reference to its location in SHELF.
    ///
    /// - SeeAlso: ``ShelfObjectReference/resolve(using:)`` to convert the reference back into in-memory data
    var shelfObjectReference: ShelfObjectReference<Self> {
        .init(id: self.id)
    }
}



public extension ShelfId {
    
    /// Converts this ID to a reference to the object stored at the given ID, which unlocks a few more capabilities without needing to load the whole object into memory.
    func shelfObjectReference<Object: ShelfData>() -> ShelfObjectReference<Object> {
        .init(id: self)
    }
}



// MARK: - Special values

public extension ShelfObjectReference {
    /// Discouraged; use `Optional`/`nil` instead whenever possible.
    ///
    /// This is a placeholder when there is no object to reference
    static var null: Self {
        .init(id: .null)
    }
}



// MARK: - Codable

private extension GenericStringCodingKey {
    static var otherShelfObjectReference: Self { .shelfSpecialKey(uniqueString: "m80uo4mTQVCIsNF7GCD4KQ") }
}



private extension ShelfObjectReference {
    typealias CodingKeys = GenericStringCodingKey
}



extension ShelfObjectReference: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GenericStringCodingKey.self)
        try container.encode(id, forKey: .otherShelfObjectReference)
    }
}



extension ShelfObjectReference: Decodable {
    public init(from decoder: Decoder) throws(DecodeError) {
        let container: KeyedDecodingContainer<GenericStringCodingKey>
        do {
            container = try decoder.container(keyedBy: GenericStringCodingKey.self)
        }
        catch {
            throw .noContainer
        }
        
        let idString: String
        do {
            idString = try container.decode(String.self, forKey: .otherShelfObjectReference)
        }
        catch {
            throw .noObjectReference
        }
        
        self.id = try ShelfId(idString).unwrappedOrThrow(error: DecodeError.invalidShelfId)
    }
    
    
    
    public enum DecodeError: Error {
        case noContainer
        case noObjectReference
        case invalidShelfId
    }
}



// MARK: - Equatable

extension ShelfObjectReference: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}



// MARK: - Hashable

extension ShelfObjectReference: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



// MARK: - RawRepresentable

extension ShelfObjectReference: RawRepresentable {
    public typealias RawValue = ShelfId
    
    
    @inline(__always)
    public init(rawValue: ShelfId) {
        self.init(id: rawValue)
    }
    
    
    @inline(__always)
    public var rawValue: ShelfId { id }
}
