//
//  ShelfObjectReference.swift
//  SHELF
//
//  Created by Ky on 2026-01-27.
//

import Foundation



/// A reference to another SHELF object.
///
/// When saved, this is encoded as an object with a single key-value pair. The key is always the same value (`")m80uo4mTQVCIsNF7GCD4KQ'{"`), and the value is always the SHELF ID of the referenced object.
///
/// For example, a reference to an object with ID `j1ZjJi7pRdO740iC44nwJw` would encode as:
/// ```json
/// {")m80uo4mTQVCIsNF7GCD4KQ'{":"j1ZjJi7pRdO740iC44nwJw"}
/// ```
public struct ShelfObjectReference<ObjectType: ShelfData>: ShelfData { // TODO: Test
    public let id: ShelfId
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
        by updater: @Sendable (inout ObjectType) async throws -> Void,
        onObjectNotFound: Shelf.ObjectNotFoundFunction<ObjectType>)
    async throws(Shelf.UpdateError) { // TODO: Test
        try await shelf.update(objectWithId: id, ofType: ObjectType.self, by: updater, onObjectNotFound: onObjectNotFound)
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
        try container.encode(id.rawValue, forKey: .otherShelfObjectReference)
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
