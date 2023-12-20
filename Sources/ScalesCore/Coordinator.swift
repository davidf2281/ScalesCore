
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
    private let flushInterval: TimeInterval = .oneMinute
    private let graphSinces: [Since] = [.oneMinuteAgo]
    private var currentSinceIndex: Int = 0
    private let screenUpdateInterval: TimeInterval = 1.0
    
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
        
        Task { [weak self] in
            
            guard let self else { return }

            while(true) {
                
                // Graph
                let graphSince = graphSinces[currentSinceIndex]
                let readings = try await self.readingStore.retrieve(since: graphSince.date)
                if let normalizedPoints = try await normalizedPointsForGraph(since: graphSince, readings: readings) {
                    let graphCommand = drawCommandForGraph(normalizedPoints: normalizedPoints
                        .sorted(by: { $0.x > $1.x })
                        .decimate(into: graphicsWidth)
                    )
                    self.graphicsContext.queueCommand(graphCommand)
                }
                
                currentSinceIndex = graphSinces.nextIndexWrapping(index: currentSinceIndex)
                
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
    
    private func normalizedPointsForGraph<T>(since: Since, readings: [AnyStorableReading<T>]) -> [Point]? {
        
        guard readings.isNotEmpty else {
            return nil
        }
        
        let minTimestamp = readings.min(by: { $1.timestamp > $0.timestamp })!.timestamp
        let maxOutput = readings.max(by: { $1.output.floatValue > $0.output.floatValue })!.output.floatValue
        let minOutput = readings.min(by: { $1.output.floatValue > $0.output.floatValue })!.output.floatValue
        let range = abs(minOutput - maxOutput)
        let zeroOffset = minOutput
        
        let normalizedPoints: [Point] = readings.map {
            
            let x = Double($0.timestamp - minTimestamp) / Double(since.representativeMillis)
            let y = maxOutput == 0 ? 0 : Double(($0.output.floatValue - zeroOffset) / range)
            
            if (y < 0 && y > 1) {
                print("y: \(y) for floatValue: \($0.output.floatValue), zeroOffset: \(zeroOffset), range: \(range)")
            }
            
            precondition(x >= 0 && x <= 1)
            precondition(y >= 0 && y <= 1)

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
      */
    }
}
