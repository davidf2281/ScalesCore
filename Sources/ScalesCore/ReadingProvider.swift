//
//  Core.swift
//  Scales
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation

public protocol Font {}

public protocol ReadingProviderDelegate {
    func didGetReading(_ reading: Float)
}

public protocol ReadingProvider: AnyObject {
    var delegate: ReadingProviderDelegate? { get set }
    func start()
}

public protocol Display {
    init(width: CGFloat, height: CGFloat)
    var font: Font { get set }
    func drawText(_ text: String, x: CGFloat, y: CGFloat)
}

public struct ReadingProcessor: ReadingProviderDelegate {
    let readingProvider: ReadingProvider
    let display: Display
    
    public init(readingProvider: some ReadingProvider, display: Display) {
        self.readingProvider = readingProvider
        self.display = display
        self.readingProvider.delegate = self
    }
    
    public func didGetReading(_ reading: Float) {
        self.display.drawText(String(reading), x: 0, y: 0)
    }
}
