
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

    var colors = Colors()
    
    public func didGetReading(_ reading: T) {
        do {
            try self.readingStore.save(reading)
        } catch {
            assert(false)
            print("Error saving ")
        }
        
//        let drawTextPayload = DrawTextPayload(string: reading.stringValue, point: .zero, font: .system, color: .white)
//        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    
        
        let drawLinesPayload1 = DrawLinesPayload(lines: [
            Line(0.0, 0.0, 1.0, 1.0),
            Line(0.0, 1.0, 1.0, 0.0),
            Line(0.5, 0.0, 0.5, 1.0),
            Line(0.0, 0.5, 1.0, 0.5)
        ], width: 2, color: colors.next()!)
        
        self.graphicsContext.queueCommand(.drawLines(drawLinesPayload1))

        self.graphicsContext.render()
    }
    
    struct Colors: IteratorProtocol {
        
        typealias Element = Color24

        private var index = 0
        
        let colors: [Color24] = [.red, .green, .white, .blue]

        mutating func next() -> Color24? {
            if index == colors.endIndex {
                index = 0
            }
            
            let color = colors[index]
            index += 1
            return color
        }
    }
}
