
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

    var colors = Colors()
    
    public func didGetReading(_ reading: T) {
        do {
            try self.readingStore.save(reading)
        } catch {
            assert(false)
            print("Error saving ")
        }
        
        let drawTextPayload = DrawTextPayload(string: reading.stringValue, point: .init(0.075, 0.5), font: .system, color: .red)
        self.graphicsContext.queueCommand(.drawText(drawTextPayload))
    
        let drawLinesPayload1 = DrawLinesPayload(lines: [
            Line(0.05, 0.05, 0.95, 0.05),
            Line(0.95, 0.05, 0.95, 0.95),
            Line(0.95, 0.95, 0.05, 0.95),
            Line(0.05, 0.95, 0.05, 0.05)
        ], width: 2, color: .gray)
        
        self.graphicsContext.queueCommand(.drawLines(drawLinesPayload1))

        self.graphicsContext.render()
        
        self.display.showFrame(self.graphicsContext.frameBuffer.swappedWidthForHeight)
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
