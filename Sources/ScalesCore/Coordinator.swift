//
//  Core.swift
//  Scales
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation

public struct Coordinator: SensorDelegate {
    
    let sensor: Sensor
    let graphicsContext: GraphicsContext
    
    public init(sensor: some Sensor, graphicsContext: GraphicsContext) {
        self.sensor = sensor
        self.graphicsContext = graphicsContext
        self.sensor.delegate = self
    }
    
    // MARK: SensorDelegate
    public func didGetReading(_ reading: Float) {
        let drawTextPayload = DrawTextPayload(string: String(reading), point: .zero, font: .system)
        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    }
}
