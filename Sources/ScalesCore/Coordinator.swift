
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
    }
    
    public func didGetReading(_ reading: T) {
        do {
            try self.readingStore.save(reading)
        } catch {
            assert(false)
            print("Error saving ")
        }
        
        let drawTextPayload = DrawTextPayload(string: reading.stringValue, point: .init(0.075, 0.5), font: .init(.system, size: 0.2), color: .red)
        self.graphicsContext.queueCommand(.drawText(drawTextPayload))

        self.graphicsContext.render()
        
        self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
    }
}
