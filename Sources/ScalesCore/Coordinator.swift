//
//  Core.swift
//  Scales
//
//  Created by David Fearon on 28/10/2023.
//

import Foundation

public class Coordinator {
    
    let sensor: Sensor
    let graphicsContext: GraphicsContext
    
    public init(sensor: some Sensor, graphicsContext: GraphicsContext) {
        self.sensor = sensor
        self.graphicsContext = graphicsContext
        self.sensor.delegate = self
    }
}

extension Coordinator: SensorDelegate {
    
    public func didGetReading(_ reading: Float) {
        let drawTextPayload = DrawTextPayload(string: String(reading), point: .zero, font: .system, color: .white)
        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    }
}
