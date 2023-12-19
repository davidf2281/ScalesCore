
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
    
    public init(temperatureSensors: [AnySensor<Temperature>], display: Display) throws {
        self.temperatureSensors = temperatureSensors
        self.graphicsContext = GraphicsContext(size: .init(width: 320, height: 240))
        self.readingStore = try HybridDataStore(persistencePolicy: .onFullToCapacityAndToSchedule(interval: .twentyFourHours), storeName: temperatureSensors.first!.name)
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
                    
                    if let graphCommand = try await drawCommandForGraph() {
                        self.graphicsContext.queueCommand(graphCommand)
                    }
                    
                    self.graphicsContext.render()
                    
                    do {
                        try self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
                    } catch {
                        self.displayUpdateErrorCount += 1
                    }
                }
                
                try await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    private func drawCommandForGraph() async throws -> GraphicsCommand? {
        
        let readings = try await self.readingStore.retrieve(since: .oneHourAgo)
        let maxX = readings.max(by: { $0.timestamp > $1.timestamp })!.timestamp
        let maxY = readings.max(by: { $0.output.floatValue > $1.output.floatValue })!.output.floatValue
        
        let normalizedPoints = readings.map {
            Point(Double($0.timestamp / maxX), Double($0.output.floatValue / maxY))
        }
        
        guard normalizedPoints.isNotEmpty else {
            return nil
        }
        
        var lines: [Line] = []
        var lastPoint = normalizedPoints.first!
        for point in normalizedPoints {
            lines.append(Line(lastPoint.x, lastPoint.y, point.x, point.y))
            lastPoint = point
        }
        
        let payload = DrawLinesPayload(lines: lines, width: 0.05, color: .white)
        
        return .drawLines(payload)
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
