//
// identifiers.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import UuidTools



/// A thin wrapper around UUID, allowing some sugar & consistency needed for SHELF.
///
/// This encodes/decodes as a string representation of a UUID, but in Base64 with the trailing `==` removed.
///
/// For example, the following struct will be serialized like this:
/// ```swift
/// struct MyData: ShelfData {
///     let id: ShelfId // let's say this is 2D3FB6B6-090D-4FBD-8AC2-428DC536FFE8
///     let message = "Hello, World!"
/// }
/// ```
/// ```json
/// {
///     "id": "LT+2tgkNT72KwkKNxTb/6A",
///     "message": "Hello, World!"
/// }
/// ```
public struct ShelfId: Sendable, RawRepresentable {
    public let rawValue: UUID
    
    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}



public extension ShelfId {
    init() {
        self.init(rawValue: .init())
    }
    
    // TODO: A way to generate an ID that isn't currently used
}



// MARK: - Codable

extension ShelfId: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.format(as: .truncatedBase64))
    }
}



extension ShelfId: Decodable {
    public init(from decoder: any Decoder) throws {
        let uuidString = try decoder.singleValueContainer().decode(String.self)
        self.init(rawValue: try .init(uuidString, format: .truncatedBase64))
    }
}



// MARK: - Identifiable

extension ShelfId: Identifiable {
    public var id: RawValue { rawValue }
}



// MARK: - Hashable

extension ShelfId: Hashable {
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}



// MARK: LosslessStringConvertible

extension ShelfId: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let uuid = try? UUID(description) else {
            return nil
        }
        self.rawValue = uuid
    }
    
    
    public var description: String {
        self.rawValue.format(as: .truncatedBase64)
    }
}
