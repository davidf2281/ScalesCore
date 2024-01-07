
public actor GraphicsContext {
    
    private var commandQueue: [GraphicsCommand] = []
    public private(set) var frameBuffer: FrameBuffer
    private let size: Size
    public init(size: Size) {
        self.size = size
        self.frameBuffer = FrameBuffer(width: size.width, height: size.height)
    }
    
    func queueCommand(_ command: GraphicsCommand) {
        self.commandQueue.append(command)
    }
    
    func queueCommands(_ commands: [GraphicsCommand]) {
        self.commandQueue += commands
    }
    
    public func render() async throws {
        
        try Task.checkCancellation()
        
        await self.frameBuffer.clear()
        
        for command in commandQueue {
            switch command {
                case .drawText(let payload):
                    guard let lines = payload.font.linesForString(payload.string)?.offset(by: payload.point) else {
                        return
                    }
                    
                    // Keep text aspect ratio constant by scaling to the inverse of buffer aspect ratio
                    let screenAspectInverse = Double(self.size.height) / Double(self.size.width)
                    for line in lines.scaledNonuniform(scaleX: screenAspectInverse, scaleY: 1.0) {
                        await self.frameBuffer.drawLine(line, width: size.width, height: size.height, color: payload.color, algorithm: .bresenham)
                    }
                    
                case .drawLines(let payload):
                    for line in payload.lines {
                        await self.frameBuffer.drawLine(line, width: size.width, height: size.height, color: payload.color, algorithm: .bresenham)
                    }
            }
        }
                
        self.commandQueue = []
    }
}
