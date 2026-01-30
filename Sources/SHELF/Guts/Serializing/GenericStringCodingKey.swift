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
    /// Creates a special key containing the given unique string.
    ///
    /// A special key is a key within any SHELF object which has special meaning to the specific application using it.
    /// These are to be used as keys in a key-value pair.
    ///
    /// For example, SHELF uses a special key to mark which fields are just SHELF IDs referencing other SHELF objects, since those can appear inside any SHELF object.
    ///
    /// The special key has characters at the start and end of the unique string, which act as delimiters so that SHELF can tell that this is a special key, rather than any object key. The starting character is the Korean letter `ㅅ`, and the ending characters are the Ethiopic section mark `፠` followed by the single left quotation mark `‘`. These characters were chosen solely lbecause they're unlikely to be paired together as the start and end characters of a key string, but using something like `__SHELF_SPECIAL_KEY__` would be an irresponsibly large amount of characters for something which might be repeated many times per SHELF object.
    /// Using these charactesr also helps guarantee that any parser must support full Unicode.
    ///
    /// For example, if a special key's unique string is `XXXXX`, then the special key would be "ㅅXXX፠‘"
    ///
    /// - Parameter uniqueString: Any string at all, long as you can guarantee it uniquely represents your usecase. It's recommended that this is a B64-encoded UUID
    /// - Returns: The given unique string, converted to a SHELF special key
    static func shelfSpecialKey(uniqueString: String) -> Self {
        // "73O476YkTCKuBdMKveV0rA" -> "ㅅ73O476YkTCKuBdMKveV0rA፠‘"
        .init(stringValue: "ㅅ\(uniqueString)፠‘")
    }
    
    
    /// Assuming this is a SHELF special key, this returns the unique string within it.
    ///
    /// See the documentation for ``shelfSpecialKey(uniqueString:)`` for more info on SHELF special keys.
    var fromShelfSpecialKey: String {
        // "ㅅ73O476YkTCKuBdMKveV0rA፠‘" -> "73O476YkTCKuBdMKveV0rA"
        stringValue.replacing(/^ㅅ(?<id>.+)፠‘/) { match in
            match.output.id
        }
    }
}
