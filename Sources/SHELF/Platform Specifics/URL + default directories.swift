//
// URL + default directories.swift
//
// Written by Ky on 2024-11-14.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



internal extension URL {
    
    /// A silly little way to get the current platform's directories
    ///
    /// - Parameter platform: The platform directories you wanna get
    /// - Returns: The platform directories you wanna get
    @inline(__always)
    static func defaultDirectories<Platform: PlatformDefaultDirectories>(for platform: Platform) -> Platform { platform }
    
    
    /// The directory where the SHELF object store for this program will be, if none is explicitly specified
    static var defaultObjectStoreDirectory: Self {
        defaultDirectories(for: .current).thisProgramObjectStore
    }
    
    
    /// Resolves the given semantic directory as a URL
    ///
    /// - Parameter semanticDirectory: Describes a way a directory is used. That description will be transformed into a concrete location where that use-case is best saved on this platform
    init(_ semanticDirectory: DriveLocation.Semantic) {
        switch semanticDirectory {
        case .thisProgramDataDirectory:
            self = URL.defaultDirectories(for: .current).thisProgramDataDirectory
        }
    }
}



/// A list of default directories for this platform
internal protocol PlatformDefaultDirectories {
    
    /// The platform's default location where this program is supposed to store data
    ///
    /// Like `%APPDATA%` on Windows, or `~/Libraries/Application Support/` on macOS
    var thisProgramDataDirectory: URL { get }
    
    /// The default place where object stores go for this program
    ///
    /// Like `%APPDATA%\My Program\` on Windows, or `~/Libraries/Application Support/com.example.MyProgram/` on macOS
    var thisProgramObjectStore: URL { get }
}



internal extension PlatformDefaultDirectories where Self == CurrentPlatformDefaultDirectories {
    
    /// The default directories for the current platform
    static var current: Self { .init() }
}



internal extension PlatformDefaultDirectories {
    
    var thisProgramObjectStore: URL {
        if #available(macOS 13.0, *) {
            thisProgramDataDirectory.appending(path: URL.objectStoreDefaultDirectoryName)
        }
        else {
            thisProgramDataDirectory.appendingPathComponent(URL.objectStoreDefaultDirectoryName)
        }
    }
}



// MARK: - Apple

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
internal struct AppleDefaultDirectories: PlatformDefaultDirectories {
    var thisProgramDataDirectory: URL {
        var bundleId: String {
            Bundle.main.bundleIdentifier
            ?? ProcessInfo.processInfo.globallyUniqueString
            //?? "__OBJECT_STORE_BACKUP__MISSING_BUNDLE_ID__"
        }
        
        if #available(macOS 13.0, *) {
            return .applicationSupportDirectory.appending(path: bundleId)
        }
        else {
            do {
                return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            }
            catch {
                return .init(fileURLWithPath: "\(NSHomeDirectory())/Library/Application Support/\(bundleId)")
            }
        }
    }
}



typealias CurrentPlatformDefaultDirectories = AppleDefaultDirectories
#endif



// MARK: - Linux

#if os(Linux)
#error("SHELF does not yet support Linux")
typealias CurrentPlatformDefaultDirectories = LinuxDefaultDirectories
#endif



// MARK: - Windows

#if os(Windows)
#error("SHELF does not yet support Windows")
typealias CurrentPlatformDefaultDirectories = WindowsDefaultDirectories
#endif
