
public class GraphicsContext {
    
    private var commandQueue: [GraphicsCommand] = []
    private let display: Display
    private var frameBuffer: FrameBuffer
    
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
                    for line in payload.lines {
                        line.draw(width: display.width, height: display.height, color: payload.color, algorithm: payload.algorithm, buffer: &self.frameBuffer)
                    }
            }
        }
        
        self.display.showFrame(self.frameBuffer)
    }
}

private extension Line {
    
    func draw(width: Int, height: Int, color: Color24, algorithm: Line.Algorithm, buffer: inout FrameBuffer) {
        switch algorithm {
            case .naive:
                drawNaive(width: width, height: height, color: color, buffer: &buffer)
                
            case .bresenham:
                drawBresenham(width: width, height: height, color: color, buffer: &buffer)
        }
    }
    
    private func drawNaive(width: Int, height: Int, color: Color24, buffer: inout FrameBuffer) {
        assert(false)
        let x1 = Int(self.start.x * Double(width - 1))
        let y1 = Int(self.start.y * Double(height - 1))

        let x2 = Int(self.end.x * Double(width - 1))
        let y2 = Int(self.end.y * Double(height - 1))
        
        let dx = x2 - x1
        let dy = y2 - y1
        
        for x in x1...x2 {
            let y = y1 + dy * (x - x1) / dx
            buffer.plotPixel(x, y, color: color)
        }
    }
    
    private func drawBresenham(width: Int, height: Int, color: Color24, buffer: inout FrameBuffer) {
        
        /* Algo lifted straight from wikipedia: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm */
        
        var x0 = Int(self.start.x * Double(width - 1))
        var y0 = Int(self.start.y * Double(height - 1))

        let x1 = Int(self.end.x * Double(width - 1))
        let y1 = Int(self.end.y * Double(height - 1))
        
        let dx = abs(x1 - x0)
        let sx = x0 < x1 ? 1 : -1
        let dy = -abs(y1 - y0)
        let sy = y0 < y1 ? 1 : -1
        var error = dx + dy
        while true {
            buffer.plotPixel(x0, y0, color: color)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * error
            if e2 >= dy {
                if x0 == x1 { break }
                error = error + dy
                x0 = x0 + sx
            }
            if e2 <= dx {
                if y0 == y1 { break }
                error = error + dx
                y0 = y0 + sy
            }
        }
    }
}
