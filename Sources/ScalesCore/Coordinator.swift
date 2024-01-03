
import Foundation

public class Coordinator<T: SensorOutput> {
    
    let sensors: [AnySensor<T>]
    let graphicsContext: GraphicsContext
    private var readingStores: [String : HybridDataStore<T>] = [:]
    let display: Display
    
    private var saveError = false
    private var ioErrorCount = 0
    private var currentSinceIndex: Int = 0
    
    private let graphicsWidth = 320
    private let graphicsHeight = 240
    private let flushInterval: TimeInterval = .oneHour
    private let graphSinces: [Since] = [.oneHourAgo, .twelveHoursAgo, .twentyFourHoursAgo, .oneWeekAgo]
    private let screenUpdateInterval: TimeInterval = 10.0
    
    public init(sensors: [AnySensor<T>], display: Display) throws {
        self.sensors = sensors
        self.graphicsContext = GraphicsContext(size: .init(width: graphicsWidth, height: graphicsHeight))
        self.display = display
        startSensorMonitoring()
        startDisplayUpdates()
    }
    
    private func startSensorMonitoring() {
        
        for sensor in sensors {
            
            Task { [weak self] in
                guard let self else { return }
                
                for await readingResult in sensor.readings {
                    switch readingResult {
                        case .success(let readings):
                            do {
                                for reading in readings {
                                    let dataStore = try dataStore(for: reading, sensor: sensor)
                                    try await dataStore.save(reading: reading, date: Date())
                                    print("Saved reading from \(sensor.id), value: \(reading.value)\(reading.outputType.displayUnit)")
                                }
                                self.saveError = false
                            } catch {
                                self.saveError = true
                            }
                            
                        case .failure(let error):
                            print("Reading error: \(error.localizedDescription)")
                            print("Sensor: \(sensor.id)")
                            ioErrorCount += 1
                    }
                    
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
    }
    
    private func dataStore(for reading: Reading<T>, sensor: AnySensor<T>) throws -> HybridDataStore<T> {
        let storeName = storeName(for: reading)
        if let dataStore = self.readingStores[storeName] {
            return dataStore
        } else {
            let newDataStore = try HybridDataStore<T>(persistencePolicy: .onFullToCapacityAndToSchedule(interval: flushInterval), storeName: storeName, associatedSensor: sensor, associatedOutputType: reading.outputType)
            self.readingStores[storeName] = newDataStore
            return newDataStore
        }
    }
    
    private func storeName(for reading: Reading<T>) -> String {
        return reading.outputType.toString + "_" + reading.sensorLocation.toString + "_" + reading.sensorID
    }
    
    private func startDisplayUpdates() {
        
        Task { [weak self] in
            
            guard let self else { return }

            while(true) {
                
                // Graph
                let graphSince = graphSinces[currentSinceIndex]
                for dataStore in self.readingStores.values {
                    
                    guard dataStore.associatedOutputType == .temperature(unit: .celsius) else {
                        continue
                    }
                    
                    let isIndoors: Bool
                    let graphColor: Color24
                    
                    switch dataStore.associatedSensor.location {
                        case .indoor(_):
                            graphColor = .blue
                            isIndoors = true
                        case .outdoor(_):
                            graphColor = .green
                            isIndoors = false
                    }
                    
                    let readings = try await dataStore.retrieve(since: graphSince.date)
                    
                    if let normalizedPoints = normalizedPointsForGraph(since: graphSince, readings: readings) {
                        let graphCommand = drawCommandForGraph(
                            color: graphColor,
                            normalizedPoints: normalizedPoints
                                .sorted(by: { $0.x > $1.x })
                                .decimate(into: graphicsWidth)
                        )
                        self.graphicsContext.queueCommand(graphCommand)
                    }
                    
                    currentSinceIndex = graphSinces.nextIndexWrapping(index: currentSinceIndex)
                    
                    if let reading = await dataStore.retrieveLatest() {
                        
                        // Reading value
                        let drawTemperaturePayload = DrawTextPayload(string: reading.output.stringValue,
                                                                     point: .init(isIndoors ? 0.05 : 0.55, 0.8),
                                                                     font: .init(.system, size: 0.11),
                                                                     color: graphColor)
                        
                        self.graphicsContext.queueCommand(.drawText(drawTemperaturePayload))
                        
                        // Reading count
                        let drawReadingsCountPayload = DrawTextPayload(string: "\(await dataStore.totalReadingsCount)",
                                                                       point: .init(isIndoors ? 0.1 : 0.2, 0.05),
                                                                       font: .init(.system, size: 0.05),
                                                                       color: .gray)
                        
                        self.graphicsContext.queueCommand(.drawText(drawReadingsCountPayload))
                    }
                }
                
                // Update error count
                let updateErrorCountPayload = DrawTextPayload(string: "\(self.ioErrorCount)",
                                                              point: .init(0.8, 0.05),
                                                              font: .init(.system, size: 0.05),
                                                              color: .gray)
                
                self.graphicsContext.queueCommand(.drawText(updateErrorCountPayload))
                
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
    
    private func drawCommandForGraph(color: Color24, normalizedPoints: [Point]) -> GraphicsCommand {
        
        var lines: [Line] = []
        var lastPoint = normalizedPoints.first! // TODO: Address the force-unwrap
        
        for point in normalizedPoints {
            lines.append(Line(lastPoint.x, lastPoint.y, point.x, point.y))
            lastPoint = point
        }
        
        let payload = DrawLinesPayload(lines: lines, width: 0.05, color: color)
        
        return .drawLines(payload)
    }
    
    private func normalizedPointsForGraph<U>(since: Since, readings: [AnyStorableReading<U>]) -> [Point]? {
        
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

