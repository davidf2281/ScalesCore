
import Foundation

public class Coordinator<Temperature: Sensor/*, Pressure: Sensor, Humidity: Sensor*/> {

    let temperatureSensors: [AnySensor<Temperature>]
//    let pressureSensors: [AnySensor<Pressure>] = []
//    let humiditySensors: [AnySensor<Humidity>] = []
    let graphicsContext: GraphicsContext
    let readingStore: HybridDataStore<Temperature.T>
    let display: Display

//    private var max: T? = nil
//    private var min: T? = nil
    private var saveError = false
    private var displayUpdateErrorCount = 0
    
    private let graphicsWidth = 320
    private let graphicsHeight = 240
    private let flushInterval: TimeInterval = .oneHour
    private let graphSince: Since = .sixHoursAgo
    private let screenUpdateInterval: TimeInterval = 10.0
    
    public init(temperatureSensors: [AnySensor<Temperature>], display: Display) throws {
        self.temperatureSensors = temperatureSensors
        self.graphicsContext = GraphicsContext(size: .init(width: graphicsWidth, height: graphicsHeight))
        self.readingStore = try HybridDataStore(persistencePolicy: .onFullToCapacityAndToSchedule(interval: flushInterval), storeName: temperatureSensors.first!.name)
        self.display = display
        startSensorMonitoring()
        startDisplayUpdates()
    }
    
    func startSensorMonitoring() {
        
        for sensor in temperatureSensors {
            
            Task { [weak self] in
                guard let self else { return }
                
                for await reading in sensor.readings {
                    do {
                        try await self.readingStore.save(reading: reading, date: Date())
                        self.saveError = false
                    } catch {
                        self.saveError = true
                    }
                }
            }
        }
    }
    
    func startDisplayUpdates() {
        
        Task {
            
            while(true) {
                if let reading = await self.readingStore.retrieveLatest() {
                    
                    // Temperature
                    let drawTemperaturePayload = DrawTextPayload(string: reading.output.stringValue, 
                                                                 point: .init(0.09, 0.75),
                                                                 font: .init(.system, size: 0.2), 
                                                                 color: .red)
                    
                    self.graphicsContext.queueCommand(.drawText(drawTemperaturePayload))
                    
                    // Reading count
                    let drawReadingsCountPayload = DrawTextPayload(string: "\(await self.readingStore.totalReadingsCount)", 
                                                                   point: .init(0.1, 0.05),
                                                                   font: .init(.system, size: 0.05),
                                                                   color: .gray)
                    
                    self.graphicsContext.queueCommand(.drawText(drawReadingsCountPayload))
                    
                    // Update error count
                    let updateErrorCountPayload = DrawTextPayload(string: "\(self.displayUpdateErrorCount)",
                                                                   point: .init(0.8, 0.05),
                                                                   font: .init(.system, size: 0.05),
                                                                   color: .gray)
                    
                    self.graphicsContext.queueCommand(.drawText(updateErrorCountPayload))
                }
                
                // Graph
                let readings = try await self.readingStore.retrieve(since: graphSince.date)
                if let normalizedPoints = try await normalizedPointsForGraph(since: graphSince, readings: readings) {
                    let graphCommand = drawCommandForGraph(normalizedPoints: normalizedPoints
                        .sorted(by: { $0.x > $1.x })
                        .decimate(into: graphicsWidth)
                    )
                    self.graphicsContext.queueCommand(graphCommand)
                }

                let things = ["Hey"].decimate(into: 1)
                
                // Finally:
                self.graphicsContext.render()

                do {
                    try self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
                } catch {
                    self.displayUpdateErrorCount += 1
                }

                try await Task.sleep(for: .seconds(screenUpdateInterval))
            }
        }
    }
    
    private func drawCommandForGraph(normalizedPoints: [Point]) -> GraphicsCommand {
        
        var lines: [Line] = []
        var lastPoint = normalizedPoints.first! // TODO: Address the force-unwrap
        
        for point in normalizedPoints {
            lines.append(Line(lastPoint.x, lastPoint.y, point.x, point.y))
            lastPoint = point
        }
        
        let payload = DrawLinesPayload(lines: lines, width: 0.05, color: .white)
        
        return .drawLines(payload)
    }
    
    private func normalizedPointsForGraph(since: Since, readings: [AnyStorableReading<Temperature.T>]) -> [Point]? {
        
        guard readings.isNotEmpty else {
            return nil
        }
        
        let minTime = readings.min(by: { $1.timestamp > $0.timestamp })!.timestamp
        let maxTime = readings.max(by: { $1.timestamp > $0.timestamp })!.timestamp

        let maxOutput = readings.max(by: { $1.output.floatValue > $0.output.floatValue })!.output.floatValue
        
        guard maxOutput > 0 else { // TODO: This won't work for temps / readings below 0
            return nil
        }
        
        let normalizedPoints: [Point] = readings.map {
            
            let x = Double($0.timestamp - minTime) / Double(since.representativeMillis)
            let y = Double($0.output.floatValue / maxOutput)
            
            return Point(x, y)
        }
        
        guard normalizedPoints.isNotEmpty else {
            return nil
        }
        
        return normalizedPoints
    }

    public func didGetReading<T>(_ reading: T, sender: any Sensor<T>) async {
    
     /*   do {
            let now = Date()
            try await self.readingStore.save(reading: reading, date: now)
            self.readingLastStoredDate = now
            self.saveError = false
        } catch {
            self.saveError = true
        }
        
        if max == nil {
            max = reading
        }
        
        if min == nil {
            min = reading
        }
   
        if let max, reading > max {
            self.max = reading
        }
        
        if let min, reading < min {
            self.min = reading
        }

        // Temperature
        let drawTemperaturePayload = DrawTextPayload(string: reading.stringValue, point: .init(0.09, 0.75), font: .init(.system, size: 0.2), color: .red)
        self.graphicsContext.queueCommand(.drawText(drawTemperaturePayload))

        // Max temperature
        if let max {
            let drawMaxTemperaturePayload = DrawTextPayload(string: max.stringValue, point: .init(0.09, 0.5), font: .init(.system, size: 0.15), color: .red)
            self.graphicsContext.queueCommand(.drawText(drawMaxTemperaturePayload))
        }
        
        // Min temperature
        if let min {
            let drawMinTemperaturePayload = DrawTextPayload(string: min.stringValue, point: .init(0.09, 0.25), font: .init(.system, size: 0.15), color: .red)
            self.graphicsContext.queueCommand(.drawText(drawMinTemperaturePayload))
        }

        // Reading count
        let drawReadingsCountPayload = DrawTextPayload(string: "\(await self.readingStore.totalReadingsCount)", point: .init(0.1, 0.05), font: .init(.system, size: 0.05), color: .gray)
        self.graphicsContext.queueCommand(.drawText(drawReadingsCountPayload))
        
        self.graphicsContext.render()
        
        self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
      */
    }
}
