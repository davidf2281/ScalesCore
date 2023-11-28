
import Foundation

public class Coordinator<U: Sensor>: SensorDelegate {
    
    public typealias T = U.T
    let sensor: U
    let graphicsContext: GraphicsContext
    let readingStore: RAMDataStore<T>
    let display: Display

    public init(sensor: U, display: Display) {
        self.sensor = sensor
        self.graphicsContext = GraphicsContext(size: .init(width: 320, height: 240))
        self.readingStore = RAMDataStore<T>()
        self.display = display
        self.sensor.delegate = self
        self.sensor.start()
        
        let currentDirectory = FileManager.default.currentDirectoryPath
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        
        print("Current directory: \(currentDirectory)")
        print("Home directory for current user: \(homeDirectory)")
    }
    
    public func didGetReading(_ reading: T) {
        do {
            try self.readingStore.save(reading)
        } catch {
            print("Error saving")
        }
        
        let drawTemperaturePayload = DrawTextPayload(string: reading.stringValue, point: .init(0.09, 0.5), font: .init(.system, size: 0.2), color: .red)
        self.graphicsContext.queueCommand(.drawText(drawTemperaturePayload))

        let drawReadingsCountPayload = DrawTextPayload(string: "\(self.readingStore.totalReadingsCount)", point: .init(0.1, 0.05), font: .init(.system, size: 0.05), color: .gray)
        self.graphicsContext.queueCommand(.drawText(drawReadingsCountPayload))
        
        self.graphicsContext.render()
        
        self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
    }
}
