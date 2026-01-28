//
//  GenericStringCodingKey.swift
//  SHELF
//
//  Created by Ky on 2026-01-27.
//

import Foundation



struct GenericStringCodingKey: CodingKey {
    let stringValue: String
    
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    
    init?(intValue: Int) { nil }
    
    
    var intValue: Int? { nil }
}



// MARK: - special keys

extension GenericStringCodingKey {
    static func shelfSpecialKey(uniqueString: String) -> Self {
        // "73O476YkTCKuBdMKveV0rA" -> ")73O476YkTCKuBdMKveV0rA'{"
        .init(stringValue: ")\(uniqueString)'{")
    }
    
    
    var fromShelfSpecialKey: String {
        // ")73O476YkTCKuBdMKveV0rA'{" -> "73O476YkTCKuBdMKveV0rA"
        stringValue.replacing(/^\)(?<id>.+)\'\{/) { match in
            match.output.id
        }
    }
}
