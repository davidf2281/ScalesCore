
public class GraphicsContext {
    
    private var commandQueue: [GraphicsCommand] = []
    private let display: Display
    private let frameBuffer: FrameBuffer
    
    public init(display: Display) {
        self.display = display
        self.frameBuffer = FrameBuffer(width: display.width, height: display.height)
    }
    
    func queueCommand(_ command: GraphicsCommand) {
        self.commandQueue.append(command)
    }
    
    private func render() {
        
        for command in commandQueue {
            switch command {
                case .drawText(let payload):
                    break // TODO: Implement me
                case .drawLines(let payload):
                    break // TODO: Implement me
            }
        }
        
        self.display.showFrame(self.frameBuffer)
    }
}
