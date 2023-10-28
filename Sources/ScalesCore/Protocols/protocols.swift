//
//  File.swift
//  
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation

public protocol ReadingProviderDelegate {
    func didGetReading(_ reading: Float)
}

public protocol ReadingProvider: AnyObject {
    var delegate: ReadingProviderDelegate? { get set }
    func start()
}

public protocol Display {
    init(width: CGFloat, height: CGFloat)
    var font: Font? { get set }
    func drawText(_ text: String, x: CGFloat, y: CGFloat)
}
