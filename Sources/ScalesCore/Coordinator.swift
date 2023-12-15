
import Foundation

public class Coordinator<U: Sensor>: SensorDelegate {

    public typealias T = U.T
    let sensor: U
    let graphicsContext: GraphicsContext
    let readingStore: HybridDataStore<T, U>
    let display: Display

    private var max: T? = nil
    private var min: T? = nil
    private var saveError = false
    private var readingLastStoredDate: Date?
    
    public init(sensor: U, display: Display) throws {
        self.sensor = sensor
        self.graphicsContext = GraphicsContext(size: .init(width: 320, height: 240))
        self.readingStore = try HybridDataStore<T, U>(sensor: sensor, persistencePolicy: .onFullToCapacityAndToSchedule(interval: .oneHour))
        self.display = display
        self.sensor.delegate = self
        self.sensor.start(minUpdateInterval: 1.0)
    }
    
    public func didGetReading(_ reading: T) async {
                
        do {
            let now = Date()
            try await self.readingStore.save(reading, date: now)
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
    }
}
