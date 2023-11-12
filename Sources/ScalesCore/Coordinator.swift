
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

    var toggle = false
    public func didGetReading(_ reading: T) {
        do {
            try self.readingStore.save(reading)
        } catch {
            assert(false)
            print("Error saving ")
        }
        
//        let drawTextPayload = DrawTextPayload(string: reading.stringValue, point: .zero, font: .system, color: .white)
//        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    
        let color: Color24 = toggle ? .red : .white
        
        let drawLinesPayload1 = DrawLinesPayload(lines: [
            Line(start: .init(x: 0.0, y: 0.0), end: .init(x: 1.0, y: 1.0)),
            Line(start: .init(x: 0.0, y: 1.0), end: .init(x: 1.0, y: 0.0)),
            Line(start: .init(x: 0.5, y: 0.0), end: .init(x: 0.5, y: 1.0)),
            Line(start: .init(x: 0.0, y: 0.5), end: .init(x: 1.0, y: 0.5))

        ], width: 2, color: color)
        
        self.graphicsContext.queueCommand(.drawLines(drawLinesPayload1))

        self.graphicsContext.render()
    }
}
