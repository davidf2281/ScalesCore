
public class GraphicsContext {
    
    private var commandQueue: [GraphicsCommand] = []
    private let display: Display
    private let frameBuffer: FrameBuffer
    
    public init(display: Display) {
        self.display = display
        self.frameBuffer = FrameBuffer(width: display.width, height: display.height)
        self.display.showFrame(self.frameBuffer)
    }
    
    func queueCommand(_ command: GraphicsCommand) {
        self.commandQueue.append(command)
    }
    
    public func render() {
        for command in commandQueue {
            switch command {
                case .drawText(_):
                    break // TODO: Implement me
                    
                case .drawLines(let payload):
                    
                    let x1 = Int(payload.lines.first!.start.x * Double(display.width))
                    let y1 = Int(payload.lines.first!.start.y * Double(display.height))

                    let x2 = Int(payload.lines.first!.end.x * Double(display.width))
                    let y2 = Int(payload.lines.first!.end.y * Double(display.height))
                    
                    let dx = x2 - x1
                    let dy = y2 - y1
                    
                    for x in x1...x2 {
                        let y = y1 + dy * (x - x1) / dx
                        self.frameBuffer.plotPixel(x, y, color: payload.color)
                    }
            }
        }
        
        self.display.showFrame(self.frameBuffer)
    }
}
