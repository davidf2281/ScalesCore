
import Foundation

public class Coordinator<Temperature: Sensor/*, Pressure: Sensor, Humidity: Sensor*/> {

    let temperatureSensors: [AnySensor<Temperature>]
//    let pressureSensors: [AnySensor<Pressure>] = []
//    let humiditySensors: [AnySensor<Humidity>] = []
    let graphicsContext: GraphicsContext
    let readingStore: HybridDataStore<Temperature.T>
    let display: Display

    private var saveError = false
    private var ioErrorCount = 0
    private var currentSinceIndex: Int = 0

    private let graphicsWidth = 320
    private let graphicsHeight = 240
    private let flushInterval: TimeInterval = .oneHour
    private let graphSinces: [Since] = [.oneHourAgo, .twelveHoursAgo, .twentyFourHoursAgo]
    private let screenUpdateInterval: TimeInterval = 10.0
    
    public init(temperatureSensors: [AnySensor<Temperature>], display: Display) throws {
        self.temperatureSensors = temperatureSensors
        self.graphicsContext = GraphicsContext(size: .init(width: graphicsWidth, height: graphicsHeight))
        
        // TODO: Think on how to create store names
        self.readingStore = try HybridDataStore(persistencePolicy: .onFullToCapacityAndToSchedule(interval: flushInterval), storeName: temperatureSensors.first!.name)
        self.display = display
        startSensorMonitoring()
        startDisplayUpdates()
    }
    
    private func startSensorMonitoring() {
        
        for sensor in temperatureSensors {
            
            Task { [weak self] in
                guard let self else { return }
                
                for await readingResult in sensor.readings {
                    switch readingResult {
                        case .success(let readings):
                            do {
                                for reading in readings {
                                    try await self.readingStore.save(reading: reading, date: Date())
                                }
                                self.saveError = false
                            } catch {
                                self.saveError = true
                            }
                            
                        case .failure(_):
                            ioErrorCount += 1
                    }
                   
                }
            }
        }
    }
    
    private func startDisplayUpdates() {
        
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
                    let updateErrorCountPayload = DrawTextPayload(string: "\(self.ioErrorCount)",
                                                                   point: .init(0.8, 0.05),
                                                                   font: .init(.system, size: 0.05),
                                                                   color: .gray)
                    
                    self.graphicsContext.queueCommand(.drawText(updateErrorCountPayload))
                }
                
                // Finally:
                self.graphicsContext.render()

                do {
                    try await self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
                } catch {
                    self.ioErrorCount += 1
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
            let y = range == 0 ? 0 : Double(($0.output.floatValue - zeroOffset) / range)

            return Point(x, y)
        }
        
        return normalizedPoints
    }
}

