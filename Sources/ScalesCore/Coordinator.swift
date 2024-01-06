
import Foundation

public class Coordinator<T: SensorOutput> {
    
    let sensors: [AnySensor<T>]
    let graphicsContext: GraphicsContext
    private var readingStores: [String : HybridDataStore<T>] = [:]
    let display: Display
    
    private var saveError = false
    private var ioErrorCount = 0
    private var currentSinceIndex: Int = 0
    
    private let graphicsWidth: Int
    private let graphicsHeight: Int
    private let flushInterval: TimeInterval = .oneHour
    private let graphSinces: [Since] = [.oneHourAgo, .twentyFourHoursAgo, .oneWeekAgo, .oneMonthAgo]
    private let screenUpdateInterval: TimeInterval = 2.0
    private var displayUpdatesPaused = false
    
    public init(sensors: [AnySensor<T>], display: Display) throws {
        self.sensors = sensors
        
        // We always want our logical graphics to be landscape
        let graphicsResolution: Size = display.aspect == .landscape ? Size(width: display.resolution.width, height: display.resolution.height) : Size(width: display.resolution.height, height: display.resolution.width)
        
        self.graphicsContext = GraphicsContext(size: .init(width: graphicsResolution.width, height: graphicsResolution.height))
        self.graphicsWidth = graphicsResolution.width
        self.graphicsHeight = graphicsResolution.height
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
    
    public func buttonPressed() {
        currentSinceIndex = graphSinces.nextIndexWrapping(index: currentSinceIndex)
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
                try await updateDisplay()
                try await Task.sleep(for: .seconds(screenUpdateInterval))
            }
        }
    }
    
    private func updateDisplay() async throws {
        
        let dataStores = self.readingStores.values
        
        // Graph
        let graphSince = graphSinces[currentSinceIndex]
        async let graphCommands = try graphCommands(for: dataStores, since: graphSince)
        
        // Latest numeric readings
        async let latestValueCommands = try latestValueCommands(for: dataStores)
        
        // I/O error count
        async let errorCountCommand = updateErrorCountCommand(count: self.ioErrorCount)
        
        // Finally:
        try await self.graphicsContext.queueCommands(graphCommands + latestValueCommands + [errorCountCommand])
        
        self.graphicsContext.render()
        
        let shouldSwapWidthForHeight = (self.display.aspect == .portrait)
        
        do {
            let frameBuffer = shouldSwapWidthForHeight ? self.graphicsContext.frameBuffer.swappedWidthForHeight : self.graphicsContext.frameBuffer
            try await self.display.showFrame(frameBuffer)
        } catch {
            self.ioErrorCount += 1
            print("Display update failed: \(error.localizedDescription)")
        }
    }
    
    private func colorFor(dataStore: HybridDataStore<T>) -> Color24 {
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
        
        return graphColor
    }
    
    private func graphCommands(for dataStores: Dictionary<String, HybridDataStore<T>>.Values, since: Since) async throws -> [GraphicsCommand] {
        
        var commands: [GraphicsCommand] = []
                
        for dataStore in dataStores {
            
            let readings = try await dataStore.retrieve(since: since.date)
            
            if let normalizedPoints = normalizedPointsForGraph(since: since, readings: readings) {
                let graphCommand = drawCommandForGraph(
                    color: colorFor(dataStore: dataStore),
                    normalizedPoints: normalizedPoints
                        .sorted(by: { $0.x > $1.x })
                        .decimate(into: graphicsWidth)
                )
                
                commands.append(graphCommand)
            }
        }
        
        return commands
    }
    
    private func latestValueCommands(for dataStores: Dictionary<String, HybridDataStore<T>>.Values) async throws -> [GraphicsCommand] {
        
        var commands: [GraphicsCommand] = []
        
        for (index, dataStore) in dataStores.enumerated() {
            
            // Numeric displays
            if let reading = await dataStore.retrieveLatest() {
                
                // Reading value
                let readingValuePayload = DrawTextPayload(string: reading.output.stringValue,
                                                             point: .init(0.05, 0.26 * Double(index)),
                                                             font: .init(.system, size: 0.085),
                                                             color: colorFor(dataStore: dataStore))
                
                commands.append(.drawText(readingValuePayload))
            }
        }
        
        return commands
    }
    
    private func updateErrorCountCommand(count: Int) async -> GraphicsCommand {
        let updateErrorCountPayload = DrawTextPayload(string: "\(count)",
                                                      point: .init(0.8, 0.05),
                                                      font: .init(.system, size: 0.05),
                                                      color: .gray)
        
        return .drawText(updateErrorCountPayload)
    }
    
    private func drawCommandForGraph(color: Color24, normalizedPoints: [Point]) -> GraphicsCommand {
        
        var lines: [Line] = []
        var previousPoint = normalizedPoints.first! // TODO: Address the force-unwrap
        
        for point in normalizedPoints {
            lines.append(Line(previousPoint.x, previousPoint.y, point.x, point.y))
            previousPoint = point
        }
        
        let payload = DrawLinesPayload(lines: lines, width: 0.05, color: color)
        
        return .drawLines(payload)
    }
    
    private func normalizedPointsForGraph<U>(since: Since, readings: [AnyStorableReading<U>]) -> [Point]? {
        
        guard
            let minTimestamp = readings.min(by: { $1.timestamp > $0.timestamp })?.timestamp,
            let maxOutput = readings.max(by: { $1.output.floatValue > $0.output.floatValue })?.output.floatValue,
            let minOutput = readings.min(by: { $1.output.floatValue > $0.output.floatValue })?.output.floatValue
        else {
            return nil
        }
        
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

