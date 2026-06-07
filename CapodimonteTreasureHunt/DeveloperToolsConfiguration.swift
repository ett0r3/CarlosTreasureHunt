//
//  DeveloperToolsConfiguration.swift
//  CapodimonteTreasureHunt
//

import Foundation

enum DeveloperToolsConfiguration {
    // Change these values while testing the app.
    static let isEnabled = true
    static let showsResetButton = true
    static let showsSkipScanButton = true

    static var isResetButtonEnabled: Bool {
#if DEBUG
        isEnabled && showsResetButton
#else
        false
#endif
    }

    static var isSkipScanButtonEnabled: Bool {
#if DEBUG
        isEnabled && showsSkipScanButton
#else
        false
#endif
    }
}
