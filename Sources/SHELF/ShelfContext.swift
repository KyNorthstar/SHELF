//
// ShelfContext.swift
//
// Written by Ky on 2024-11-14.
// Copyright waived. No rights reserved.
//
// This file is part of SHELF, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// Use this to manipulate the SHELF object store
///
/// ```swift
/// @main
/// struct App: SwiftUI.App {
///
///     @ShelfContext // ✨ That's this type!
///     private var shelfContext
///
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(\.shelfContext, shelfContext) // If you don't do this it'll be in-memory-only!
///         }
///     }
/// }
/// ```
///
/// - Attention: If you don't ever specify a `.environment(\.shelfContext` for SHELF, it will run in-memory-only!
@propertyWrapper
public struct ShelfContext: __ShelfContextProtocol {
    public let wrappedValue: WrappedValue
    
    public var config: Config { wrappedValue.config }
    
    
    public init(wrappedValue: WrappedValue) {
        self.wrappedValue = wrappedValue
        
    }
    
    
    public init(config: Config = .init(paradigm: .goldenPath)) {
        self.init(wrappedValue: .init(config: config))
    }
    
    
    public typealias WrappedValue = Guts
}



public extension ShelfContext {
    /// The actual implementation of the ``ShelfContext``.
    ///
    /// We had to do this to allow `@ShelfContext` to both wrap a value and also be the value
    struct Guts: __ShelfContextProtocol {
        public var config: Config
        
        public init(config: Config) {
            self.config = config
        }
    }
}



/// A protocol backing ``ShelfContext``, to ensure that the public API and the guts both do the same thing
public protocol __ShelfContextProtocol: Sendable {
    
    /// This context's configuration
    var config: Config { get }
    
    /// Creates a new context with the given configuration
    init(config: Config)
}

