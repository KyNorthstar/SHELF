//
// URL + constants.swift
//
// Written by Ky on 2024-11-25.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public extension URL {
    
    /// This is the name of the subdirectory where the object store is located
    @inlinable
    static var objectStoreDefaultDirectoryName: String { ".object store" }
    
    
    /// This is the name of the file where the config is located within an object store
    @inlinable
    static var objectStoreDefaultConfigFileName: String { ".shelf config" }
}



public extension URL {
    
    /// The subdirectory of the object store in this directory
    ///
    /// This assumes that this current URL is a directory and contains an object store which is using the default object store name.
    ///
    /// Assuming this URL points to a directory which might contain a SHELF object store, this var appends the name of the subdirectory where the object store is located
    var defaultObjectStoreDirectory: Self {
        appending(component: Self.objectStoreDefaultDirectoryName, directoryHint: .isDirectory)
    }
    
    /// The config file in this object store directory
    ///
    /// This assumes that this current URL is an object store database directory and contains a config file which is using the default SHELF config file name.
    ///
    /// Assuming this URL points to a SHELF object store directory, this var appends the name of the file inside it where the config file is located
    var defaultConfigFile: Self {
        appending(component: Self.objectStoreDefaultConfigFileName, directoryHint: .notDirectory)
    }
}
