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

public protocol ReadingProvider {
    var delegate: ReadingProviderDelegate? { get set }
    func start()
}

public protocol Display {
    init(width: CGFloat, height: CGFloat)
    var font: Font { get set }
    func drawText(x: CGFloat, y: CGFloat)
}

public struct ReadingProcessor: ReadingProviderDelegate {
    let readingProvider: ReadingProvider
    
    init(readingProvider: some ReadingProvider) {
        self.readingProvider = readingProvider
    }
    
    public func didGetReading(_ reading: Float) {
        // TODO: Implement me
    }
}
