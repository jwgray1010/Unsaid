//
//  UnsaidShared.swift
//  UnsaidShared Framework
//
//  Created by John Gray on 7/7/25.
//  Copyright © 2025 Unsaid. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Framework Header

/// UnsaidShared Framework - Shared types and utilities for Unsaid app and keyboard extension
public struct UnsaidShared {
    
    /// Framework version
    public static let version = "1.0.0"
    
    /// Framework identifier
    public static let identifier = "com.unsaid.UnsaidShared"
    
    /// Initialize the framework
    public static func initialize() {
        // Framework initialization logic if needed
        print("UnsaidShared Framework v\(version) initialized")
    }
}
