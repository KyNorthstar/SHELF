//
// ShelfConfig.swift
//
// Written by Ky on 2024-11-14.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import UuidTools



/// Configuration for SHELF
///
/// Use this when you need to tweak the behvior of SHELF
///
/// - SeeAlso: ``ShelfContext``
public struct ShelfConfig: Sendable, Codable {
    
    /// Where the object store lives
    public var storageLocation: StorageLocation
    
    /// Initialize a config
    /// - Parameter storageLocation: _optional_ - Where you want the SHELF object store database to be located.
    ///                              If omitted, a reasonable default is used. Future implementations might take omission to mean "automatically detect"
    public init(storageLocation: StorageLocation? = nil) {
        self.storageLocation = storageLocation ?? .defaultOnDrive
    }
}



public extension __ShelfContextProtocol {
    typealias Config = ShelfConfig
}



// MARK: - Constant(s)

public extension ShelfConfig {
    
    /// The ID that a SHELF config uses by default: `45F23C5F-2468-464D-976F-4C1DD20DEB19`.
    ///
    /// You can specify one if you want to, but if you don't, it'll always be this.
    ///
    /// This isn't a specific magical or special UUID or anthing like that; We literally generated it while writing this file.
    static let defaultId = ShelfId(rawValue: UUID(uuid: (0x45,0xF2,0x3C,0x5F, 0x24,0x68, 0x46,0x4D, 0x97,0x6F, 0x4C,0x1D,0xD2,0x0D,0xEB,0x19)))
}



// MARK: - Subtypes

public extension ShelfConfig {
    enum StorageLocation: Codable, Sendable {
        
        /// This location means that all the SHELF data will be sored in (and read from) memory.
        /// Any data persisted to the drive in previous runs will neither be read, nor overwritten.
        /// Changes will still occur and the in-memory database will behave exactly like a persisted one, except none of the data will be saved and future runs will not be able to access any of it.
        case onlyInMemory
        
        
        /// This location is what most people might expect: SHELF will read data from an object-storage database persisted to the drive, and all changes will be written to it.
        ///
        /// - Parameter directory: A local file url (`file:///Path/to/store/`) pointing to the directory where the object store is persisted
        case local(DriveLocation)
        
        
        /// The default on-drive location for the object store.
        ///
        /// This is what most applications should use by default in production, and is what fills documentation
        static var defaultOnDrive: Self { .local(.defaultObjectStoreDirectory) }
    }
}



// MARK: - Default configs

public extension ShelfConfig {
    
    /// Create a new SHELF config, with pre-set values matching the given semantic paradigm.
    ///
    /// If you wanna set these values yourself, you should probably use initializers that let you do that instead of this one.
    /// Or don't. I'm a doc comment, not a cop.
    ///
    /// - Parameter paradigm: The semantic paradigm describing the reason you want to create a new SHELF config.
    init(paradigm: NewConfigParadigm) {
        self.init(
            storageLocation: paradigm.storageLocation
        )
    }
    
    
    /// A default paradigm for why you'd want a SHELF config
    enum NewConfigParadigm {
        
        /// The golden path is the way SHELF is meant to be used
        case goldenPath
        
        /// Devs are encouraged to explicitly set a `shelfContext`. if they don't, then this paradigm applies
        case devNeverExplicitlySetContext
    }
}



private extension ShelfConfig.NewConfigParadigm {
    /// A UUID appropriate for this paradigm
    var id: ShelfId {
        switch self {
        case .goldenPath,
                .devNeverExplicitlySetContext:
                .init()
        }
    }
    
    
    /// The storage location that this paradigm prescribes
    var storageLocation: ShelfConfig.StorageLocation {
        switch self {
        case .goldenPath:                   .defaultOnDrive
        case .devNeverExplicitlySetContext: .onlyInMemory
        }
    }
}



internal extension ShelfConfig.NewConfigParadigm {
    
    /// Whether this paradigm aligns with preferring to load pre-existing configurations
    var preferLoadingPastConfig: Bool {
        switch self {
        case .goldenPath:                   true
        case .devNeverExplicitlySetContext: false
        }
    }
}



// MARK: - Loading

internal extension ShelfConfig {
    
    /// Attempts to load the existing config at the given location.
    ///
    /// Of course, the given location must point to the whole SHELF database, not just the one config file within it. After all, the point of this function is to find the config in a given database.
    ///
    /// - Parameter storageLocation: Where to expect a SHELF object store, to load the config from
    ///
    /// - Parameters:
    ///   - storageLocation: Where to expect a SHELF object store, to load the config from
    ///                      This shouldn't be a SHELF store itself, but instead _contain_ the SHELF store as a subdirectory.
    ///                      For example, if the SHELF store is at `~/Library/Application Support/MyCoolApp/.object store`, then this would be `~/Application Support/MyCoolApp/`
    ///   - storeName:       _optional_ - The name of the SHELF store's root directory. Not all locations support this (e.g. only-in-memory doesn't name its store)
    ///                      Omit to use the default store root dir name.
    ///                      For example, if the SHELF store is at `~/Library/Application Support/MyCoolApp/.object store`, then   this would be `.object store`
    ///   - configName:      _optional_ - The name of the SHELF store's config file. Not all locations support this (e.g. only-in-memory doesn't name its config)
    ///                      Omit to use the default config file name.
    ///                      For example, if the SHELF store's config is at `~/Library/Application Support/MyCoolApp/.object   store/.shelf config`, then this would be `.shelf config`
    ///
    /// - Throws: A ``ShelfConfig/LoadError`` iff any issue occurs loading the config
    ///
    /// - Returns: The config found at the given location, or `nil` if no such config exists
    init?(loadingFrom storageLocation: StorageLocation,
          storeName: String? = nil,
          configName: String? = nil)
    async throws(LoadError) {
        switch storageLocation {
        case .local(let driveLocation):
            guard let loaded = try await LocalDriveShelfSerializer.config(at: driveLocation,
                                                                          storeName: storeName,
                                                                          configName: configName)
            else {
                return nil
            }
            
            self = loaded
            
        case .onlyInMemory:
            return nil
        }
    }
    
    
    
    enum LoadError: Error {
        
        /// The config file definitely exists, but it isn't readable
        case unreadable(cause: any Error)
        
        /// The config file exists and we could read its content, but couldn't parse its content into a ``ShelfConfig``.
        ///
        /// This is most likely a migration bug, where the content is missing something this version expects, ence the name `incompatible`.
        /// However, this can also be due to bitrot and other corruptions, or a user manually editing it, or many other things that can affect a file's content.
        case incompatible(cause: any Error)
    }
}
