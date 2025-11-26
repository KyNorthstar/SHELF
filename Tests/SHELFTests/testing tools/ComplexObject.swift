//
// Shelf tests.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import SHELF
import OptionalTools



// MARK: - Fields

struct ComplexObject {
    
    var id: ShelfId
    
    // Basic types
    var integer: Int
    var float: Float
    var double: Double
    var string: String
    var boolean: Bool
    
    // Optional values
    var optionalInteger: Int?
    var optionalString: String?
    
    // Collections
    var arrayOfInts: [Int]
    var dictionaryOfStrings: [String: String]
    var setOfDoubles: Set<Double>
    
    // Properties using nested types
    var nestedStruct: NestedStruct
    var enumValue: NestedEnum
    var arrayOfNested: [NestedStruct]
    
    // Computed property
    var computedValue: String {
        return "\(string) - \(integer)"
    }
    
    
    
    // MARK: - Common Initialization
    
    // Original initializer with default values
    init(
        id: ShelfId = .init(),
        integer: Int = .random(in: .min ... .max),
        float: Float = .random(in: .fullRange),
        double: Double = .random(in: .fullRange),
        string: String = .random(),
        boolean: Bool = .random(),
        optionalInteger: Int? = Bool.random() ? nil : .random(in: .min ... .max),
        optionalString: String? = Bool.random() ? nil : .random(),
        arrayOfInts: [Int] = (0 ... .random(in: 0 ... 99)).map { _ in .random(in: .min ... .max) },
        dictionaryOfStrings: [String: String] = ["key": "value"],
        setOfDoubles: Set<Double> = [1.0, 2.0, 3.0],
        nestedStruct: NestedStruct = .random(),
        enumValue: NestedEnum = .random(),
        arrayOfNested: [NestedStruct] = (0 ... .random(in: 0 ... 10)).map { _ in .random() }
    ) {
        self.id = id
        self.integer = integer
        self.float = float
        self.double = double
        self.string = string
        self.boolean = boolean
        self.optionalInteger = optionalInteger
        self.optionalString = optionalString
        self.arrayOfInts = arrayOfInts
        self.dictionaryOfStrings = dictionaryOfStrings
        self.setOfDoubles = setOfDoubles
        self.nestedStruct = nestedStruct
        self.enumValue = enumValue
        self.arrayOfNested = arrayOfNested
    }
}



// MARK: - Nested Types

extension ComplexObject {
    
    struct NestedStruct: Codable {
        let name: String
        let value: Double
        let metadata: [String: String]
        
        static func random() -> NestedStruct {
            return NestedStruct(
                name: String.random(length: .random(in: 1...20)),
                value: .random(in: -1000...1000),
                metadata: [
                    "randomKey": .random(length: 10),
                    "randomValue": Int.random(in: -100...100).description,
                    "randomFlag": Bool.random().description
                ]
            )
        }
    }
    
    
    
    enum NestedEnum: Codable {
        case simple
        case withValue(Int)
        case complex(name: String, count: Int)
        
        static func random() -> NestedEnum {
            switch Int.random(in: 0...2) {
            case 0: return .simple
            case 1: return .withValue(.random(in: -100...100))
            case 2: return .complex(
                name: String.random(length: .random(in: 1...15)),
                count: .random(in: 0...100)
            )
            default: return .simple
            }
        }
    }
}



// MARK: - `ShelfData`

extension ComplexObject: ShelfData {}



// MARK: - `Equatable`

extension ComplexObject: Equatable {}
extension ComplexObject.NestedStruct: Equatable {}
extension ComplexObject.NestedEnum: Equatable {}



// MARK: - Random generation

extension String {
    static let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        + difficultStrings.joined()
    
    static func random(length: UInt = .random(in: 0 ... 1312)) -> String {
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}



extension ComplexObject {
    static func random() -> ComplexObject {
        
        return ComplexObject(
            id: .init(),
            integer: Int.random(in: .min ... .max),
            float: Float.random(in: -1000...1000),
            double: Double.random(in: -1000...1000),
            string: String.random(),
            boolean: Bool.random(),
            optionalInteger: .random() ? .random(in: -1000...1000) : nil,
            optionalString: .random() ? String.random(length: .random(in: 1...20)) : nil,
            arrayOfInts: .random(),
            dictionaryOfStrings: .random(in: 0 ... 5),
            setOfDoubles: .random(),
            nestedStruct: NestedStruct.random(),
            enumValue: NestedEnum.random(),
            arrayOfNested: (0 ... .random(in: 0...5)).map { _ in .random() }
        )
    }
    
    /// A predictable constant value of this struct
    static let sample = ComplexObject(
        integer: 1312,
        float: 2.71828,
        double: .pi,
        string: "Sample String",
        boolean: true,
        optionalInteger: 42,
        optionalString: "Optional",
        arrayOfInts: [1, 2, 3, 4, 5],
        dictionaryOfStrings: ["key1": "value1", "key2": "value2"],
        setOfDoubles: [1.1, 2.2, 3.3],
        nestedStruct: NestedStruct(
            name: "Sample Nested",
            value: 999.999,
            metadata: ["type": "test", "version": "1.0"]
        ),
        enumValue: .complex(name: "Sample", count: 10),
        arrayOfNested: [
            NestedStruct(name: "First", value: 1.0, metadata: [:]),
            NestedStruct(name: "Second", value: 2.0, metadata: [:])
        ]
    )
}



// MARK: Type-extension sugar

extension Array where Element: FixedWidthInteger {
    static func random(
        length: UInt = .random(in: 0...1312),
        eachElementRange: ClosedRange<Element> = .min ... .max)
    -> Self {
        (0..<length).map { _ in .random(in: eachElementRange) }
    }
}



extension Set
where Element: BinaryFloatingPoint,
      Element.RawSignificand: FixedWidthInteger
{
    static func random(
        length: UInt = .random(in: 0...1312),
        eachElementRange: ClosedRange<Element> = .fullRange)
    -> Self {
        .init((0..<length).map { _ in .random(in: eachElementRange) })
    }
}



extension [String : String] {
    static func random(in range: ClosedRange<UInt>) -> Self {
        .init(uniqueKeysWithValues: (0 ..< UInt.random(in: range)).map { _ in
            (.random(), .random())
        })
    }
}



extension ClosedRange where Bound: BinaryFloatingPoint {
    static var fullRange: Self { -(.greatestFiniteMagnitude / 10) ... (.greatestFiniteMagnitude / 10) }
}



