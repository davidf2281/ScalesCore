
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
    private let graphSinces: [Since] = [.oneHourAgo, .twentyFourHoursAgo, .oneWeekAgo, .oneMonthAgo]
    private let screenUpdateInterval: TimeInterval = 10.0
    
    public init(sensors: [AnySensor<T>], display: Display) throws {
        self.sensors = sensors
        self.graphicsContext = GraphicsContext(size: .init(width: graphicsWidth, height: graphicsHeight))
        self.display = display
        startSensorMonitoring()
        startDisplayUpdates()
    }
    
    public struct FlushToDiskError: Error {
        public var errorDescriptions: [String]
    }
    
    public func flushAllToDisk() async -> Result<Void, FlushToDiskError> {
        var errorDescriptions: [String] = []
        for readingStore in self.readingStores.values {
            do {
                try await readingStore.flushToDisk()
            } catch {
                errorDescriptions.append("Failed to save reading store data for sensor \(readingStore.associatedSensor.id)")
            }
        }
        
        if errorDescriptions.isEmpty {
            return .success(())
        } else {
            return .failure(FlushToDiskError(errorDescriptions: errorDescriptions))
        }
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
                for (index, dataStore) in self.readingStores.values.enumerated() {
        
                    let graphColor: Color24
                    switch dataStore.associatedOutputType {
                        case .temperature:
                            switch dataStore.associatedSensor.location {
                                case .indoor:
                                    graphColor = .red
                                case .outdoor:
                                    graphColor = .blue
                            }
                        case .barometricPressure:
                            graphColor = .yellow
                        case .humidity:
                            graphColor = .gray
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
                    
                    // Numeric displays
                    if let reading = await dataStore.retrieveLatest() {
                        
                        // Reading value
                        let drawTemperaturePayload = DrawTextPayload(string: reading.output.stringValue,
                                                                     point: .init(0.3 * Double(index), 0.8),
                                                                     font: .init(.system, size: 0.085),
                                                                     color: graphColor)
                        
                        self.graphicsContext.queueCommand(.drawText(drawTemperaturePayload))
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
                    print("Display update failed: \(error.localizedDescription)")
                }
                try await Task.sleep(for: .seconds(screenUpdateInterval))
                
                currentSinceIndex = graphSinces.nextIndexWrapping(index: currentSinceIndex)
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

