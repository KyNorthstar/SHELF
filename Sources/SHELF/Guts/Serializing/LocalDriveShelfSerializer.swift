//
// LocalDriveShelfSerializer.swift
//
// Written by Ky on 2024-11-22.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// The star of the show, humbly working the magic from the booth behind the scenes. This handles persisting/retrieving objects to/from the store on the machine's local drive
internal struct LocalDriveShelfSerializer {
    
    /// File URL to the actual location of the object store that this (de)serializes
    private let resolvedLocation: URL
    
    /// Use this file manager when performing FileManager operations in this file
    private let fileManager: FileManager
}



internal extension LocalDriveShelfSerializer {
    init(location: DriveLocation, fileManager: FileManager = .default) {
        self.init(
            resolvedLocation: .init(location),
            fileManager: fileManager
        )
    }
}



extension LocalDriveShelfSerializer: ShelfSerializer {
    
    func __read(rawDataForObjectWithId id: ShelfId) async throws(Shelf.ReadError) -> Data? {
        let objectFileUrl = objectUrl(for: id)
        let objectFilePath = objectFileUrl.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: objectFilePath) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: objectFileUrl)
        }
        catch {
            throw .couldNotReadObjectFile(cause: error)
        }
    }
    
    
    mutating func __write(rawObjectData: Data, withId id: ShelfId) async throws(Shelf.WriteError) {
        // TODO: Batch into queued transactions
        
        let objectFileUrl = objectUrl(for: id)
        
        do {
            try fileManager.createDirectory(at: objectFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
            try rawObjectData.write(to: objectFileUrl, options: [.atomic])
        }
        catch {
            throw .couldNotWriteObjectFile(cause: error)
        }
    }
    
    
    mutating func __update(rawDataForObjectWithId id: ShelfId, by transform: (Data?) async throws(Shelf.UpdateError) -> Data?) async throws(Shelf.UpdateError) {
        var oldData: Data?
        
        do {
            oldData = try await __read(rawDataForObjectWithId: id)
        }
        catch {
            throw .couldNotReadObject(cause: error)
        }
        
        
        let newData: Data
        
        do {
            guard let transformed = try await transform(oldData) else {
                return
            }
            
            newData = transformed
        }
        catch {
            throw .updateFunctionThrewSomeError(error)
        }
        
        
        do {
            try await __write(rawObjectData: newData, withId: id)
        }
        catch {
            throw .couldNotWriteObject(cause: error)
        }
    }
    
    
    mutating func delete(objectWithId id: ShelfId) async throws(Shelf.DeleteError) {
        // TODO: Batch into queued transactions
        
        let objectFileUrl = objectUrl(for: id)
        
        do {
            try fileManager.removeItem(at: objectFileUrl)
        }
        catch {
            throw .couldNotDeleteObjectFile(cause: error)
        }
    }
    
    
    
    func __deleteAllData() throws(Shelf.WholeDatabaseDeleteError) {
        do {
            try fileManager.removeItem(at: resolvedLocation)
        }
        catch {
            throw .couldNotPerformApprovedDeletion(cause: error)
        }
    }
}



// MARK: - Object finding

private extension LocalDriveShelfSerializer {
    
    /// The URL where the object with the given ID would be inside this store
    ///
    /// - Parameter id: The ID of the object which would be at the returned URL
    /// - Returns: The URL where the object with the given ID would be
    func objectUrl(for id: ShelfId) -> URL {
        let strings = id.shelfStrings
        
        return resolvedLocation
            .appending(components: strings.topFolderName, strings.subFolderName, directoryHint: .isDirectory)
            .appending(component: strings.objectName, directoryHint: .notDirectory)
    }
}



// MARK: - Config persistence

internal extension LocalDriveShelfSerializer {
    
    /// Deserializes the SHELF config file at the given location
    /// 
    /// - Parameters:
    ///   - driveLocation: The location on the drive which contains the SHELF store directory.
    ///                    This shouldn't be a SHELF store itself, but instead _contain_ the SHELF store as a subdirectory.
    ///                    For example, if the SHELF store is at `~/Library/Application Support/MyCoolApp/.object store`, then this would be `~/Application Support/MyCoolApp/`
    ///   - storeName:     _optional_ - The name of the SHELF store's root directory.
    ///                    Omit to use the default store root dir name.
    ///                    For example, if the SHELF store is at `~/Library/Application Support/MyCoolApp/.object store`, then this would be `.object store`
    ///   - configName:    _optional_ - The name of the SHELF store's config file.
    ///                    Omit to use the default config file name.
    ///                    For example, if the SHELF store's config is at `~/Library/Application Support/MyCoolApp/.object store/.shelf config`, then this would be `.shelf config`
    ///
    /// - Throws: A ``ShelfConfig/LoadError`` iff any issue occurs loading the config
    static func config(at driveLocation: DriveLocation,
                       storeName: String? = nil,
                       configName: String? = nil)
    async throws(ShelfConfig.LoadError) -> ShelfConfig? {
        let driveLocation = URL(driveLocation)
        
        guard FileManager.default.fileExists(atPath: driveLocation.path(percentEncoded: false)) else {
            return nil
        }
        
        let objectStoreRootFolder = driveLocation.defaultObjectStoreDirectory
        
        guard FileManager.default.fileExists(atPath: objectStoreRootFolder.path(percentEncoded: false)) else {
            return nil
        }
        
        let configFile = objectStoreRootFolder.defaultConfigFile
        
        guard FileManager.default.fileExists(atPath: objectStoreRootFolder.path(percentEncoded: false)) else {
            return nil
        }
        
        let configData: Data
        
        do { configData = try Data(contentsOf: configFile) }
        catch { throw .unreadable(cause: error) }
        
        do { return try ShelfConfig(jsonData: configData) }
        catch { throw .incompatible(cause: error) }
    }
}
