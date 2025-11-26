//
// DriveLocation.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// A location on a machine's persistent data drive
public enum DriveLocation: Codable, Sendable {
    
    /// A location on the drive identified by its purpose, rather than by some explicit path
    case semantic(Semantic, subpath: String)
    
    /// A location on the drive at the given file path.
    ///
    /// This should only be used when reading from an existing object store at a known existing location.
    /// You should not use this to find a place to create a new object store.
    case explicit(path: String)
}



// MARK: - Supporting Types

public extension DriveLocation {
    
    /// Represents a location on the drive by its purpose, rather than by some explicit path
    enum Semantic: String, Codable, Sendable {
        /// This platform's default location where this program is supposed to store data
        ///
        /// Like `%APPDATA%` on Windows, or `~/Libraries/Application Support/` on macOS.
        ///
        /// This automatically adapts to conditions such as sandboxing to always refer to the most-correct place
        case thisProgramDataDirectory
    }
}



// MARK: - API: Conveniences

public extension DriveLocation {
    
    /// The best location to keep an application's object store on this platform.
    static var defaultObjectStoreDirectory: Self {
        .semantic(.thisProgramDataDirectory, subpath: URL.objectStoreDefaultDirectoryName)
    }
}



// MARK: - Resolution

internal extension URL {
    
    /// Resolves the given drive location into a URL
    ///
    /// - Parameter driveLocation: A location on the machine's persistent data drive
    init(_ driveLocation: DriveLocation) {
        switch driveLocation {
        case .semantic(let semantic, let subpath):
            self = Self.init(semantic).appending(path: subpath.trimmingPrefix(/[\\\/]/))
            
        case .explicit(let path):
            self.init(filePath: path)
        }
    }
}
