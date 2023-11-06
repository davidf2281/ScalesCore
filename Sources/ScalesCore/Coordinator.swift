
import Foundation

public class Coordinator<U: Sensor>: SensorDelegate {

    public typealias T = U.T
    let sensor: U
    let graphicsContext: GraphicsContext
    let readingStore: RAMDataStore<T>
    
    public init(sensor: U, graphicsContext: GraphicsContext) {
        self.sensor = sensor
        self.graphicsContext = graphicsContext
        self.readingStore = RAMDataStore<T>()
        
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
        
        let drawTextPayload = DrawTextPayload(string: reading.stringValue, point: .zero, font: .system, color: .white)
        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    
        let drawLinesPayload1 = DrawLinesPayload(lines: [
            Line(start: .init(x: 0, y: 0.25), end: .init(x: 1, y: 0.35))
        ], width: 2, color: .white)
        
        self.graphicsContext.queueCommand(.drawLines(drawLinesPayload1))

        self.graphicsContext.render()
    }
}
