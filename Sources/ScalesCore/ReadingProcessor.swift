//
//  Core.swift
//  Scales
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation

public protocol Font {}

public struct ReadingProcessor: ReadingProviderDelegate {
    
    let readingProvider: ReadingProvider
    let display: Display
    
    public init(readingProvider: some ReadingProvider, display: Display) {
        self.readingProvider = readingProvider
        self.display = display
        self.readingProvider.delegate = self
    }
    
    // MARK: ReadingProviderDelegate
    public func didGetReading(_ reading: Float) {
        self.display.drawText(String(reading), x: 0, y: 0)
    }
}
